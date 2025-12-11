# High Availability Kubernetes Testing Scenarios

This document provides comprehensive testing scenarios to validate the strength and resilience of our Ansible-deployed HA Kubernetes cluster with HAProxy + Keepalived.

## 🏗️ Architecture Overview

```
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

## 📋 Test Environment Setup

### Infrastructure Components
- **3 Master Nodes**: 192.168.10.138-140 (etcd + API server)
- **2 HAProxy Nodes**: 192.168.10.141, 143 (Load balancers with Keepalived)
- **1 Worker Node**: 192.168.10.142 (Workload execution)
- **Virtual IP**: 192.168.10.100 (Keepalived managed)

### Prerequisites for Testing

**⚠️ Security Warning**: This testing environment uses plaintext passwords for simplicity. 
This is acceptable for isolated test labs but should NEVER be used in production.

```bash
# Install required tools
sudo apt update
sudo apt install -y jq curl

# Copy etcd certificates for local testing
scp -r master@192.168.10.138:/etc/kubernetes/pki/etcd .

# Verify etcdctl is available
which etcdctl || echo "Install etcdctl: https://github.com/etcd-io/etcd/releases"

# For production environments:
# - Use SSH key authentication
# - Configure passwordless sudo with NOPASSWD
# - Use proper certificate management
# - Implement proper access controls
```

### Deployed via Ansible

⚠️ **Security Warning**: This setup uses plaintext passwords for testing. Never use in production.

```bash
# Full cluster deployment
cd /path/to/project-k8s-multi-master-haproxy-keepalived
ansible-playbook -i inventory playbooks/site.yml

# Verify deployment
kubectl get nodes

# Production deployment recommendations:
# - Use SSH keys: ansible-playbook -i inventory --private-key ~/.ssh/id_rsa playbooks/site.yml
# - Use Ansible Vault: ansible-playbook -i inventory --ask-vault-pass playbooks/site.yml
# - Implement proper secret management
```

---

## 🧪 Test Scenario 1: Basic Cluster Validation

### Objective
Verify the cluster is properly deployed and all components are healthy.

### Test Steps

#### 1.1 Cluster Status Validation
```bash
# Connect via VIP
export KUBECONFIG=/path/to/kubeconfig
kubectl get nodes

# Expected Output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   10m   v1.33.6
k8s-master-2   Ready    control-plane   8m    v1.33.6
k8s-master-3   Ready    control-plane   7m    v1.33.6
k8s-worker-1   Ready    <none>          5m    v1.33.6
```

#### 1.2 etcd Cluster Health
```bash
# Copy etcd certificates from master node first
ssh master@192.168.10.138
sudo cp -r /etc/kubernetes/pki/etcd /home/master/
sudo chown -R master:master /home/master/etcd

# Logout and copy to local
scp -r master@192.168.10.138:/home/master/etcd .

# Check etcd health from local machine
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health --write-out=table

# Expected Output (All Healthy):
+-----------------------------+--------+--------------+-------+
|          ENDPOINT           | HEALTH |     TOOK     | ERROR |
+-----------------------------+--------+--------------+-------+
| https://192.168.10.138:2379 |   true |  15.678432ms |       |
| https://192.168.10.139:2379 |   true |  12.345678ms |       |
| https://192.168.10.140:2379 |   true |  18.901234ms |       |
+-----------------------------+--------+--------------+-------+

# Example Output (One Node Failed):
+-----------------------------+--------+--------------+---------------------------+
|          ENDPOINT           | HEALTH |     TOOK     |           ERROR           |
+-----------------------------+--------+--------------+---------------------------+
| https://192.168.10.139:2379 |   true |  21.583638ms |                           |
| https://192.168.10.140:2379 |   true |  22.922916ms |                           |
| https://192.168.10.138:2379 |  false | 5.001822225s | context deadline exceeded |
+-----------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster
```

#### 1.3 HAProxy Status Check (not yet enable stat)
```bash
# Check HAProxy stats 
curl http://192.168.10.141:8404/stats
curl http://192.168.10.143:8404/stats

# Verify all backends are UP
# Expected: All master nodes showing as UP in backend
```

#### 1.4 Keepalived VIP Status
```bash
# Check which node owns the VIP
for node in 192.168.10.141 192.168.10.143; do
  echo "Checking VIP on $node:"
  ssh ha@$node "ip addr show | grep 192.168.10.100 || echo 'No VIP found'"
done

# Check Keepalived logs on both nodes
ssh ha@192.168.10.141 "journalctl -u keepalived -n 10"
ssh ha@192.168.10.143 "journalctl -u keepalived -n 10"

