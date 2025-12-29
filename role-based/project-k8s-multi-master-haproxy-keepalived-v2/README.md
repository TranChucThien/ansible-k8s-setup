# Kubernetes Multi-Master HA v2 - Role-Based Architecture

Enterprise-grade HA Kubernetes cluster with HAProxy + Keepalived using advanced roles architecture.

## 🎯 Overview

This project uses **advanced role-based architecture** for enterprise HA deployments:
- **Complete HA architecture** - Multiple masters + HAProxy + Keepalived + VIP failover
- **Advanced roles** - Specialized roles for each component with proper separation
- **Enterprise operations** - Automated backup, restore, upgrade, scaling
- **Multi-environment** - Production-ready with dev/staging/prod support
- **Disaster recovery** - Complete ETCD backup/restore workflows

## 🏛️ Enterprise Architecture

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
ansible-playbook -i inventories/lab playbooks/site.yml

# Step-by-step deployment
ansible-playbook -i inventories/lab playbooks/site-haproxy-only.yml    # HA load balancer
ansible-playbook -i inventories/lab playbooks/site-master-only.yml     # Masters
ansible-playbook -i inventories/lab playbooks/site-add-workers.yml     # Workers

# Advanced operations
ansible-playbook -i inventories/lab playbooks/site-add-masters.yml     # Scale masters
ansible-playbook -i inventories/lab playbooks/site-upgrade-masters.yml # Upgrade K8s
ansible-playbook -i inventories/lab playbooks/site-backup.yml          # Backup ETCD
```

## 🏗️ Advanced Role Architecture

```
project-k8s-multi-master-haproxy-keepalived-v2/
├── roles/                          # Enterprise role architecture
│   ├── common/                     # System setup + etcdctl
│   ├── containerd/                 # Container runtime
│   ├── kubernetes/
│   │   ├── install/               # Package installation
│   │   ├── master/                # Control plane setup
│   │   ├── worker/                # Worker node setup
│   │   ├── join/                  # Join command generation
│   │   ├── join_master/           # Master join operations
│   │   ├── join_worker/           # Worker join operations
│   │   ├── upgrade_master/        # Rolling master upgrades
│   │   ├── upgrade_worker/        # Worker upgrades
│   │   └── reset/                 # Cluster cleanup
│   ├── network/
│   │   └── calico/                # CNI plugin
│   ├── etcd/
│   │   ├── backup/                # Backup operations
│   │   └── restore/               # Disaster recovery
│   └── haproxy_keepalived/        # HA load balancer + VIP
├── inventories/                    # Multi-environment
│   └── lab/
│       ├── hosts.ini
│       └── group_vars/
├── playbooks/                     # Enterprise operations
│   ├── site.yml                   # Complete deployment
│   ├── site-add-masters.yml       # Scale masters
│   ├── site-upgrade-masters.yml   # Rolling upgrades
│   ├── site-backup.yml            # ETCD backup
│   ├── site-restore-etcd.yml      # Disaster recovery
│   └── site-reset-nodes.yml       # Cluster reset
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

## 🔧 Enterprise Operations

### **Cluster Lifecycle**
```bash
# Initial deployment
ansible-playbook -i inventories/prod playbooks/site.yml

# Scale operations
ansible-playbook -i inventories/prod playbooks/site-add-masters.yml
ansible-playbook -i inventories/prod playbooks/site-add-workers.yml

# Upgrade operations
ansible-playbook -i inventories/prod playbooks/site-upgrade-masters.yml
ansible-playbook -i inventories/prod playbooks/site-upgrade-workers.yml
```

### **Disaster Recovery**
```bash
# Backup operations
ansible-playbook -i inventories/prod playbooks/site-backup.yml
ansible-playbook -i inventories/prod playbooks/site-backup-cron.yml

# Disaster recovery
ansible-playbook -i inventories/prod playbooks/site-restore-etcd.yml
```

### **Multi-Environment Management**
```bash
# Deploy to different environments
ansible-playbook -i inventories/dev playbooks/site.yml      # Development
ansible-playbook -i inventories/staging playbooks/site.yml  # Staging
ansible-playbook -i inventories/prod playbooks/site.yml     # Production
```

## 📊 Comparison with Learning Approach

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

## 🚀 Migration Path

From playbook-based HA:
1. **Study role architecture** - Understand advanced modular design
2. **Learn enterprise patterns** - Multi-environment, backup/restore
3. **Practice operations** - Scaling, upgrades, disaster recovery
4. **Implement monitoring** - Add observability and alerting
5. **Production deployment** - Deploy with proper security

