# 🔧 Troubleshooting Documentation

Solutions for common Kubernetes cluster issues and problems.

## 📋 Available Guides

### 🚨 [etcd Restore Troubleshooting](etcd-restore-troubleshooting.md)
Common issues encountered during etcd restore operations
- **Member synchronization problems**
- **Peer URL configuration issues**
- **Token and certificate expiration**
- **API server connection problems**

## 🎯 Quick Solutions

### Most Common Issues
1. **"can only promote a learner member"** → Update etcd peer URLs
2. **Expired tokens** → Generate new bootstrap tokens
3. **Stale etcd members** → Remove old members from cluster
4. **API server connection** → Verify etcd endpoints

## 🔗 Related Documentation

- [Backup & Restore](../backup-restore/) - Prevention through proper backup
- [Operations Guide](../operations-guide/) - Cluster maintenance
- [HA Testing](../test-ha-cluster/) - Validate fixes

## 📞 Emergency Procedures

If all troubleshooting fails:
1. Save current workloads
2. Reset all nodes
3. Reinitialize cluster
4. Restore workloads

**Remember**: Prevention is better than cure - regular backups and testing are essential!