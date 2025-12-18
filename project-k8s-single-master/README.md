# Kubernetes Single-Master Cluster

**Simple Kubernetes cluster deployment for development and testing environments.**

Deploy a Kubernetes cluster with a single master node using Ansible automation. Perfect for development, testing, and learning.

## 🏗️ Architecture

```text
┌─────────────────────────────────┐
│         Master Node             │
│    (Control Plane + etcd)       │
│  • API Server                   │
│  • Controller Manager           │
│  • Scheduler                    │
│  • etcd Database                │
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

## 🚀 Quick Start

### Complete Cluster (Master + Workers)
```bash
# Deploy complete cluster from scratch
ansible-playbook -i inventory playbooks/site.yml
```

### Master Only (Development)
```bash
# Deploy only master node for development
ansible-playbook -i inventory playbooks/site-master-only.yml
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

## 📁 Project Structure

```text
project-k8s-single-master/
├── playbooks/
│   ├── 01-setup-common.yaml         # Base setup (Docker, K8s packages)
│   ├── 02-setup-master.yaml         # Master initialization + Calico
│   ├── 03-setup-worker.yaml         # Workers join cluster
│   ├── 04-setup-add-worker.yaml     # Add new workers
│   ├── 11-maintenance-reset-node.yml# Reset cluster
│   ├── 21-backup-etcd.yml           # Backup operations
│   ├── 22-backup-setup-cron.yml     # Automated backup
│   ├── 23-backup-remove-cron.yml    # Remove backup
│   ├── 24-backup-etcd-restore.yml   # Restore from backup
│   ├── site.yml                     # 🎯 Complete cluster deployment
│   └── site-master-only.yml         # 🏠 Master-only deployment
├── troubleshooting/                 # Issue diagnosis guides
├── backups/                         # Local backup storage
├── logs/                           # Execution logs
├── inventory                       # Server inventory file
├── ansible.cfg                     # Ansible configuration
└── README.md                       # This documentation
```

## 🎯 Deployment Options

### Option 1: Complete Cluster
**Use case:** Production-like environment with master and workers

```bash
ansible-playbook -i inventory playbooks/site.yml
```

**What happens:**
1. ✅ Installs Docker and Kubernetes on all nodes
2. ✅ Initializes master with kubeadm
3. ✅ Installs Calico CNI networking
4. ✅ Joins all worker nodes to cluster
5. ✅ Configures kubectl access

### Option 2: Master-Only
**Use case:** Development/testing with single node

```bash
ansible-playbook -i inventory playbooks/site-master-only.yml
```

**What happens:**
1. ✅ Sets up master node only
2. ✅ Master can schedule pods (no workers needed)
3. ✅ Perfect for learning and development

### Manual Step-by-Step
```bash
# Step 1: Prepare all nodes
ansible-playbook -i inventory playbooks/01-setup-common.yaml

# Step 2: Initialize master
ansible-playbook -i inventory playbooks/02-setup-master.yaml

# Step 3: Join workers (optional)
ansible-playbook -i inventory playbooks/03-setup-worker.yaml
```

## 📋 Inventory Configuration

### Cloud Environment (AWS/GCP/Azure)
```ini
# inventory
[masters]
47.129.50.197

[workers]
18.142.245.203

[masters:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=ansible-key.pem

[workers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=ansible-key.pem
```

### Lab Environment (Local VMs)
```ini
# inventory-lab
[masters]
192.168.10.138

[workers]
192.168.10.142

[masters:vars]
ansible_user=master
ansible_ssh_pass=password123
ansible_become_pass=password123

[workers:vars]
ansible_user=worker
ansible_ssh_pass=password123
ansible_become_pass=password123
```

## ✅ Validation

```bash
# Test connectivity
ansible all -i inventory -m ping

# Validate playbook syntax
ansible-playbook --syntax-check -i inventory playbooks/site.yml

# Deploy cluster
ansible-playbook -i inventory playbooks/site.yml

# Check cluster status
kubectl get nodes
```

## 🔧 Configuration

- **OS**: Ubuntu 24.04 LTS
- **Kubernetes**: v1.33.x
- **Container Runtime**: containerd
- **CNI Plugin**: Calico v3.28.0
- **Pod Network CIDR**: 10.10.0.0/16

## ⚠️ Limitations

- **Single Point of Failure**: Master node failure = cluster down
- **Development/Testing Only**: Not suitable for production
- **No HA**: No load balancer or VIP failover

For production, use [Multi-Master HA setup](../project-k8s-multi-master-haproxy/README.md).

## 🔗 Related

- [Troubleshooting Guide](troubleshooting/README.md)
- [Multi-Master HA](../project-k8s-multi-master-haproxy/README.md)
- [Multi-Master + Keepalived](../project-k8s-multi-master-haproxy-keepalived/README.md)