## 🔄 Next Steps

After mastering enterprise HA:
1. **Implement GitOps** - Infrastructure as Code workflows
2. **Add monitoring** - Prometheus, Grafana, alerting
3. **Security hardening** - RBAC, network policies, secrets management
4. **CI/CD integration** - Automated deployment pipelines
5. **Multi-cluster** - Federation and cross-cluster management

## 📚 What You'll Master

- **Enterprise HA architecture** - Complete understanding of production HA
- **Advanced Ansible patterns** - Complex role interactions and workflows
- **Kubernetes operations** - Scaling, upgrades, disaster recovery
- **Production deployment** - Multi-environment, security, monitoring
- **Operational excellence** - Backup strategies, incident response

## 🎓 Prerequisites

- Experience with single master deployments
- Understanding of HA concepts from playbook-based approach
- Kubernetes operational knowledge
- Production deployment experience
- Infrastructure automation expertise

The ultimate Kubernetes HA deployment for enterprise environments!

## Quick Start Guide

### 1. Setup Your Environment

```bash
# Clone or copy this project
cp -r inventories/lab inventories/myenv

# Edit your inventory
vim inventories/myenv/hosts.ini
vim inventories/myenv/group_vars/all.yml
```

### 2. Configure Inventory

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

[ha]
192.168.10.141
192.168.10.143
```

### 3. Deployment Scenarios

#### Complete Cluster Deployment
```bash
# Deploy everything (recommended for new clusters)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site.yml
```

#### Step-by-Step Deployment
```bash
# 1. Setup HAProxy + Keepalived first
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-haproxy-only.yml

# 2. Deploy master nodes only
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-master-only.yml

# 3. Add worker nodes
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-workers.yml
```

#### Scaling Operations
```bash
# Add new master nodes (use k8s_new_masters group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-masters.yml

# Add new worker nodes (use k8s_new_workers group)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-workers.yml

# Add specific workers only
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-workers.yml --limit k8s_new_workers
```

#### Upgrade Operations
```bash
# Upgrade all masters (one by one)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-upgrade-masters.yml

# Complete upgrade with backup and verification
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-upgrade-masters-complete.yml
```

#### Disaster Recovery Operations
```bash
# Restore ETCD from backup and reinitialize cluster
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-restore-etcd.yml

# Backup ETCD (runs on all masters, fetches to control host)
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-backup.yml

# Setup automated daily backups
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-backup-cron.yml

# Reset entire cluster
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-reset-nodes.yml
```

### 4. Configuration Variables

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

# ETCD Restore (in inventories/myenv/group_vars/new_cluster.yml)
backup_file_path: "./backups/myenv/k8s-master-1/etcd-backup-20250124.db"
control_plane_endpoint: "192.168.10.100:6443"
```

### 5. Verify Deployment

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

## Architecture Overview

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

## Available Playbooks

| Playbook | Purpose | Usage |
|----------|---------|-------|
| `site.yml` | Complete cluster deployment | New cluster setup |
| `site-master-only.yml` | Deploy masters only | Initial master setup |
| `site-add-masters.yml` | Add new masters | Scale master nodes |
| `site-add-workers.yml` | Add new workers | Scale worker nodes |
| `site-upgrade-masters.yml` | Upgrade all masters | Kubernetes version upgrade |
| `site-upgrade-masters-complete.yml` | Complete upgrade with backup | Safe upgrade with verification |
| `site-backup.yml` | Manual ETCD backup | One-time backup |
| `site-backup-cron.yml` | Setup automated backup | Daily backup schedule |
| `site-restore-etcd.yml` | Restore ETCD and reinit cluster | Disaster recovery |
| `site-reset-nodes.yml` | Reset entire cluster | Cluster cleanup |

## Directory Structure

```
project-k8s-multi-master-haproxy-keepalived-v2/
├── roles/                          # Modular role-based architecture
│   ├── common/                     # System setup + etcdctl
│   ├── containerd/                 # Container runtime
│   ├── kubernetes/
│   │   ├── install/               # Install k8s packages
│   │   ├── master/                # Initialize master + kubeadm config
│   │   ├── worker/                # Join workers
│   │   ├── join/                  # Generate join command
│   │   ├── upgrade_master/        # Upgrade master nodes
│   │   └── reset/                 # Cluster cleanup
│   ├── network/
│   │   └── calico/                # CNI plugin
│   ├── etcd/
│   │   └── backup/                # ETCD backup operations
│   └── haproxy_keepalived/        # HAProxy + Keepalived HA
├── playbooks/
│   ├── site.yml                   # Complete cluster deployment
│   ├── site-master-only.yml       # Master-only deployment
│   ├── site-add-workers.yml       # Add workers to existing cluster
│   ├── site-upgrade-masters.yml   # Upgrade masters
│   ├── site-backup.yml            # ETCD backup
│   └── site-reset-nodes.yml       # Reset cluster
├── docs/
│   └── MANUAL_UPGRADE_MASTERS.md  # Manual upgrade guide
├── archive/
│   └── playbooks/                 # Original playbooks (archived)
├── inventories/
│   └── lab/
│       ├── hosts.ini
│       └── group_vars/
└── README.md                      # This file
```

