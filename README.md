# Kubernetes Ansible Setup

Deploy Kubernetes cluster on Ubuntu 24.04 using Ansible.

## Directory Structure

```
ansible-k8s/
├── project-k8s-simple-no-ha/      # Single master cluster (no HA)
│   ├── playbooks/
│   │   ├── 01-common.yaml         # Common setup for all nodes
│   │   ├── 02-master.yaml         # Master node setup
│   │   ├── 03-worker.yaml         # Worker nodes setup
│   │   ├── site.yml               # Main playbook
│   │   └── join-command.txt       # Generated join command
│   └── inventory                  # Server inventory
├── project-k8s-multimaster/       # Multi-master cluster (HA)
│   ├── playbooks/
│   │   ├── 01-common.yaml         # Common setup for all nodes
│   │   ├── 02-cluster-init-master.yaml  # Initialize first master
│   │   ├── 03-join-master.yaml    # Join additional masters
│   │   ├── 03-join-worker.yaml    # Join worker nodes
│   │   ├── site.yml               # Main playbook
│   │   ├── join-command.txt       # Generated worker join command
│   │   └── join-command-master.txt # Generated master join command
│   └── inventory                  # Server inventory
├── docs/                          # Documentation
│   ├── installation.md            # Manual installation guide
│   ├── connect-cluster.md         # Cluster connection guide
│   ├── troubleshooting.md         # Troubleshooting guide
│   ├── node-management.md         # Node management guide
│   ├── ha-setup.md                # HA setup guide
│   ├── multi-master-setup.md      # Multi-master setup guide
│   └── test-ha-cluster.md         # HA cluster testing guide
├── inventory                      # Root inventory (optional)
└── README.md                      # This file
```

## Quick Start

### Option 1: Simple Cluster (Single Master - No HA)

1. Configure inventory:
```bash
cd project-k8s-simple-no-ha
nano inventory
```

2. Run playbook:
```bash
ansible-playbook -i inventory playbooks/site.yml
```

3. Check cluster:
```bash
kubectl get nodes
```

### Option 2: Multi-Master Cluster (HA)

1. Configure inventory:
```bash
cd project-k8s-multimaster
nano inventory
```

2. Run playbook:
```bash
ansible-playbook -i inventory playbooks/site.yml
```

3. Check cluster:
```bash
kubectl get nodes
```

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

## Validate Source

### For Simple Cluster:
```bash
cd project-k8s-simple-no-ha

# Check playbook syntax
ansible-playbook --syntax-check playbooks/site.yml

# Test connection to servers
ansible all -i inventory -m ping

# Dry run (no execution)
ansible-playbook -i inventory playbooks/site.yml --check
```

### For Multi-Master Cluster:
```bash
cd project-k8s-multimaster

# Check playbook syntax
ansible-playbook --syntax-check playbooks/site.yml

# Test connection to servers
ansible all -i inventory -m ping

# Dry run (no execution)
ansible-playbook -i inventory playbooks/site.yml --check
```

## Documentation

### General Guides
- [Manual Installation Guide](docs/installation.md)
- [Cluster Connection Guide](docs/connect-cluster.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Node Management Guide](docs/node-management.md)

### High Availability (HA) Guides
- [HA Setup Guide](docs/ha-setup.md)
- [Multi-Master Setup Guide](docs/multi-master-setup.md)
- [Test HA Cluster Guide](docs/test-ha-cluster.md)

## Release

```bash
# 1. Cập nhật CHANGELOG.md với các thay đổi mới

# 2. Commit và push
git add .
git commit -m "Release v1.0.0"
git push origin main

# 3. Tạo tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 4. Tạo release trên GitHub/GitLab từ tag v1.0.0
```

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Contributing

Contributions are welcome! Please ensure:
- Test all playbooks before submitting
- Update documentation for new features
- Follow existing code style
- Add entries to CHANGELOG.md

## License

This project is provided as-is for educational and demonstration purposes.