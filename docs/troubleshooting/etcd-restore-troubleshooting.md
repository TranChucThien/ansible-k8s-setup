# etcd Restore Troubleshooting Guide

## 🔍 Common Issues After etcd Restore

When restoring etcd in multi-master Kubernetes clusters, you may encounter various issues related to cluster state inconsistency and member synchronization.

## ❌ Problem: "can only promote a learner member which is in sync with leader"

### Symptoms
```bash
error: rpc error: code = FailedPrecondition desc = etcdserver: can only promote a learner member which is in sync with leader
```

This error occurs when:
- Joining additional master nodes after etcd restore
- etcd member has incorrect peer-urls
- etcd cluster state is inconsistent after restore

### Root Cause
After etcd restore, etcd members may have **stale or incorrect peer-urls** that prevent proper cluster communication and synchronization.

## ✅ Solution: Update etcd Member Peer URLs

### Step 1: Identify the Problem Member

```bash
# List etcd members to find the problematic one
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

### Step 2: Update Member Peer URLs

```bash
# Update the member with correct peer-urls
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member update <MEMBER_ID> --peer-urls=https://<CORRECT_IP>:2380
```

**Example:**
```bash
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member update 8e9e05c52164694d --peer-urls=https://192.168.10.139:2380
```

### Step 3: Verify the Fix

```bash
# Check etcd cluster health
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Check member list again
kubectl exec -n kube-system etcd-k8s-master-2 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

## 🚨 Other Common Issues After etcd Restore

### 1. Expired Tokens and Certificate Keys

**Problem:** Bootstrap tokens and certificate keys from backup are expired.

**Solution:**
```bash
# Clean old tokens
sudo kubeadm token list
sudo kubeadm token delete <OLD_TOKEN>

# Create new token and certificate key
sudo kubeadm init phase upload-certs --upload-certs
sudo kubeadm token create --ttl 24h --print-join-command --certificate-key <NEW_CERT_KEY>
```

### 2. Stale etcd Members

**Problem:** Old etcd members still exist in cluster after restore.

**Solution:**
```bash
# List members
kubectl exec -n kube-system etcd-<ACTIVE_MASTER> -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Remove stale members
kubectl exec -n kube-system etcd-<ACTIVE_MASTER> -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member remove <STALE_MEMBER_ID>
```

### 3. API Server Connection Issues

**Problem:** API server cannot connect to etcd after restore.

**Solution:**
```bash
# Check etcd endpoints in API server manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd-servers

# Restart API server
sudo crictl stop $(sudo crictl ps | grep kube-apiserver | awk '{print $1}')
```

## 📋 Best Practices

1. **Always verify etcd cluster health** before and after restore operations
2. **Update peer-urls immediately** after restore if needed
3. **Clean expired tokens** before attempting to join new nodes
4. **Test restore procedures** in non-production environments first
5. **Document your specific cluster configuration** for faster troubleshooting

## 🔗 Related Documentation

- [etcd Backup and Restore](../project-k8s-single-master/playbooks/21-backup-etcd.yml)
- [Multi-Master Setup Guide](../project-k8s-multi-master-haproxy/README.md)
- [Kubernetes etcd Documentation](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

## 📞 Emergency Recovery

If all else fails and you need to rebuild the cluster:

1. **Save current workloads**: `kubectl get all --all-namespaces -o yaml > cluster-backup.yaml`
2. **Reset all nodes**: `kubeadm reset --force` on all nodes
3. **Reinitialize cluster**: Start fresh with your Ansible playbooks
4. **Restore workloads**: `kubectl apply -f cluster-backup.yaml`

Remember: **Prevention is better than cure** - regular backups and testing are essential!