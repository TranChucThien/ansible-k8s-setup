# Kubernetes Single Master - Playbook Approach

Simple single master Kubernetes cluster using traditional Ansible playbooks for learning.

## 🎯 Overview

This project uses **playbook-based approach** for educational purposes:
- **Linear execution** - Easy to follow step by step
- **Educational focus** - Great for understanding K8s setup process
- **Simple structure** - Direct playbook approach without roles
- **Learning foundation** - Build understanding before moving to production

## 🚀 Quick Start

```bash
# Deploy complete cluster
ansible-playbook -i inventory-lab playbooks/site.yml

# Or run step by step
ansible-playbook -i inventory-lab playbooks/01-setup-common.yaml
ansible-playbook -i inventory-lab playbooks/02-setup-master.yaml
ansible-playbook -i inventory-lab playbooks/03-setup-worker.yaml
```

## 📁 Structure

```
project-k8s-single-master/
├── playbooks/
│   ├── 01-setup-common.yaml    # System setup for all nodes
│   ├── 02-setup-master.yaml    # Master node initialization
│   ├── 03-setup-worker.yaml    # Worker nodes join
│   └── site.yml                # Complete deployment
├── inventory-lab               # Lab environment hosts
└── README.md                   # This file
```

## 🎓 Learning Benefits

- **Visibility**: See every step of K8s installation
- **Understanding**: Learn what each component does
- **Debugging**: Easy to identify and fix issues
- **Customization**: Simple to modify for experiments

## 🔄 Next Steps

After mastering this approach:
1. **Understand concepts** thoroughly
2. **Practice troubleshooting**
3. **Move to role-based** for production:
   ```bash
   cd ../../role-based/project-k8s-single-master-v2/
   ```

## 📚 What You'll Learn

- Kubernetes component installation process
- Container runtime (containerd) setup
- Network plugin (Calico) configuration
- Basic cluster operations and verification

Perfect starting point for Kubernetes and Ansible learning!