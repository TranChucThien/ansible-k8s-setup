# Kubernetes High Availability (HA) Setup Guide

This guide explains how to set up a highly available Kubernetes cluster with multiple master nodes.

## HA Architecture Overview

```
                    Load Balancer (HAProxy/Nginx)
                           :6443
                              |
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   Master-1              Master-2              Master-3
   :6443                 :6443                 :6443
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                         etcd Cluster
                    (can be external or stacked)
```

## Prerequisites

- **Minimum 3 master nodes** (odd number for etcd quorum)
- **Load balancer** for API server endpoint
- **Shared storage** for etcd (if external)
- **Network connectivity** between all nodes

## Components for HA

### 1. Load Balancer Options

#### Option A: HAProxy
```bash
# Install HAProxy
sudo apt install haproxy -y

# Configure /etc/haproxy/haproxy.cfg
frontend kubernetes-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    server master1 192.168.10.134:6443 check
    server master2 192.168.10.135:6443 check
    server master3 192.168.10.136:6443 check
```

#### Option B: Nginx
```bash
# Install Nginx
sudo apt install nginx -y

# Configure /etc/nginx/nginx.conf
stream {
    upstream kubernetes {
        server 192.168.10.134:6443;
        server 192.168.10.135:6443;
        server 192.168.10.136:6443;
    }
    
    server {
        listen 6443;
        proxy_pass kubernetes;
    }
}
```

### 2. etcd Configuration

#### Stacked etcd (Recommended for simplicity)
- etcd runs on same nodes as control plane
- Easier to manage
- Less hardware required

#### External etcd (Better for production)
- Separate etcd cluster
- Better isolation
- More resilient

## HA Inventory Configuration

```ini
# HA Inventory Example
[masters]
master1 ansible_host=192.168.10.134 ansible_user=master
master2 ansible_host=192.168.10.135 ansible_user=master  
master3 ansible_host=192.168.10.136 ansible_user=master

[workers]
worker1 ansible_host=192.168.10.137 ansible_user=worker
worker2 ansible_host=192.168.10.138 ansible_user=worker

[loadbalancer]
lb1 ansible_host=192.168.10.139 ansible_user=lb

[etcd]
# If using external etcd
etcd1 ansible_host=192.168.10.140 ansible_user=etcd
etcd2 ansible_host=192.168.10.141 ansible_user=etcd
etcd3 ansible_host=192.168.10.142 ansible_user=etcd

[all:vars]
# HA specific variables
kubernetes_api_server_address=192.168.10.139  # Load balancer IP
kubernetes_api_server_port=6443
```

## HA Playbook Structure

### 1. Load Balancer Setup
```yaml
# playbooks/00-loadbalancer.yaml
- name: Setup Load Balancer for HA
  hosts: loadbalancer
  become: yes
  tasks:
    - name: Install HAProxy
      apt:
        name: haproxy
        state: present
    
    - name: Configure HAProxy for Kubernetes API
      template:
        src: haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
      notify: restart haproxy
    
    - name: Start and enable HAProxy
      systemd:
        name: haproxy
        state: started
        enabled: yes
```

### 2. First Master Initialization
```yaml
# playbooks/02-first-master.yaml
- name: Initialize first master node
  hosts: masters[0]
  become: yes
  tasks:
    - name: Initialize Kubernetes cluster with HA
      command: >
        kubeadm init
        --control-plane-endpoint="{{ kubernetes_api_server_address }}:{{ kubernetes_api_server_port }}"
        --upload-certs
        --pod-network-cidr=10.10.0.0/16
      register: kubeadm_init_output
    
    - name: Extract certificate key
      set_fact:
        certificate_key: "{{ kubeadm_init_output.stdout | regex_search('--certificate-key ([a-f0-9]+)', '\\1') | first }}"
    
    - name: Generate join command for additional masters
      shell: kubeadm token create --print-join-command --certificate-key {{ certificate_key }}
      register: master_join_cmd
```

### 3. Additional Masters Setup
```yaml
# playbooks/03-additional-masters.yaml
- name: Join additional master nodes
  hosts: masters[1:]
  become: yes
  tasks:
    - name: Join additional masters to cluster
      command: "{{ hostvars[groups['masters'][0]]['master_join_cmd']['stdout'] }} --control-plane"
```

## HA Verification Commands

```bash
# Check cluster status
kubectl get nodes -o wide

# Check etcd cluster health
kubectl exec -n kube-system etcd-master1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Check API server endpoints
kubectl cluster-info

# Test failover by stopping one master
sudo systemctl stop kubelet
```

## HA Best Practices

### 1. Resource Requirements
- **Masters**: 2 CPU, 4GB RAM minimum
- **etcd**: SSD storage, low latency network
- **Load Balancer**: Redundant setup

### 2. Network Considerations
- **Latency**: <10ms between etcd nodes
- **Bandwidth**: Sufficient for cluster communication
- **Firewall**: Open required ports (6443, 2379-2380, etc.)

### 3. Backup Strategy
```bash
# etcd backup
ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore etcd backup
ETCDCTL_API=3 etcdctl snapshot restore backup.db
```

### 4. Monitoring
- **etcd metrics**: Monitor cluster health
- **API server**: Response times and availability
- **Load balancer**: Health checks and failover

## Troubleshooting HA Issues

### Common Problems
1. **Split-brain**: Ensure odd number of masters
2. **Certificate issues**: Check certificate-key validity
3. **Load balancer**: Verify health checks
4. **Network**: Check connectivity between nodes

### Recovery Procedures
```bash
# Reset failed master node
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/

# Re-join master to cluster
kubeadm join <lb-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane --certificate-key <cert-key>
```

## Migration from Single Master

1. **Setup load balancer** pointing to current master
2. **Update kubeconfig** to use load balancer endpoint
3. **Add additional masters** using join command
4. **Verify cluster health** after each addition
5. **Update applications** to use new endpoint

This HA setup provides resilience against single points of failure and ensures cluster availability even if one master node fails.