# Expected: One node should have VIP, logs show MASTER/BACKUP states
```

**✅ Success Criteria:**
- All nodes in Ready state
- All etcd members healthy
- HAProxy backends UP
- VIP active on one HAProxy node

---

## 🧪 Test Scenario 2: Workload Deployment & Resilience

### Objective
Deploy a sample application and verify it remains available during failures.

### Test Steps

#### 2.1 Deploy Test Application
```bash
# Create test namespace
kubectl create namespace ha-test

# Deploy nginx with multiple replicas
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ha-test
  namespace: ha-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-ha-test
  template:
    metadata:
      labels:
        app: nginx-ha-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-ha-test-svc
  namespace: ha-test
spec:
  selector:
    app: nginx-ha-test
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
EOF
```

#### 2.2 Verify Application Deployment
```bash
# Check pod distribution across nodes
kubectl get pods -n ha-test -o wide

# Expected: Pods distributed across all available nodes
# Test service accessibility
kubectl get svc -n ha-test
curl http://192.168.10.142:<nodeport>
```

#### 2.3 Continuous Load Testing
```bash
# Start continuous requests (run in background)
while true; do
  curl -s http://192.168.10.142:<nodeport> > /dev/null
  if [ $? -eq 0 ]; then
    echo "$(date): SUCCESS"
  else
    echo "$(date): FAILED"
  fi
  sleep 1
done &

# Save PID for later cleanup
LOAD_TEST_PID=$!
kill %1
```

**✅ Success Criteria:**
- All pods deployed successfully
- Pods distributed across nodes
- Service accessible via NodePort
- Continuous requests succeeding

---

## 🧪 Test Scenario 3: Keepalived VIP Failover Testing

### Objective
Validate Keepalived VIP migration when the MASTER node fails.

### Test Steps

#### 3.1 Identify Current MASTER Keepalived Node
```bash
# Check which node has the VIP (Virtual IP)
for node in 192.168.10.141 192.168.10.143; do
  echo "Checking VIP on $node:"
  ssh ha@$node "ip addr show | grep 192.168.10.100 || echo 'No VIP found'"
done

# Check Keepalived status and priority
ssh ha@192.168.10.141 "systemctl status keepalived"
ssh ha@192.168.10.143 "systemctl status keepalived"

# Expected: One node shows VIP (192.168.10.100), that's the MASTER
```

#### 3.2 Simulate Keepalived MASTER Failure

**⚠️ Security Note**: Using plaintext passwords for testing only. Never use in production.

```bash
# Method 1: Stop Keepalived service (simulates Keepalived failure)
echo "1" | ssh ha@192.168.10.141 "sudo -S systemctl stop keepalived"
# Note: Replace '1' with actual password

# Method 2: Interactive login (recommended for testing)
ssh ha@192.168.10.141
sudo systemctl stop keepalived  # or sudo systemctl stop haproxy
exit

# Monitor VIP migration (should happen within 3-5 seconds)
watch -n 1 'ping -c 1 192.168.10.100'

# Production alternatives:
# - SSH key authentication: ssh -i ~/.ssh/id_rsa ha@192.168.10.141
# - Passwordless sudo: configure NOPASSWD in /etc/sudoers
# - Ansible automation: ansible ha -m systemd -a "name=keepalived state=stopped"
```

#### 3.3 Verify VIP Failover Behavior
```bash
# Check VIP migration (should move to .143)
ssh ha@192.168.10.143 "ip addr show | grep 192.168.10.100"
# Expected: VIP now on .143 node
# inet 192.168.10.100/24 scope global secondary ens33

# Verify original MASTER no longer has VIP
ssh ha@192.168.10.141 "ip addr show | grep 192.168.10.100 || echo 'VIP migrated away'"
# Expected: No output (VIP migrated away)

# ⚠️ CRITICAL: If HAProxy is stopped, Kubernetes API becomes unavailable
kubectl get nodes
# Expected with HAProxy stopped: "connection refused" 
# Expected with only Keepalived stopped: Works normally (HAProxy still running)

# Check application accessibility (depends on what was stopped)
curl http://192.168.10.142:<nodeport>
# Expected: Should work if backend masters are healthy

# Monitor Keepalived logs on new MASTER (.143):
ssh ha@192.168.10.143 "journalctl -u keepalived -n 20"

# Expected log entries on .143 (new MASTER):
# (VI_1) Entering MASTER STATE
# VRRP_Script(check_haproxy) succeeded
# (VI_1) Received advertisement with lower priority

# Check logs on failed node (.141):
ssh ha@192.168.10.141 "journalctl -u keepalived -n 10" 2>/dev/null || echo "Keepalived stopped"
```

#### 3.4 Test Recovery and VIP Migration Back

**⚠️ Security Note**: Using plaintext passwords for testing only.

```bash
# Recovery depends on what was stopped:

