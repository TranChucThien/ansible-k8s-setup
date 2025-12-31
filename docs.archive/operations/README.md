# 🔄 Operations Documentation

Day-to-day cluster operations and maintenance procedures.

## 📋 Available Guides

### 📖 [Operations Guide](../operations-guide/)
Comprehensive cluster operations documentation
- **Complete operations procedures**
- **Visual step-by-step guides**
- **Scaling and maintenance tasks**
- **Available in English and Vietnamese**

### 🔧 [Node Management](node-management.md)
Add and remove cluster nodes
- **Adding new master nodes**
- **Adding new worker nodes**
- **Removing nodes safely**
- **Node maintenance procedures**

### 🔄 [Reset Nodes](reset-nodes.md)
Clean node reset and cleanup procedures
- **Complete node reset**
- **Clean cluster state**
- **Prepare nodes for re-joining**

## 🎯 Common Operations

### Daily Tasks
- Monitor cluster health
- Check node status
- Review logs and metrics
- Backup verification

### Scaling Operations
- [Add worker nodes](node-management.md#adding-worker-nodes)
- [Add master nodes](node-management.md#adding-master-nodes)
- [Remove nodes](node-management.md#removing-nodes)

### Maintenance Tasks
- [Node updates and patches](node-management.md#node-maintenance)
- [Clean node reset](reset-nodes.md)
- [Cluster component updates](../operations-guide/)

## 🔗 Related Documentation

- [Setup Guides](../setup-guides/) - Initial cluster deployment
- [Backup & Restore](../backup-restore/) - Data protection
- [Troubleshooting](../troubleshooting/) - Fix common issues
- [HA Testing](../test-ha-cluster/) - Validate operations

## ⚠️ Best Practices

- **Always backup** before major operations
- **Test procedures** in non-production first
- **Monitor cluster health** during operations
- **Document changes** for future reference
- **Follow maintenance windows** for production clusters