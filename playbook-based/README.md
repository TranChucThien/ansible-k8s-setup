# Playbook-Based Kubernetes Deployments

Traditional Ansible playbooks for learning and understanding Kubernetes deployment concepts.

## 🎯 Projects Overview

### 🔰 **Single Master**
**[project-k8s-single-master/](project-k8s-single-master/)**

Simple single master cluster for learning:
- **Linear playbook structure** - Easy to follow step by step
- **Educational focus** - Great for understanding K8s components
- **Quick setup** - Perfect for dev/test environments
- **Learning foundation** - Build understanding before HA

```bash
cd project-k8s-single-master/
ansible-playbook -i inventory-lab playbooks/site.yml
```

### 🏗️ **Multi-Master with HAProxy**
**[project-k8s-multi-master-haproxy/](project-k8s-multi-master-haproxy/)**

High availability with load balancer:
- **Multiple masters** - Learn HA concepts
- **HAProxy integration** - Understand load balancing
- **Manual HA setup** - Step-by-step HA configuration
- **Foundation for advanced HA** - Prepare for full HA setup

```bash
cd project-k8s-multi-master-haproxy/
ansible-playbook -i inventory playbooks/site.yml
```

### 🚀 **Multi-Master with HAProxy + Keepalived**
**[project-k8s-multi-master-haproxy-keepalived/](project-k8s-multi-master-haproxy-keepalived/)**

Complete HA setup with VIP failover:
- **Full HA cluster** - Multiple masters + VIP
- **Keepalived integration** - Automatic failover
- **Complete playbook flow** - Understand full HA process
- **Production concepts** - Learn enterprise patterns

```bash
cd project-k8s-multi-master-haproxy-keepalived/
ansible-playbook -i inventory-lab playbooks/site.yml
```

## 📚 Learning Progression

```
Step 1: Single Master
├── Learn basic K8s setup
├── Understand component installation
└── Master node initialization

Step 2: Multi-Master + HAProxy
├── Learn HA concepts
├── Understand load balancing
└── Multiple master coordination

Step 3: Full HA + Keepalived
├── Learn VIP failover
├── Understand complete HA
└── Production HA patterns
```

## 🎓 Educational Benefits

### **Why Start with Playbooks?**
- **Visibility**: See every step of the deployment
- **Understanding**: Learn what each task does
- **Debugging**: Easy to identify and fix issues
- **Customization**: Simple to modify for learning
- **Foundation**: Build solid understanding before roles

### **Learning Outcomes**
- Kubernetes component installation process
- HA cluster architecture and concepts
- HAProxy configuration and load balancing
- Keepalived VIP management
- ETCD cluster setup and management
- Network plugin (Calico) installation

## 🔧 Common Features

All projects include:
- **Ubuntu 24.04** target support
- **Containerd** container runtime
- **Kubernetes v1.33.x** installation
- **Calico CNI** network plugin
- **Basic backup** operations
- **Node reset** capabilities

## 🚀 Next Steps

After mastering playbook-based deployments:

1. **Understand the concepts** thoroughly
2. **Practice troubleshooting** common issues
3. **Experiment with modifications**
4. **Move to role-based** for production use

## 📖 Migration to Role-Based

When ready for production:
```bash
# Move from playbook-based to role-based
cd ../role-based/project-k8s-single-master-v2/
# or
cd ../role-based/project-k8s-multi-master-haproxy-keepalived-v2/
```

The role-based versions provide:
- Modular architecture
- Production best practices
- Advanced operations
- Multi-environment support

Choose playbook-based for learning, role-based for production!