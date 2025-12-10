# Kubernetes Multi-Master HA Cluster with HAProxy + Keepalived

Deploy a fully highly available Kubernetes cluster with multiple master nodes, HAProxy load balancing, and Keepalived VIP failover using Ansible.

## Architecture

```
                         Virtual IP (VIP)
                        192.168.10.100:6443
                               │
                    ┌──────────┴──────────┐
                    │                     │
            ┌───────▼────────┐    ┌───────▼────────┐
            │  HAProxy + KA  │    │  HAProxy + KA  │
            │ 192.168.10.141 │    │ 192.168.10.143 │
            │   (MASTER)     │    │   (BACKUP)     │
            └───────┬────────┘    └───────┬────────┘
                    │                     │
          ┌─────────┼─────────────────────┼─────────┐
          │         │                     │         │
    ┌─────▼─────┐ ┌─▼───────┐       ┌─────▼─────┐   │
    │  Master 1 │ │ Master 2│       │  Master 3 │   │
    │.138 (Init)│ │   .139  │       │    .140   │   │
    └───────────┘ └─────────┘       └───────────┘   │
          │         │                     │         │
          └─────────┼─────────────────────┼─────────┘
                    │                     │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Worker Nodes    │
                    │  192.168.10.142   │
                    └───────────────────┘
```

## Features

- ✅ **Full High Availability** - No single point of failure
- ✅ **HAProxy Load Balancing** - Distributes API server traffic
- ✅ **Keepalived VIP Failover** - Automatic IP failover between HAProxy nodes
- ✅ **Multi-Master Setup** - 3 master nodes for etcd quorum
- ✅ **Calico CNI Networking** - Pod networking with network policies
- ✅ **Idempotent Playbooks** - Safe to run multiple times
- ✅ **Health Monitoring** - Automatic failover on service failure

## Prerequisites

- **OS**: Ubuntu 24.04 LTS on all nodes
- **Ansible**: 2.9+ on control machine
- **Master Nodes**: Minimum 3 nodes (for etcd quorum)
- **HAProxy Nodes**: 2 nodes (for HA load balancing)
- **Worker Nodes**: 1+ nodes
- **Network**: All nodes in same subnet
- **Access**: SSH access to all nodes with root/sudo privileges
- **Resources**: Minimum 2GB RAM, 2 CPU cores per node

## Directory Structure

```
project-k8s-multi-master-haproxy-keepalived/
├── playbooks/
│   ├── templates/
│   │   ├── haproxy.cfg.j2           # HAProxy configuration template
│   │   └── keepalived.conf.j2       # Keepalived configuration template
│   ├── 00-ha.yml                    # Setup HAProxy + Keepalived
│   ├── 01-common.yaml               # Common setup for all nodes
│   ├── 02-cluster-init-master.yaml  # Initialize first master
│   ├── 03-join-master.yaml          # Join additional masters
│   ├── 03-join-worker.yaml          # Join worker nodes
│   └── site.yml                     # Main playbook (runs all)
├── inventory                        # Server inventory
└── README.md                        # This file
```

## Quick Start

### 1. Configure Inventory

Edit `inventory` file:

```ini
[masters]
192.168.10.138
192.168.10.139
192.168.10.140

[workers]   
192.168.10.142

[ha]
192.168.10.141
192.168.10.143

[masters:vars]
ansible_user=master
ansible_ssh_pass=1
ansible_become_pass=1
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[workers:vars]
ansible_user=worker
ansible_ssh_pass=1
ansible_become_pass=1
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[ha:vars]
ansible_user=ha
ansible_ssh_pass=1
ansible_become_pass=1
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 2. Deploy Cluster

```bash
# Run all playbooks (recommended)
ansible-playbook -i inventory playbooks/site.yml

# Or run step by step:
ansible-playbook -i inventory playbooks/00-ha.yml              # Setup HAProxy + Keepalived
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

# Test cluster via VIP
curl -k https://192.168.10.100:6443/healthz
# Should return: ok
```

## Monitoring & Management

### HAProxy Stats

Access HAProxy statistics page:

```bash
# Via VIP (active HAProxy)
http://192.168.10.100:8404/stats

# Direct access to HAProxy nodes
http://192.168.10.141:8404/stats  # HAProxy 1
http://192.168.10.143:8404/stats  # HAProxy 2
```

### VIP Status

Check which node holds the VIP:

```bash
# Check VIP assignment
ansible -i inventory ha -m shell -a "ip addr show | grep 192.168.10.100"

# Check Keepalived status
ansible -i inventory ha -m shell -a "systemctl status keepalived"
```

## Configuration

### Key Variables (in 00-ha.yml)

- `vip_address`: 192.168.10.100 (Virtual IP)
- `vip_netmask`: 24
- `virtual_router_id`: 51
- `keepalived_password`: 123456
- `network_interface`: ens33
- `pod_network_cidr`: 10.10.0.0/16
- `control_plane_endpoint`: 192.168.10.100:6443 (VIP)

### HAProxy Configuration

- **Frontend**: Port 6443 (Kubernetes API)
- **Backend**: All master nodes on port 6443
- **Health Check**: TCP check every 2s
- **Stats Page**: Port 8404
- **Load Balancing**: Round-robin

### Keepalived Configuration

- **VIP**: 192.168.10.100/24
- **VRRP ID**: 51
- **Master Priority**: 100 (192.168.10.141)
- **Backup Priority**: 90 (192.168.10.143)
- **Health Check**: HAProxy process monitoring

## Troubleshooting

### VIP Not Working

```bash
# Check which node has VIP
ansible -i inventory ha -m shell -a "ip addr show | grep 192.168.10.100"

