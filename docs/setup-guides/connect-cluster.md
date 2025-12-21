# Kubernetes Cluster Connection Guide

Guide for connecting to Kubernetes cluster from remote clients.

## 🔧 Prerequisites

- **kubectl**: Must be installed on client machine
- **SSH Access**: Access to master node to copy kubeconfig
- **Network Access**: Port 6443 accessible from client

## 📋 Connection Steps

### Step 1: Get kubeconfig from Master
```bash
# Replace with your master node details
MASTER_IP="192.168.10.138"
MASTER_USER="master"

# Copy kubeconfig from master node (contains correct endpoint)
scp ${MASTER_USER}@${MASTER_IP}:/home/${MASTER_USER}/.kube/config ./cluster-config
```

### Step 2: Configure local kubeconfig
```bash
# Create .kube directory if not exists
mkdir -p ~/.kube

# Backup existing config (if any)
[ -f ~/.kube/config ] && cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d-%H%M%S)

# Option A: Replace existing config
cp ./cluster-config ~/.kube/config

# Option B: Merge with existing config
export KUBECONFIG=~/.kube/config:./cluster-config
kubectl config view --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config

# Set secure permissions
chmod 600 ~/.kube/config
```

## ✅ Verification

### Step 1: Test Connection
```bash
# Test cluster connectivity
kubectl cluster-info

# Check cluster health
kubectl get componentstatuses

# View nodes
kubectl get nodes -o wide

# View system pods
kubectl get pods -n kube-system
```

### Step 2: Verify Permissions
```bash
# Check current user
kubectl auth whoami

# Test permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments
```

**Expected Output:**
```bash
$ kubectl auth whoami
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=c3576c8e38068287a3f893179ed9735654942c1067e67b7ff33710472ba76086]

$ kubectl auth can-i get pods
yes

$ kubectl auth can-i create deployments
yes
```

**What this means:**
- **Username**: `kubernetes-admin` - You're authenticated as cluster administrator
- **Groups**: `kubeadm:cluster-admins` - Member of cluster admin group with full privileges
- **Credential ID**: X509 certificate fingerprint for authentication
- **Permissions**: `yes` responses confirm you have full cluster access

## 🔧 Configuration Management

### Context Management
```bash
# View all contexts
kubectl config get-contexts

# View current context
kubectl config current-context

# Rename context for clarity
kubectl config rename-context kubernetes-admin@kubernetes prod-k8s

# Switch context
kubectl config use-context prod-k8s

# Set default namespace
kubectl config set-context --current --namespace=default
```



## 🛡️ Security Best Practices
### Access Control
```bash
# Create limited user (run on master)
kubectl create serviceaccount readonly-user
kubectl create clusterrolebinding readonly-user --clusterrole=view --serviceaccount=default:readonly-user

# Get token for service account
kubectl create token readonly-user
```

**What each command does:**
- **`serviceaccount`**: Creates a new identity in Kubernetes for authentication
- **`clusterrolebinding`**: Grants the `view` ClusterRole permissions to the service account
- **`view` ClusterRole**: Built-in role that allows read-only access to most resources
- **`create token`**: Generates a JWT token for API authentication

**Expected Output:**
```bash
$ kubectl create serviceaccount readonly-user
serviceaccount/readonly-user created

$ kubectl create clusterrolebinding readonly-user --clusterrole=view --serviceaccount=default:readonly-user
clusterrolebinding.rbac.authorization.k8s.io/readonly-user created

$ kubectl create token readonly-user
eyJhbGciOiJSUzI1NiIsImtpZCI6Im9yZVRxMndhSm4xQmcyeGo0dE81RzR5TTJLbi1WYkpmd3FpbWF5dldnbncifQ...
```

### Using Service Account Token
```bash
# Save token to variable
TOKEN=$(kubectl create token readonly-user)

# Create kubeconfig for readonly user
kubectl config set-credentials readonly-user --token=$TOKEN
kubectl config set-context readonly-context --cluster=kubernetes --user=readonly-user

# Switch to readonly context
kubectl config use-context readonly-context

# Test readonly access
kubectl get pods
kubectl auth can-i create pods  # Should return "no"
kubectl auth can-i get pods     # Should return "yes"
```



## 📚 References

### Official Kubernetes Documentation
- [Organizing Cluster Access Using kubeconfig Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