# If Keepalived was stopped:
echo "1" | ssh ha@192.168.10.141 "sudo -S systemctl start keepalived"

# If HAProxy was stopped:
echo "1" | ssh ha@192.168.10.141 "sudo -S systemctl start haproxy"

# Method 1: Interactive restart (recommended)
ssh ha@192.168.10.141
sudo systemctl start keepalived  # or haproxy
exit

# Wait for Keepalived to detect service recovery
sleep 10

# Check if VIP migrates back to .141 (higher priority node)
ssh ha@192.168.10.141 "ip addr show | grep 192.168.10.100"
# Expected: VIP should return to .141 due to higher priority (110 vs 100)

# Verify .143 releases VIP
ssh ha@192.168.10.143 "ip addr show | grep 192.168.10.100 || echo 'VIP released'"
# Expected: No VIP (released back to higher priority node)

# Check Keepalived logs on recovered node (.141):
ssh ha@192.168.10.141 "journalctl -u keepalived -n 15"

# Expected log entries on .141 (reclaiming MASTER):
# (VI_1) Entering BACKUP STATE (init)
# VRRP_Script(check_haproxy) succeeded  
# (VI_1) Changing effective priority from 100 to 110
# (VI_1) received lower priority (100) advert from 192.168.10.143 - discarding
# (VI_1) Entering MASTER STATE

# Verify .143 becomes BACKUP again
ssh ha@192.168.10.143 "journalctl -u keepalived -n 10"
# Expected: (VI_1) Master received advert from 192.168.10.141 with higher priority 110
#           (VI_1) Entering BACKUP STATE

# Test Kubernetes API accessibility (should work now)
kubectl  get nodes
# Expected: Normal cluster status

# Production recommendations:
# - Use SSH keys: ssh -i ~/.ssh/id_rsa ha@192.168.10.141
# - Ansible automation: ansible ha -m systemd -a "name=keepalived state=started"
# - Monitoring tools: Nagios, Zabbix, Prometheus for automated recovery
# - Health checks: Automated service monitoring and alerting
```

**✅ Success Criteria:**
- **VIP Migration**: VIP migrates within 3-5 seconds when Keepalived fails
- **Priority-based Recovery**: Higher priority node (110) reclaims VIP from lower priority (100)
- **Service Impact**: 
  - Keepalived failure only: Minimal impact (VIP migrates, services continue)
  - HAProxy failure: API unavailable until service restored or VIP migrates
- **Automatic Failback**: Original MASTER reclaims VIP when recovered
- **Log Visibility**: Clear state transitions in Keepalived logs

**📝 Key Learning:**
```
Keepalived vs HAProxy Failure Impact:
✅ Stop Keepalived only: VIP migrates, API works (HAProxy still running)
❌ Stop HAProxy only: VIP stays, but API fails (no load balancer)
✅ Stop both: Complete failover to backup node

Priority System:
- Node .141: Priority 110 (MASTER)
- Node .143: Priority 100 (BACKUP)
- Higher priority always reclaims VIP when healthy
```

---

## 🧪 Test Scenario 4: Kubernetes Master Node Failover

### Objective
Test etcd and API server resilience when master nodes fail.

### Test Steps

#### 4.1 Baseline etcd Status
```bash
# Check cluster components status
kubectl get componentstatuses
# Expected Output:
# Warning: v1 ComponentStatus is deprecated in v1.19+
# NAME                 STATUS    MESSAGE   ERROR
# controller-manager   Healthy   ok
# scheduler            Healthy   ok
# etcd-0               Healthy   ok

# Check all nodes status
kubectl get nodes
# Expected Output:
# NAME           STATUS   ROLES           AGE     VERSION
# k8s-master-1   Ready    control-plane   6h11m   v1.33.7
# k8s-master-2   Ready    control-plane   6h1m    v1.33.7
# k8s-master-3   Ready    control-plane   6h1m    v1.33.7
# k8s-worker-1   Ready    <none>          5h53m   v1.33.6

# Check etcd member list (using local certificates)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  member list --write-out=table

# Expected Output:
# +------------------+---------+--------------+-----------------------------+-----------------------------+------------+
# |        ID        | STATUS  |     NAME     |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
# +------------------+---------+--------------+-----------------------------+-----------------------------+------------+
# | 5b69bf7e5bd49c74 | started | k8s-master-2 | https://192.168.10.139:2380 | https://192.168.10.139:2379 |      false |
# | e09fc9cfd94aa09f | started | k8s-master-1 | https://192.168.10.138:2380 | https://192.168.10.138:2379 |      false |
# | fd0662997bf732af | started | k8s-master-3 | https://192.168.10.140:2380 | https://192.168.10.140:2379 |      false |
# +------------------+---------+--------------+-----------------------------+-----------------------------+------------+
```

#### 4.2 Simulate Single Master Failure

**Important**: In kubeadm stacked etcd, stopping kubelet does NOT stop etcd pods immediately.

**⚠️ Security Note**: The following commands use plaintext passwords for testing purposes only. 
Never use these methods in production environments. Use SSH keys instead.

```bash
# Method 1: Complete node shutdown (most reliable)
# Option A: Interactive login
ssh master@192.168.10.138
sudo shutdown -h now
# (Connection will be lost)

