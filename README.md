# Kubernetes Ansible Setup

Deploy Kubernetes cluster on Ubuntu 24.04 using Ansible.

## 🚀 Quick Links

- **[Single Master Setup](project-k8s-single-master/README.md)** - Simple cluster for dev/test
- **[Multi-Master HA with HAProxy](project-k8s-multi-master-haproxy/README.md)** - HA cluster with HAProxy
- **[Multi-Master HA with HAProxy + Keepalived](project-k8s-multi-master-haproxy-keepalived/README.md)** - Full HA with VIP failover

## 📁 Directory Structure

```
ansible-k8s/
├── project-k8s-single-master/     # Single master cluster (Simple)
│   ├── playbooks/
│   │   ├── 01-common.yaml         # Common setup for all nodes
│   │   ├── 02-master.yaml         # Master node setup
│   │   ├── 03-worker.yaml         # Worker nodes setup
│   │   └── site.yml               # Main playbook
│   ├── inventory                  # Server inventory
│   └── README.md                  # Single master documentation
│
├── project-k8s-multi-master-haproxy/  # Multi-master HA with HAProxy
│   ├── playbooks/
│   │   ├── 00-ha.yml              # Setup HAProxy load balancer
│   │   ├── 01-common.yaml         # Common setup for all nodes
│   │   ├── 02-cluster-init-master.yaml  # Initialize first master
│   │   ├── 03-join-master.yaml    # Join additional masters
│   │   ├── 03-join-worker.yaml    # Join worker nodes
│   │   ├── haproxy.cfg.j2         # HAProxy configuration template
│   │   └── site.yml               # Main playbook
│   ├── inventory                  # Server inventory
│   └── README.md                  # HAProxy setup documentation
│
├── project-k8s-multi-master-haproxy-keepalived/  # Full HA with VIP
│   ├── playbooks/
│   │   ├── 00-ha.yml              # Setup HAProxy + Keepalived
│   │   ├── 01-common.yaml         # Common setup for all nodes
│   │   ├── 02-cluster-init-master.yaml  # Initialize first master
│   │   ├── 03-join-master.yaml    # Join additional masters
│   │   ├── 03-join-worker.yaml    # Join worker nodes
│   │   ├── haproxy.cfg.j2         # HAProxy configuration template
│   │   └── site.yml               # Main playbook
│   ├── inventory                  # Server inventory
│   └── README.md                  # HAProxy + Keepalived documentation
│
├── project/                       # Work in progress (excluded from git)
│   ├── groups_vars/
│   ├── host_vars/
│   └── roles/
│
├── docs/                          # Documentation
│   ├── installation.md            # Manual installation guide
│   ├── connect-cluster.md         # Cluster connection guide
│   ├── troubleshooting.md         # Troubleshooting guide
│   ├── node-management.md         # Node management guide
│   ├── ha-setup.md                # HA setup guide
│   ├── multi-master-setup.md      # Multi-master setup guide
│   └── test-ha-cluster.md         # HA cluster testing guide
│
├── .gitignore                     # Git ignore rules
├── CHANGELOG.md                   # Version history
└── README.md                      # This file
```

## 🎯 Which Setup Should I Use?

| Feature | Single Master | Multi-Master + HAProxy | Multi-Master + HAProxy + Keepalived |
|---------|--------------|------------------------|-------------------------------------|
| **Use Case** | Dev/Test | Production | Mission-Critical Production |
| **High Availability** | ❌ No | ✅ Yes | ✅✅ Full HA |
| **Master Nodes** | 1 | 3+ | 3+ |
| **Load Balancer** | Not needed | HAProxy (1 node) | HAProxy (2+ nodes) |
| **VIP Failover** | ❌ No | ❌ No | ✅ Yes (Keepalived) |
| **Complexity** | Simple | Moderate | Advanced |
| **Cost** | Lower | Medium | Higher |
| **Downtime Risk** | High | Low | Very Low |
| **SPOF** | Master node | HAProxy node | None |

## ⚡ Quick Start

### Option 1: Single Master (Simple)

**Best for**: Development, testing, learning

```bash
cd project-k8s-single-master
ansible-playbook -i inventory playbooks/site.yml
```

📖 **[Full Documentation](project-k8s-single-master/README.md)**

