# Kubernetes Ansible Deployment

Deploy Kubernetes clusters on Ubuntu 24.04 using Ansible with two distinct approaches.

## 🎯 Choose Your Approach

### 📚 **Playbook-Based** - Learning & Understanding
**[playbook-based/](playbook-based/)**

Traditional Ansible playbooks for educational purposes:
- **Easy to understand** - Linear execution flow
- **Learning focused** - Great for understanding Kubernetes setup
- **Simple structure** - Direct playbook approach
- **Quick modifications** - Easy to customize and experiment

### 🏗️ **Role-Based** - Production & Best Practices
**[role-based/](role-based/)**

Modern Ansible roles architecture for production use:
- **Modular design** - Reusable and maintainable components
- **Production ready** - Enterprise-grade deployments
- **Advanced operations** - Automated backup, restore, upgrade
- **Multi-environment** - Dev, staging, production support

## 📁 Repository Structure

```
ansible-k8s/
├── playbook-based/                     # Traditional playbook approach
│   ├── project-k8s-single-master/     # Single master (playbooks)
│   ├── project-k8s-multi-master-haproxy/  # Multi-master + HAProxy
│   └── project-k8s-multi-master-haproxy-keepalived/  # Full HA setup
├── role-based/                         # Modern roles architecture
│   ├── project-k8s-single-master-v2/  # Single master (roles)
│   └── project-k8s-multi-master-haproxy-keepalived-v2/  # Enterprise HA
├── docs/                               # Documentation
├── backups/                            # Cluster backups
└── README.md                           # This file
```

## 🚀 Quick Start

### For Learning (Playbook-Based)
```bash
cd playbook-based/project-k8s-single-master/
ansible-playbook -i inventory-lab playbooks/site.yml
```

### For Production (Role-Based)
```bash
cd role-based/project-k8s-single-master-v2/
ansible-playbook -i inventories/lab/hosts.ini playbooks/01-cluster-deploy.yml
```

## 🎓 Learning Path

```
1. Playbook-Based (Learning)
   ├── Single Master → Multi-Master → HA Setup
   └── Understand concepts and flow

2. Role-Based (Production)
   ├── Single Master v2 → Multi-Master v2
   └── Production deployment and operations
```

## 🔧 Requirements

- **OS**: Ubuntu 24.04 LTS
- **Ansible**: 2.9+
- **Python**: 3.x
- **SSH**: Access to all nodes
- **Privileges**: Root/sudo access

## 📦 What Gets Installed

- **Container Runtime**: containerd
- **Kubernetes**: v1.33.x (v1.34.x in role-based)
- **CNI Plugin**: Calico v3.28.0
- **Load Balancer** (HA): HAProxy + Keepalived
- **Backup Tools**: etcdctl, etcdutl

## 📚 Documentation

- **[Setup Guides](docs/01-setup-guides/)** - Installation and configuration
- **[Operations Guide](docs/02-operations-guide/)** - Day-to-day management
- **[Backup & Restore](docs/03-backup-restore/)** - Data protection
- **[Upgrade Strategies](docs/04-upgrade-strategies/)** - Version management
- **[HA Testing](docs/05-test-ha-cluster/)** - High availability validation
- **[Troubleshooting](docs/06-troubleshooting/)** - Common issues and solutions

## ⚠️ Security Notice

This repository contains sample configurations for demonstration purposes. For production use:
- Use SSH key-based authentication
- Implement Ansible Vault for secrets
- Follow security best practices
- Review and harden all configurations