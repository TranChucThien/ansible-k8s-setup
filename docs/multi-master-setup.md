# Multi-Master Kubernetes Setup Guide

> **⚠️ WARNING**: This setup is for TESTING and LAB purposes only.
> **NOT A BEST PRACTICE** for production environments.
> Production requires Load Balancer and proper HA setup.

## Multi-Master Theory

### Architecture:
- **Etcd cluster**: Replicated across all master nodes
- **API Server**: Runs on each master, clients connect directly
- **Controller Manager & Scheduler**: Active/Passive (leader election)
- **Certificate sharing**: Need to share certificates between masters

### Requirements:
- **controlPlaneEndpoint** must be defined in cluster config
- **Certificate key** to encrypt/share certificates (TTL: 2 hours)
- **Join token** for authentication (TTL: 24 hours)

## Certificate Sharing Mechanism (upload-certs)

### Workflow Process:

#### 1. **Upload Certs Phase**:
```bash
kubeadm init phase upload-certs --upload-certs
```

**Functions**:
- Generate random **certificate key** (32 bytes)
- **Encrypt** all required certificates using certificate key
- **Upload** encrypted certificates to Kubernetes Secret `kubeadm-certs` in `kube-system` namespace
- **TTL**: 2 hours (auto-delete after 2h)

#### 2. **Certificates being shared**:
- `/etc/kubernetes/pki/ca.crt` - Cluster CA certificate
- `/etc/kubernetes/pki/ca.key` - Cluster CA private key
- `/etc/kubernetes/pki/sa.key` - Service Account signing key
- `/etc/kubernetes/pki/sa.pub` - Service Account public key
- `/etc/kubernetes/pki/front-proxy-ca.crt` - Front proxy CA
- `/etc/kubernetes/pki/front-proxy-ca.key` - Front proxy CA key
- `/etc/kubernetes/pki/etcd/ca.crt` - Etcd CA certificate
- `/etc/kubernetes/pki/etcd/ca.key` - Etcd CA private key

#### 3. **Join Process**:
```bash
kubeadm join --control-plane --certificate-key <KEY>
```

**Process**:
1. **Download** encrypted certificates from Secret `kubeadm-certs`
2. **Decrypt** certificates using certificate key
3. **Write** certificates to `/etc/kubernetes/pki/` on new master
4. **Generate** node-specific certificates (apiserver, etcd peer, etc.)
5. **Start** control plane components
6. **Join** etcd cluster

#### 4. **Security Model**:
- **Certificate key** only exists in memory and command line
- **Encrypted data** stored in Kubernetes Secret
- **Auto-cleanup** after 2 hours to avoid security risk
- **One-time use**: Each upload creates new key

#### 5. **Workflow Timeline**:
```
Master 1: kubeadm init --upload-certs
    ↓
[Certificates encrypted & uploaded to Secret]
    ↓
Master 2: kubeadm join --certificate-key <KEY>
    ↓
[Download → Decrypt → Install → Join etcd]
    ↓
Master 3: kubeadm join --certificate-key <SAME_KEY>
    ↓
[Download → Decrypt → Install → Join etcd]
    ↓
[After 2h: Secret auto-deleted]
```

### Why Certificate Sharing is Needed?

1. **Etcd Cluster**: All masters need same etcd CA to join cluster
2. **API Server**: Need same cluster CA to validate requests
3. **Service Account**: Need same SA keys to sign/verify tokens
4. **Front Proxy**: Need same front-proxy CA for aggregation layer

### Alternatives (not recommended):
- **Manual copy**: `scp` certificates between nodes (not secure)
- **External CA**: Use external certificate authority
- **Separate etcd**: External etcd cluster (more complex)

## Step 1: Initialize cluster with controlPlaneEndpoint

### ✅ Correct way (should do from beginning):
```bash
sudo kubeadm init \
  --pod-network-cidr=10.10.0.0/16 \
  --control-plane-endpoint=192.168.10.138:6443 \
  --upload-certs
```

### ❌ If already initialized without endpoint:
Need to patch kubeadm-config ConfigMap:

```bash
# Create patch file
cat > /tmp/kubeadm-config-patch.yaml << EOF
data:
  ClusterConfiguration: |
    apiServer:
      timeoutForControlPlane: 4m0s
    apiVersion: kubeadm.k8s.io/v1beta3
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controlPlaneEndpoint: "192.168.10.138:6443"
    controllerManager: {}
    dns: {}
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: registry.k8s.io
    kind: ClusterConfiguration
    kubernetesVersion: v1.33.0
    networking:
      dnsDomain: cluster.local
      podSubnet: 10.10.0.0/16
      serviceSubnet: 10.96.0.0/12
    scheduler: {}
EOF

# Apply patch
kubectl patch configmap kubeadm-config -n kube-system --patch-file /tmp/kubeadm-config-patch.yaml
```

## Step 2: Create certificate key and join command

### On first master:
```bash
# Create certificate key and upload certificates
sudo kubeadm init phase upload-certs --upload-certs

# Output:
# I1205 07:31:02.205547   14257 version.go:261] remote version is much newer: v1.34.2; falling back to: stable-1.33
# [upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
# [upload-certs] Using certificate key:
# a8cf71f0739b8ff4ceeaf5a46c1544a3847c98404e6aabd52bfb1ed9441eb383 <-- Copy this key

# Create join command with certificate key
sudo kubeadm token create --print-join-command --certificate-key a8cf71f0739b8ff4ceeaf5a46c1544a3847c98404e6aabd52bfb1ed9441eb383

# Output:
# kubeadm join 192.168.10.138:6443 --token vdxepb.m49o22r6cuyfr4yp --discovery-token-ca-cert-hash sha256:c7e24144fe7526be2cb219ca7af1f790b992b06d71c5194dc9f6679262d23849 --control-plane --certificate-key a8cf71f0739b8ff4ceeaf5a46c1544a3847c98404e6aabd52bfb1ed9441eb383
```

### Check created Secret:
```bash
# View secret containing encrypted certificates
kubectl get secret kubeadm-certs -n kube-system

# View content (encrypted)
kubectl get secret kubeadm-certs -n kube-system -o yaml
```

## Step 3: Join master nodes

### On 2nd, 3rd masters:
```bash
# Join with --control-plane flag
sudo kubeadm join 192.168.10.138:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH> \
  --control-plane \
  --certificate-key <CERT_KEY>

# Setup kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Step 4: Verify setup

```bash
# Check nodes
kubectl get nodes

# Check control plane pods
kubectl get pods -n kube-system

# Check etcd members
kubectl get pods -n kube-system -l component=etcd

# Check etcd cluster health
kubectl exec -n kube-system etcd-<master-name> -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

## Troubleshooting

### Error "controlPlaneEndpoint not found":
- Patch kubeadm-config as in Step 1
- Or reinit cluster with --control-plane-endpoint

### Certificate key expired:
```bash
# Check if secret still exists
kubectl get secret kubeadm-certs -n kube-system

# If not exists, recreate certificate key
sudo kubeadm init phase upload-certs --upload-certs

# Create new join command with new certificate key
sudo kubeadm token create --print-join-command --certificate-key <NEW_CERT_KEY>
```

### Delete certificate key manually (security):
```bash
# Delete secret containing certificates (if needed)
kubectl delete secret kubeadm-certs -n kube-system
```

### Token expired:
```bash
# Create new token
sudo kubeadm token create --ttl 24h
```

### Etcd cluster not healthy:
```bash
# Check etcd logs
kubectl logs -n kube-system etcd-<master-name>

# Restart etcd if needed
sudo systemctl restart kubelet
```

## Limitations (Why not best practice)

1. **No Load Balancer**: Clients must know all master IPs
2. **Single Point of Failure**: If first master down, need manual failover
3. **Certificate Management**: Manual certificate rotation
4. **Network Complexity**: No VIP for API server
5. **Client Configuration**: Must config multiple endpoints

## Production Best Practices

1. **Load Balancer**: HAProxy/NGINX for API server
2. **VIP**: Virtual IP for high availability
3. **External etcd**: Separate etcd cluster
4. **Monitoring**: Proper health checks
5. **Backup**: Automated etcd backup
6. **Security**: Proper RBAC and network policies

---

**Conclusion**: This setup is only suitable for testing and learning. Production needs proper HA architecture with load balancer.