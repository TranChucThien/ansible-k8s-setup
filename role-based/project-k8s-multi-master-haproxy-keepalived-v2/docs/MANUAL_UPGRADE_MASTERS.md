# Manual Kubernetes Master Upgrade Guide

This guide covers the manual upgrade process for Kubernetes masters in a multi-master HA cluster.

## Prerequisites

- Backup your cluster before upgrading (see [Disaster Recovery Guide](../README.md#disaster-recovery-guide))
- Ensure all nodes are healthy
- Have SSH access to all master nodes
- Verify current cluster version: `kubectl version --short`

## Upgrade Process Overview

1. **First Master (Control Plane)**: Use `kubeadm upgrade apply`
2. **Additional Masters**: Use `kubeadm upgrade node`
3. **Upgrade kubelet and kubectl** on all masters

## Step 1: Upgrade First Master Node

### 1.1 SSH to First Master
```bash
ssh master@k8s-master-1
```

### 1.2 Setup Kubernetes Repository for Target Version
```bash
# Create keyring directory
sudo mkdir -p /etc/apt/keyrings

# Download and install GPG key for target version (replace 1.34 with your target version)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### 1.3 Upgrade kubeadm
```bash
# Unhold kubeadm
sudo apt-mark unhold kubeadm

# Update package list
sudo apt update

# Install specific kubeadm version
sudo apt install -y kubeadm=1.34.*

# Hold kubeadm to prevent automatic updates
sudo apt-mark hold kubeadm
```

### 1.4 Verify Upgrade Plan
```bash
# Check upgrade plan
sudo kubeadm upgrade plan
```

**Expected Output:**
```
[upgrade/versions] Cluster version: 1.33.7
[upgrade/versions] kubeadm version: v1.34.3
[upgrade/versions] Target version: v1.34.3

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE           CURRENT   TARGET
kubelet     k8s-master-1   v1.33.7   v1.34.3
kubelet     k8s-master-2   v1.33.7   v1.34.3
kubelet     k8s-master-3   v1.33.7   v1.34.3
```

### 1.5 Apply Upgrade to First Master
```bash
# Apply upgrade (replace v1.34.3 with your target version)
sudo kubeadm upgrade apply v1.34.3 -y
```

**Expected Output:**
```
[upgrade] SUCCESS! A control plane node of your cluster was upgraded to "v1.34.3".
[upgrade] Now please proceed with upgrading the rest of the nodes by following the right order.
```

### 1.6 Verify Control Plane Upgrade
```bash
# Check API server version
kubectl get pods -n kube-system \
  -l component=kube-apiserver \
  -o=jsonpath='{.items[0].spec.containers[0].image}'
```

### 1.7 Upgrade kubelet and kubectl on First Master
```bash
# Unhold packages
sudo apt-mark unhold kubelet kubectl

# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade kubelet kubectl -y

# Reload systemd and restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Hold packages
sudo apt-mark hold kubelet kubectl
```

## Step 2: Upgrade Additional Master Nodes

Repeat these steps for each additional master node (k8s-master-2, k8s-master-3, etc.).

### 2.1 SSH to Additional Master
```bash
ssh master@k8s-master-2  # or k8s-master-3
```

### 2.2 Setup Kubernetes Repository
```bash
# Create keyring directory
sudo mkdir -p /etc/apt/keyrings

# Download and install GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### 2.3 Upgrade kubeadm
```bash
# Unhold kubeadm
sudo apt-mark unhold kubeadm

# Update and install kubeadm
sudo apt update
sudo apt install -y kubeadm=1.34.*
sudo apt-mark hold kubeadm
```

### 2.4 Upgrade Node (NOT apply)
```bash
# Use 'upgrade node' for additional masters
sudo kubeadm upgrade node
```

**Expected Output:**
```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[upgrade] Skipping phase. Not a control-plane node.
[upgrade] Applying user provided patch to the control plane.
[upgrade] SUCCESS! This node was upgraded to "v1.34.3".
```

### 2.5 Upgrade kubelet and kubectl
```bash
# Unhold packages
sudo apt-mark unhold kubelet kubectl

# Update and upgrade
sudo apt update
sudo apt upgrade kubelet kubectl -y

# Restart services
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Hold packages
sudo apt-mark hold kubelet kubectl
```

## Step 3: Verification

### 3.1 Check Cluster Status
```bash
# From any master node
kubectl get nodes

# Check all nodes are Ready and showing new version
kubectl get nodes -o wide
```

### 3.2 Verify Control Plane Components
```bash
# Check all control plane pods
kubectl get pods -n kube-system -l tier=control-plane

# Verify API server versions on all masters
kubectl get pods -n kube-system -l component=kube-apiserver -o wide
```

### 3.3 Check Cluster Health
```bash
# Verify cluster health
kubectl cluster-info
kubectl get componentstatuses  # Deprecated but still useful

# Test API access through VIP
curl -k https://192.168.10.100:6443/healthz
```

## Troubleshooting

### Version Mismatch Warning
If you see warnings about different API server versions:
```
W1229 01:57:02.102081 30320 compute.go:93] Different API server versions in the cluster were discovered: v1.34.3 on nodes [k8s-master-1], v1.33.7 on nodes [k8s-master-2 k8s-master-3]
```

This is normal during the upgrade process. Complete all master upgrades to resolve.

### Upgrade Fails
```bash
# Check kubeadm logs
sudo journalctl -xeu kubelet

# Verify etcd health
kubectl get pods -n kube-system -l component=etcd

# Check control plane pod status
kubectl get pods -n kube-system -l tier=control-plane
```

### Rollback (if needed)
```bash
# Downgrade kubeadm (emergency only)
sudo apt-mark unhold kubeadm
sudo apt install kubeadm=1.33.*
sudo apt-mark hold kubeadm

# Note: Full cluster rollback requires restoring from backup
```

## Post-Upgrade Tasks

### 1. Update Worker Nodes
After all masters are upgraded, upgrade worker nodes:
```bash
# From control plane
kubectl get nodes  # Note worker versions

# SSH to each worker and upgrade (similar process but with 'kubeadm upgrade node')
```

### 2. Update Add-ons
```bash
# Check if CNI needs updating
kubectl get pods -n kube-system -l k8s-app=calico-node

# Update Calico if needed (check compatibility matrix)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

### 3. Verify Everything Works
```bash
# Test pod creation
kubectl run test-pod --image=nginx --rm -it -- /bin/bash

# Check all system pods
kubectl get pods -A

# Verify services
kubectl get svc -A
```

## Best Practices

- ✅ **Always backup before upgrading**
- ✅ **Test upgrades in non-production first**
- ✅ **Upgrade one master at a time**
- ✅ **Wait for each master to be healthy before proceeding**
- ✅ **Monitor cluster during upgrade**
- ✅ **Have rollback plan ready**

## Version Compatibility

| Current | Target | Supported |
|---------|--------|-----------|
| 1.33.x  | 1.34.x | ✅ Yes    |
| 1.32.x  | 1.34.x | ❌ No (skip versions not supported) |
| 1.33.x  | 1.35.x | ❌ No (skip versions not supported) |

**Note**: Kubernetes supports upgrading only one minor version at a time.