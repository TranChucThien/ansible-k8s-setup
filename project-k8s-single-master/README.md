# Kubernetes Single Master Cluster

Deploy a simple Kubernetes cluster with single master node using Ansible.

## 🏗️ Architecture

```
┌─────────────────┐
│   Master Node   │
│ (Control Plane) │
└────────┬────────┘
         │
┌────────▼────────┐
│   Worker Node   │
│   (Compute)     │
└─────────────────┘
```

## 📁 Files Structure

```
project-k8s-single-master/
├── playbooks/
│   ├── 01-common.yaml         # Common setup for all nodes
│   ├── 02-master.yaml         # Master node initialization
│   ├── 03-worker.yaml         # Worker nodes join cluster
│   ├── clean-worker.yml       # Reset K8s configuration (all nodes)
│   ├── site.yml               # Main deployment playbook
│   └── logs/                  # Execution logs with timestamps
├── inventory                  # Cloud environment inventory
├── inventory-lab              # Lab environment inventory
├── ansible.cfg                # Ansible configuration with logging
├── run-clean.sh               # Script for cleanup with logging
└── README.md                  # This file
```

## 🚀 Quick Deploy

```bash
# Deploy complete cluster
ansible-playbook -i inventory playbooks/site.yml

# Or step by step
ansible-playbook -i inventory playbooks/01-common.yaml   # All nodes setup
ansible-playbook -i inventory playbooks/02-master.yaml   # Master init
ansible-playbook -i inventory playbooks/03-worker.yaml   # Workers join
```

## 🧹 Cleanup & Reset

```bash
# Reset all nodes (masters + workers)
ansible-playbook -i inventory playbooks/clean-worker.yml

# Or use script with logging
./run-clean.sh
```

## 📋 Inventory Examples

### Cloud (AWS/EC2)
```ini
[masters]
47.129.50.197

[workers]
18.142.245.203

[masters:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=ansible-key.pem
```

### Lab Environment
```ini
[masters]
192.168.10.138

[workers]
192.168.10.142

[masters:vars]
ansible_user=master
ansible_ssh_pass=1
ansible_become_pass=1
```

## ✅ Verification

```bash
# Check cluster status
kubectl get nodes

# Expected output:
NAME           STATUS   ROLES           AGE   VERSION
k8s-master-1   Ready    control-plane   5m    v1.33.x
k8s-worker-1   Ready    <none>          3m    v1.33.x
```

## 🔧 Configuration

- **Pod Network**: 10.10.0.0/16
- **CNI**: Calico v3.28.0
- **Kubernetes**: v1.33.x
- **Container Runtime**: containerd
- **Logging**: Enabled with timestamps

## 📊 Logging

All playbook executions are automatically logged:
- Main logs: `logs/ansible.log`
- Cleanup logs: `logs/k8s-reset-[timestamp].log`
- Deprecation warnings: Disabled

## ⚠️ Limitations

- **Single Point of Failure**: Master node failure = cluster down
- **Development/Testing Only**: Not suitable for production
- **No HA**: No load balancer or VIP failover

For production, use [Multi-Master HA setup](../project-k8s-multi-master-haproxy/README.md).

## 🔗 Related

- [Multi-Master HA](../project-k8s-multi-master-haproxy/README.md)
- [Multi-Master + Keepalived](../project-k8s-multi-master-haproxy-keepalived/README.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)