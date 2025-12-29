# Role-Based Kubernetes Deployments

Modern Ansible roles architecture for production-ready Kubernetes deployments with advanced operations.

## 🎯 Projects Overview

### 🏗️ **Single Master v2**
**[project-k8s-single-master-v2/](project-k8s-single-master-v2/)**

Production-ready single master with roles architecture:
- **Modular roles** - Reusable components (common, containerd, kubernetes, network)
- **Multi-environment** - Dev, lab, prod inventories
- **Advanced operations** - Automated backup, worker scaling
- **Best practices** - Industry standard organization

```bash
cd project-k8s-single-master-v2/
ansible-playbook -i inventories/lab playbooks/site.yml
```

### 🚀 **Multi-Master HA v2**
**[project-k8s-multi-master-haproxy-keepalived-v2/](project-k8s-multi-master-haproxy-keepalived-v2/)**

Enterprise-grade HA cluster with complete operations:
- **Full HA architecture** - Multiple masters + HAProxy + Keepalived + VIP
- **Advanced roles** - Specialized roles for each component
- **Disaster recovery** - Complete ETCD backup/restore workflows
- **Upgrade automation** - Rolling upgrades with verification
- **Production operations** - Scaling, monitoring, maintenance

```bash
cd project-k8s-multi-master-haproxy-keepalived-v2/
ansible-playbook -i inventories/lab playbooks/site.yml
```

## 🏗️ Roles Architecture

### **Common Roles Structure**
```
roles/
├── common/              # System setup, hostname, packages
├── containerd/          # Container runtime
├── kubernetes/
│   ├── install/         # Package installation
│   ├── master/          # Control plane setup
│   ├── worker/          # Worker node setup
│   ├── join/            # Join command generation
│   └── reset/           # Cleanup operations
├── network/
│   └── calico/          # CNI plugin
├── etcd/
│   ├── backup/          # Backup operations
│   └── restore/         # Restore operations
└── haproxy_keepalived/  # HA load balancer (v2 only)
```

### **Multi-Environment Support**
```
inventories/
├── dev/
│   ├── hosts.ini
│   └── group_vars/
├── lab/
│   ├── hosts.ini
│   └── group_vars/
└── prod/
    ├── hosts.ini
    └── group_vars/
```

## 🚀 Advanced Operations

### **Single Master v2 Operations**
- **Worker scaling**: Add/remove workers dynamically
- **Automated backup**: ETCD backup with retention
- **Node reset**: Clean cluster reset
- **Multi-environment**: Deploy to dev/lab/prod

### **Multi-Master HA v2 Operations**
- **Master scaling**: Add new masters to existing cluster
- **Rolling upgrades**: Kubernetes version upgrades
- **Disaster recovery**: Complete ETCD restore workflows
- **VIP failover**: Automatic load balancer failover
- **Advanced backup**: Multi-master backup strategies
- **Health monitoring**: Cluster health verification

## 🎯 Production Features

### **Enterprise Capabilities**
- **High Availability**: Zero downtime deployments
- **Disaster Recovery**: Complete backup/restore procedures
- **Upgrade Automation**: Rolling upgrades with rollback
- **Multi-Environment**: Separate dev/staging/prod configs
- **Security**: Production security best practices
- **Monitoring**: Health checks and verification
- **Scalability**: Dynamic node scaling

### **Operational Excellence**
- **Idempotency**: Safe to run multiple times
- **Error Handling**: Comprehensive error recovery
- **Logging**: Detailed operation logs
- **Documentation**: Complete operational guides
- **Testing**: Verification and validation steps

## 📊 Comparison with Playbook-Based

| Feature | Playbook-Based | Role-Based |
|---------|----------------|------------|
| **Learning Curve** | Easy | Moderate |
| **Structure** | Linear playbooks | Modular roles |
| **Reusability** | Limited | High |
| **Maintainability** | Basic | Excellent |
| **Production Ready** | No | Yes |
| **Multi-Environment** | No | Yes |
| **Advanced Operations** | Basic | Complete |
| **Scalability** | Limited | High |

## 🔧 Best Practices Implemented

### **Ansible Best Practices**
- **Roles separation** by responsibility
- **Variables hierarchy** (defaults → group_vars → host_vars)
- **Template usage** for configuration files
- **Handler organization** per role
- **Tag implementation** for granular control
- **Cross-host communication** via hostvars

### **Kubernetes Best Practices**
- **HA architecture** with proper quorum
- **Security hardening** configurations
- **Network policies** and CNI setup
- **ETCD backup** strategies
- **Rolling updates** procedures
- **Health monitoring** integration

## 🚀 Getting Started

### **Prerequisites**
- Experience with playbook-based deployments
- Understanding of Ansible roles concept
- Kubernetes operational knowledge
- Production deployment requirements

### **Migration from Playbook-Based**
1. **Study role structure** - Understand modular approach
2. **Review variables** - Learn variable hierarchy
3. **Practice operations** - Test advanced features
4. **Customize for environment** - Adapt to your infrastructure

### **Production Deployment**
1. **Environment setup** - Configure inventories
2. **Security hardening** - Implement security measures
3. **Backup strategy** - Set up disaster recovery
4. **Monitoring setup** - Implement health checks
5. **Operational procedures** - Document processes

## 📚 Documentation

Each project includes:
- **Comprehensive README** - Setup and operations guide
- **Architecture diagrams** - Visual system overview
- **Operational guides** - Day-to-day management
- **Troubleshooting** - Common issues and solutions
- **Upgrade procedures** - Version management

## 🎓 When to Use Role-Based

Choose role-based when you need:
- **Production deployments**
- **Multi-environment support**
- **Advanced operations** (backup, restore, upgrade)
- **Team collaboration** and code reusability
- **Enterprise-grade** reliability and scalability

Role-based architecture provides the foundation for enterprise Kubernetes operations!