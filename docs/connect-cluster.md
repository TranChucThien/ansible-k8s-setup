# Hướng dẫn kết nối vào Kubernetes Cluster

## Bước 1: Lấy kubeconfig từ Master
```bash
# Copy kubeconfig từ master node
scp master@192.168.10.134:/home/master/.kube/config .
```

## Bước 2: Merge config với config cũ
```bash
# Backup config cũ (nếu có)
cp ~/.kube/config ~/.kube/config.backup 2>/dev/null || true

# Merge config mới với config cũ
export KUBECONFIG=~/.kube/config:./config
kubectl config view --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config

# Set quyền
chmod 600 ~/.kube/config
```

## Bước 3: Kiểm tra kết nối
```bash
# Test cluster
kubectl cluster-info

# Xem nodes
kubectl get nodes

# Xem pods
kubectl get pods --all-namespaces
```

## Lệnh hữu ích
```bash
# Xem context hiện tại
kubectl config current-context

# Đổi tên context
kubectl config rename-context kubernetes-admin@kubernetes my-k8s

# Chuyển context
kubectl config use-context my-k8s
```

## Troubleshooting
```bash
# Lỗi permission
chmod 600 ~/.kube/config

# Lỗi connection
kubectl config set-cluster kubernetes --server=https://192.168.10.134:6443
```