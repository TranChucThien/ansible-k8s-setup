# Kubernetes Multi-Master HA v2 - Role-Based Architecture

Enterprise-grade HA Kubernetes cluster with HAProxy + Keepalived using advanced roles architecture.

## 🎯 Overview

This project uses **advanced role-based architecture** for enterprise HA deployments:
- **Complete HA architecture** - Multiple masters + HAProxy + Keepalived + VIP failover
- **Advanced roles** - Specialized roles for each component with proper separation
- **Enterprise operations** - Automated backup, restore, upgrade, scaling
- **Multi-environment** - Production-ready with dev/staging/prod support
- **Disaster recovery** - Complete ETCD backup/restore workflows

## 🏛️ Architecture

```
                         Virtual IP (VIP)
                        192.168.10.100:6443
                               │
                    ┌──────────┴──────────┐
                    │                     │
            ┌───────▼────────┐    ┌───────▼────────┐
            │  HAProxy + KA  │    │  HAProxy + KA  │
            │ 192.168.10.141 │    │ 192.168.10.143 │
            │   (MASTER)     │    │   (BACKUP)     │
            └───────┬────────┘    └───────┬────────┘
                    │                     │
          ┌─────────┼─────────────────────┼─────────┐
          │         │                     │         │
    ┌─────▼─────┐ ┌─▼───────┐       ┌─────▼─────┐   │
    │  Master 1 │ │ Master 2│       │  Master 3 │   │
    │.138 (Init)│ │   .139  │       │    .140   │   │
    └───────────┘ └─────────┘       └───────────┘   │
          │         │                     │         │
          └─────────┼─────────────────────┼─────────┘
                    │                     │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Worker Nodes    │
                    │  192.168.10.142   │
                    └───────────────────┘
```

## 🚀 Quick Start

```bash
# Deploy complete HA cluster
ansible-playbook -i inventories/lab/hosts.ini playbooks/01-cluster-deploy.yml

# Step-by-step deployment
ansible-playbook -i inventories/lab/hosts.ini playbooks/06-haproxy-deploy-only.yml    # HA load balancer
ansible-playbook -i inventories/lab/hosts.ini playbooks/07-masters-init-only.yml      # Masters
ansible-playbook -i inventories/lab/hosts.ini playbooks/03-cluster-add-workers.yml    # Workers

# Advanced operations
ansible-playbook -i inventories/lab/hosts.ini playbooks/02-cluster-add-masters.yml    # Scale masters
ansible-playbook -i inventories/lab/hosts.ini playbooks/20-upgrade-masters.yml        # Upgrade K8s
ansible-playbook -i inventories/lab/hosts.ini playbooks/10-etcd-backup.yml            # Backup ETCD
```

## 🏗️ Project Structure

```
project-k8s-multi-master-haproxy-keepalived-v2/
├── roles/                          # Enterprise role architecture
│   ├── system-common/              # System setup + etcdctl
│   ├── containerd/                 # Container runtime
│   ├── kubernetes/
│   │   ├── install-k8s-components/ # Package installation
│   │   ├── master-init-cluster/    # Control plane setup
│   │   ├── k8s-worker/             # Worker node setup
│   │   ├── generate_join_master/   # Master join command generation
│   │   ├── generate_join_worker/   # Worker join command generation
│   │   ├── join_master/            # Master join operations
│   │   ├── join_worker/            # Worker join operations
│   │   ├── upgrade_master/         # Rolling master upgrades
│   │   ├── upgrade_worker/         # Worker upgrades
│   │   ├── remove-master/          # Remove master nodes
│   │   ├── remove-worker/          # Remove worker nodes
│   │   └── reset-node/             # Cluster cleanup
│   ├── network/
│   │   └── calico/                 # CNI plugin
│   ├── etcd/
│   │   ├── backup/                 # Backup operations
│   │   └── restore/                # Disaster recovery
│   └── haproxy_keepalived/         # HA load balancer + VIP
├── inventories/                     # Multi-environment
│   └── lab/
│       ├── hosts.ini
│       └── group_vars/
├── playbooks/                      # Enterprise operations
│   ├── 01-cluster-deploy.yml       # Complete deployment
│   ├── 02-cluster-add-masters.yml  # Scale masters
│   ├── 03-cluster-add-workers.yml  # Scale workers
│   ├── 04-cluster-remove-masters.yml # Remove masters
│   ├── 05-cluster-remove-workers.yml # Remove workers
│   ├── 06-haproxy-deploy-only.yml  # Deploy HAProxy only
│   ├── 07-masters-init-only.yml    # Deploy masters only
│   ├── 10-etcd-backup.yml          # ETCD backup
│   ├── 11-etcd-backup-cron.yml     # Automated backup
│   ├── 12-etcd-restore.yml         # Disaster recovery
│   ├── 20-upgrade-masters.yml      # Rolling upgrades
│   ├── 21-upgrade-workers.yml      # Worker upgrades
│   ├── 22-upgrade-complete.yml     # Complete upgrade
│   └── 99-reset-cluster.yml        # Cluster reset
└── docs/                           # Operations guides
```

