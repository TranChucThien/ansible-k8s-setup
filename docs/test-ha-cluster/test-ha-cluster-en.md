# Kubernetes High Availability Cluster Testing

This document describes the complete HA testing process, including:

- Internal Etcd status inspection (via `kubectl exec`)
- Workload deployment for real-world behavior monitoring
- Test scenario execution
- Analysis of Etcd quorum behavior, API server failover, and data-plane resiliency

**Environment:** Kubernetes v1.33 (Multi-Master, Stacked Etcd)

**Architecture:** 3 Control Plane Nodes (Masters), 1 Worker Node, 2 HAProxy/Keepalived Load Balancers

```markdown
## 🏗️ Architecture Overview
                    ┌─────────────────┐
                    │   Virtual IP    │
                    │ 192.168.10.100  │ ← Keepalived VIP
                    └─────────┬───────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    ┌─────▼─────┐       ┌─────▼─────┐       ┌─────▼─────┐
    │ HAProxy1  │       │ HAProxy2  │       │ HAProxy3  │
    │ (MASTER)  │       │ (BACKUP)  │       │ (BACKUP)  │
    │ .141      │       │ .143      │       │ (future)  │
    └─────┬─────┘       └─────┬─────┘       └─────┬─────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    ┌─────▼─────┐       ┌─────▼─────┐       ┌─────▼─────┐
    │ Master1   │       │ Master2   │       │ Master3   │
    │ etcd1     │       │ etcd2     │       │ etcd3     │
    │ .138      │       │ .139      │       │ .140      │
    └───────────┘       └───────────┘       └───────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │    Worker Nodes   │
                    │      .142         │
                    └───────────────────┘
```

---

# **PART 1 — BASELINE HEALTH CHECK**

First, verify the baseline state of the Kubernetes cluster to ensure all components are operating stably.

---

## **1. Validate Node & System Pod Health**

**Expectation:** All 3 etcd pods must be in `Running` state on 3 different control-plane nodes.

```bash
# Check node list
kubectl get nodes -o wide

# Check etcd pods running in kube-system namespace
kubectl get pods -n kube-system -l component=etcd -o wide
```

![Node Status](images/baseline/01-nodes-status.png)

![Etcd Pods Status](images/baseline/02-etcd-pods.png)

---

## **2. Etcd Inspection (kubectl exec direct inspection)**

Instead of installing `etcdctl` on the host, use **direct exec into etcd container**.

### **2.1. Check etcd member list**

```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://k8s-master-1:2379,https://k8s-master-2:2379,https://k8s-master-3:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list --write-out=table
```

![Etcd Member List](images/etcd-tests/01-member-list.png)

### **2.2. Check Leader and Raft health**

```bash
kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://k8s-master-1:2379,https://k8s-master-2:2379,https://k8s-master-3:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```

![Etcd Endpoint Status](images/etcd-tests/02-endpoint-status.png)

---

# **PART 2 — DEPLOY WORKLOAD**

## **1. Deploy a sample workload**

```bash
kubectl create deployment nginx-ha-test \
  --image=nginx:latest \
  --replicas=3

kubectl expose deployment nginx-ha-test \
  --port=80 \
  --type=NodePort \
  --name=nginx-service
```

![Nginx Deployment](images/workload/01-nginx-deployment.png)

---

# **PART 3 — SCENARIO 1: CONTROL-PLANE FAILURE & ETCD LEADER FAILOVER**

**Objective:** Verify Etcd leader failover, HAProxy, and Kubernetes API behavior when losing 1 master.

---

## **1. Action: Shutdown Master Node holding Etcd Leader role**

```bash
ssh master@k8s-master-1 "sudo poweroff"
```

(*Replace `k8s-master-1` with actual leader.*)

---

## **2. Post-failure Verification**

**Expected:** New leader must be elected, cluster remains stable.

SSH to a surviving Master:

```bash
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://k8s-master-1:2379,https://k8s-master-2:2379,https://k8s-master-3:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```

![Etcd Status After Failure](images/control-plane-failure/01-etcd-status-after-failure.png)