# Option B: Non-interactive with password (TEST ONLY - NOT FOR PRODUCTION)
echo '1' | ssh master@192.168.10.138 "sudo -S shutdown -h now"
# Note: Replace '1' with actual password

# Method 2: Network isolation (simulates network partition)
ssh master@192.168.10.138
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
exit

# Method 3: Kill etcd process directly (advanced)
ssh master@192.168.10.138
sudo pkill -f etcd
exit

# Note: 
# ❌ sudo systemctl stop kubelet <- Node becomes NotReady but etcd keeps running
# ✅ Complete node shutdown <- Only reliable way to stop etcd
# ✅ Network isolation <- Simulates network failure
```

#### 4.3 Verify Cluster Resilience (After Node Shutdown)
```bash
# Wait for node failure detection
sleep 60

# Check nodes status - failed node should be NotReady
kubectl get nodes
# Expected Output (after node shutdown):
# NAME           STATUS     ROLES           AGE     VERSION
# k8s-master-1   NotReady   control-plane   6h39m   v1.33.7  <- Failed node
# k8s-master-2   Ready      control-plane   6h29m   v1.33.7
# k8s-master-3   Ready      control-plane   6h29m   v1.33.7
# k8s-worker-1   Ready      <none>          6h21m   v1.33.6

# Check etcd pods status - failed node's etcd should be unreachable
kubectl get pods -n kube-system -o wide | grep etcd
# Expected: etcd pods on remaining nodes still running

# Check etcd health - failed endpoint should timeout
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health --write-out=table

# Expected Output (with .138 unreachable after shutdown):
+-----------------------------+--------+--------------+---------------------------+
|          ENDPOINT           | HEALTH |     TOOK     |           ERROR           |
+-----------------------------+--------+--------------+---------------------------+
| https://192.168.10.139:2379 |   true |  21.583638ms |                           |
| https://192.168.10.140:2379 |   true |  22.922916ms |                           |
| https://192.168.10.138:2379 |  false | 5.001822225s | context deadline exceeded |
+-----------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster

# Test cluster functionality - should still work (2/3 quorum)
kubectl get all
# Expected: All existing resources accessible

kubectl run test-pod-failover --image=nginx --restart=Never
# Expected: pod/test-pod-failover created (2/3 etcd quorum sufficient)
```

#### 4.4 Test Critical Operations During Failure
```bash
# Test etcd quorum behavior - only check healthy endpoints
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health --write-out=table

# Expected (2/3 quorum maintained):
+-----------------------------+--------+-------------+-------+
|          ENDPOINT           | HEALTH |    TOOK     | ERROR |
+-----------------------------+--------+-------------+-------+
| https://192.168.10.140:2379 |   true | 16.126979ms |       |
| https://192.168.10.139:2379 |   true | 17.161789ms |       |
+-----------------------------+--------+-------------+-------+

# ⚠️ CRITICAL: If 2 nodes fail (lose quorum), cluster becomes unavailable:
# Example output when quorum lost:
# Shutdown master2
echo '1' | ssh master@192.168.10.139 "sudo -S shutdown -h now"

ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health --write-out=table
+-----------------------------+--------+--------------+---------------------------+
|          ENDPOINT           | HEALTH |     TOOK     |           ERROR           |
+-----------------------------+--------+--------------+---------------------------+
| https://192.168.10.140:2379 |  false | 5.000281678s | context deadline exceeded |
| https://192.168.10.139:2379 |  false | 5.000381946s | context deadline exceeded |
+-----------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster

# When quorum is lost, kubectl operations fail:
kubectl get nodes
# Error from server: etcdserver: request timed out

# Test cluster operations with 2/3 quorum (when available)
kubectl create namespace test-quorum
kubectl run test-quorum-pod --image=nginx -n test-quorum
kubectl get pods -n test-quorum
# Expected: All operations succeed (2/3 > 50% quorum)

# Check existing workloads continue running
kubectl get pods -n ha-test
# Expected: All pods still running normally

# Test etcd write operations
kubectl create configmap test-config --from-literal=test=value
kubectl get configmap test-config
# Expected: ConfigMap created successfully (etcd writes work)

