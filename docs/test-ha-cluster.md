# Test HA Cluster - Etcd Sync & Availability

> Test cluster 3 masters về đồng bộ etcd và độ khả dụng

## Prerequisites
- Cluster: 3 masters + 1 worker
- kubectl configured on master-1

---

## Test 1: Kiểm tra Etcd Cluster Health

### 1.1. Xem danh sách etcd members
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list -w table
```

**Expected output:**
- 3 members: master-1, master-2, master-3
- All members: `started`

### 1.2. Kiểm tra endpoint health của cả 3 masters
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health -w table
```

**Expected output:**
```
+-----------------------------+--------+--------------+-------+
|          ENDPOINT           | HEALTH |     TOOK     | ERROR |
+-----------------------------+--------+--------------+-------+
| https://192.168.10.139:2379 |   true | 149.063647ms |       |
| https://192.168.10.140:2379 |   true | 148.489748ms |       |
| https://192.168.10.138:2379 |   true | 157.444345ms |       |
+-----------------------------+--------+--------------+-------+
```
- All 3 endpoints: `HEALTH = true`

### 1.3. Kiểm tra endpoint status
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status -w table
```

**Expected output:**
```
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|          ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.10.138:2379 | e09fc9cfd94aa09f |  3.5.24 |  8.4 MB |      true |      false |         2 |       4421 |               4421 |        |
| https://192.168.10.139:2379 | b8caa5f2f3e2b3d2 |  3.5.24 |  7.5 MB |     false |      false |         2 |       4422 |               4422 |        |
| https://192.168.10.140:2379 | 9992afccf74f0d62 |  3.5.24 |  8.2 MB |     false |      false |         2 |       4422 |               4422 |        |
+-----------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```
- 1 leader (IS LEADER = true): master-1 (192.168.10.138)
- 2 followers (IS LEADER = false): master-2, master-3
- DB size similar: ~7-8 MB
- RAFT INDEX synced across all members

---

## Test 2: Test Đồng Bộ Dữ Liệu Kubernetes

### 2.1. Tạo deployment từ master-1
```bash
kubectl create deployment test-sync --image=nginx --replicas=3
kubectl get deployment test-sync -o wide
```

### 2.2. Kiểm tra từ master-2
```bash
# SSH to master-2
ssh master@k8s-master-2

# Check deployment
kubectl get deployment test-sync
kubectl get pods -l app=test-sync -o wide
```

### 2.3. Kiểm tra từ master-3
```bash
# SSH to master-3
ssh master@k8s-master-3

# Check deployment
kubectl get deployment test-sync
kubectl get pods -l app=test-sync -o wide
```

### 2.4. Scale deployment từ master-2
```bash
# On master-2
kubectl scale deployment test-sync --replicas=5

# Check from master-1
kubectl get deployment test-sync
```

### 2.5. Cleanup
```bash
kubectl delete deployment test-sync
```

**Expected result:**
- Deployment visible from all masters
- Scale operation synced across all masters

---

## Test 3: Test Etcd Data Consistency

### 3.1. Ghi dữ liệu vào etcd từ master-1
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  put /test-key "data-from-master-1"
```

### 3.2. Đọc từ master-2
```bash
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /test-key
```

### 3.3. Đọc từ master-3
```bash
kubectl exec -n kube-system etcd-k8s-master-3 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /test-key
```

### 3.4. Cleanup
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  del /test-key
```

**Expected result:**
- Data written to master-1 readable from master-2 and master-3

---

## Test 4: Test Failover - Tắt 1 Master (Quorum 2/3)

### 4.1. Kiểm tra trạng thái ban đầu
```bash
kubectl get nodes
kubectl get pods -n kube-system -o wide
```

### 4.2. Tắt master-2
```bash
# SSH to master-2
ssh master@k8s-master-2

# Stop kubelet and containerd
sudo systemctl stop kubelet
sudo systemctl stop containerd

# Check status
sudo systemctl status kubelet
sudo systemctl status containerd
```

### 4.3. Kiểm tra cluster từ master-1 (vẫn hoạt động)
```bash
# Check nodes (master-2 will be NotReady)
kubectl get nodes

# Check etcd health (2/3 still healthy)
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health -w table

# Create test pod
kubectl run test-failover --image=nginx

# Check pod created
kubectl get pod test-failover -o wide
```

### 4.4. Kiểm tra etcd quorum
```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status -w table
```

### 4.5. Bật lại master-2
```bash
# On master-2
sudo systemctl start containerd
sudo systemctl start kubelet

# Wait for node ready
kubectl get nodes -w
```

### 4.6. Cleanup
```bash
kubectl delete pod test-failover
```

**Expected result:**
- Cluster vẫn hoạt động khi tắt 1 master
- Etcd có quorum 2/3
- Có thể tạo pods mới
- Master-2 rejoin cluster sau khi bật lại

---

## Test 5: Test API Server Failover

### 5.1. Kiểm tra health của tất cả API servers
```bash
# Master-1
curl -k https://192.168.10.138:6443/healthz

# Master-2
curl -k https://192.168.10.139:6443/healthz

# Master-3
curl -k https://192.168.10.140:6443/healthz
```

**Expected output:** `ok` from all

### 5.2. Test kubectl với từng API server
```bash
# Test master-1
kubectl --server=https://192.168.10.138:6443 get nodes