### Option 2: Multi-Master with HAProxy

**Best for**: Production with HA requirements

```bash
cd project-k8s-multi-master-haproxy
ansible-playbook -i inventory playbooks/site.yml
```

📖 **[Full Documentation](project-k8s-multi-master-haproxy/README.md)**

### Option 3: Multi-Master with HAProxy + Keepalived

**Best for**: Mission-critical production with full HA and VIP failover

```bash
cd project-k8s-multi-master-haproxy-keepalived
ansible-playbook -i inventory playbooks/site.yml
```

📖 **[Full Documentation](project-k8s-multi-master-haproxy-keepalived/README.md)**

⚠️ **Security Notice**: This is a sample project. The inventory file may contain plaintext passwords and SSH keys for demonstration purposes. In production environments, use proper secret management, SSH key authentication, and Ansible Vault for sensitive data.

## Security Considerations

⚠️ **Important**: This repository contains sample configurations that prioritize simplicity over security:
- Inventory file may contain plaintext credentials
- SSH configurations are basic
- No encryption for sensitive data

For production use:
- Use SSH key-based authentication
- Implement Ansible Vault for secrets
- Follow security best practices
- Review and harden all configurations

## ✅ Validation

```bash
# Check playbook syntax
ansible-playbook --syntax-check -i inventory playbooks/site.yml

# Test connection to servers
ansible all -i inventory -m ping

# Dry run (no actual changes)
ansible-playbook -i inventory playbooks/site.yml --check
```

## 📚 Documentation

### Setup Guides
- **[Single Master Setup](project-k8s-single-master/README.md)** - Simple cluster setup
- **[Multi-Master with HAProxy](project-k8s-multi-master-haproxy/README.md)** - HA cluster with HAProxy
- **[Multi-Master with HAProxy + Keepalived](project-k8s-multi-master-haproxy-keepalived/README.md)** - Full HA with VIP failover

### General Guides
- [Manual Installation Guide](docs/installation.md) - Step-by-step manual setup
- [Cluster Connection Guide](docs/connect-cluster.md) - Connect to your cluster
- [Node Management Guide](docs/node-management.md) - Add/remove nodes
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and fixes

### High Availability Guides
- [HA Setup Guide](docs/ha-setup.md) - HA architecture overview
- [Multi-Master Setup Guide](docs/multi-master-setup.md) - Detailed HA setup
- [Test HA Cluster Guide](docs/test-ha-cluster.md) - Verify HA functionality

## 🔧 Requirements

- **OS**: Ubuntu 24.04 LTS
- **Ansible**: 2.9+
- **Python**: 3.x
- **SSH**: Access to all nodes
- **Privileges**: Root/sudo access

## 📦 What Gets Installed

- **Container Runtime**: containerd
- **Kubernetes**: v1.33.x
- **CNI Plugin**: Calico v3.28.0
- **Load Balancer** (HA only): HAProxy

## 🔄 Release Process

```bash
# 1. Update CHANGELOG.md

# 2. Commit and push
git add .
git commit -m "Release v1.0.0"
git push origin main

# 3. Create tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 📖 References

### Official Documentation
- [Kubernetes Official Documentation](https://kubernetes.io/vi/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) - Installing kubeadm

### Tutorials & Guides
- [Install Kubernetes on Ubuntu - Cherry Servers](https://www.cherryservers.com/blog/install-kubernetes-ubuntu) - Comprehensive Ubuntu installation guide
- [Creating HA Kubernetes Cluster with kubeadm and HAProxy](https://blog.devops.dev/creating-a-highly-available-kubernetes-cluster-with-kubeadm-and-haproxy-best-practices-and-8de9001197de) - Best practices for HA setup
- [Achieving High Availability in Kubernetes Clusters](https://kubeops.net/blog/achieving-high-availability-in-kubernetes-clusters) - HA architecture and strategies

### Advanced Topics
- [Raft Algorithm & Backup etcd](https://ezyinfra.dev/blog/raft-algo-backup-etcd) - Understanding etcd consensus and backup strategies

## Contributing

Contributions are welcome! Please ensure:
- Test all playbooks before submitting
- Update documentation for new features
- Follow existing code style
- Add entries to CHANGELOG.md

## License

This project is provided as-is for educational and demonstration purposes.