# Tài Liệu Vận Hành & Kiểm Thử K8s Cluster (Ansible)

## Mục Lục
- [Phần 1: Chuẩn Bị và Kiểm Tra Điều Kiện Tiên Quyết](#phần-1-chuẩn-bị-và-kiểm-tra-điều-kiện-tiên-quyết)
- [Phần 2: Vận Hành Master Node](#phần-2-vận-hành-master-node)
- [Phần 3: Vận Hành Worker Node](#phần-3-vận-hành-worker-node)

## Phần 1: Chuẩn Bị và Kiểm Tra Điều Kiện Tiên Quyết

### Tổng Quan Hạ Tầng Triển Khai

#### Giai đoạn 1 - Cluster Ban Đầu

| Component | IP Address | Role |
|-----------|------------|------|
| Master | 192.168.10.138 | etcd embedded |
| Worker | 192.168.10.142 | Compute node |
| HAProxy Primary | 192.168.10.141 | Load balancer + Keepalived |
| HAProxy Backup | 192.168.10.143 | Backup load balancer |
| VIP | 192.168.10.100 | Virtual IP (Keepalived) |

#### Giai đoạn 2 - Scale-up

| Component | IP Address | Purpose |
|-----------|------------|----------|
| Master 2 | 192.168.10.139 | Additional control plane |
| Master 3 | 192.168.10.140 | Additional control plane |
| Worker 2 | 192.168.10.144 | Additional compute (optional) |
| etcd cluster | 3 nodes | Quorum 2/3 |

### Kiểm Tra Trạng Thái Cluster Ban Đầu

```bash
# Check initial cluster status
kubectl get nodes -o wide
kubectl get pods -A

# Check etcd health (single node)
kubectl exec -n kube-system etcd-$(hostname) -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

```

![Cluster Overview](images/2025-12-18_16h24_25.png)
*Hình 1: Trạng thái cluster ban đầu*

![ETCD Status](images/2025-12-18_16h26_43.png)
*Hình 2: Trạng thái etcd cluster*

```bash
# Check HAProxy status
curl -I http://192.168.10.141:8404/stats

# Check VIP status
ansible ha -i inventory-lab -m shell -a "ip addr show | grep 192.168.10.100" --become
```

![HAProxy and VIP Status](images/01-cluster-overview.png)
*Hình 3: HAProxy stats và VIP status*

### Kiểm Tra Kết Nối SSH

```bash
# Test SSH connection to all nodes
ansible all -i inventory -m ping

# Test specific groups
ansible masters -i inventory -m ping
ansible workers -i inventory -m ping
ansible haproxy -i inventory -m ping
```

![SSH Connection Test](images/02-inventory-structure.png)
*Hình 4: Kết quả test kết nối SSH tới các nodes*

## Phần 2: Vận Hành Master Node

### 2.1. Thêm Master Mới (Scale-up)

#### Lý Thuyết về Quy Trình Join Master

**Tại sao cần join master theo thứ tự:**

1. **etcd Cluster Formation**: etcd cần tạo cluster với quorum (majority)
2. **Certificate Distribution**: Certificates phải được share giữa các masters
3. **API Server Registration**: Mỗi master cần register với load balancer
4. **Control Plane Components**: kubelet, kube-proxy, scheduler cần sync

**Thành phần cần thiết cho Join Master:**

- **Certificate Key**: Để decrypt và share certificates
- **Join Token**: Authentication token cho cluster
- **CA Certificate Hash**: Verify cluster identity
- **Control Plane Endpoint**: VIP address (192.168.10.100:6443)

**Quá trình Join Master:**

1. **Certificate Upload**: Master đầu tiên upload certs với certificate-key
2. **Token Generation**: Tạo join token với certificate-key
3. **Join Command**: New master sử dụng join command với --control-plane flag
4. **etcd Member Add**: Tự động thêm vào etcd cluster
5. **Component Sync**: Sync kubelet, kube-proxy configs

#### Quy Trình Thực Hiện

```bash
# Bước 1: Kiểm tra kết nối
ansible new_masters -i inventory-lab -m ping

# Bước 2: Cài đặt cơ bản
ansible-playbook -i inventory-lab playbooks/01-common.yaml --limit new_masters

# Bước 3: Join vào cluster
ansible-playbook -i inventory-lab playbooks/03-join-master.yaml --limit 192.168.10.138:new_masters

# Bước 4: Kiểm tra kết quả
kubectl get nodes -o wide
kubectl get pods -A
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list --write-out=table

```

![Master Join Process](images/04-master-join-process.png)
*Hình 5: Kết quả join master nodes thành công*

### 2.2. Xóa Master (Scale-down)

#### Lý Thuyết về Quy Trình Remove Master

**Tại sao cần remove master theo thứ tự:**

1. **etcd Consensus**: etcd sử dụng Raft algorithm, cần maintain quorum (majority)
2. **API Server Load Balancing**: HAProxy cần update backend servers
3. **Certificate Management**: Cleanup certificates và keys
4. **Resource Cleanup**: Remove kubelet data, CNI configs

**Thứ tự quan trọng:**

- Remove từ etcd cluster TRƯỚC (maintain quorum)
- Remove từ Kubernetes cluster SAU
- Cleanup node cuối cùng

#### Quy Trình Manual (Reference)

```bash
# Get member ID
MEMBER_ID=$(kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list | grep master-3 | cut -d',' -f1)

# Remove member
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member remove $MEMBER_ID

```

#### Quy Trình Automated

```bash
#remove khỏi cluster
ansible-playbook -i inventory-lab playbooks/04-remove-master.yaml 

#reset nodes
ansible-playbook -i inventory-lab playbooks/99-k8s-reset-node.yml --limit remove_masters 

```

#### Validation

```bash
# Check etcd quorum (should be odd number)
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Test cluster resilience
kubectl get nodes
kubectl get pods -A

```

![Remove Master Process](images/07-remove-master-process.png)
*Hình 6: Kết quả remove master nodes*

## Phần 3: Vận Hành Worker Node

### 3.1. Thêm Worker Mới

```bash
# Run common setup
ansible-playbook -i inventory-lab playbooks/01-common.yaml --limit new_workers

# Join worker to cluster
ansible-playbook -i inventory-lab playbooks/03-join-worker.yaml --limit 192.168.10.138:new_workers

```

![Worker Scaling](images/06-worker-scaling.png)
*Hình 7: Kết quả thêm worker nodes*

#### Validation

```bash
# Create Deployment
kubectl create deployment web-test --image=nginx

# Expose Deployment as NodePort Service
kubectl expose deployment web-test \
  --type=NodePort \
  --port=80 \
  --name=web-test-svc

# Get Service and NodePort
kubectl get svc web-test-svc

# Test connectivity from Node (Host)
curl http://<NODE-IP>:<NODEPORT>

# Cleanup
kubectl delete deployment web-test
kubectl delete svc web-test-svc
```

![Service Validation](images/03-pre-flight-checks.png)
*Hình 8: Test service connectivity trên worker nodes*

### 3.2. Xóa Worker (Decommissioning)

#### Lý Thuyết về Remove Worker An Toàn

1. **Cordon:**
    - **Mục đích**: Ngăn scheduler tạo pods mới trên node ta muốn xóa
    - **Cơ chế**: Đánh dấu node là "unschedulable"
    - **Tác động**: Pods hiện tại vẫn chạy, nhưng không có pods mới
    - **Lệnh**: `kubectl cordon <node-name>`
2. **Drain:**
    - **Mục đích**: Di chuyển tất cả pods khỏi node một cách an toàn
    - **Cơ chế**: Evict pods và reschedule lên nodes khác
    - **Tác động**: Node trở nên "empty" và sẵn sàng remove
    - **Lệnh**: `kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force`

**Quy Trình 3 Bước Remove Worker:**

```
1. CORDON  → Ngăn pods mới
2. DRAIN   → Di chuyển pods hiện tại
3. DELETE  → Xóa node khỏi cluster
```

#### So Sánh Phương Pháp

**❌ Xóa trực tiếp (kubectl delete node) gây:**

- **Service Disruption**: Pods bị terminate đột ngột
- **Data Loss**: EmptyDir volumes bị mất
- **Connection Drops**: Active connections bị ngắt
- **Resource Waste**: Pods không được reschedule

**✅ Cordon + Drain + Delete đảm bảo:**

- **Zero Downtime**: Pods được di chuyển trước khi xóa
- **Data Safety**: Graceful termination với cleanup
- **Service Continuity**: Pods được reschedule lên nodes khác
- **Resource Optimization**: Tài nguyên được tái phân bổ

#### Quy Trình Automated

```bash
# Chạy playbook remove worker (tự động cordon + drain + delete)
ansible-playbook -i inventory-lab playbooks/05-remove-worker.yaml

# Playbook sẽ thực hiện:
# 1. Cordon nodes (ngăn pods mới)
# 2. Drain nodes (di chuyển pods hiện tại)
# 3. Delete nodes khỏi cluster

# Reset cấu hình Kubernetes trên node
ansible-playbook -i inventory-lab playbooks/99-k8s-reset-node.yml --limit remove_workers
```

#### Validation

```bash
while true; do
  curl -s http://192.168.10.142:30967
  sleep 0.2
done
```

![Remove Worker Process](images/08-remove-worker-process.png)
*Hình 9: Quá trình remove worker với zero downtime*

![ETCD Cluster Formation](images/05-etcd-cluster-formation.png)
*Hình 10: Trạng thái etcd cluster sau các thao tác*

---

## Tóm Tắt

Tài liệu này cung cấp hướng dẫn chi tiết về:

- **Pre-flight checks**: Kiểm tra điều kiện tiên quyết
- **Master operations**: Thêm/xóa master nodes an toàn
- **Worker operations**: Thêm/xóa worker nodes với zero downtime
- **Validation**: Kiểm tra và xác nhận các thao tác

Tất cả các thao tác đều được automated bằng Ansible playbooks để đảm bảo tính nhất quán và giảm thiểu lỗi human error. Cluster Formation](images/05-etcd-cluster-formation.png)
*Hình 10: Trạng thái etcd cluster sau các thao tác*