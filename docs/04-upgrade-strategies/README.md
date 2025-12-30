# Kubernetes Upgrade Strategies

Complete guide for upgrading Kubernetes clusters from theoretical foundation to practical implementation.

## 📚 Upgrade Documentation

### [01. Upgrade Theory & Best Practices](01-kubernetes-upgrade-theory-and-best-practices.md)
Theoretical foundation and enterprise-grade upgrade strategies
- **Version Skew Policy**: Component compatibility matrix
- **Package Infrastructure**: Migration to pkgs.k8s.io
- **etcd Backup Strategy**: Data protection procedures
- **Control Plane Upgrade**: Safe execution principles

### [02. Manual Upgrade Guide](02-manual-kubernetes-upgrade-guide.md)
Step-by-step manual upgrade procedures for learning and understanding
- **Prerequisites**: Repository setup and backup procedures
- **Master Upgrade**: Sequential control plane upgrade
- **Worker Upgrade**: Rolling worker node updates
- **Verification**: Post-upgrade health checks
- **Troubleshooting**: Common issues and solutions

### [03. Ansible Upgrade Guide](03-ansible-kubernetes-upgrade-guide.md)
Automated upgrade procedures using Ansible for production environments
- **Zero-Downtime Upgrade**: Automated rolling updates
- **Application Testing**: Real-time downtime monitoring
- **Visual Walkthrough**: Complete upgrade process with screenshots
- **Multiple Scenarios**: Conservative, automated, and dry-run options

## 🎯 Upgrade Path

### Learning Path
1. **Start with Theory** → Understand version skew and upgrade principles
2. **Practice Manual** → Learn step-by-step procedures
3. **Implement Ansible** → Automate for production use

### Production Path
1. **Review Theory** → Ensure understanding of risks and procedures
2. **Test in Staging** → Validate upgrade procedures
3. **Execute with Ansible** → Automated production upgrade

## 🔄 Supported Upgrade Paths

| Current Version | Target Version | Method | Notes |
|----------------|----------------|---------|-------|
| 1.33.x | 1.34.x | ✅ All Methods | Direct upgrade supported |
| 1.32.x | 1.34.x | ❌ Not Supported | Must upgrade 1.32→1.33→1.34 |
| 1.34.x | 1.35.x | ✅ All Methods | When 1.35 becomes available |

## 📋 Prerequisites

### Environment Requirements
- **OS**: Ubuntu 24.04 LTS
- **Ansible**: 2.9+
- **Access**: SSH access to all nodes
- **Privileges**: Root/sudo access
- **Backup**: etcd backup capability

### Version Compatibility
- **Never skip minor versions**: Always upgrade sequentially
- **Test first**: Validate in non-production environment
- **Backup always**: Create etcd backup before upgrade
- **Monitor closely**: Watch cluster health during upgrade

## 🛠️ Quick Reference

### Pre-Upgrade Checklist
- [ ] Review upgrade theory and best practices
- [ ] Update package repositories to pkgs.k8s.io
- [ ] Create etcd backup
- [ ] Deploy test application for downtime monitoring
- [ ] Verify cluster health

### Upgrade Execution
- [ ] Upgrade control plane nodes sequentially
- [ ] Monitor API server availability
- [ ] Upgrade worker nodes with rolling strategy
- [ ] Test application availability during upgrade
- [ ] Verify all components upgraded successfully

### Post-Upgrade Validation
- [ ] Check all nodes show new version
- [ ] Verify cluster health
- [ ] Test workload functionality
- [ ] Clean up test applications
- [ ] Document upgrade completion

## 🔍 Visual Guides

All upgrade guides include comprehensive screenshots showing:
- **Before/After States**: Cluster status comparison
- **Process Execution**: Step-by-step command outputs
- **Monitoring Results**: Real-time application availability
- **Verification Steps**: Health check confirmations

## 📖 Additional Resources

- **[Backup & Restore Guide](../03-backup-restore/)** - Data protection procedures
- **[HA Testing Guide](../05-test-ha-cluster/)** - High availability validation
- **[Troubleshooting Guide](../06-troubleshooting/)** - Problem resolution

## 🏷️ Version Information

- **Kubernetes**: 1.33.x → 1.34.x
- **Documentation**: January 2025
- **Tested On**: Ubuntu 24.04 LTS
- **Ansible**: 2.9+