- Etcd reports error with k8s-master-1 → This is expected when Master Leader is down
    
    ```bash
    rpc error: ... dial tcp 192.168.10.138:2379: connect: no route to host
    Failed to get the status of endpoint https://k8s-master-1:2379
    ```
    
- Etcd endpoint status result — Leader failover successful: **Etcd elected new leader `k8s-master-2`.** This confirms **etcd quorum is maintained**:
    - Etcd nodes: 3
    - Alive nodes: 2
    
    → **Etcd cluster operates normally**, no data loss, no write loss.

![Cluster Status After Failure](images/control-plane-failure/02-cluster-status.png)

- K8s Node Status: `k8s-master-1` shutdown → becomes `NotReady`
- Nginx HA Test application still runs fine — proves entire cluster is unaffected

## **3. Summary**

After shutting down 1 master (etcd leader), we proved:

### **✔ 1. Etcd leader failover works correctly**

- Dead node → leader automatically re-elected
- New leader is `k8s-master-2`
- Quorum remains 2/3 so etcd cluster can still read/write

### **✔ 2. Control-plane HA still operational**

- kube-apiserver continues serving via HAProxy
- Control-plane components not interrupted

### **✔ 3. Kubernetes cluster remains stable**

- No pod restarts
- No scheduling issues
- Services still operational

---

# **PART 4 — SCENARIO 2: QUORUM LOSS / SPLIT-BRAIN PROTECTION**

**Objective:** Test behavior when Etcd loses quorum (1/3 members alive).

---

## **1. Action: Shutdown another control-plane node**

```bash
ssh user@k8s-master-2 "sudo poweroff"
```

---

## **2. Analysis**

- **Etcd Quorum Requirement:**
    
    ```
    Quorum = ⌊N/2⌋ + 1 = 2
    ```
    
    Only 1 node remains → **quorum lost**.
    
- **Etcd Behavior:**
    - Reject all write operations: cannot achieve quorum for leader election and data replication. Cluster enters read-only state, rejecting updates.
    - Limited read support: Etcd supports reads from local data on each node (serializable snapshot isolation), but Kubernetes API server requires strongly-consistent reads so will fail without leader.
    - Cannot elect leader: Cannot perform election due to lack of majority nodes (quorum = n/2 + 1), resulting in "no leader" state and stuck cluster.
- **Kubernetes API:** Cannot serve requests → `Unable to connect to the server`.
- **Workload (Pods):** **STILL running** because data-plane (Kubelet, Container runtime) operates independently from control-plane.

---

## **3. Verification**

**Expected:** 

- Commands will timeout → This is correct behavior when Etcd loses quorum.
- Workload on worker nodes still operational

```bash
kubectl get nodes

curl 192.168.10.142:31324 #Worker node IP and service port

etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint status --write-out=table | less -S
  
 etcdctl \
  --endpoints=https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health --cluster=false --write-out=table
  
  
  etcdctl \
  --endpoints=https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  get / --prefix --consistency=s --keys-only | grep service
```

![Kubectl Timeout](images/quorum-loss/01-kubectl-timeout.png)

- Correct per spec: **Control-plane not operational.**
    - kube-apiserver uses etcd to read all cluster information → When etcd loses quorum → kube-apiserver **cannot serve requests**
    - HAProxy/Keepalived still operational but **API server not responding**
- Since **data-plane operates independently from control-plane → workload still runs**

![Workload Still Running](images/quorum-loss/02-workload-still-running.png)

![Nginx Still Accessible](images/quorum-loss/03-nginx-accessible.png)

![Etcd Health Check](images/quorum-loss/04-etcd-health-check.png)

![Etcd Serializable Read](images/quorum-loss/05-etcd-serializable-read.png)

The command has parameter `--consistency=s` (short for `serializable`).

- **Linearizable (Default - `l`):** When reading, this etcd node (even if Follower) must contact Leader to confirm data is latest. If connection to Leader is lost, read command will fail.
- **Serializable (`s`):** Etcd is instructed to read directly from data in **local store** of that node without asking Leader.
    - **Conclusion:** The command succeeding with `s` flag proves it's getting data stored locally on node `192.168.10.140`.

