# Kubernetes Single-Master Cluster (v2.0)

**Enterprise-grade Kubernetes cluster deployment with modular role-based architecture.**

Deploy a production-ready Kubernetes cluster with a single master node using modern Ansible automation. Perfect for development, testing, and small production environments.

## 🏗️ Architecture

```text
┌─────────────────────────────────┐
│         Master Node             │
│    (Control Plane + etcd)       │
│  • API Server                   │
│  • Controller Manager           │
│  • Scheduler                    │
│  • etcd Database + etcdctl      │
│  • Calico CNI                   │
└────────────┬────────────────────┘
              │ Kubernetes API
              │
    ┌─────────▼─────────┐
    │   Worker Node 1   │
    │    (Compute)      │
    │  • kubelet        │
    │  • kube-proxy     │
    │  • containerd     │
    └───────────────────┘
```

## 📖 Hướng dẫn sử dụng

### Bước 1: Chuẩn bị môi trường
```bash
# Clone repository
git clone <repository-url>
cd project-k8s-single-master-v2

# Cài đặt Ansible (nếu chưa có)
sudo apt update
sudo apt install ansible -y

# Kiểm tra version
ansible --version
```

### Bước 2: Cấu hình inventory
```bash
# Sửa file inventory cho môi trường của bạn
vim inventories/lab/hosts.ini

# Cập nhật IP addresses
[k8s_masters]
k8s-master-1 ansible_host=YOUR_MASTER_IP

[k8s_workers]
k8s-worker-1 ansible_host=YOUR_WORKER_IP
```

### Bước 3: Kiểm tra kết nối
```bash
# Test SSH connectivity
ansible all -i inventories/lab/hosts.ini -m ping

# Nếu lỗi, kiểm tra:
# - SSH keys đã setup chưa
# - Firewall có block không
# - IP addresses có đúng không
```

### Bước 4: Deploy cluster
```bash
# Deploy complete cluster
ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml

# Hoặc chỉ deploy master (development)
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-master-only.yml
```

### Bước 5: Verify installation
```bash
# SSH vào master node
ssh master@YOUR_MASTER_IP

# Kiểm tra cluster
kubectl get nodes
kubectl get pods -A

# Test deploy một pod
kubectl run test-pod --image=nginx
kubectl get pods
```

### Bước 6: Add workers (nếu cần)
```bash
# Thêm worker mới
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-2

# Verify
kubectl get nodes
```

## 🚀 Quick Start

### Complete Cluster (Master + Workers)
```bash
# Deploy complete cluster from scratch
ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml
```

### Master Only (Development)
```bash
# Deploy only master node for development
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-master-only.yml
```

### Add Workers to Existing Cluster
```bash
# Add specific workers
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-2

# Add multiple workers
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-1,k8s-worker-2
```

### Verify Installation
```bash
# Check cluster status
kubectl get nodes

# Expected output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   5m    v1.33.x
k8s-worker-1   Ready    <none>          3m    v1.33.x
```

## 📁 Project Structure (v2.0)

```text
project-k8s-single-master-v2/
├── inventories/                     # Multi-environment inventory
│   ├── lab/                        # Lab environment (local VMs)
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       ├── all.yml
│   │       ├── k8s_masters.yml
│   │       ├── k8s_workers.yml
│   │       └── k8s_new_workers.yml
│   ├── dev/                        # Dev environment (cloud)
│   └── prod/                       # Production environment
├── roles/                          # Modular role-based architecture
│   ├── common/                     # System setup + etcdctl
│   ├── containerd/                 # Container runtime
│   ├── kubernetes/
│   │   ├── install/               # Install k8s packages
│   │   ├── master/                # Initialize master + kubeadm config
│   │   ├── worker/                # Join workers
│   │   ├── join/                  # Generate join command
│   │   └── reset/                 # Cluster cleanup
│   ├── network/
│   │   └── calico/                # CNI plugin
│   └── etcd/
│       └── backup/                # ETCD backup operations
├── playbooks/
│   ├── site.yml                   # Complete cluster deployment
│   ├── site-master-only.yml       # Master-only deployment
│   ├── site-add-workers.yml       # Add workers to existing cluster
│   ├── site-add-specific-workers.yml # Add specific workers using k8s_new_workers group
│   ├── site-backup.yml            # ETCD backup
│   ├── site-backup-cron.yml       # Automated backup setup
│   └── archive/                   # Legacy playbooks (reference)
├── logs/                          # Execution logs
├── ansible.cfg                    # Ansible configuration
├── README.md                      # This documentation
└── ROLES.md                       # Role architecture guide
```

