# 💾 Backup & Restore Documentation

Complete documentation for etcd backup and disaster recovery procedures.

## 📋 Contents

### 📖 [etcd Backup & Restore Guide](etcd-backup-restore/)
Comprehensive guide for etcd backup and restore operations
- **Manual backup procedures**
- **Automated backup setup**
- **Disaster recovery steps**
- **Ansible playbook automation**

### 🖼️ Visual Documentation
All guides include detailed screenshots and diagrams in `images/` folders for:
- Backup verification procedures
- Restore process validation
- Cluster health checks
- Recovery confirmation

## 🎯 Quick Links

- **[Main Guide](etcd-backup-restore/etcd%20Backup%20&%20Restore%20Guide%20(Ansible)%202ce233b7125780749f0ccbe4e4116b50.md)** - Complete backup/restore documentation
- **[Troubleshooting](../troubleshooting/etcd-restore-troubleshooting.md)** - Fix common restore issues

## ⚠️ Important Notes

- **etcd backup = Disaster recovery only**
- **Always test restore procedures** in non-production environments
- **Store backups in multiple locations**
- **Verify backup integrity** before relying on them

## 🔄 Related Operations

- [Node Management](../operations/node-management.md) - Add/remove nodes
- [HA Testing](../test-ha-cluster/) - Validate cluster resilience
- [Operations Guide](../operations-guide/) - Daily cluster management