## 🎯 Enterprise Features

### **High Availability**
- ✅ **Multiple masters** with etcd clustering
- ✅ **HAProxy + Keepalived** for load balancer HA
- ✅ **VIP failover** - Automatic virtual IP management
- ✅ **Zero downtime** deployments and upgrades
- ✅ **Quorum-based** decision making

### **Advanced Operations**
- ✅ **Rolling upgrades** - Kubernetes version upgrades with verification
- ✅ **Master scaling** - Add/remove masters dynamically
- ✅ **Worker scaling** - Dynamic worker node management
- ✅ **Disaster recovery** - Complete ETCD backup/restore workflows
- ✅ **Health monitoring** - Cluster health verification

### **Production Ready**
- ✅ **Multi-environment** - Dev/staging/prod configurations
- ✅ **Automated backup** - Scheduled ETCD backups with retention
- ✅ **Security hardening** - Production security configurations
- ✅ **Monitoring integration** - Ready for observability stack
- ✅ **Documentation** - Complete operational guides

## 🔧 Operations Guide

### **Setup Environment**
```bash
# Clone or copy this project
cp -r inventories/lab inventories/myenv

# Edit your inventory
vim inventories/myenv/hosts.ini
vim inventories/myenv/group_vars/all.yml
```

### **Deployment**
```bash
# Complete cluster deployment
ansible-playbook -i inventories/myenv/hosts.ini playbooks/01-cluster-deploy.yml

# Step-by-step deployment
ansible-playbook -i inventories/myenv/hosts.ini playbooks/06-haproxy-deploy-only.yml
ansible-playbook -i inventories/myenv/hosts.ini playbooks/07-masters-init-only.yml
ansible-playbook -i inventories/myenv/hosts.ini playbooks/03-cluster-add-workers.yml
```

### **Scaling Operations**
```bash
# Add new master nodes (use k8s_new_masters group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/02-cluster-add-masters.yml

# Add new worker nodes (use k8s_new_workers group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/03-cluster-add-workers.yml

# Remove master nodes (use k8s_remove_masters group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/04-cluster-remove-masters.yml

# Remove worker nodes (use k8s_remove_workers group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/05-cluster-remove-workers.yml
```

### **Upgrade Operations**
```bash
# Upgrade all masters (one by one)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/20-upgrade-masters.yml

# Upgrade all workers
ansible-playbook -i inventories/myenv/hosts.ini playbooks/21-upgrade-workers.yml

# Complete upgrade with backup and verification
ansible-playbook -i inventories/myenv/hosts.ini playbooks/22-upgrade-complete.yml
```

### **Disaster Recovery**
```bash
# Manual backup
ansible-playbook -i inventories/myenv/hosts.ini playbooks/10-etcd-backup.yml

# Setup automated daily backups
ansible-playbook -i inventories/myenv/hosts.ini playbooks/11-etcd-backup-cron.yml

# Restore ETCD and reinitialize cluster
ansible-playbook -i inventories/myenv/hosts.ini playbooks/12-etcd-restore.yml

# Reset entire cluster
ansible-playbook -i inventories/myenv/hosts.ini playbooks/99-reset-cluster.yml
```

## 📋 Available Playbooks

| Playbook | Purpose | Usage |
|----------|---------|-------|
| `01-cluster-deploy.yml` | Complete cluster deployment | New cluster setup |
| `02-cluster-add-masters.yml` | Add new masters | Scale master nodes |
| `03-cluster-add-workers.yml` | Add new workers | Scale worker nodes |
| `04-cluster-remove-masters.yml` | Remove masters | Scale down masters |
| `05-cluster-remove-workers.yml` | Remove workers | Scale down workers |
| `06-haproxy-deploy-only.yml` | Deploy HAProxy only | HA load balancer setup |
| `07-masters-init-only.yml` | Deploy masters only | Initial master setup |
| `10-etcd-backup.yml` | Manual ETCD backup | One-time backup |
| `11-etcd-backup-cron.yml` | Setup automated backup | Daily backup schedule |
| `12-etcd-restore.yml` | Restore ETCD and reinit cluster | Disaster recovery |
| `20-upgrade-masters.yml` | Upgrade all masters | Kubernetes version upgrade |
| `21-upgrade-workers.yml` | Upgrade all workers | Worker version upgrade |
| `22-upgrade-complete.yml` | Complete upgrade with backup | Safe upgrade with verification |
| `99-reset-cluster.yml` | Reset entire cluster | Cluster cleanup |