# 📝 Key Learning: etcd quorum is CRITICAL
# - 3 nodes: Can lose 1 node (2/3 quorum)
# - 2 nodes: Cannot lose any node (1/2 < 50%)
# - 1 node: Single point of failure
# Recovery: Power on any failed node to restore quorum
```

#### 4.5 Recovery Testing

**⚠️ Security Note**: Commands shown with plaintext passwords for testing only.

```bash
# Recovery method depends on failure type:

# If node shutdown: Power on the node
# - VM: Start via hypervisor console (VMware vSphere, VirtualBox, etc.)
# - Physical: Power button
# - Cloud: Start instance via AWS/Azure/GCP console

# If network isolation: Clear iptables rules
# Method 1: Interactive
ssh master@192.168.10.138
sudo iptables -F  # Clear all iptables rules
exit

# Method 2: Non-interactive (TEST ONLY)
echo "1" | ssh master@192.168.10.138 "sudo -S iptables -F"

# If killed etcd process:
# etcd pod should restart automatically via kubelet
# Check with: kubectl get pods -n kube-system | grep etcd

# Wait for node to rejoin cluster (2-5 minutes)
sleep 180

# Production recovery procedures:
# - Automated monitoring and alerting
# - Infrastructure as Code (Terraform, CloudFormation)
# - Configuration management (Ansible, Puppet, Chef)
# - Disaster recovery runbooks
```

```bash
# Verify node becomes Ready again
kubectl get nodes

# Expected Output:
# NAME           STATUS   ROLES           AGE     VERSION
# k8s-master-1   Ready    control-plane   6h20m   v1.33.7  <- Back to Ready
# k8s-master-2   Ready    control-plane   6h10m   v1.33.7
# k8s-master-3   Ready    control-plane   6h10m   v1.33.7
# k8s-worker-1   Ready    <none>          6h2m    v1.33.6

# Verify etcd cluster is fully healthy (all 3 members)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint health

# Expected: All 3 endpoints healthy again
# https://192.168.10.138:2379 is healthy: successfully committed proposal: took = 13.117293ms
# https://192.168.10.139:2379 is healthy: successfully committed proposal: took = 16.295806ms
# https://192.168.10.140:2379 is healthy: successfully committed proposal: took = 15.233686ms

# Verify etcd member list (should show all 3 members)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  member list

# Test normal operations after recovery
kubectl run test-pod-recovery --image=nginx --restart=Never
kubectl get pod test-pod-recovery
# Expected: Pod created and running normally

# Clean up test resources
kubectl delete pod test-pod-failover test-quorum-pod test-pod-recovery
kubectl delete namespace test-quorum
kubectl delete configmap test-config
```
```

**✅ Success Criteria:**
- **etcd Architecture**: Understand kubeadm stacked etcd behavior
- **Proper Failure Simulation**: Complete node shutdown or network isolation
- **etcd Quorum**: 2/3 members maintain cluster functionality  
- **API Operations**: All kubectl commands work during failure
- **Data Consistency**: No data loss, all writes preserved
- **Recovery**: Automatic rejoin when node/network restored
- **Zero Downtime**: Existing workloads continue running throughout

**📝 Key Learning:**
```
Kubeadm Stacked etcd Reality:
❌ sudo systemctl stop kubelet     # Node becomes NotReady but etcd keeps running!
✅ sudo shutdown -h now            # Only reliable way to stop etcd
✅ Network isolation (iptables)    # Simulates connectivity issues
✅ sudo pkill -f etcd             # Kill etcd process directly

Important: Static pods are more resilient than expected!
Stopping kubelet ≠ Stopping etcd pods immediately

Security for Production:
✅ SSH key authentication
✅ Passwordless sudo (NOPASSWD)
✅ Proper certificate management
✅ Network segmentation
✅ Monitoring and alerting
❌ Plaintext passwords (TEST ONLY)
```

---

## 🧪 Test Scenario 5: etcd Data Consistency & Sync Testing

### Objective
Verify etcd data synchronization and consistency across the cluster.

### Test Steps

#### 5.1 Create Test Data
```bash
# Create multiple resources to generate etcd data
for i in {1..10}; do
  kubectl create configmap test-cm-$i --from-literal=key$i=value$i
  kubectl create secret generic test-secret-$i --from-literal=password$i=secret$i
done

# Create a deployment with rolling updates
kubectl create deployment rolling-test --image=nginx:1.20 --replicas=3
kubectl set image deployment/rolling-test nginx=nginx:1.21
```

