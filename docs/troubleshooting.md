# Kubernetes Ansible Deployment - Troubleshooting Guide

## 1. Invalid Hostname Error

**Lỗi:**
```
Could not set pretty hostname: Invalid pretty hostname '  k8s-worker-1\n'
```

**Nguyên nhân:** Jinja2 template tạo ra hostname có khoảng trắng thừa do cách format multiline string.

**Cách fix:**
```yaml
my_hostname: >-
  {% if 'masters' in group_names -%}
  {{ master_prefix }}-{{ groups['masters'].index(inventory_hostname) + 1 }}
  {%- elif 'workers' in group_names -%}
  {{ worker_prefix }}-{{ groups['workers'].index(inventory_hostname) + 1 }}
  {%- else -%}
  {{ inventory_hostname }}
  {%- endif %}
```

**Giải thích:** Sử dụng `{%-` và `-%}` để loại bỏ khoảng trắng trong Jinja2 template.

## 2. Malformed Docker Repository Entry

**Lỗi:**
```
E:Malformed entry 1 in list file /etc/apt/sources.list.d/docker.list (Suite)
```

**Nguyên nhân:** Repository Docker thiếu Ubuntu codename và có format không đúng.

**Cách fix:**
```yaml
- name: Remove existing Docker repository file
  file:
    path: /etc/apt/sources.list.d/docker.list
    state: absent

- name: Set up the Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
    filename: docker
```

**Giải thích:** Xóa file repository cũ và tạo lại với format đúng bao gồm Ubuntu codename.

## 3. Missing Handler Error

**Lỗi:**
```
The requested handler 'Restart containerd' was not found
```

**Nguyên nhân:** Task notify handler nhưng handler không được định nghĩa.

**Cách fix:**
```yaml
handlers:
  - name: Restart containerd
    systemd:
      name: containerd
      state: restarted
```

**Giải thích:** Thêm section handlers với định nghĩa handler cần thiết.

## 4. Kubernetes Repository 403 Forbidden

**Lỗi:**
```
E:Failed to fetch https://pkgs.k8s.io/core:/stable:/v1.33/deb/dists/kubernetes-xenial/InRelease 403 Forbidden
```

**Nguyên nhân:** Format repository Kubernetes không đúng với API mới.

**Cách fix:**
```yaml
- name: Add Kubernetes apt repository
  copy:
    dest: /etc/apt/sources.list.d/kubernetes.list
    content: |
      deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /
```

**Giải thích:** Loại bỏ "kubernetes-xenial main" và chỉ để "/" ở cuối URL.

## 5. Unsupported APT Module Parameter

**Lỗi:**
```
Unsupported parameters for (apt) module: mark
```

**Nguyên nhân:** Module `apt` không hỗ trợ parameter `mark` để hold packages.

**Cách fix:**
```yaml
- name: Hold Kubernetes packages at current version
  dpkg_selections:
    name: "{{ item }}"
    selection: hold
  loop:
    - kubelet
    - kubeadm
    - kubectl
```

**Giải thích:** Sử dụng module `dpkg_selections` thay vì `apt` để hold packages.

## 6. Local Action Sudo Password Required

**Lỗi:**
```
sudo: a password is required
```

**Nguyên nhân:** Task `local_action` chạy với `become: yes` trên localhost.

**Cách fix:**
```yaml
- name: Save join command locally
  local_action: copy content="{{ join_cmd.stdout }}" dest="./join-command.txt"
  run_once: true
  become: no
```

**Giải thích:** Thêm `become: no` cho các task `local_action` để tránh yêu cầu sudo.

## 7. Node Already Exists in Cluster

**Lỗi:**
```
a Node with name "k8s-worker-1" and status "Ready" already exists in the cluster
```

**Nguyên nhân:** Worker node đã join cluster trước đó.

**Cách fix:**
```yaml
- name: Check if kubelet service is running
  systemd:
    name: kubelet
  register: kubelet_status
  ignore_errors: yes

- name: Join worker to Kubernetes cluster
  command: "{{ join_command }} --ignore-preflight-errors=FileAvailable--etc-kubernetes-bootstrap-kubelet.conf,FileAvailable--etc-kubernetes-pki-ca.crt"
  when: kubelet_status.status.ActiveState != 'active'
  ignore_errors: yes
```

**Giải thích:** Kiểm tra trạng thái kubelet và chỉ join khi chưa active, sử dụng `--ignore-preflight-errors` để bỏ qua file đã tồn tại.

## 8. Ansible Deprecation Warning

**Lỗi:**
```
Using a mapping for `action` is deprecated
```

**Nguyên nhân:** Cú pháp `local_action` dạng mapping đã deprecated.

**Cách fix:**
```yaml
# Thay vì:
local_action:
  module: slurp
  src: ./join-command.txt

# Sử dụng:
local_action: slurp src=./join-command.txt
```

**Giải thích:** Sử dụng string format thay vì mapping format cho `local_action`.

## 9. Python Interpreter Discovery Warning

**Lỗi:**
```
Host is using the discovered Python interpreter at '/usr/bin/python3.12'
```

**Nguyên nhân:** Ansible tự động phát hiện Python interpreter.

**Cách fix:**
```ini
[masters]
192.168.10.132 ansible_python_interpreter=/usr/bin/python3

[workers]  
192.168.10.133 ansible_python_interpreter=/usr/bin/python3
```

**Giải thích:** Chỉ định rõ Python interpreter trong inventory để tránh auto-discovery.

## 10. Worker Nodes Missing Role Label

**Lỗi:** Worker nodes hiển thị `<none>` trong cột ROLES.

**Nguyên nhân:** Kubernetes không tự động gán role label cho worker nodes.

**Cách fix:**
```yaml
- name: Label worker nodes with worker role
  command: kubectl label node {{ hostvars[item].my_hostname }} node-role.kubernetes.io/worker=worker
  environment:
    KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"
  loop: "{{ groups['workers'] }}"
  ignore_errors: yes
```

**Giải thích:** Thủ công gán label role cho worker nodes từ master node.

## 11. Calico Operator Already Exists

**Lỗi:**
```
Error from server (AlreadyExists): namespaces "tigera-operator" already exists
Error from server (AlreadyExists): customresourcedefinitions.apiextensions.k8s.io "bgpconfigurations.crd.projectcalico.org" already exists
```

**Nguyên nhân:** Calico operator đã được cài đặt trước đó khi chạy lại playbook.

**Cách fix:**
```yaml
- name: Check if Calico operator exists
  command: kubectl get namespace tigera-operator
  register: calico_check
  ignore_errors: yes
  environment:
    KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"

- name: Deploy Calico operator
  command: kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
  when: calico_check.rc != 0
  environment:
    KUBECONFIG: "/home/{{ ansible_user }}/.kube/config"
```

**Giải thích:** Kiểm tra xem Calico đã tồn tại chưa, sử dụng `apply` thay vì `create` để tránh lỗi AlreadyExists.