---

# **PART 5 — RECOVERY**

**Objective:** Confirm cluster can recover when member count returns to sufficient quorum.

---

## **1. Action: Bring Master Node #2 back online**

Power on master node 2

---

## **2. Verify Control-Plane Recovery**

Expected: Must work immediately when quorum (2/3) is restored.

```bash
kubectl get nodes
```

![Cluster Recovered](images/recovery/01-cluster-recovered.png)

---

## **3. Verify Write Path Recovery**

```bash
kubectl scale deployment nginx-ha-test --replicas=5
```

![Scaling Test](images/recovery/02-scaling-test.png)

Scheduler creates additional Pods → cluster fully recovered.

---

# **PART 6 — HAProxy/Keepalived Testing**

🎯 **Objectives**

- Test **failover** VIP from MASTER → BACKUP when Master node fails.
- Test **failback** BACKUP → MASTER when Master recovers.
- Ensure services (HAProxy, API Server, or any service using VIP) **experience no prolonged interruption**.

---

## **1. Check Initial State (Baseline)**

### 1.1 SSH to both nodes and check Keepalived status

**Expected:**

- Keepalived = active (running)
- VIP 192.168.10.100 must be on network interface of node 141.
- NO VIP on node 143

```bash
# Check which node owns the VIP
for node in 192.168.10.141 192.168.10.143; do
  echo "Checking VIP on $node:"
  ssh ha@$node "ip addr show | grep 192.168.10.100 || echo 'No VIP found'"
done

# Check HAProxy stats 
curl -I http://192.168.10.141:8404/stats
curl -I http://192.168.10.143:8404/stats
```

![VIP Baseline Check](images/haproxy-keepalived/01-vip-baseline.png)

---

### 1.2 Check VRRP role via logs

**Expected:**

- Node 141 = `MASTER`
- Node 143 = `BACKUP`

```bash
ssh ha@192.168.10.141 "systemctl status keepalived"
ssh ha@192.168.10.143 "systemctl status keepalived"
```

![Master Status](images/haproxy-keepalived/02-master-status.png)

![Backup Status](images/haproxy-keepalived/03-backup-status.png)

---

## 🔥 **2. SCENARIO 1 — FAILOVER (MASTER → BACKUP)**

**Objective:** When MASTER dies, VIP moves to BACKUP

---

### 2.1 **Shutdown MASTER node**

SSH from another node:

```bash
ssh ha@192.168.10.141 
sudo poweroff
```

---

### 2.2 **Check failover at BACKUP node**

```bash
ip a | grep 192.168.10.100
```

**Expected:**

- Node 143 *receives VIP*.
- Interface: usually `eth0` or `ens33`.

![VIP Failover](images/haproxy-keepalived/04-vip-failover.png)

---

### 2.3 Check Keepalived logs on BACKUP

```bash
journalctl -u keepalived -n 20
```

**Expected:**

- MASTER STATE

![Backup Logs](images/haproxy-keepalived/05-backup-logs.png)

---

### 2.4 Check service connectivity (via VIP)

Ping VIP:

```bash
ping -c4 192.168.10.100
```

![Ping VIP](images/haproxy-keepalived/06-ping-vip.png)

---

## 3. SCENARIO 2 — FAILBACK (BACKUP → MASTER)

### 3.1 Check logs on MASTER

```bash
ssh ha@192.168.10.141 "systemctl status keepalived"
```

**Expected:**

```
MASTER STATE
```

![Master Recovered](images/haproxy-keepalived/07-master-recovered.png)

---

### 3.2 Check VIP

```bash
#On MASTER
ip a | grep 192.168.10.100
```

**Expected:** VIP returns to node 141.

---

```bash
#On BACKUP:
ip a | grep 192.168.10.100
```

**Expected:** Node 143 no longer holds VIP.

![VIP Failback](images/haproxy-keepalived/08-vip-failback.png)

---

## 3.3 Check services after failback

```bash
kubectl get no
kubectl get all
```

**Expected:**

- Services remain continuous.
- No connection loss.

![Final Status](images/haproxy-keepalived/09-final-status.png)

---