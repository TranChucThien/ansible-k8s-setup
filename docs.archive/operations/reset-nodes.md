# Kubernetes Node Reset Guide

Guide for resetting Kubernetes nodes to remove them from cluster and prepare for joining another cluster.

## 🚨 Warning

**This will completely remove the node from the cluster and delete all Kubernetes data!**
- All pods and data on the node will be lost
- Node will be removed from cluster
- All Kubernetes configurations will be deleted

## 🎯 Use Cases

- **Remove node from cluster** - Permanently remove node
- **Join different cluster** - Reset and join another cluster
- **Troubleshoot issues** - Clean slate for debugging
- **Cluster migration** - Move nodes between clusters

## 📋 Reset Methods

### Method 1: Reset Master Node

#### Step 1: Drain and Remove Node (Optional)
```bash
# Run from another master node or before reset
kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node <node-name>
```

#### Step 2: Reset Master Node
```bash
# Run on the master node to be reset
sudo kubeadm reset -f

# Remove CNI configuration
sudo rm -rf /etc/cni/net.d

# Remove kubectl configuration
rm -rf $HOME/.kube
sudo rm -rf /root/.kube

# Remove etcd data (master only)
sudo rm -rf /var/lib/etcd

# Clean iptables rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Restart services
sudo systemctl restart kubelet
sudo systemctl restart containerd
```

### Method 2: Reset Worker Node

#### Step 1: Drain and Remove Node (Recommended)
```bash
# Run from master node
kubectl drain <worker-node-name> --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node <worker-node-name>
```

#### Step 2: Reset Worker Node
```bash
# Run on the worker node to be reset
sudo kubeadm reset -f

# Remove Kubernetes configuration files
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/

# Remove CNI configuration
sudo rm -rf /etc/cni/net.d

# Remove kubectl configuration
rm -rf $HOME/.kube

# Clean iptables rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Restart services
sudo systemctl restart kubelet
sudo systemctl restart containerd
```

### Method 3: Automated Reset (Ansible)

#### Using Existing Playbook
```bash
# Reset entire cluster
cd project-k8s-single-master
ansible-playbook -i inventory playbooks/clean-cluster.yml

# Reset specific nodes
ansible-playbook -i inventory playbooks/clean-cluster.yml --limit worker-nodes
```

#### Custom Reset Playbook
```yaml
# reset-nodes.yml
---
- name: Reset Kubernetes nodes
  hosts: "{{ target_hosts | default('all') }}"
  become: yes
  tasks:
    - name: Reset kubeadm
      shell: kubeadm reset -f
      ignore_errors: yes

    - name: Remove CNI configuration
      file:
        path: /etc/cni/net.d
        state: absent

    - name: Remove kube config
      file:
        path: "{{ ansible_env.HOME }}/.kube"
        state: absent

    - name: Remove etcd data (masters only)
      file:
        path: /var/lib/etcd
        state: absent
      when: inventory_hostname in groups['masters']

    - name: Clean iptables
      shell: |
        iptables -F
        iptables -t nat -F
        iptables -t mangle -F
        iptables -X
      ignore_errors: yes

    - name: Restart services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - kubelet
        - containerd
```

## ✅ Verification

### Check Node Status
```bash
# Verify node is removed from cluster (run from remaining master)
kubectl get nodes

# Verify services are running on reset node
sudo systemctl status kubelet
sudo systemctl status containerd

# Check no Kubernetes processes
ps aux | grep kube
```

### Verify Clean State
```bash
# No CNI interfaces
ip link show | grep cni

# No Kubernetes iptables rules
sudo iptables -L | grep KUBE

# No etcd data (master nodes)
ls -la /var/lib/etcd/

# No kubectl config
ls -la ~/.kube/
```

## 🔄 Joining New Cluster

### After Reset - Join Different Cluster

#### For Worker Nodes
```bash
# Get join command from new cluster master
kubeadm token create --print-join-command

# Run join command on reset worker node
sudo kubeadm join <new-cluster-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

#### For Master Nodes
```bash
# Initialize new cluster or get join command for additional masters
# For first master:
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# For additional masters:
sudo kubeadm join <cluster-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --control-plane
```

## 🔍 Troubleshooting

### Common Issues

#### Worker Node Already Joined Error
```bash
# Error when trying to join:
# [ERROR FileAvailable--etc-kubernetes-bootstrap-kubelet.conf]: /etc/kubernetes/bootstrap-kubelet.conf already exists
# [ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists

# Solution 1: Reset the node first
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /etc/cni/net.d/

# Then join again
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Solution 2: Force join (if you know what you're doing)
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --ignore-preflight-errors=FileAvailable--etc-kubernetes-bootstrap-kubelet.conf,FileAvailable--etc-kubernetes-pki-ca.crt
```

#### Reset Fails
```bash
# Force remove containers
sudo crictl rm --force $(sudo crictl ps -aq)
sudo crictl rmi --prune

# Manual cleanup
sudo systemctl stop kubelet
sudo systemctl stop containerd
sudo rm -rf /var/lib/kubelet/*
sudo systemctl start containerd
sudo systemctl start kubelet
```

#### Network Issues
```bash
# Reset network completely
sudo systemctl stop kubelet
sudo systemctl stop containerd

# Remove all network interfaces
sudo ip link delete cni0
sudo ip link delete flannel.1
sudo ip link delete docker0

# Restart networking
sudo systemctl restart networking
sudo systemctl start containerd
sudo systemctl start kubelet
```

#### Persistent Pods

```bash
# Force delete stuck pods
kubectl delete pods --all --force --grace-period=0

# Remove finalizers
kubectl patch pod <pod-name> -p '{"metadata":{"finalizers":null}}'
```

## 📚 Best Practices

### Before Reset

1. **Backup important data** from pods
2. **Drain node gracefully** to migrate workloads
3. **Document node configuration** for recreation
4. **Notify team members** about maintenance

### During Reset
1. **Follow order**: Workers first, then masters
2. **Verify each step** before proceeding
3. **Check cluster health** after each node removal
4. **Keep one master running** (for multi-master setups)

### After Reset
1. **Verify clean state** before joining new cluster
2. **Test connectivity** to new cluster
3. **Monitor logs** during join process
4. **Validate node functionality** after join

## 🚨 Production Considerations

### High Availability
- **Never reset all masters** simultaneously
- **Maintain quorum** during master node resets
- **Use rolling updates** for worker nodes
- **Have backup masters** ready

### Data Safety
- **Backup etcd** before resetting masters
- **Migrate workloads** before resetting workers
- **Use persistent volumes** for important data
- **Test recovery procedures** regularly

## 📚 References

### Official Documentation
- [kubeadm reset](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/)
- [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Remove Nodes from Cluster](https://kubernetes.io/docs/concepts/architecture/nodes/#manual-node-administration)

### Related Documentation
- [Node Management Guide](node-management.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Cluster Connection Guide](connect-cluster.md)