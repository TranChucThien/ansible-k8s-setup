# Kubernetes Single Master Deployments

Two approaches for deploying single master Kubernetes clusters, designed for different skill levels and use cases.

## 📚 Choose Your Learning Path

### 🔰 **Beginner Approach**
**[project-k8s-single-master/](project-k8s-single-master/)**

Perfect for those new to Ansible and Kubernetes:
- **Simple playbook structure** - Easy to read and understand
- **Step-by-step execution** - Clear sequence of operations
- **Learning focused** - Great for understanding the deployment process
- **Quick modifications** - Easy to customize and experiment

```bash
cd project-k8s-single-master/
ansible-playbook -i inventory-lab playbooks/site.yml
```

### 🏗️ **Advanced Approach**
**[project-k8s-single-master-v2/](project-k8s-single-master-v2/)**

Production-ready architecture with Ansible best practices:
- **Roles-based structure** - Modular and reusable components
- **Multi-environment support** - Dev, staging, production inventories
- **Advanced operations** - Worker scaling, backup automation
- **Professional patterns** - Industry standard organization

```bash
cd project-k8s-single-master-v2/
ansible-playbook -i inventories/lab playbooks/site.yml
```

## 🎯 Comparison

| Feature | Beginner | Advanced |
|---------|----------|----------|
| **Learning Curve** | Easy | Moderate |
| **File Structure** | Simple playbooks | Ansible roles |
| **Customization** | Direct editing | Variable-driven |
| **Scalability** | Limited | High |
| **Production Ready** | No | Yes |
| **Multi-Environment** | No | Yes |
| **Best Practices** | Basic | Advanced |

## 🚀 Getting Started

1. **New to Ansible?** → Start with **project-k8s-single-master/**
2. **Want production setup?** → Use **project-k8s-single-master-v2/**
3. **Need high availability?** → Check parent directory for multi-master options

## 📖 Learning Progression

```
Beginner Playbooks → Advanced Roles → Multi-Master HA
      ↓                    ↓              ↓
   Learn basics      Production ready   Enterprise
```

## 🔧 Common Requirements

Both approaches require:
- Ubuntu 24.04 LTS target nodes
- Ansible 2.9+ on control machine
- SSH access to all nodes
- Sudo privileges on target nodes

Choose the approach that matches your current skill level and project requirements!