# Check Keepalived logs
ansible -i inventory ha -m shell -a "journalctl -u keepalived -n 20"

# Test VIP connectivity
ping 192.168.10.100
curl -k https://192.168.10.100:6443/healthz
```

### HAProxy Issues

```bash
# Check HAProxy status on both nodes
ansible -i inventory ha -m shell -a "systemctl status haproxy"

# Validate HAProxy config
ansible -i inventory ha -m shell -a "haproxy -c -f /etc/haproxy/haproxy.cfg"

# Check HAProxy logs
ansible -i inventory ha -m shell -a "journalctl -u haproxy -n 50"
```

### Keepalived Issues

```bash
# Check Keepalived status
ansible -i inventory ha -m shell -a "systemctl status keepalived"

# Check VRRP state
ansible -i inventory ha -m shell -a "journalctl -u keepalived | grep MASTER\|BACKUP"

# Restart Keepalived if needed
ansible -i inventory ha -b -m systemd -a "name=keepalived state=restarted"
```

### Master Node Issues

```bash
# Check join command
cat playbooks/join-command-master.txt

# Reset and retry master join
ansible -i inventory masters[1] -b -m shell -a "kubeadm reset -f"
ansible-playbook -i inventory playbooks/03-join-master.yaml

# Check cluster status
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

## Testing High Availability

### Test VIP Failover

```bash
# Check current VIP holder
ansible -i inventory ha -m shell -a "ip addr show | grep 192.168.10.100"

# Stop Keepalived on master HAProxy node
ansible -i inventory ha[0] -b -m systemd -a "name=keepalived state=stopped"

# VIP should move to backup node
ansible -i inventory ha -m shell -a "ip addr show | grep 192.168.10.100"

# Test cluster access via VIP
curl -k https://192.168.10.100:6443/healthz
```

### Test HAProxy Failover

```bash
# Stop HAProxy on active node
ansible -i inventory ha[0] -b -m systemd -a "name=haproxy state=stopped"

# Keepalived should detect failure and failover
# Test continuous access
for i in {1..10}; do
  curl -k https://192.168.10.100:6443/healthz
  sleep 1
done
```

### Test Master Node Failover

```bash
# Stop one master node
ansible -i inventory masters[0] -b -m systemd -a "name=kubelet state=stopped"

# Cluster should remain accessible
kubectl get nodes
kubectl get pods -n kube-system

# Test API access via VIP
curl -k https://192.168.10.100:6443/healthz
```

### Full HA Test

```bash
# Simulate complete node failure
ansible -i inventory ha[0] -b -m shell -a "systemctl stop haproxy keepalived"
ansible -i inventory masters[0] -b -m shell -a "systemctl stop kubelet"

# Cluster should still be fully functional
kubectl get nodes
curl -k https://192.168.10.100:6443/healthz
```

## Cleanup

```bash
# Reset Kubernetes cluster
ansible -i inventory masters,workers -b -m shell -a "kubeadm reset -f"

# Remove HAProxy and Keepalived
ansible -i inventory ha -b -m apt -a "name=haproxy,keepalived state=absent purge=yes"

# Clean up VIP (if stuck)
ansible -i inventory ha -b -m shell -a "ip addr del 192.168.10.100/24 dev ens33" || true

# Remove configuration files
ansible -i inventory ha -b -m file -a "path=/etc/haproxy/haproxy.cfg state=absent"
ansible -i inventory ha -b -m file -a "path=/etc/keepalived/keepalived.conf state=absent"
```

## Security Considerations

⚠️ **Important**: This is a sample configuration. For production environments:

### Authentication & Access
- Replace password authentication with SSH key-based authentication
- Use Ansible Vault for sensitive data (passwords, keys)
- Implement proper RBAC policies in Kubernetes
- Configure firewall rules (UFW/iptables)

### Network Security
- Use TLS certificates for HAProxy frontend
- Enable Kubernetes network policies
- Secure etcd communication with TLS
- Implement pod security standards

### Monitoring & Logging
- Set up centralized logging (ELK stack)
- Implement monitoring (Prometheus + Grafana)
- Configure alerting for HA failures
- Monitor VIP failover events

### Keepalived Security
- Change default VRRP authentication password
- Use stronger authentication methods
- Restrict VRRP multicast traffic
- Monitor for VRRP conflicts

## Related Documentation

- [HA Setup Guide](../docs/ha-setup.md)
- [Multi-Master Setup Guide](../docs/multi-master-setup.md)
- [Test HA Cluster Guide](../docs/test-ha-cluster.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)

## License

This project is provided as-is for educational purposes.
