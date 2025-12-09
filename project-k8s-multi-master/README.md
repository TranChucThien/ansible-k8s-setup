# Kubernetes Multi-Master Cluster (HA Setup)

Deploy a highly available Kubernetes cluster with multiple master nodes using Ansible.

## Architecture

```
                    ┌─────────────────┐
                    │   HAProxy LB    │
                    │ 192.168.10.141  │
                    │    Port: 6443   │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────▼─────┐      ┌─────▼─────┐      ┌─────▼─────┐
    │  Master 1 │      │  Master 2 │      │  Master 3 │
    │ (Primary) │      │           │      │           │
    └───────────┘      └───────────┘      └───────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Worker Nodes  │
                    └─────────────────┘
```

## Features

- ✅ High Availability with multiple master nodes
- ✅ HAProxy load balancer for API server
- ✅ Automatic failover
- ✅ Calico CNI networking
- ✅ Idempotent playbooks

## Prerequisites

- Ubuntu 24.04 LTS on all nodes
- Ansible 2.9+ on control machine
- Minimum 3 master nodes (recommended)
- 1 dedicated HAProxy node
- SSH access to all nodes
- Root/sudo privileges

## Directory Structure

```
project-k8s-multimaster/
├── playbooks/
│   ├── 00-ha.yml                    # Setup HAProxy load balancer
│   ├── 01-common.yaml               # Common setup for all nodes
│   ├── 02-cluster-init-master.yaml  # Initialize first master
│   ├── 03-join-master.yaml          # Join additional masters
│   ├── 03-join-worker.yaml          # Join worker nodes
│   ├── haproxy.cfg.j2               # HAProxy configuration template
│   └── site.yml                     # Main playbook (runs all)
├── inventory                        # Server inventory
└── README.md                        # This file
```

## Quick Start

### 1. Configure Inventory

Edit `inventory` file:

```ini
[masters]
master1 ansible_host=192.168.10.138
master2 ansible_host=192.168.10.139
master3 ansible_host=192.168.10.140

[workers]
worker1 ansible_host=192.168.10.142

[ha]
haproxy ansible_host=192.168.10.141

[masters:vars]
ansible_user=master

[workers:vars]
ansible_user=worker

[ha:vars]
ansible_user=ha
```

### 2. Deploy Cluster

```bash
# Run all playbooks
ansible-playbook -i inventory playbooks/site.yml

# Or run step by step:
ansible-playbook -i inventory playbooks/00-ha.yml              # Setup HAProxy
ansible-playbook -i inventory playbooks/01-common.yaml         # Setup all nodes
ansible-playbook -i inventory playbooks/02-cluster-init-master.yaml  # Init first master
ansible-playbook -i inventory playbooks/03-join-master.yaml    # Join other masters
ansible-playbook -i inventory playbooks/03-join-worker.yaml    # Join workers
```

### 3. Verify Cluster

```bash
# SSH to any master node
ssh master@192.168.10.138

# Check nodes
kubectl get nodes

# Expected output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   10m   v1.33.6
k8s-master-2   Ready    control-plane   8m    v1.33.6
k8s-master-3   Ready    control-plane   7m    v1.33.6
k8s-worker-1   Ready    <none>          5m    v1.33.6
```

## HAProxy Monitoring

Access HAProxy stats page:

```bash
# Open in browser
http://192.168.10.141:8404/stats

# Or via curl
curl http://192.168.10.141:8404/stats
```

## Configuration

### Key Variables (in playbooks)

- `pod_network_cidr`: 10.10.0.0/16
- `control_plane_endpoint`: 192.168.10.141:6443
- `calico_version`: v3.28.0
- `k8s_version`: v1.33

### HAProxy Configuration

- Frontend: Port 6443 (Kubernetes API)
- Backend: All master nodes on port 6443
- Health check: TCP check every 2s
- Stats page: Port 8404

## Troubleshooting

### HAProxy not starting

```bash
# Check HAProxy status
ansible -i inventory ha -m shell -a "systemctl status haproxy"

# Check HAProxy config
ansible -i inventory ha -m shell -a "haproxy -c -f /etc/haproxy/haproxy.cfg"

# View logs
ansible -i inventory ha -m shell -a "journalctl -u haproxy -n 50"
```

### Master node not joining

```bash
# Check join command
cat playbooks/join-command-master.txt

# Reset and retry
ansible -i inventory masters[1] -b -m shell -a "kubeadm reset -f"
ansible-playbook -i inventory playbooks/03-join-master.yaml
```

### Cluster not accessible via HAProxy

```bash
# Test HAProxy endpoint
curl -k https://192.168.10.141:6443/healthz

# Check backend status
echo "show stat" | socat /run/haproxy/admin.sock -
```

## Testing HA

### Test master failover

```bash
# Stop first master
ansible -i inventory masters[0] -b -m shell -a "systemctl stop kubelet"

# Cluster should still work via other masters
kubectl get nodes
```

### Test HAProxy failover

```bash
# Check which master is handling requests
for i in {1..10}; do
  curl -k https://192.168.10.141:6443/healthz
done
```

## Cleanup

```bash
# Reset all nodes
ansible -i inventory all -b -m shell -a "kubeadm reset -f"

# Remove HAProxy
ansible -i inventory ha -b -m apt -a "name=haproxy state=absent purge=yes"
```

## Security Notes

⚠️ **Important**: This is a sample configuration. For production:

- Use SSH key authentication instead of passwords
- Implement Ansible Vault for secrets
- Configure firewall rules
- Enable RBAC and network policies
- Use TLS certificates for HAProxy
- Implement monitoring and alerting

## Related Documentation

- [HA Setup Guide](../docs/ha-setup.md)
- [Multi-Master Setup Guide](../docs/multi-master-setup.md)
- [Test HA Cluster Guide](../docs/test-ha-cluster.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)

## License

This project is provided as-is for educational purposes.
