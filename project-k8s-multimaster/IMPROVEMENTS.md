# Đề xuất cải tiến cho project-k8s-multimaster

## 1. BẢO MẬT (CRITICAL)

### Vấn đề hiện tại:
```ini
ansible_ssh_pass=1
ansible_become_pass=1
```

### Giải pháp:

#### Option A: Sử dụng Ansible Vault
```bash
# Tạo vault file
ansible-vault create group_vars/all/vault.yml

# Nội dung:
vault_ansible_ssh_pass: "your_secure_password"
vault_ansible_become_pass: "your_secure_password"

# Inventory sử dụng:
ansible_ssh_pass: "{{ vault_ansible_ssh_pass }}"
ansible_become_pass: "{{ vault_ansible_become_pass }}"

# Chạy playbook:
ansible-playbook -i inventory playbooks/site.yml --ask-vault-pass
```

#### Option B: SSH Key Authentication (RECOMMENDED)
```bash
# Generate và copy SSH key
ssh-keygen -t ed25519 -C "ansible-k8s"
ssh-copy-id -i ~/.ssh/id_ed25519.pub master@192.168.10.138

# Inventory đơn giản hơn:
[masters:vars]
ansible_user=master
ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

## 2. HA LOAD BALANCER

### Vấn đề:
- Node HA (192.168.10.141) bị comment
- Hardcoded IP trong playbook

### Giải pháp: Thêm playbook cho HAProxy/Keepalived

```yaml
# playbooks/00-ha-setup.yaml
---
- name: Setup HAProxy Load Balancer for K8s API
  hosts: ha
  become: yes
  vars:
    vip: 192.168.10.141
    master_nodes:
      - { name: "k8s-master-1", ip: "192.168.10.138" }
      - { name: "k8s-master-2", ip: "192.168.10.139" }
      - { name: "k8s-master-3", ip: "192.168.10.140" }
  
  tasks:
    - name: Install HAProxy
      apt:
        name: haproxy
        state: present
        update_cache: yes

    - name: Configure HAProxy for K8s API
      template:
        src: ../templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
      notify: Restart HAProxy

    - name: Enable and start HAProxy
      systemd:
        name: haproxy
        enabled: yes
        state: started

  handlers:
    - name: Restart HAProxy
      systemd:
        name: haproxy
        state: restarted
```

### Template HAProxy:
```jinja2
# templates/haproxy.cfg.j2
global
    log /dev/log local0
    maxconn 4096

defaults
    log global
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend k8s-api
    bind *:6443
    default_backend k8s-masters

backend k8s-masters
    balance roundrobin
    option tcp-check
{% for node in master_nodes %}
    server {{ node.name }} {{ node.ip }}:6443 check fall 3 rise 2
{% endfor %}
```

## 3. VARIABLES & CONFIGURATION

### Tạo file group_vars:

```yaml
# group_vars/all.yml
---
# Cluster configuration
k8s_version: "1.33"
pod_network_cidr: "10.10.0.0/16"
service_cidr: "10.96.0.0/12"
control_plane_endpoint: "{{ hostvars[groups['ha'][0]]['ansible_host'] }}:6443"

# Calico version
calico_version: "v3.28.0"

# Node naming
master_prefix: "k8s-master"
worker_prefix: "k8s-worker"

# Container runtime
containerd_version: "latest"
```

### Cập nhật playbook sử dụng biến:
```yaml
# 02-cluster-init-master.yaml
- name: Initialize Kubernetes cluster
  command: >
    kubeadm init 
    --pod-network-cidr={{ pod_network_cidr }}
    --control-plane-endpoint={{ control_plane_endpoint }}
    --upload-certs
```

## 4. VALIDATION & PREREQUISITES

### Thêm playbook kiểm tra:

```yaml
# playbooks/00-preflight-check.yaml
---
- name: Preflight checks for Kubernetes nodes
  hosts: all
  become: yes
  tasks:
    - name: Check minimum RAM (2GB)
      assert:
        that:
          - ansible_memtotal_mb >= 2048
        fail_msg: "Node has {{ ansible_memtotal_mb }}MB RAM. Minimum 2GB required."

    - name: Check minimum CPU cores (2)
      assert:
        that:
          - ansible_processor_vcpus >= 2
        fail_msg: "Node has {{ ansible_processor_vcpus }} CPUs. Minimum 2 required."

    - name: Check disk space on / (20GB)
      assert:
        that:
          - item.size_available > 20000000000
        fail_msg: "Insufficient disk space on {{ item.mount }}"
      when: item.mount == '/'
      loop: "{{ ansible_mounts }}"

    - name: Check required ports are not in use
      wait_for:
        port: "{{ item }}"
        state: stopped
        timeout: 1
      loop:
        - 6443  # K8s API
        - 2379  # etcd
        - 2380  # etcd
        - 10250 # kubelet
      ignore_errors: yes
      register: port_check

    - name: Verify network connectivity between nodes
      wait_for:
        host: "{{ item }}"
        port: 22
        timeout: 5
      loop: "{{ groups['all'] }}"
      when: item != inventory_hostname
