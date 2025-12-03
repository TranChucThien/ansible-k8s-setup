# Kubernetes Ansible Setup

Deploy Kubernetes cluster on Ubuntu 24.04 using Ansible.

## Directory Structure

```
ansible-k8s/
├── playbooks/           # Ansible playbooks
│   ├── 01-common.yaml   # Common setup for all nodes
│   ├── 02-master.yaml   # Master node setup
│   ├── 03-worker.yaml   # Worker nodes setup
│   └── site.yml         # Main playbook
├── docs/                # Documentation
│   ├── installation.md  # Manual installation guide
│   ├── troubleshooting.md # Troubleshooting guide
│   └── connect-cluster.md # Cluster connection guide
├── inventory            # Server inventory
├── config               # Kubeconfig file
└── SETUP-GUIDE.md       # Code organization guide
```

## Quick Start

1. Configure inventory:
```bash
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

## Validate Source

```bash
# Check playbook syntax
ansible-playbook --syntax-check playbooks/site.yml
# (Warning about empty hosts list is normal)

# Test connection to servers
ansible all -i inventory -m ping

# Dry run (no execution)
ansible-playbook -i inventory playbooks/site.yml --check
```

## Documentation

- [Manual Installation Guide](docs/installation.md)
- [Cluster Connection Guide](docs/connect-cluster.md)
- [Troubleshooting Guide](docs/troubleshooting.md)