## ⚙️ Configuration

### **Inventory Setup**
Edit `inventories/myenv/hosts.ini`:
```ini
[k8s_masters]
k8s-master-1 ansible_host=192.168.10.138

[k8s_new_masters]
k8s-master-2 ansible_host=192.168.10.139
k8s-master-3 ansible_host=192.168.10.140

[k8s_workers]
k8s-worker-1 ansible_host=192.168.10.142

[k8s_new_workers]
k8s-worker-2 ansible_host=192.168.10.144

[k8s_remove_masters]
; k8s-master-2

[k8s_remove_workers]
; k8s-worker-1

[ha]
192.168.10.141
192.168.10.143
```

### **Variables**
Customize in `inventories/myenv/group_vars/all.yml`:
```yaml
# HAProxy/Keepalived
vip_address: "192.168.10.100"
keepalived_password: "your-secure-password"

# Kubernetes
pod_network_cidr: "10.10.0.0/16"
calico_version: "v3.28.0"

# Kubernetes Upgrade
kubernetes_upgrade_version: "1.34"
kubernetes_target_version: "v1.34.3"
kubernetes_package_version: "1.34.*"

# ETCD Backup
local_backup_dir: "/backup/k8s-etcd"
etcd_backup_retention_days: 30
```

### **ETCD Restore Configuration**
Edit `inventories/myenv/group_vars/new_cluster.yml`:
```yaml
backup_file_path: "./backups/myenv/k8s-master-1/etcd-backup-20250124.db"
control_plane_endpoint: "192.168.10.100:6443"
pod_network_cidr: "10.10.0.0/16"
```

## 🔍 Verification

```bash
# SSH to any master node
ssh master@192.168.10.138

# Check cluster status
kubectl get nodes
kubectl get pods -n kube-system

# Test VIP access
curl -k https://192.168.10.100:6443/healthz

# Check HAProxy stats
http://192.168.10.100:8404/stats
```

## 🛠️ Troubleshooting

**VIP not accessible:**
```bash
# Check Keepalived status
ansible -i inventories/myenv/hosts.ini ha -m shell -a "systemctl status keepalived"

# Check which node has VIP
ansible -i inventories/myenv/hosts.ini ha -m shell -a "ip addr show | grep 192.168.10.100"
```

**Master join fails:**
```bash
# Regenerate join tokens
ansible-playbook -i inventories/myenv/hosts.ini playbooks/02-cluster-add-masters.yml --tags always
```

**Backup fails:**
```bash
# Check etcd pod status
kubectl get pods -n kube-system -l component=etcd

# Manual backup test
ansible-playbook -i inventories/myenv/hosts.ini playbooks/10-etcd-backup.yml --limit k8s_masters[0]
```

## 📊 Comparison with Playbook-Based

| Feature | Playbook-Based | Role-Based (v2) |
|---------|----------------|------------------|
| **Architecture** | Simple HA | Enterprise HA |
| **Structure** | Linear playbooks | Advanced roles |
| **VIP Failover** | Manual | Automated |
| **Backup/Restore** | Basic | Complete workflows |
| **Upgrade Support** | Manual | Rolling upgrades |
| **Multi-Environment** | ❌ | ✅ |
| **Disaster Recovery** | Basic | Enterprise-grade |
| **Production Ready** | Learning only | ✅ |
| **Scalability** | Limited | Enterprise |

## 🔒 Security Notes

⚠️ **Production Checklist:**
- [ ] Change default passwords in `group_vars/`
- [ ] Use SSH keys instead of password auth
- [ ] Configure firewall rules
- [ ] Enable TLS for HAProxy
- [ ] Set up monitoring and alerting
- [ ] Configure backup encryption

## 🎓 Prerequisites

- Experience with single master deployments
- Understanding of HA concepts from playbook-based approach
- Kubernetes operational knowledge
- Production deployment experience
- Infrastructure automation expertise

The ultimate Kubernetes HA deployment for enterprise environments!