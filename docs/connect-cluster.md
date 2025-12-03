# Kubernetes Cluster Connection Guide

## Step 1: Get kubeconfig from Master
```bash
# Copy kubeconfig from master node
scp master@192.168.10.134:/home/master/.kube/config .
```

## Step 2: Merge config with existing config
```bash
# Backup existing config (if any)
cp ~/.kube/config ~/.kube/config.backup 2>/dev/null || true

# Merge new config with existing config
export KUBECONFIG=~/.kube/config:./config
kubectl config view --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config

# Set permissions
chmod 600 ~/.kube/config
```

## Step 3: Test connection
```bash
# Test cluster
kubectl cluster-info

# View nodes
kubectl get nodes

# View pods
kubectl get pods --all-namespaces
```

## Useful Commands
```bash
# View current context
kubectl config current-context

# Rename context
kubectl config rename-context kubernetes-admin@kubernetes my-k8s

# Switch context
kubectl config use-context my-k8s
```

## Troubleshooting
```bash
# Permission error
chmod 600 ~/.kube/config

# Connection error
kubectl config set-cluster kubernetes --server=https://192.168.10.134:6443
```