```

## 5. ERROR HANDLING & ROLLBACK

### Cải thiện error handling:

```yaml
# 03-join-worker.yaml (improved)
- name: Join worker nodes with proper error handling
  hosts: workers
  become: yes
  tasks:
    - name: Check if node already in cluster
      stat:
        path: /etc/kubernetes/kubelet.conf
      register: kubelet_conf

    - name: Join worker to cluster
      block:
        - name: Execute join command
          command: "{{ join_command }}"
          register: join_result
          when: not kubelet_conf.stat.exists

        - name: Verify node joined successfully
          command: kubectl get nodes {{ ansible_hostname }}
          delegate_to: "{{ groups['masters'][0] }}"
          register: node_status
          until: "'Ready' in node_status.stdout or 'NotReady' in node_status.stdout"
          retries: 10
          delay: 10

      rescue:
        - name: Reset kubeadm on failure
          command: kubeadm reset -f
          
        - name: Clean up kubelet
          systemd:
            name: kubelet
            state: stopped
            enabled: no

        - name: Fail with helpful message
          fail:
            msg: |
              Failed to join worker node to cluster.
              Node has been reset. Check:
              1. Network connectivity to masters
              2. Join token validity
              3. Firewall rules
```

## 6. MONITORING & VERIFICATION

### Thêm playbook kiểm tra sau khi deploy:

```yaml
# playbooks/99-verify-cluster.yaml
---
- name: Verify Kubernetes cluster health
  hosts: masters[0]
  become: yes
  tasks:
    - name: Check all nodes are Ready
      command: kubectl get nodes
      register: nodes
      environment:
        KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"

    - name: Verify expected node count
      assert:
        that:
          - nodes.stdout_lines | select('search', 'Ready') | list | length == (groups['masters'] | length + groups['workers'] | length)
        fail_msg: "Not all nodes are Ready"

    - name: Check system pods
      command: kubectl get pods -n kube-system
      register: system_pods
      environment:
        KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"

    - name: Verify no pods in CrashLoopBackOff
      assert:
        that:
          - "'CrashLoopBackOff' not in system_pods.stdout"
        fail_msg: "Some system pods are crashing"

    - name: Test pod deployment
      shell: |
        kubectl run test-nginx --image=nginx --restart=Never
        kubectl wait --for=condition=Ready pod/test-nginx --timeout=60s
        kubectl delete pod test-nginx
      environment:
        KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"
```

## 7. INVENTORY IMPROVEMENTS

### Cấu trúc inventory tốt hơn:

```ini
# inventory (improved)
[masters]
k8s-master-1 ansible_host=192.168.10.138
k8s-master-2 ansible_host=192.168.10.139
k8s-master-3 ansible_host=192.168.10.140

[workers]
k8s-worker-1 ansible_host=192.168.10.142

[ha]
k8s-ha ansible_host=192.168.10.141

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# Use vault or SSH keys instead of passwords
# ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

## 8. SITE.YML UPDATE

```yaml
# playbooks/site.yml (improved)
---
- name: Complete Kubernetes Multi-Master Cluster Setup
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Display deployment plan
      debug:
        msg: |
          Deploying Kubernetes cluster:
          - Masters: {{ groups['masters'] | length }}
          - Workers: {{ groups['workers'] | length }}
          - HA: {{ groups['ha'] | length }}

- import_playbook: 00-preflight-check.yaml
- import_playbook: 00-ha-setup.yaml
- import_playbook: 01-common.yaml
- import_playbook: 02-cluster-init-master.yaml
- import_playbook: 03-join-master.yaml
- import_playbook: 03-join-worker.yaml
- import_playbook: 99-verify-cluster.yaml
```

## 9. MAKEFILE cho dễ sử dụng

```makefile
# Makefile
.PHONY: help deploy check clean

help:
	@echo "Available targets:"
	@echo "  deploy       - Deploy full cluster"
	@echo "  check        - Run preflight checks"
	@echo "  verify       - Verify cluster health"
	@echo "  clean        - Reset all nodes"

deploy:
	ansible-playbook -i inventory playbooks/site.yml

check:
	ansible-playbook -i inventory playbooks/00-preflight-check.yaml

verify:
	ansible-playbook -i inventory playbooks/99-verify-cluster.yaml

clean:
	ansible-playbook -i inventory playbooks/reset-cluster.yaml
```

## 10. DOCUMENTATION

### Tạo README.md cho project:

```markdown
# Kubernetes Multi-Master Cluster with Ansible

## Architecture
- 3 Master nodes (HA)
- 1+ Worker nodes
- 1 HAProxy load balancer
- Calico CNI

## Prerequisites
- Ubuntu 24.04
- 2+ CPU cores per node
- 2GB+ RAM per node
- 20GB+ disk space

## Quick Start

1. Setup SSH keys:
   ```bash
   ssh-keygen -t ed25519
   ssh-copy-id master@192.168.10.138
   # Repeat for all nodes
   ```

2. Update inventory with your IPs

3. Deploy:
   ```bash
   make deploy
   ```

4. Verify:
   ```bash
   make verify
   ```

## Troubleshooting
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
```

## Tổng kết ưu tiên

### Priority 1 (CRITICAL):
1. ✅ Sử dụng SSH keys thay vì password
2. ✅ Uncomment và setup HA node
3. ✅ Thêm preflight checks

### Priority 2 (HIGH):
4. ✅ Sử dụng variables thay vì hardcode
5. ✅ Cải thiện error handling
6. ✅ Thêm cluster verification

### Priority 3 (MEDIUM):
7. ✅ Tạo Makefile
8. ✅ Cải thiện documentation
9. ✅ Thêm rollback mechanism
