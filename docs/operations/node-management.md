# Kubernetes Node Management Guide

This guide explains how to add or remove worker nodes from your Kubernetes cluster.

## Current Source Code Analysis

### Existing Structure
- **01-common.yaml**: Sets up all nodes (masters + workers)
- **02-master.yaml**: Initializes master and generates join command
- **03-worker.yaml**: Joins workers using saved join command
- **site.yml**: Orchestrates all playbooks

### Current Limitations
1. **Static inventory**: Workers defined in inventory file
2. **Join command dependency**: Requires existing join-command.txt
3. **No removal process**: No playbook for node removal

## Adding New Worker Nodes

### Method 1: Update Inventory (Recommended)

#### Step 1: Add new worker to inventory
```ini
[workers]
192.168.10.135 ansible_user=worker ansible_ssh_pass=1 ansible_become_pass=1 ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter=/usr/bin/python3
192.168.10.136 ansible_user=worker ansible_ssh_pass=1 ansible_become_pass=1 ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter=/usr/bin/python3
# Add new worker here
192.168.10.137 ansible_user=worker ansible_ssh_pass=1 ansible_become_pass=1 ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter=/usr/bin/python3
```

#### Step 2: Run playbooks for new node only
```bash
# Setup common components on new node
ansible-playbook -i inventory playbooks/01-common.yaml --limit 192.168.10.137

# Join new worker to cluster
ansible-playbook -i inventory playbooks/03-worker.yaml --limit 192.168.10.137
```

#### Step 3: Verify new node
```bash
kubectl get nodes
```

### Method 2: Generate Fresh Join Command

#### Create new playbook: `playbooks/04-add-worker.yaml`
```yaml
---
- name: Generate new join command and add worker
  hosts: masters[0]
  become: yes
  tasks:
    - name: Generate new join command
      shell: kubeadm token create --print-join-command
      register: new_join_cmd
    
    - name: Save new join command
      local_action: copy content="{{ new_join_cmd.stdout }}" dest="./new-join-command.txt"
      become: no

- name: Setup and join new worker nodes
  hosts: new_workers  # Define this group in inventory
  become: yes
  tasks:
    - name: Read new join command
      local_action: slurp src=./new-join-command.txt
      register: join_cmd_file
      run_once: true
      become: no
    
    - name: Set join command variable
      set_fact:
        join_command: "{{ join_cmd_file.content | b64decode | trim }}"
    
    - name: Join worker to cluster
      command: "{{ join_command }}"
      register: join_result
    
    - name: Show join result
      debug:
        var: join_result
```

#### Usage:
```bash
# Add new_workers group to inventory
[new_workers]
192.168.10.137 ansible_user=worker ansible_ssh_pass=1

# Run common setup first
ansible-playbook -i inventory playbooks/01-common.yaml --limit new_workers

# Add worker to cluster
ansible-playbook -i inventory playbooks/04-add-worker.yaml
```

## Removing Worker Nodes

### Method 1: Graceful Removal (Recommended)

#### Create playbook: `playbooks/05-remove-worker.yaml`
```yaml
---
- name: Gracefully remove worker nodes
  hosts: masters[0]
  become: yes
  tasks:
    - name: Drain worker nodes
      command: kubectl drain {{ item }} --ignore-daemonsets --delete-emptydir-data --force
      loop: "{{ groups['remove_workers'] }}"
      environment:
        KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"
      ignore_errors: yes
    
    - name: Delete worker nodes from cluster
      command: kubectl delete node {{ item }}
      loop: "{{ groups['remove_workers'] }}"
      environment:
        KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"
      ignore_errors: yes

- name: Reset worker nodes
  hosts: remove_workers
  become: yes
  tasks:
    - name: Reset kubeadm on worker
      command: kubeadm reset --force
      ignore_errors: yes
    
    - name: Remove Kubernetes directories
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - /etc/kubernetes
        - /var/lib/kubelet
        - /var/lib/etcd
        - ~/.kube
      ignore_errors: yes
    
    - name: Stop and disable services
      systemd:
        name: "{{ item }}"
        state: stopped
        enabled: no
      loop:
        - kubelet
        - docker
      ignore_errors: yes
```