# Test master-2
kubectl --server=https://192.168.10.139:6443 get nodes

# Test master-3
kubectl --server=https://192.168.10.140:6443 get nodes
```

### 5.3. Tắt API server trên master-2
```bash
# On master-2
sudo systemctl stop kube-apiserver

# Or stop kubelet (stops all control plane)
sudo systemctl stop kubelet
```

### 5.4. Kiểm tra API server master-1 và master-3 vẫn hoạt động
```bash
kubectl --server=https://192.168.10.138:6443 get nodes
kubectl --server=https://192.168.10.140:6443 get nodes
```

### 5.5. Bật lại master-2
```bash
# On master-2
sudo systemctl start kubelet
```

**Expected result:**
- API servers hoạt động độc lập
- Tắt 1 API server không ảnh hưởng các API server khác

---

## Test 6: Test Quorum Loss - Tắt 2 Masters (CLUSTER DOWN)

> ⚠️ **WARNING**: Test này sẽ làm cluster KHÔNG hoạt động

### 6.1. Tắt master-2
```bash
# On master-2
sudo systemctl stop kubelet
```

### 6.2. Tắt master-3
```bash
# On master-3
sudo systemctl stop kubelet
```

### 6.3. Kiểm tra cluster từ master-1 (KHÔNG hoạt động)
```bash
# This will timeout or error
kubectl get nodes
```

**Output:**
```
Error from server: etcdserver: request timed out
Error from server: etcdserver: request timed out
```

```bash
# Etcd lost quorum (only 1/3)
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status -w table
```

**Output:**
```
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://127.0.0.1:2379 | e09fc9cfd94aa09f |  3.5.24 |  8.4 MB |      true |      false |         3 |       5857 |               5857 |        |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

**Giải thích:**
- `kubectl get nodes` timeout vì API server không thể ghi vào etcd (mất quorum)
- Etcd vẫn chạy nhưng chỉ còn 1/3 members (không đủ quorum 2/3)
- RAFT TERM tăng lên (từ 2 → 3) do election mới
- Etcd ở trạng thái read-only, không thể write

### 6.4. Bật lại master-2 (khôi phục quorum)
```bash
# On master-2
sudo systemctl start kubelet

# Wait 30s, then test from master-1
kubectl get nodes
```

**Output sau khi khôi phục:**
```bash
# Cluster hoạt động trở lại
kubectl get nodes
# NAME            STATUS   ROLES           AGE   VERSION
# k8s-master-1    Ready    control-plane   XXh   v1.33.0
# k8s-master-2    Ready    control-plane   XXh   v1.33.0
# k8s-master-3    NotReady control-plane   XXh   v1.33.0  (still down)
# k8s-worker-1    Ready    <none>          XXh   v1.33.0

# Etcd có quorum 2/3
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health -w table
# 2/3 endpoints healthy → cluster hoạt động
```

### 6.5. Bật lại master-3
```bash
# On master-3
sudo systemctl start kubelet
```

**Expected result:**
- Tắt 2 masters: cluster KHÔNG hoạt động (mất quorum)
- Bật lại 1 master: cluster hoạt động trở lại (quorum 2/3)

---

## Test 7: Test Controller Manager & Scheduler Leader Election

### 7.1. Kiểm tra leader hiện tại
```bash
# Controller Manager leader
kubectl get endpoints kube-controller-manager -n kube-system -o yaml | grep holderIdentity

# Scheduler leader
kubectl get endpoints kube-scheduler -n kube-system -o yaml | grep holderIdentity
```

### 7.2. Tắt master đang là leader
```bash
# Assume master-1 is leader, stop it
# On master-1
sudo systemctl stop kubelet
```

### 7.3. Kiểm tra leader mới được bầu
```bash
# From master-2
kubectl get endpoints kube-controller-manager -n kube-system -o yaml | grep holderIdentity
kubectl get endpoints kube-scheduler -n kube-system -o yaml | grep holderIdentity
```

### 7.4. Bật lại master-1
```bash
# On master-1
sudo systemctl start kubelet
```

**Expected result:**
- Leader election tự động chuyển sang master khác
- Controller Manager và Scheduler vẫn hoạt động

---

## Summary - Expected Results

| Test | Scenario | Expected Result |
|------|----------|-----------------|
| Test 1 | Etcd health | 3 members healthy, 1 leader + 2 followers |
| Test 2 | K8s data sync | Deployment synced across all masters |
| Test 3 | Etcd data sync | Data written to 1 master readable from others |
| Test 4 | 1 master down | Cluster works (quorum 2/3) |
| Test 5 | API server down | Other API servers still work |
| Test 6 | 2 masters down | Cluster DOWN (lost quorum) |
| Test 7 | Leader election | New leader elected automatically |

---

## Troubleshooting

### Etcd member unhealthy
```bash
# Check logs
kubectl logs -n kube-system etcd-k8s-master-X

# Restart kubelet
sudo systemctl restart kubelet
```

### Node NotReady after restart
```bash
# Wait 1-2 minutes for kubelet to start
kubectl get nodes -w

# Check kubelet status
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

### Etcd quorum lost
```bash
# Need to restore from backup or rebuild cluster
# Prevention: Never stop more than 1 master at a time
```

---

**Conclusion**: Multi-master cluster provides HA but requires minimum 2/3 nodes for quorum.
