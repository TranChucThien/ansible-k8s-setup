# Kubernetes Single Master v2 - Role-Based Architecture

Production-ready single master Kubernetes cluster using modern Ansible roles architecture.

## 🎯 Overview

This project uses **role-based architecture** for production deployments:
- **Modular roles** - Reusable components (common, containerd, kubernetes, network)
- **Multi-environment** - Dev, lab, prod inventories with proper variable hierarchy
- **Advanced operations** - Automated backup, worker scaling, cluster management
- **Production patterns** - Industry standard organization and best practices

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│         Master Node             │
│    (Control Plane + etcd)       │
│  • API Server                   │
│  • Controller Manager           │
│  • Scheduler                    │
│  • etcd Database + etcdctl      │
│  • Calico CNI                   │
└─────────────┬───────────────────┘
              │ Kubernetes API
              │
    ┌─────────▼─────────┐
    │   Worker Nodes    │
    │    (Compute)      │
    │  • kubelet        │
    │  • kube-proxy     │
    │  • containerd     │
    └───────────────────┘
```

## 🚀 Quick Start

```bash
# Deploy complete cluster
ansible-playbook -i inventories/lab playbooks/site.yml

# Deploy master only (development)
ansible-playbook -i inventories/lab playbooks/site-master-only.yml

# Add workers to existing cluster
ansible-playbook -i inventories/lab playbooks/site-add-workers.yml
```

## 📁 Role-Based Structure

```
project-k8s-single-master-v2/
├── roles/                          # Modular role architecture
│   ├── common/                     # System setup + etcdctl
│   ├── containerd/                 # Container runtime
│   ├── kubernetes/
│   │   ├── install/               # Package installation
│   │   ├── master/                # Control plane setup
│   │   ├── worker/                # Worker node setup
│   │   ├── join/                  # Join command generation
│   │   └── reset/                 # Cleanup operations
│   ├── network/
│   │   └── calico/                # CNI plugin
│   └── etcd/
│       └── backup/                # Backup operations
├── inventories/                    # Multi-environment support
│   ├── dev/
│   ├── lab/
│   └── prod/
├── playbooks/
│   ├── site.yml                   # Complete deployment
│   ├── site-master-only.yml       # Master-only deployment
│   ├── site-add-workers.yml       # Add workers
│   ├── site-backup.yml            # ETCD backup
│   └── archive/                   # Legacy playbooks
└── README.md                      # This file
```

## 🎯 Production Features

### **Enterprise Capabilities**
- ✅ **Multi-environment** - Separate dev/lab/prod configurations
- ✅ **Automated backup** - ETCD backup with retention policies
- ✅ **Worker scaling** - Dynamic node addition/removal
- ✅ **Idempotent operations** - Safe to run multiple times
- ✅ **Comprehensive logging** - Detailed execution logs
- ✅ **Best practices** - Following Ansible and K8s standards

### **Operational Excellence**
- **Modular design** - Reusable roles for different projects
- **Variable hierarchy** - Proper defaults → group_vars → host_vars
- **Template usage** - Dynamic configuration generation
- **Handler organization** - Proper service management
- **Cross-host communication** - Fact-based, no file dependencies

## 🔧 Advanced Operations

### **Cluster Management**
```bash
# Add specific workers
ansible-playbook -i inventories/lab playbooks/site-add-workers.yml --limit k8s-worker-2

# Backup operations
ansible-playbook -i inventories/lab playbooks/site-backup.yml
ansible-playbook -i inventories/lab playbooks/site-backup-cron.yml

# Reset cluster
ansible-playbook -i inventories/lab playbooks/site-reset-nodes.yml
```

### **Multi-Environment Deployment**
```bash
# Deploy to different environments
ansible-playbook -i inventories/dev playbooks/site.yml     # Development
ansible-playbook -i inventories/lab playbooks/site.yml     # Lab testing
ansible-playbook -i inventories/prod playbooks/site.yml    # Production
```

## 📊 Comparison with Playbook-Based

| Feature | Playbook-Based | Role-Based (v2) |
|---------|----------------|------------------|
| **Learning Curve** | Easy | Moderate |
| **Structure** | Linear playbooks | Modular roles |
| **Reusability** | Limited | High |
| **Maintainability** | Basic | Excellent |
| **Production Ready** | No | Yes |
| **Multi-Environment** | No | Yes |
| **Advanced Operations** | Basic | Complete |
| **Scalability** | Limited | High |

## 🚀 Migration Path

From playbook-based approach:
1. **Understand role structure** - Learn modular organization
2. **Study variable hierarchy** - Master defaults → group_vars → host_vars
3. **Practice operations** - Test advanced features
4. **Customize for production** - Adapt to your infrastructure

## 🔄 Next Steps

After mastering single master v2:
1. **Scale to production** - Use multi-environment features
2. **Implement monitoring** - Add observability stack
3. **Move to HA** - Upgrade to multi-master:
   ```bash
   cd ../project-k8s-multi-master-haproxy-keepalived-v2/
   ```
4. **Contribute back** - Share improvements with community

## 📚 What You'll Learn

- **Ansible roles architecture** and best practices
- **Multi-environment** deployment strategies
- **Production operations** - backup, scaling, maintenance
- **Variable management** and template usage
- **Enterprise patterns** for infrastructure automation

## 🎓 Prerequisites

- Experience with playbook-based deployments
- Understanding of Ansible roles concept
- Kubernetes operational knowledge
- Production deployment requirements

Perfect foundation for enterprise Kubernetes operations!