## 🎯 Deployment Options

### Option 1: Complete Cluster
**Use case:** Production-like environment with master and workers

```bash
ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml
```

**What happens:**
1. ✅ Installs Docker and Kubernetes on all nodes
2. ✅ Installs etcdctl on master nodes
3. ✅ Initializes master with kubeadm config file
4. ✅ Installs Calico CNI networking
5. ✅ Joins all worker nodes to cluster
6. ✅ Configures kubectl access

### Option 2: Master-Only
**Use case:** Development/testing with single node

```bash
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-master-only.yml
```

### Option 3: Add Workers Later
**Use case:** Scale existing cluster

```bash
# Add specific workers using --limit
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-2

# Or use k8s_new_workers group
# 1. Uncomment worker in inventories/lab/hosts.ini [k8s_new_workers] section
# 2. Run: ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-specific-workers.yml
```

## 📋 Inventory Configuration

### Lab Environment (Local VMs)
```ini
# inventories/lab/hosts.ini
[k8s_masters]
k8s-master-1 ansible_host=192.168.10.138

[k8s_workers]
k8s-worker-1 ansible_host=192.168.10.142

# Temporary group for adding specific workers
[k8s_new_workers]
# k8s-worker-2 ansible_host=192.168.10.144  # Uncomment to add

[k8s_cluster:children]
k8s_masters
k8s_workers
k8s_new_workers
```


## 🔧 Configuration Variables

### Global Settings (inventories/{env}/group_vars/all.yml)
```yaml
# Global variables for all hosts
kubernetes_version: "1.33"
pod_network_cidr: "10.10.0.0/16"
container_runtime: containerd
calico_version: "v3.28.0"

# ETCD backup settings
backup_dir: "/opt/etcd-backup"
backup_time: "0 2"  # Daily at 2:00 AM
backup_retention_days: 7
```

## 🛠️ Operations

### Cluster Management
```bash
# Add workers to existing cluster
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-2

# Add workers using k8s_new_workers group
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-specific-workers.yml
```

### ETCD Backup Operations
```bash
# Manual backup
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-backup.yml

# Setup automated daily backups
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-backup-cron.yml

# Custom backup schedule (3:00 AM, keep 14 days)
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-backup-cron.yml \
  -e backup_time="0 3" -e backup_retention_days=14
```

### Testing & Validation
```bash
# Test connectivity
ansible all -i inventories/lab/hosts.ini -m ping

# Validate playbook syntax
ansible-playbook --syntax-check -i inventories/lab/hosts.ini playbooks/site.yml

# Dry run
ansible-playbook --check -i inventories/lab/hosts.ini playbooks/site.yml
```

## 🔄 What's New in v2.0

### ✅ **Phase 1: Standardized Inventory**
- Multi-environment support (lab/dev/prod)
- Proper group_vars structure
- Scalable host management

### ✅ **Phase 2: Role-Based Architecture**
- Modular, reusable roles
- Clear separation of concerns
- Easy testing and maintenance
- Prepared for HA deployments

### ✅ **Phase 3: Kubeadm Lifecycle Management**
- Idempotent cluster initialization
- Kubeadm configuration templates