#### Usage:
```bash
# Define nodes to remove in inventory
[remove_workers]
192.168.10.137 ansible_user=worker ansible_ssh_pass=1

# Remove workers gracefully
ansible-playbook -i inventory playbooks/05-remove-worker.yaml
```

### Method 2: Manual Removal
```bash
# On master node
kubectl drain <worker-node-name> --ignore-daemonsets --delete-emptydir-data --force
kubectl delete node <worker-node-name>

# On worker node
sudo kubeadm reset --force
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd ~/.kube
sudo systemctl stop kubelet docker
sudo systemctl disable kubelet docker
```

## Improved Playbook Structure

### Enhanced `site.yml` for flexibility
```yaml
---
# Enhanced main playbook
- import_playbook: 01-common.yaml
- import_playbook: 02-master.yaml
- import_playbook: 03-worker.yaml
  when: groups['workers'] is defined and groups['workers']|length > 0

# Optional playbooks
- import_playbook: 04-add-worker.yaml
  when: groups['new_workers'] is defined and groups['new_workers']|length > 0

- import_playbook: 05-remove-worker.yaml
  when: groups['remove_workers'] is defined and groups['remove_workers']|length > 0
```

### Dynamic Inventory Groups
```ini
# Standard groups
[masters]
192.168.10.134 ansible_user=master

[workers]
192.168.10.135 ansible_user=worker
192.168.10.136 ansible_user=worker

# Temporary groups for operations
[new_workers]
# Add new workers here when needed
# 192.168.10.137 ansible_user=worker

[remove_workers]
# Add workers to remove here when needed
# 192.168.10.136 ansible_user=worker

[all:vars]
ansible_ssh_pass=1
ansible_become_pass=1
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
```

## Best Practices for Node Management

### 1. Pre-checks Before Adding Nodes
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Verify resources
kubectl top nodes
kubectl describe nodes
```

### 2. Post-addition Verification
```bash
# Verify new node joined
kubectl get nodes -o wide

# Check node labels and taints
kubectl describe node <new-node-name>

# Verify pods can schedule on new node
kubectl get pods -o wide --all-namespaces
```

### 3. Monitoring During Removal
```bash
# Monitor pod migration during drain
kubectl get pods -o wide --watch

# Check cluster capacity after removal
kubectl top nodes
kubectl describe nodes
```

### 4. Automation Scripts

#### `scripts/add-worker.sh`
```bash
#!/bin/bash
NEW_WORKER_IP=$1
NEW_WORKER_USER=$2

# Add to inventory temporarily
echo "$NEW_WORKER_IP ansible_user=$NEW_WORKER_USER ansible_ssh_pass=1" >> inventory.tmp

# Run setup
ansible-playbook -i inventory.tmp playbooks/01-common.yaml --limit $NEW_WORKER_IP
ansible-playbook -i inventory.tmp playbooks/03-worker.yaml --limit $NEW_WORKER_IP

# Cleanup
rm inventory.tmp

echo "Worker $NEW_WORKER_IP added successfully"
```

#### `scripts/remove-worker.sh`
```bash
#!/bin/bash
WORKER_NAME=$1

# Drain and delete
kubectl drain $WORKER_NAME --ignore-daemonsets --delete-emptydir-data --force
kubectl delete node $WORKER_NAME

echo "Worker $WORKER_NAME removed successfully"
```

## Troubleshooting Node Operations

### Common Issues
1. **Join command expired**: Generate new token
2. **Node not ready**: Check kubelet logs
3. **Drain stuck**: Force drain with --force flag
4. **Certificate issues**: Reset and rejoin

### Recovery Commands
```bash
# Generate new join command
kubeadm token create --print-join-command

# Check node status
kubectl describe node <node-name>

# View kubelet logs
journalctl -u kubelet -f

# Reset node completely
kubeadm reset --force
```

This guide provides flexible approaches for managing worker nodes in your Kubernetes cluster while maintaining cluster stability.