#### 5.2 Verify Data Consistency Across etcd Members
```bash
# Function to check etcd data on each member
check_etcd_data() {
  local endpoint=$1
  echo "Checking etcd member: $endpoint"
  
  ETCDCTL_API=3 etcdctl \
    --endpoints=https://$endpoint:2379 \
    --cacert=etcd/ca.crt \
    --cert=etcd/healthcheck-client.crt \
    --key=etcd/healthcheck-client.key \
    get /registry/configmaps/default/test-cm-1
}

# Check data on all etcd members
for member in 192.168.10.138 192.168.10.139 192.168.10.140; do
  check_etcd_data $member
done

# All should return identical data (same revision number and content)
# Compare output to ensure consistency
```

#### 5.3 Test etcd Compaction and Defragmentation
```bash
# Check etcd database size and status (all members)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint status --write-out=table

kubectl exec -n kube-system etcd-k8s-master-1 -- etcdctl \
  --endpoints=https://k8s-master-1:2379,https://k8s-master-2:2379,https://k8s-master-3:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table

# Expected Output (shows DB size, leader, etc.):
# +-----------------------------+------------------+---------+---------+--------+-----------+------------+-----------+
# |          ENDPOINT           |        ID        | VERSION | DB SIZE | IN USE | IS LEADER | RAFT TERM | RAFT INDEX |
# +-----------------------------+------------------+---------+---------+--------+-----------+-----------+------------+
# | https://192.168.10.138:2379 | e09fc9cfd94aa09f |  3.5.24 |  8.0 MB | 4.7 MB |     false |        10 |      27821 |
# | https://192.168.10.139:2379 | 5b69bf7e5bd49c74 |  3.5.24 |  7.9 MB | 4.8 MB |     false |        10 |      27821 |
# | https://192.168.10.140:2379 | fd0662997bf732af |  3.5.24 |  8.0 MB | 4.8 MB |      true |        10 |      27821 |
# +-----------------------------+------------------+---------+---------+--------+-----------+-----------+------------+

# Get current revision for compaction
CURRENT_REV=$(ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint status --write-out="json" | jq -r '.[0].Status.header.revision')

echo "Current revision: $CURRENT_REV"
# Expected: Current revision: 27821 (or similar number)

# Perform compaction (compact to current revision - 1000 for safety)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  compact $((CURRENT_REV - 1000))

# Expected: compacted revision 26821 (or similar)

# Defragment all members (WARNING: This can cause temporary unavailability)
for member in 192.168.10.138 192.168.10.139 192.168.10.140; do
  echo "Defragmenting $member..."
  ETCDCTL_API=3 etcdctl \
    --endpoints=https://$member:2379 \
    --cacert=etcd/ca.crt \
    --cert=etcd/healthcheck-client.crt \
    --key=etcd/healthcheck-client.key \
    defrag
  echo "Defragmentation of $member completed"
done

# Expected Output:
# Defragmenting 192.168.10.138...
# Finished defragmenting etcd member[https://192.168.10.138:2379]
# Defragmentation of 192.168.10.138 completed
# (Similar for other members)
```

**✅ Success Criteria:**
- All etcd members return identical data
- Compaction and defragmentation complete successfully
- Cluster remains functional during maintenance operations

---

## 🧪 Test Scenario 6: Network Partition Testing

### Objective
Test cluster behavior during network partitions (split-brain scenarios).

### Test Steps

#### 6.1 Simulate Network Partition
```bash
# Block traffic between master1 and other masters
ssh master@192.168.10.138 "sudo iptables -A INPUT -s 192.168.10.139 -j DROP"
ssh master@192.168.10.138 "sudo iptables -A INPUT -s 192.168.10.140 -j DROP"
ssh master@192.168.10.138 "sudo iptables -A OUTPUT -d 192.168.10.139 -j DROP"
ssh master@192.168.10.138 "sudo iptables -A OUTPUT -d 192.168.10.140 -j DROP"
```

#### 6.2 Verify etcd Behavior
```bash
# Check etcd status on isolated node (should lose quorum)
ssh master@192.168.10.138 "sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health"

# Check etcd on majority partition (should maintain quorum)
ssh master@192.168.10.139 "sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health"
```

#### 6.3 Test API Server Behavior
```bash
# API server on isolated node should become unavailable
kubectl --server=https://192.168.10.138:6443 get nodes
# Expected: Connection timeout or error

# API servers on majority partition should work
kubectl --server=https://192.168.10.139:6443 get nodes
kubectl --server=https://192.168.10.140:6443 get nodes
```

#### 6.4 Restore Network Connectivity
```bash
# Remove iptables rules
ssh master@192.168.10.138 "sudo iptables -F"

# Wait for etcd to rejoin
sleep 30

# Verify cluster health
kubectl get nodes
```

**✅ Success Criteria:**
- Isolated node loses etcd quorum and API server becomes unavailable
- Majority partition maintains cluster functionality
- Full functionality restored when partition healed

