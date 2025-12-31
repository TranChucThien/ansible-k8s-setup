# 📚 Kubernetes Ansible Documentation

Comprehensive documentation for Kubernetes cluster deployment and management using Ansible.

## 📁 Documentation Structure

### 🚀 [Setup Guides](setup-guides/)
Initial cluster setup and configuration guides
- **[Manual Installation Guide](setup-guides/k8s-manual-installation.md)** - Step-by-step manual setup
- **[Multi-Master Setup (No HA)](setup-guides/multi-master-setup-noha.md)** - Basic multi-master configuration
- **[Cluster Connection Guide](setup-guides/connect-cluster.md)** - Connect to your cluster

### 🔄 [Operations](operations/)
Day-to-day cluster operations and management
- **[Operations Guide](operations-guide/)** - Complete operations documentation
- **[Node Management](operations/node-management.md)** - Add/remove nodes
- **[Reset Nodes](operations/reset-nodes.md)** - Clean node reset procedures

### 💾 [Backup & Restore](backup-restore/)
Data protection and disaster recovery
- **[etcd Backup & Restore Guide](backup-restore/)** - Complete backup/restore procedures
- Automated backup strategies
- Disaster recovery procedures

### 🔧 [Troubleshooting](troubleshooting/)
Common issues and solutions
- **[etcd Restore Troubleshooting](troubleshooting/etcd-restore-troubleshooting.md)** - Fix restore issues
- Common cluster problems
- Emergency recovery procedures

### 🧪 [Testing](test-ha-cluster/)
High availability testing and validation
- **[HA Cluster Testing Guide](test-ha-cluster/)** - Comprehensive HA testing
- Failure scenarios and recovery
- Performance validation

## 🎯 Quick Navigation

### For New Users
1. Start with [Setup Guides](setup-guides/) for initial deployment
2. Follow [Operations Guide](operations-guide/) for daily management
3. Setup [Backup & Restore](backup-restore/) for data protection

### For Troubleshooting
1. Check [Troubleshooting](troubleshooting/) for common issues
2. Review [Testing Guide](test-ha-cluster/) for validation procedures
3. Use [Operations](operations/) for maintenance tasks

### For Advanced Users
1. Explore [HA Testing](test-ha-cluster/) for failure scenarios
2. Review [Backup Strategies](backup-restore/) for disaster recovery
3. Check [Operations Guide](operations-guide/) for scaling procedures

## 📖 Documentation Standards

Each section includes:
- **Step-by-step procedures** with commands
- **Screenshots and diagrams** for visual guidance
- **Troubleshooting tips** for common issues
- **Best practices** and recommendations
- **Ansible playbooks** for automation

## 🔗 Related Resources

- **[Main README](../README.md)** - Project overview and quick start
- **[Single Master Setup](../project-k8s-single-master/)** - Simple cluster setup
- **[Multi-Master HA Setup](../project-k8s-multi-master-haproxy-keepalived/)** - Full HA cluster
- **[Playbooks](../project-k8s-multi-master-haproxy-keepalived/playbooks/)** - Ansible automation

## 🤝 Contributing

When adding new documentation:
1. Place files in appropriate category folders
2. Include images in `images/` subfolder
3. Follow existing naming conventions
4. Update this README with new content
5. Test all procedures before documenting

---

**Need help?** Check the appropriate section above or refer to the troubleshooting guides.