## Configuration Variables

**HAProxy/Keepalived Role** (`roles/haproxy_keepalived/defaults/main.yml`):
- `vip_address`: 192.168.10.100 (Virtual IP)
- `vip_netmask`: 24
- `virtual_router_id`: 51
- `keepalived_password`: 123456

**Kubernetes Upgrade Role** (`roles/kubernetes/upgrade_master/defaults/main.yml`):
- `kubernetes_upgrade_version`: "1.34" (Major.minor version)
- `kubernetes_target_version`: "v1.34.3" (Full version for kubeadm)
- `kubernetes_package_version`: "1.34.*" (Package version pattern)

**ETCD Backup Role** (`roles/etcd/backup/defaults/main.yml`):
- `etcd_backup_dir`: /opt/etcd-backup
- `etcd_backup_retention_days`: 7
- `local_backup_dir`: ./backups

**ETCD Restore Role** (`roles/etcd/restore/defaults/main.yml`):
- `backup_file_path`: Path to backup file
- `pod_network_cidr`: 10.10.0.0/16
- `control_plane_endpoint`: 192.168.10.100:6443
- `ignore_preflight_errors`: DirAvailable--var-lib-etcd

## Disaster Recovery Guide

### ETCD Backup and Restore

#### 1. Create Backup
```bash
# Manual backup
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-backup.yml

# Setup automated daily backups
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-backup-cron.yml
```

#### 2. Prepare for Restore
```bash
# List available backups
ls -la ./backups/myenv/k8s-master-1/

# Edit restore configuration
vim inventories/myenv/group_vars/new_cluster.yml
```

#### 3. Configure Restore Settings
Edit `inventories/myenv/group_vars/new_cluster.yml`:
```yaml
# Path to backup file (relative or absolute)
backup_file_path: "./backups/myenv/k8s-master-1/etcd-backup-20250124-143022.db"

# Cluster configuration
pod_network_cidr: "10.10.0.0/16"
control_plane_endpoint: "192.168.10.100:6443"
```

#### 4. Perform Restore
```bash
# Restore ETCD and reinitialize cluster
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-restore-etcd.yml
```

#### 5. Verify Restored Cluster
```bash
# SSH to restored master
ssh master@192.168.10.138

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Verify workloads are restored
kubectl get all -A
```

#### 6. Rejoin Other Masters and Workers
```bash
# Add other masters back
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-masters.yml

# Add workers back
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-workers.yml
```

### Important Notes

⚠️ **Disaster Recovery Warnings:**
- Restore will **completely reset** the target master node
- All existing cluster data will be **lost** and replaced with backup data
- Only use `new_cluster` group (single master) for restore
- Test restore procedure in non-production environment first
- Ensure backup file path is correct before running restore

💡 **Best Practices:**
- Take regular backups using automated cron job
- Store backups in multiple locations (local + remote)
- Test restore procedure regularly
- Document your backup/restore procedures
- Keep backup retention policy appropriate for your needs

## Troubleshooting

### Common Issues

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
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-add-masters.yml --tags always
```

**Backup fails:**
```bash
# Check etcd pod status
kubectl get pods -n kube-system -l component=etcd

# Manual backup test
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-backup.yml --limit k8s_masters[0]
```

**Restore fails:**
```bash
# Check backup file exists
ls -la ./backups/myenv/k8s-master-1/

# Verify backup file path in group_vars
vim inventories/myenv/group_vars/new_cluster.yml

# Test restore on single node
ansible-playbook -i inventories/myenv/hosts.ini playbooks/site-restore-etcd.yml --limit new_cluster
```

## Security Notes

⚠️ **Production Checklist:**
- [ ] Change default passwords in `group_vars/`
- [ ] Use SSH keys instead of password auth
- [ ] Configure firewall rules
- [ ] Enable TLS for HAProxy
- [ ] Set up monitoring and alerting
- [ ] Configure backup encryption

## License

This project is provided as-is for educational purposes.