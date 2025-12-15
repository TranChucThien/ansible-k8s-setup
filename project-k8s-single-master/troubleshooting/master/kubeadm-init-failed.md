# Issue: kubeadm init Failed

## Symptoms
```text
[ERROR Port-6443]: Port 6443 is in use
[ERROR FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml]: /etc/kubernetes/manifests/kube-apiserver.yaml already exists
```

## Cause
- Previous failed initialization
- Kubernetes already partially installed
- Port conflicts

## Solution

### Reset and Retry
```bash
# Reset kubeadm on master
sudo kubeadm reset -f

# Clean up
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf ~/.kube/

# Restart services
sudo systemctl restart kubelet
sudo systemctl restart containerd

# Re-run master playbook
ansible-playbook -i inventory playbooks/02-master.yaml
```

### Check Prerequisites
```bash
# Verify swap is disabled
sudo swapoff -a
free -h

# Check required ports
sudo netstat -tlnp | grep :6443
sudo netstat -tlnp | grep :2379

# Check container runtime
sudo systemctl status containerd
```

## Prevention
- Always run `kubeadm reset -f` before re-initialization
- Use cleanup playbooks before redeployment