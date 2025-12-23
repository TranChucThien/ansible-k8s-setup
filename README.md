# Kubernetes Ansible Deployment

Deploy Kubernetes clusters on Ubuntu 24.04 using Ansible with multiple architecture options.

## 🚀 Quick Links

- **[Single Master](project-k8s-single-master/)** - Simple cluster for dev/test/learning
- **[Multi-Master HA with HAProxy](project-k8s-multi-master-haproxy/)** - HA cluster with HAProxy
- **[Multi-Master HA with HAProxy + Keepalived](project-k8s-multi-master-haproxy-keepalived/)** - Full HA with VIP failover

## 📁 Repository Structure

```
ansible-k8s/
├── project-k8s-single-master/           # Single master deployments
│   ├── project-k8s-single-master/      # Basic playbook approach
│   └── project-k8s-single-master-v2/   # Advanced roles approach
├── project-k8s-multi-master-haproxy/   # Multi-master with HAProxy
├── project-k8s-multi-master-haproxy-keepalived/  # Full HA setup
├── docs/                               # Documentation
│   ├── setup-guides/
│   ├── operations/
│   ├── backup-restore/
│   └── troubleshooting/
├── backups/                            # Cluster backups
└── README.md                           # This file
```

## 🎯 Choose Your Deployment

### 🔰 **Beginners** - Start Here
**[project-k8s-single-master/project-k8s-single-master/](project-k8s-single-master/project-k8s-single-master/)**
- Simple playbook structure
- Easy to understand and modify
- Perfect for learning Ansible + Kubernetes

### 🏗️ **Advanced** - Production Ready
**[project-k8s-single-master/project-k8s-single-master-v2/](project-k8s-single-master/project-k8s-single-master-v2/)**
- Ansible roles architecture
- Multi-environment support
- Production best practices

### 🚀 **High Availability** - Enterprise
**[project-k8s-multi-master-haproxy-keepalived/](project-k8s-multi-master-haproxy-keepalived/)**
- Multiple master nodes
- Load balancer with failover
- Zero downtime deployments

## ⚡ Quick Start

```bash
# Clone repository
git clone <repository-url>
cd ansible-k8s

# Choose your deployment type
cd project-k8s-single-master/project-k8s-single-master/  # Beginner
# OR
cd project-k8s-single-master/project-k8s-single-master-v2/  # Advanced

# Deploy cluster
ansible-playbook -i inventory-lab playbooks/site.yml
```

## 🔧 Requirements

- **OS**: Ubuntu 24.04 LTS
- **Ansible**: 2.9+
- **Python**: 3.x
- **SSH**: Access to all nodes
- **Privileges**: Root/sudo access

## 📦 What Gets Installed

- **Container Runtime**: containerd
- **Kubernetes**: v1.33.x
- **CNI Plugin**: Calico v3.28.0
- **Load Balancer** (HA only): HAProxy + Keepalived
- **Backup Tools**: etcdctl, etcdutl

## 📚 Documentation

- **[Setup Guides](docs/setup-guides/)** - Installation and configuration
- **[Operations Guide](docs/operations/)** - Day-to-day management
- **[Backup & Restore](docs/backup-restore/)** - Data protection
- **[Troubleshooting](docs/troubleshooting/)** - Common issues and solutions

## 🔄 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## ⚠️ Security Notice

This repository contains sample configurations for demonstration purposes. For production use:
- Use SSH key-based authentication
- Implement Ansible Vault for secrets
- Follow security best practices
- Review and harden all configurations