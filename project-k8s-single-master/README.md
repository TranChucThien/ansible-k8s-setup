# Kubernetes Single Master Cluster (Simple Setup)

Deploy a simple Kubernetes cluster with a single master node using Ansible.

## Architecture

```
    ┌─────────────────┐
    │   Master Node   │
    │  (Control Plane)│
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │  Worker Nodes   │
    └─────────────────┘
```

## Features

- ✅ Simple single master setup
- ✅ Easy to deploy and manage
- ✅ Calico CNI networking
- ✅ Idempotent playbooks
- ✅ Perfect for development/testing

## Prerequisites

- Ubuntu 24.04 LTS on all nodes
- Ansible 2.9+ on control machine
- 1 master node
- 1+ worker nodes
- SSH access to all nodes
- Root/sudo privileges

## Directory Structure

```
project-k8s-single-master/
├── playbooks/
│   ├── 01-common.yaml    # Common setup for all nodes
│   ├── 02-master.yaml    # Setup master node
│   ├── 03-worker.yaml    # Join worker nodes
│   └── site.yml          # Main playbook (runs all)
├── inventory             # Server inventory
└── README.md             # This file
```

## Quick Start

### 1. Configure Inventory

Edit `inventory` file:

```ini
[masters]
master1 ansible_host=192.168.10.138

[workers]
worker1 ansible_host=192.168.10.139
worker2 ansible_host=192.168.10.140

[masters:vars]
ansible_user=master

[workers:vars]
ansible_user=worker
```

### 2. Deploy Cluster

```bash
# Run all playbooks
ansible-playbook -i inventory playbooks/site.yml

# Or run step by step:
ansible-playbook -i inventory playbooks/01-common.yaml   # Setup all nodes
ansible-playbook -i inventory playbooks/02-master.yaml   # Setup master
ansible-playbook -i inventory playbooks/03-worker.yaml   # Join workers
```

### 3. Verify Cluster

```bash
# SSH to master node
ssh master@192.168.10.138

# Check nodes
kubectl get nodes

# Expected output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   5m    v1.33.6
k8s-worker-1   Ready    <none>          3m    v1.33.6
k8s-worker-2   Ready    <none>          3m    v1.33.6
```

## Configuration

### Key Variables (in playbooks)

- `pod_network_cidr`: 10.10.0.0/16
- `calico_version`: v3.28.0
- `k8s_version`: v1.33
- `master_prefix`: k8s-master
- `worker_prefix`: k8s-worker

## Validation

### Before deployment

```bash
# Check playbook syntax
ansible-playbook --syntax-check -i inventory playbooks/site.yml

# Test connection
ansible all -i inventory -m ping

# Dry run
ansible-playbook -i inventory playbooks/site.yml --check
```

## Troubleshooting

### Master initialization failed

```bash
# Check logs
ansible -i inventory masters -m shell -a "journalctl -u kubelet -n 50"

# Reset and retry
ansible -i inventory masters -b -m shell -a "kubeadm reset -f"
ansible-playbook -i inventory playbooks/02-master.yaml
```

### Worker not joining

```bash
# Check join command
cat playbooks/join-command.txt

# Reset worker
ansible -i inventory workers -b -m shell -a "kubeadm reset -f"
ansible-playbook -i inventory playbooks/03-worker.yaml
```

### Pods not starting

```bash
# Check pod status
kubectl get pods -A

# Check Calico
kubectl get pods -n calico-system

# Check node conditions
kubectl describe nodes
```

## Adding More Workers

1. Add new worker to inventory:
```ini
[workers]
worker1 ansible_host=192.168.10.139
worker2 ansible_host=192.168.10.140
worker3 ansible_host=192.168.10.141  # New worker
```

2. Run playbooks:
```bash
# Setup new worker
ansible-playbook -i inventory playbooks/01-common.yaml --limit worker3

# Join to cluster
ansible-playbook -i inventory playbooks/03-worker.yaml --limit worker3
```

## Cleanup

```bash
# Reset all nodes
ansible -i inventory all -b -m shell -a "kubeadm reset -f"

# Clean up iptables
ansible -i inventory all -b -m shell -a "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X"
```

## Upgrading to Multi-Master (HA)

To upgrade this cluster to high availability:

1. See [project-k8s-multimaster](../project-k8s-multimaster/README.md)
2. Follow [Multi-Master Setup Guide](../docs/multi-master-setup.md)

## Limitations

⚠️ **Single Point of Failure**: If the master node goes down, the entire cluster becomes unavailable.

For production environments, consider using the multi-master setup instead.

## Security Notes

⚠️ **Important**: This is a sample configuration. For production:

- Use SSH key authentication instead of passwords
- Implement Ansible Vault for secrets
- Configure firewall rules
- Enable RBAC and network policies
- Implement monitoring and alerting
- Regular backups of etcd

## Related Documentation

- [Manual Installation Guide](../docs/installation.md)
- [Cluster Connection Guide](../docs/connect-cluster.md)
- [Node Management Guide](../docs/node-management.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)

## License

This project is provided as-is for educational purposes.
