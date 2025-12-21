# 🚀 Setup Guides

Initial cluster setup and configuration documentation.

## 📋 Available Guides

### 📖 [Manual Installation Guide](k8s-manual-installation.md)
Step-by-step manual Kubernetes installation
- **Prerequisites and requirements**
- **Node preparation procedures**
- **Manual cluster initialization**
- **Component installation steps**

### 🔗 [Multi-Master Setup (No HA)](multi-master-setup-noha.md)
Basic multi-master cluster configuration
- **Multiple control plane nodes**
- **Basic load balancing**
- **No high availability features**

### 🌐 [Cluster Connection Guide](connect-cluster.md)
Connect to and access your Kubernetes cluster
- **kubectl configuration**
- **Access methods and authentication**
- **Remote cluster management**

## 🎯 Recommended Setup Path

1. **Start here**: Choose your deployment method
   - Simple: [Single Master](../../project-k8s-single-master/)
   - Production: [Multi-Master HA](../../project-k8s-multi-master-haproxy-keepalived/)

2. **Follow setup**: Use Ansible playbooks for automated deployment

3. **Connect**: Use [Connection Guide](connect-cluster.md) to access cluster

4. **Secure**: Setup [Backup & Restore](../backup-restore/) procedures

## 🔗 Related Documentation

- [Operations Guide](../operations-guide/) - Post-setup management
- [Backup & Restore](../backup-restore/) - Data protection
- [HA Testing](../test-ha-cluster/) - Validate your setup

## ⚠️ Important Notes

- **Test in non-production** environments first
- **Follow security best practices** from the start
- **Setup monitoring and backup** immediately after deployment
- **Document your specific configuration** for troubleshooting