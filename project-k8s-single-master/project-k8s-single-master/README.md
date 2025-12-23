# Kubernetes Single Master Setup

## 🎯 Chọn phiên bản phù hợp

### 👶 **Beginner Version** - Dành cho người mới
📁 `project-k8s-single-master-beginner/`

**Đặc điểm:**
- ✅ Playbooks đơn giản, dễ hiểu
- ✅ Chạy tuần tự từng bước
- ✅ Phù hợp học tập và thực hành
- ✅ Debug dễ dàng

**Phù hợp với:**
- Người mới học Ansible
- Muốn hiểu rõ từng bước setup K8s
- Thực hành và experiment

---

### 🏗️ **Roles Version** - Professional
📁 `project-k8s-single-master-roles/`

**Đặc điểm:**
- ✅ Cấu trúc Ansible Roles chuẩn
- ✅ Modular và reusable
- ✅ Multi-environment support
- ✅ Production-ready

**Phù hợp với:**
- Đã có kinh nghiệm Ansible
- Cần deploy production
- Muốn học best practices
- Team development

---

## 🚀 Quick Start

### Beginner:
```bash
cd project-k8s-single-master-beginner/
ansible-playbook -i inventory-lab playbooks/site.yml
```

### Roles:
```bash
cd project-k8s-single-master-roles/
ansible-playbook -i inventories/lab playbooks/site.yml
```

## 📚 Learning Path

1. **Bắt đầu** với `beginner` để hiểu cơ bản
2. **Chuyển sang** `roles` khi đã thành thạo
3. **Áp dụng** roles cho production environments

## 🔄 So sánh

| Feature | Beginner | Roles |
|---------|----------|-------|
| **Độ phức tạp** | Đơn giản | Trung bình |
| **Cấu trúc** | Linear | Modular |
| **Tái sử dụng** | Thấp | Cao |
| **Production** | Demo/Lab | Production |
| **Learning curve** | Dễ | Trung bình |