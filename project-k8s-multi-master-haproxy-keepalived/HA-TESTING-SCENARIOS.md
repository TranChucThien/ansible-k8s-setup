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
- **2 HAProxy Nodes**: 192.168.10.141, 143 (Load balancers)
- **1 Worker Node**: 192.168.10.142 (Workload execution)
- **Virtual IP**: 192.168.10.100 (Keepalived managed)

### Deployed via Ansible
```bash
# Full cluster deployment
ansible-playbook -i inventory playbooks/site.yml
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
kubectl --server=https://192.168.10.100:6443 get nodes

# Expected Output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   10m   v1.33.6
k8s-master-2   Ready    control-plane   8m    v1.33.6
k8s-master-3   Ready    control-plane   7m    v1.33.6
k8s-worker-1   Ready    <none>          5m    v1.33.6
```

#### 1.2 etcd Cluster Health
```bash
# On any master node
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379,https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health

# Expected Output:
https://192.168.10.138:2379 is healthy: successfully committed proposal
https://192.168.10.139:2379 is healthy: successfully committed proposal
https://192.168.10.140:2379 is healthy: successfully committed proposal
```

#### 1.3 HAProxy Status Check
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
ip addr show | grep 192.168.10.100

# Check Keepalived logs
journalctl -u keepalived -f
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
  replicas: 6
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
```

**✅ Success Criteria:**
- All pods deployed successfully
- Pods distributed across nodes
- Service accessible via NodePort
- Continuous requests succeeding

---

## 🧪 Test Scenario 3: HAProxy Failover Testing

### Objective
Validate HAProxy failover using Keepalived VIP migration.

### Test Steps

#### 3.1 Identify Current MASTER HAProxy
```bash
# Check which HAProxy node has the VIP
for node in 192.168.10.141 192.168.10.143; do
  echo "Checking $node:"
  ssh ha@$node "ip addr show | grep 192.168.10.100"
done

# Check Keepalived status
ssh ha@192.168.10.141 "systemctl status keepalived"
```

#### 3.2 Simulate HAProxy MASTER Failure
```bash
# Assume 192.168.10.141 is MASTER
# Stop HAProxy service (simulating service failure)
ssh ha@192.168.10.141 "sudo systemctl stop haproxy"

# Monitor VIP migration
watch -n 1 'ping -c 1 192.168.10.100'
```

#### 3.3 Verify Failover Behavior
```bash
# Check VIP migration (should move to .143)
ssh ha@192.168.10.143 "ip addr show | grep 192.168.10.100"

# Verify Kubernetes API still accessible
kubectl --server=https://192.168.10.100:6443 get nodes

# Check application still works
curl http://192.168.10.142:<nodeport>

# Monitor Keepalived logs
ssh ha@192.168.10.143 "journalctl -u keepalived -n 20"
```

#### 3.4 Test Recovery
```bash
# Restart HAProxy on failed node
ssh ha@192.168.10.141 "sudo systemctl start haproxy"

# VIP should stay on current MASTER (.143)
# But .141 should become BACKUP
ssh ha@192.168.10.141 "journalctl -u keepalived -n 10"
```

**✅ Success Criteria:**
- VIP migrates within 3-5 seconds
- Kubernetes API remains accessible
- Application continues serving requests
- Failed node becomes BACKUP when recovered

---

## 🧪 Test Scenario 4: Kubernetes Master Node Failover

### Objective
Test etcd and API server resilience when master nodes fail.

### Test Steps

#### 4.1 Baseline etcd Status
```bash
# Check etcd cluster status
kubectl get componentstatuses
kubectl get nodes

# Check etcd member list
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  member list
```

#### 4.2 Simulate Single Master Failure
```bash
# Stop kubelet and etcd on master1 (192.168.10.138)
ssh master@192.168.10.138 "sudo systemctl stop kubelet"
ssh master@192.168.10.138 "sudo systemctl stop etcd"

# Or simulate complete node failure
ssh master@192.168.10.138 "sudo shutdown -h now"
```

#### 4.3 Verify Cluster Resilience
```bash
# Cluster should still be functional (2/3 etcd quorum)
kubectl get nodes
kubectl get pods -A

# Deploy new workload to test API server
kubectl run test-pod --image=nginx --restart=Never

# Check etcd health (should show 2 healthy, 1 unhealthy)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.139:2379,https://192.168.10.140:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health
```

#### 4.4 Test Two Master Failure (Critical Test)
```bash
# Stop second master (192.168.10.139)
ssh master@192.168.10.139 "sudo systemctl stop kubelet etcd"

# Cluster should still work (2/3 quorum lost, but existing workloads continue)
kubectl get pods -n ha-test

# New operations should fail (no etcd quorum)
kubectl run test-pod2 --image=nginx --restart=Never
# Expected: This should hang or fail
```

#### 4.5 Recovery Testing
```bash
# Restart first master
ssh master@192.168.10.138 "sudo systemctl start etcd kubelet"

# Wait for etcd to rejoin
sleep 30

# Cluster should be functional again
kubectl get nodes
kubectl run test-pod3 --image=nginx --restart=Never
```

**✅ Success Criteria:**
- Single master failure: Cluster remains fully functional
- Two master failure: Existing workloads continue, new operations blocked
- Recovery: Full functionality restored when quorum recovered

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
  
  sudo ETCDCTL_API=3 etcdctl \
    --endpoints=https://$endpoint:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    get /registry/configmaps/default/test-cm-1
}

# Check data on all etcd members
for member in 192.168.10.138 192.168.10.139 192.168.10.140; do
  check_etcd_data $member
done

# All should return identical data
```

#### 5.3 Test etcd Compaction and Defragmentation
```bash
# Check etcd database size
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint status --write-out=table

# Perform compaction
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  compact $(sudo ETCDCTL_API=3 etcdctl \
    --endpoints=https://192.168.10.138:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    endpoint status --write-out="json" | jq -r '.[] | .Status.header.revision')

# Defragment all members
for member in 192.168.10.138 192.168.10.139 192.168.10.140; do
  sudo ETCDCTL_API=3 etcdctl \
    --endpoints=https://$member:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    defrag
done
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
# etcd write performance
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://192.168.10.138:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  check perf
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

### 2. **High Availability Architecture**
- ✅ **Zero Single Points of Failure**: Multiple masters + HAProxy HA
- ✅ **Automatic Failover**: VIP migration in seconds
- ✅ **Data Consistency**: etcd quorum ensures data integrity
- ✅ **Service Continuity**: Applications survive infrastructure failures

### 3. **Operational Excellence**
- ✅ **Monitoring Integration**: HAProxy stats, etcd health checks
- ✅ **Automated Recovery**: Keepalived handles HAProxy failures
- ✅ **Configuration Management**: Ansible prevents drift
- ✅ **Disaster Recovery**: Automated backup/restore procedures

### 4. **Production Readiness**
- ✅ **Security**: Authentication, TLS, network policies
- ✅ **Performance**: Load balancing, resource optimization
- ✅ **Maintainability**: Clear documentation, standardized procedures
- ✅ **Compliance**: Infrastructure as Code audit trail

This comprehensive testing suite validates that our Ansible-deployed HA Kubernetes cluster meets enterprise-grade reliability, performance, and operational requirements.