### ✅ **Phase 4: ETCD Backup System**
- Automated snapshot backups
- Cron job scheduling
- Backup retention policies
- etcdctl installation on masters

### ✅ **Phase 5: Organized Operations**
- Separated deployment vs operations playbooks
- Safety confirmations for destructive operations
- Maintenance operations (cordon/drain/uncordon)
- Node removal procedures
### 🔧 **Technical Improvements**
- **Idempotent operations** - Safe to run multiple times
- **Fact-based communication** - No local file dependencies
- **Selective worker addition** - Add specific nodes with --limit
- **Comprehensive logging** - Detailed execution logs
- **Best practices** - Following Ansible and Kubernetes standards
- **Organized playbooks** - Clear separation of deploy vs ops

## 🎯 Migration from v1.0

### Old Structure (v1.0)
```bash
# Old monolithic playbooks
ansible-playbook -i inventory playbooks/01-setup-common.yaml
ansible-playbook -i inventory playbooks/02-setup-master.yaml
ansible-playbook -i inventory playbooks/03-setup-worker.yaml
```

### New Structure (v2.0)
```bash
# New role-based approach
ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml
```

**Legacy playbooks are preserved in `playbooks/archive/` for reference.**

## ⚠️ Troubleshooting

### Lỗi thường gặp

#### 1. SSH Connection Failed
```bash
# Kiểm tra SSH key
ssh-copy-id master@YOUR_MASTER_IP
ssh-copy-id worker@YOUR_WORKER_IP

# Hoặc sử dụng password (không khuyến nghị)
# Đã cấu hình trong group_vars
```

#### 2. Kubeadm Init Failed
```bash
# Reset và thử lại
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/

# Chạy lại playbook
ansible-playbook -i inventories/lab/hosts.ini playbooks/site.yml
```

#### 3. Worker Join Failed
```bash
# Tạo lại join token
sudo kubeadm token create --print-join-command

# Hoặc chạy lại add-worker playbook
ansible-playbook -i inventories/lab/hosts.ini playbooks/site-add-workers.yml --limit k8s-worker-1
```

#### 4. Pods Stuck in Pending
```bash
# Kiểm tra nodes
kubectl get nodes
kubectl describe nodes

# Kiểm tra CNI
kubectl get pods -n kube-system | grep calico
```

### Debug Commands
```bash
# Kiểm tra logs
journalctl -u kubelet -f
journalctl -u containerd -f

# Kiểm tra cluster health
kubectl cluster-info
kubectl get componentstatuses

# Kiểm tra network
kubectl get pods -n kube-system
kubectl logs -n kube-system <calico-pod-name>
```

## ⚠️ Important Notes

### Limitations
- **Single Point of Failure**: Master node failure = cluster down
- **Development/Testing Focus**: Not suitable for high-availability production
- **No Load Balancer**: No VIP failover mechanism

### Security Considerations
- SSH key-based authentication recommended for production
- Network policies should be implemented
- RBAC configuration required for multi-tenant environments

### Performance Tuning
- Adjust resource limits based on workload
- Monitor etcd performance and disk I/O
- Consider node affinity for critical workloads

## 🔗 Related Projects

- [Multi-Master HA Setup](../project-k8s-multi-master-haproxy/README.md)
- [Multi-Master + Keepalived](../project-k8s-multi-master-haproxy-keepalived/README.md)
- [Troubleshooting Guide](troubleshooting/README.md)

## 📊 System Requirements

- **OS**: Ubuntu 24.04 LTS
- **Kubernetes**: v1.33.x
- **Container Runtime**: containerd
- **CNI Plugin**: Calico v3.28.0
- **Pod Network CIDR**: 10.10.0.0/16
- **Minimum Resources**: 2 CPU, 4GB RAM per node

## 🤝 Contributing

1. Follow the role-based architecture
2. Update both code and documentation
3. Test in lab environment first
4. Maintain backward compatibility where possible

---

**Built with ❤️ for the Kubernetes community**