---

## 🧪 Test Scenario 7: Load Balancer Stress Testing

### Objective
Test HAProxy performance and failover under high load.

### Test Steps

#### 7.1 Generate High API Server Load
```bash
# Install hey (HTTP load testing tool)
# wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
# chmod +x hey_linux_amd64

# Generate load against VIP
./hey_linux_amd64 -n 10000 -c 50 -H "Authorization: Bearer $(kubectl config view --raw -o jsonpath='{.users[0].user.token}')" https://192.168.10.100:6443/api/v1/nodes

# Monitor HAProxy stats during load
watch -n 1 'curl -s http://192.168.10.141:8404/stats | grep -A 5 "kubernetes-backend"'
```

#### 7.2 Failover During Load
```bash
# Start continuous load in background
while true; do
  kubectl get nodes > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$(date): API Success"
  else
    echo "$(date): API Failed"
  fi
  sleep 0.1
done &

LOAD_PID=$!

# Trigger HAProxy failover during load
ssh ha@192.168.10.141 "sudo systemctl stop haproxy"

# Monitor for any API failures
sleep 10

# Stop load test
kill $LOAD_PID
```

#### 7.3 Multiple Concurrent Clients
```bash
# Simulate multiple kubectl clients
for i in {1..10}; do
  (
    while true; do
      kubectl get pods -A > /dev/null 2>&1
      sleep 1
    done
  ) &
done

# Let run for 2 minutes
sleep 120

# Kill all background jobs
jobs -p | xargs kill
```

**✅ Success Criteria:**
- HAProxy handles high load without errors
- Failover occurs with minimal request failures (<1%)
- Multiple concurrent clients work without issues

---

## 🧪 Test Scenario 8: Disaster Recovery Testing

### Objective
Test complete cluster recovery scenarios.

### Test Steps

#### 8.1 Complete etcd Cluster Failure
```bash
# Stop all etcd members
for master in 192.168.10.138 192.168.10.139 192.168.10.140; do
  ssh master@$master "sudo systemctl stop etcd"
done

# Verify cluster is non-functional
kubectl get nodes
# Expected: Connection errors
```

#### 8.2 etcd Backup and Restore
```bash
# Create etcd backup (before failure)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save /tmp/etcd-backup.db

# Restore etcd from backup (on all masters)
for master in 192.168.10.138 192.168.10.139 192.168.10.140; do
  ssh master@$master "sudo systemctl stop etcd"
  ssh master@$master "sudo rm -rf /var/lib/etcd/*"
  
  # Restore from backup
  scp /tmp/etcd-backup.db master@$master:/tmp/
  ssh master@$master "sudo ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
    --data-dir=/var/lib/etcd \
    --name=master$((${master##*.} - 137)) \
    --initial-cluster=master1=https://192.168.10.138:2380,master2=https://192.168.10.139:2380,master3=https://192.168.10.140:2380 \
    --initial-advertise-peer-urls=https://$master:2380"
  
  ssh master@$master "sudo chown -R etcd:etcd /var/lib/etcd"
  ssh master@$master "sudo systemctl start etcd"
done
```

#### 8.3 Verify Recovery
```bash
# Wait for etcd cluster to form
sleep 60

# Check cluster health
kubectl get nodes
kubectl get pods -A

# Verify our test applications are still there
kubectl get pods -n ha-test
```

**✅ Success Criteria:**
- Backup creation succeeds
- Restore process completes on all nodes
- Cluster functionality fully restored
- All previous workloads recovered

---

## 🧪 Test Scenario 9: Ansible Automation Validation

### Objective
Validate Ansible automation capabilities for cluster management.

### Test Steps

#### 9.1 Idempotency Testing
```bash
# Run playbook multiple times
ansible-playbook -i inventory playbooks/site.yml
ansible-playbook -i inventory playbooks/site.yml
ansible-playbook -i inventory playbooks/site.yml

# Should show no changes on subsequent runs
```

#### 9.2 Selective Component Updates
```bash
# Update only HAProxy configuration
ansible-playbook -i inventory playbooks/00-ha.yml

# Update only Kubernetes components
ansible-playbook -i inventory playbooks/01-common.yaml
```

#### 9.3 Node Addition via Ansible
```bash
# Add new worker to inventory
echo "192.168.10.144" >> inventory

# Run worker join playbook
ansible-playbook -i inventory playbooks/03-join-worker.yaml --limit 192.168.10.144

# Verify new node joined
kubectl get nodes
```

#### 9.4 Configuration Drift Detection
```bash
# Manually modify HAProxy config
ssh ha@192.168.10.141 "sudo sed -i 's/roundrobin/leastconn/' /etc/haproxy/haproxy.cfg"

# Run Ansible to detect and fix drift
ansible-playbook -i inventory playbooks/00-ha.yml

# Verify configuration restored
ssh ha@192.168.10.141 "grep roundrobin /etc/haproxy/haproxy.cfg"
```

