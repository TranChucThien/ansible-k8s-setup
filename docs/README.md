# Kubernetes Ansible Documentation

Complete documentation for deploying and managing Kubernetes clusters using Ansible.

## 📚 Documentation Structure

### [01. Setup Guides](01-setup-guides/)
Initial cluster setup and installation procedures
- **[README](01-setup-guides/README.md)** - Setup overview
- **[Connect Cluster](01-setup-guides/connect-cluster.md)** - Cluster connection guide
- **[Manual Installation](01-setup-guides/k8s-manual-installation.md)** - Manual K8s setup
- **[Multi-Master Setup](01-setup-guides/multi-master-setup-noha.md)** - Multi-master without HA

### [02. Operations Guide](02-operations-guide/)
Day-to-day cluster management and operations
- **[Operations Guide (EN)](02-operations-guide/operations-guide-en.md)** - English operations manual
- **[Operations Guide (VI)](02-operations-guide/operations-guide.md)** - Vietnamese operations manual

### [03. Backup & Restore](03-backup-restore/)
Data protection and disaster recovery procedures
- **[README](03-backup-restore/README.md)** - Backup overview
- **[etcd Backup & Restore](03-backup-restore/etcd-backup-restore/)** - Complete etcd backup/restore guide

### [04. Upgrade Strategies](04-upgrade-strategies/)
Kubernetes cluster upgrade procedures and best practices
- **[Upgrade Theory](04-upgrade-strategies/kubernetes-upgrade-theory-and-best-practices.md)** - Theoretical foundation
- **[Manual Upgrade](04-upgrade-strategies/manual-kubernetes-upgrade-guide.md)** - Manual upgrade procedures
- **[Ansible Upgrade](04-upgrade-strategies/upgrade-strategies/ansible-kubernetes-upgrade-guide.md)** - Automated upgrade with Ansible

### [05. HA Cluster Testing](05-test-ha-cluster/)
High availability testing and validation procedures
- **[HA Test Guide (EN)](05-test-ha-cluster/test-ha-cluster-en.md)** - English HA testing guide
- **[HA Test Guide (VI)](05-test-ha-cluster/test-ha-cluster.md)** - Vietnamese HA testing guide

### [06. Troubleshooting](06-troubleshooting/)
Problem diagnosis and resolution procedures
- **[README](06-troubleshooting/README.md)** - Troubleshooting overview
- **[etcd Restore Troubleshooting](06-troubleshooting/etcd-restore-troubleshooting.md)** - etcd specific issues
- **[Node Management](06-troubleshooting/node-management.md)** - Node-related problems
- **[Reset Nodes](06-troubleshooting/reset-nodes.md)** - Node reset procedures

## 🚀 Quick Start

### For New Deployments
1. Start with **[Setup Guides](01-setup-guides/)** for initial cluster deployment
2. Follow **[Operations Guide](02-operations-guide/)** for daily management
3. Implement **[Backup Procedures](03-backup-restore/)** for data protection

### For Existing Clusters
1. Review **[Operations Guide](02-operations-guide/)** for management procedures
2. Plan **[Upgrade Strategy](04-upgrade-strategies/)** for version updates
3. Validate **[HA Configuration](05-test-ha-cluster/)** for reliability

### For Troubleshooting
1. Check **[Troubleshooting Guide](06-troubleshooting/)** for common issues
2. Review **[Backup & Restore](03-backup-restore/)** for recovery procedures
3. Consult specific component guides for detailed solutions

## 📋 Documentation Standards

### File Naming Convention
- **Numbered Folders**: `01-setup-guides`, `02-operations-guide`, etc.
- **Descriptive Names**: Clear, concise file names
- **Language Suffixes**: `-en.md` for English, `-vi.md` for Vietnamese

### Image Organization
- **Dedicated Folders**: Each section has its own `images/` folder
- **Sequential Naming**: `01-description.png`, `02-description.png`
- **Descriptive Names**: Clear image descriptions in filenames

### Content Structure
- **Table of Contents**: All major documents include TOC
- **Cross-References**: Links between related documents
- **Code Examples**: Practical, copy-paste ready commands
- **Visual Aids**: Screenshots and diagrams where helpful

## 🔧 Repository Structure

```
docs/
├── 01-setup-guides/           # Initial deployment
├── 02-operations-guide/       # Daily operations
├── 03-backup-restore/         # Data protection
├── 04-upgrade-strategies/     # Version management
├── 05-test-ha-cluster/       # HA validation
├── 06-troubleshooting/       # Problem resolution
└── README.md                 # This file
```

## 📖 Contributing

When adding new documentation:
1. Follow the numbered folder structure
2. Include proper table of contents
3. Add relevant images to `images/` folders
4. Update this README if adding new sections
5. Use consistent formatting and style

## 🏷️ Version Information

- **Kubernetes Versions**: 1.33.x - 1.34.x
- **Ansible Version**: 2.9+
- **OS Support**: Ubuntu 24.04 LTS
- **Last Updated**: January 2025