# Kubernetes Ansible Setup

Cài đặt Kubernetes cluster trên Ubuntu 24.04 bằng Ansible.

## Cấu trúc thư mục

```
ansible-k8s/
├── playbooks/           # Ansible playbooks
│   ├── 01-common.yaml   # Cài đặt chung cho tất cả nodes
│   ├── 02-master.yaml   # Thiết lập master node
│   ├── 03-worker.yaml   # Thiết lập worker nodes
│   └── site.yml         # Main playbook
├── docs/                # Tài liệu
│   ├── installation.md  # Hướng dẫn cài đặt thủ công
│   ├── troubleshooting.md # Khắc phục sự cố
│   └── connect-cluster.md # Kết nối cluster
├── inventory            # Danh sách servers
├── config               # Kubeconfig file
└── SETUP-GUIDE.md       # Hướng dẫn tổ chức code
```

## Sử dụng nhanh

1. Cấu hình inventory:
```bash
nano inventory
```

2. Chạy playbook:
```bash
ansible-playbook -i inventory playbooks/site.yml
```

3. Kiểm tra cluster:
```bash
kubectl get nodes
```

## Validate source

```bash
# Kiểm tra syntax playbook
ansible-playbook --syntax-check playbooks/site.yml
# (Warning về empty hosts list là bình thường)

# Test kết nối tới servers
ansible all -i inventory -m ping

# Dry run (không thực thi)
ansible-playbook -i inventory playbooks/site.yml --check
```

## Tài liệu

- [Hướng dẫn cài đặt thủ công](docs/installation.md)
- [Kết nối cluster](docs/connect-cluster.md)
- [Khắc phục sự cố](docs/troubleshooting.md)