**✅ Success Criteria:**
- Multiple playbook runs show idempotency
- Selective updates work correctly
- New nodes can be added seamlessly
- Configuration drift automatically corrected

---

## 📊 Performance Benchmarks

### API Server Response Times
```bash
# Measure API response times
time kubectl get nodes
time kubectl get pods -A
time kubectl create deployment bench-test --image=nginx --replicas=10
```

### etcd Performance
```bash
# etcd write performance test
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  check perf

# Expected Output:
# 60 / 60 Boooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo! 100.00%1m0s
# PASS: Throughput is 150 writes/s
# PASS: Slowest request took 0.020s
# PASS: Stddev is 0.005s
# PASS

# Check etcd cluster status with table format
ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=etcd/ca.crt \
  --cert=etcd/healthcheck-client.crt \
  --key=etcd/healthcheck-client.key \
  endpoint status --write-out=table
```

### HAProxy Statistics
```bash
# Connection statistics
curl -s http://192.168.10.141:8404/stats | grep -E "(Total|Rate)"
```

---

## 🎯 Success Metrics Summary

| Test Scenario | Success Criteria | Expected Results |
|---------------|------------------|------------------|
| **Basic Validation** | All components healthy | ✅ 100% success rate |
| **Workload Resilience** | Apps survive failures | ✅ <1% downtime |
| **HAProxy Failover** | VIP migration <5s | ✅ 3-5 second failover |
| **Master Failover** | Cluster survives 1 master loss | ✅ Zero downtime |
| **etcd Consistency** | Data sync across members | ✅ 100% consistency |
| **Network Partition** | Majority partition functional | ✅ Quorum maintained |
| **Load Testing** | Handle 1000+ req/s | ✅ No dropped requests |
| **Disaster Recovery** | Full cluster restoration | ✅ Complete recovery |
| **Ansible Automation** | Idempotent operations | ✅ Zero config drift |

---

## 🚀 Ansible & HA Kubernetes Strengths Demonstrated

### 1. **Infrastructure as Code Excellence**
- ✅ **Reproducible Deployments**: Identical clusters every time
- ✅ **Version Control**: All configurations tracked in Git
- ✅ **Idempotency**: Safe to run multiple times
- ✅ **Scalability**: Easy to add/remove nodes
- ✅ **Automation**: Reduces human error and deployment time

### 2. **High Availability Architecture**
- ✅ **Zero Single Points of Failure**: Multiple masters + HAProxy HA with Keepalived
- ✅ **Automatic Failover**: VIP migration in 3-5 seconds
- ✅ **Data Consistency**: etcd quorum (2/3) ensures data integrity
- ✅ **Service Continuity**: Applications survive infrastructure failures
- ✅ **Network Resilience**: Survives network partitions and node failures

### 3. **Operational Excellence**
- ✅ **Monitoring Integration**: HAProxy stats page, etcd health checks
- ✅ **Automated Recovery**: Keepalived handles HAProxy failures automatically
- ✅ **Configuration Management**: Ansible prevents configuration drift
- ✅ **Disaster Recovery**: Automated backup/restore procedures
- ✅ **Real-time Visibility**: Comprehensive logging and status monitoring

### 4. **Production Readiness**
- ✅ **Security Best Practices**: TLS encryption, authentication, RBAC
- ✅ **Performance Optimization**: Load balancing, resource limits, health checks
- ✅ **Maintainability**: Clear documentation, standardized procedures
- ✅ **Compliance**: Infrastructure as Code provides audit trail
- ✅ **Scalability**: Horizontal scaling of both control plane and workers

### 5. **Testing & Validation**
- ✅ **Comprehensive Test Scenarios**: 9 different failure scenarios covered
- ✅ **Real-world Conditions**: Network partitions, hardware failures, load testing
- ✅ **Automated Validation**: Scripts to verify cluster health and functionality
- ✅ **Performance Benchmarks**: Measurable SLAs and success criteria

⚠️ **Important Security Note**: 
This testing documentation includes plaintext passwords and simplified authentication methods for educational and testing purposes only. In production environments:

- Use SSH key-based authentication
- Implement proper secret management (Ansible Vault, HashiCorp Vault)
- Configure passwordless sudo with NOPASSWD for service accounts
- Implement network segmentation and firewall rules
- Use monitoring and alerting systems
- Follow security hardening guidelines

This comprehensive testing suite validates that our Ansible-deployed HA Kubernetes cluster meets enterprise-grade reliability, performance, and operational requirements while maintaining security best practices.