# Kubernetes Multi-Master HA with HAProxy + Keepalived - Playbook Approach

Learn complete HA Kubernetes with VIP failover using traditional playbooks for educational purposes.

## 🎯 Overview

This project uses **playbook-based approach** for learning complete HA:
- **Full HA cluster** - Multiple masters + HAProxy + Keepalived + VIP
- **Educational structure** - Step-by-step HA deployment process
- **Complete HA concepts** - Learn all aspects of K8s HA
- **Production preparation** - Foundation for enterprise HA patterns

## 🏛️ Architecture

```
                    Virtual IP (VIP)
                   192.168.10.100:6443
                          │
               ┌──────────┴──────────┐
               │                     │
       ┌───────▼────────┐    ┌───────▼────────┐
       │  HAProxy + KA  │    │  HAProxy + KA  │
       │   (MASTER)     │    │   (BACKUP)     │
       └───────┬────────┘    └───────┬────────┘
               │                     │
     ┌─────────┼─────────────────────┼─────────┐
     │         │                     │         │
┌────▼────┐ ┌──▼───────┐       ┌─────▼─────┐   │
│Master 1 │ │Master 2 │       │  Master 3 │   │
│ (Init)  │ │         │       │           │   │
└─────────┘ └─────────┘       └───────────┘   │
     │         │                     │         │
     └─────────┼─────────────────────┼─────────┘
               │                     │
               └─────────┬───────────┘
                         │
               ┌─────────▼─────────┐
               │   Worker Nodes    │
               └───────────────────┘
```

## 🚀 Quick Start

```bash
# Deploy complete HA cluster with VIP
ansible-playbook -i inventory-lab playbooks/site.yml

# Or run step by step for learning
ansible-playbook -i inventory-lab playbooks/00-ha.yml              # Setup HAProxy + Keepalived
ansible-playbook -i inventory-lab playbooks/01-common.yaml         # Setup all nodes
ansible-playbook -i inventory-lab playbooks/02-cluster-init-master.yaml  # Init first master
ansible-playbook -i inventory-lab playbooks/03-join-master.yaml    # Join other masters
ansible-playbook -i inventory-lab playbooks/03-join-worker.yaml    # Join workers
```

## 📁 Structure

```
project-k8s-multi-master-haproxy-keepalived/
├── playbooks/
│   ├── 00-ha.yml                    # HAProxy + Keepalived setup
│   ├── 01-common.yaml               # Common node setup + etcdctl
│   ├── 02-cluster-init-master.yaml  # Initialize first master
│   ├── 03-join-master.yaml          # Join additional masters
│   ├── 03-join-worker.yaml          # Join worker nodes
│   ├── 21-backup-etcd.yml           # ETCD backup operations
│   └── site.yml                     # Complete deployment
├── inventory-lab                    # Lab environment hosts
└── README.md                        # This file
```

## 🎓 Learning Benefits

- **Complete HA Architecture**: Understand full enterprise HA setup
- **VIP Failover**: Learn Keepalived and virtual IP management
- **Load Balancer HA**: Understand HAProxy high availability
- **ETCD Clustering**: Learn distributed etcd setup
- **Backup Operations**: Understand ETCD backup procedures
- **Production Concepts**: Foundation for enterprise deployments

## 🔧 Advanced Features

- ✅ Multiple master nodes with etcd clustering
- ✅ HAProxy + Keepalived for load balancer HA
- ✅ Virtual IP (VIP) automatic failover
- ✅ ETCD backup and restore operations
- ✅ Complete disaster recovery procedures
- ✅ Educational step-by-step process

## 🚀 Next Steps

After mastering this approach:
1. **Understand complete HA** architecture
2. **Practice VIP failover** scenarios
3. **Learn backup/restore** procedures
4. **Test disaster recovery**
5. **Move to production** with roles:
   ```bash
   cd ../../role-based/project-k8s-multi-master-haproxy-keepalived-v2/
   ```

## 📚 What You'll Learn

- Complete HA Kubernetes architecture
- HAProxy + Keepalived integration
- Virtual IP management and failover
- ETCD clustering and backup strategies
- Load balancer high availability
- Enterprise HA patterns and concepts

The most comprehensive HA learning experience before production deployment!

## 🎯 Feature Comparison

| Feature | Learning (v1) | Production (v2) |
|---------|---------------|-----------------|
| **Learning Curve** | Moderate | Advanced |
| **File Structure** | Simple playbooks | Ansible roles |
| **HA Setup** | Manual steps | Automated |
| **Load Balancer** | HAProxy only | HAProxy + Keepalived |
| **VIP Failover** | ❌ | ✅ |
| **Backup/Restore** | Manual | Automated |
| **Upgrade Support** | Manual | Automated |
| **Multi-Environment** | ❌ | ✅ |
| **Disaster Recovery** | Basic | Complete |
| **Production Ready** | Learning only | ✅ |

## 🏛️ Architecture Overview

### Learning Version (v1)
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Master 1  │    │   Master 2  │    │   Master 3  │
│   (Init)    │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                  ┌─────────────┐
                  │   HAProxy   │
                  │ (Single LB) │
                  └─────────────┘
```

### Production Version (v2)
```
                    Virtual IP (VIP)
                   192.168.10.100:6443
                          │
               ┌──────────┴──────────┐
               │                     │
       ┌───────▼────────┐    ┌───────▼────────┐
       │  HAProxy + KA  │    │  HAProxy + KA  │
       │   (MASTER)     │    │   (BACKUP)     │
       └───────┬────────┘    └───────┬────────┘
               │                     │
     ┌─────────┼─────────────────────┼─────────┐
     │         │                     │         │
┌────▼────┐ ┌──▼──────┐       ┌─────▼─────┐   │
│Master 1 │ │Master 2 │       │  Master 3 │   │
│ (Init)  │ │         │       │           │   │
└─────────┘ └─────────┘       └───────────┘   │
     │         │                     │         │
     └─────────┼─────────────────────┼─────────┘
               │                     │
               └─────────┬───────────┘
                         │
               ┌─────────▼─────────┐
               │   Worker Nodes    │
               └───────────────────┘
```

## 🚀 Getting Started

### **New to HA Kubernetes?**
1. Start with **project-k8s-multi-master-haproxy-keepalived/**
2. Learn HA concepts and setup process
3. Understand HAProxy configuration
4. Practice multi-master deployment

### **Ready for Production?**
1. Use **project-k8s-multi-master-haproxy-keepalived-v2/**
2. Configure multi-environment inventories
3. Set up automated backup/restore
4. Implement upgrade procedures

### **Migration Path**
```
Single Master → Multi-Master (Learning) → Multi-Master (Production)
     ↓                    ↓                        ↓
  Basic setup      Learn HA concepts        Enterprise ready
```

## 🔧 Common Requirements

Both approaches require:
- Ubuntu 24.04 LTS target nodes
- Ansible 2.9+ on control machine
- SSH access to all nodes
- Sudo privileges on target nodes
- **Minimum 3 master nodes** for HA
- **2 HAProxy nodes** for load balancer HA (v2 only)

## 📖 Key Differences

### Learning Version Features:
- Simple playbook structure
- Manual HA setup steps
- Basic HAProxy configuration
- Educational comments and documentation
- Good for understanding concepts

### Production Version Features:
- Modular roles architecture
- Automated VIP failover with Keepalived
- Complete disaster recovery workflows
- Multi-environment support
- Automated backup/restore operations
- Rolling upgrade capabilities
- Production monitoring and logging

Choose the approach that matches your current needs and skill level!