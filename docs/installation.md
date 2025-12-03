# Hướng dẫn cài đặt Kubernetes (K8s) trên Ubuntu 24.04

Tài liệu này hướng dẫn chi tiết cách cài đặt Kubernetes trên Ubuntu 24.04, được chia thành 3 phần chính: Cấu hình chung, Thiết lập Master và Thiết lập Worker.

## Phần 1: Chuẩn bị môi trường (Thực hiện trên TẤT CẢ các Node)

Các bước này đảm bảo hệ điều hành sẵn sàng để K8s hoạt động. Bạn cần chạy các lệnh này trên cả Master Node và các Worker Node.

### 1.1 Đặt tên và định danh mạng

Kubernetes cần biết máy nào là máy nào thông qua tên (hostname) thay vì chỉ IP.

#### Chỉnh sửa file hosts để khai báo IP và tên các máy
```bash
sudo nano /etc/hosts
```
Thêm các dòng sau:
```
<IP_Master> k8s-master-node
<IP_Worker1> k8s-worker-node-1
```

#### Đặt tên host cho từng máy
```bash
# Trên máy Master
sudo hostnamectl set-hostname "k8s-master-node"

# Trên máy Worker 1
sudo hostnamectl set-hostname "k8s-worker-node-1"
```

#### Tắt swap
K8s yêu cầu tắt bộ nhớ ảo để quản lý tài nguyên chính xác:
```bash
sudo swapoff -a
```
**Lưu ý:** Sau đó bạn cần vào `/etc/fstab` comment dòng swap lại để nó không bật lại khi khởi động lại máy.

### 1.2 Cấu hình Kernel và Network

K8s cần các module hạt nhân Linux đặc biệt để quản lý mạng giữa các Container.

#### Tải module overlay và br_netfilter
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

#### Lưu cấu hình để tự động tải khi khởi động lại
```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

#### Cấu hình iptables để nhìn thấy traffic cầu nối
```bash
sudo nano /etc/sysctl.d/k8s.conf
```
Thêm nội dung sau vào file:
```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```

#### Áp dụng cấu hình ngay lập tức
```bash
sudo sysctl --system
```

### 1.3 Cài đặt Container Runtime (Docker/Containerd)

K8s cần một trình chạy container. Ở đây sử dụng Docker (bao gồm sẵn containerd).

#### Cài đặt Docker
```bash
sudo apt update
sudo apt install docker.io -y
```

#### Bật Docker tự khởi động cùng máy
```bash
sudo systemctl enable docker
```

#### Cấu hình containerd để sử dụng SystemdCgroup
```bash
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"

# Sửa SystemdCgroup = false thành true
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
```

#### Khởi động lại containerd
```bash
sudo systemctl restart containerd.service
```

### 1.4 Cài đặt các công cụ Kubernetes

#### Cài các gói phụ trợ
```bash
sudo apt-get install curl ca-certificates apt-transport-https -y
```

#### Thêm khóa bảo mật (GPG Key) của Kubernetes
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

#### Thêm kho phần mềm (Repository) của K8s
```bash
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

#### Cài đặt 3 công cụ chính
```bash
sudo apt update
sudo apt install kubelet kubeadm kubectl -y
```

## Phần 2: Khởi tạo Cluster (CHỈ thực hiện trên Master Node)

Đây là bước biến máy chủ cài Ubuntu thành bộ não điều khiển (Control Plane).

### 2.1 Khởi tạo Cluster
```bash
sudo kubeadm init --pod-network-cidr=10.10.0.0/16
```
**LƯU Ý:** Sau lệnh này, màn hình sẽ hiện ra lệnh `kubeadm join...`, hãy copy lại nó!

### 2.2 Cấp quyền cho tài khoản user
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 2.3 Cài đặt Calico (Plugin mạng)

#### Tải file cấu hình Calico
```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml -O
```

#### Cài đặt Operator
```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
```

#### Sửa dải mạng trong cấu hình Calico
```bash
sed -i 's/cidr: 192.168.0.0\/16/cidr: 10.10.0.0\/16/g' custom-resources.yaml
```

#### Áp dụng cấu hình mạng
```bash
kubectl create -f custom-resources.yaml
```

## Phần 3: Kết nối Worker Nodes (CHỈ thực hiện trên Worker Nodes)

Bước này đưa các máy con vào sự quản lý của Master.

### 3.1 Join Worker Node vào Cluster
Dán lệnh bạn đã copy ở bước "kubeadm init" phía trên:
```bash
kubeadm join <IP_MASTER>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

## Phần 4: Kiểm tra và Test (Trên Master Node)

Sau khi cài xong, bạn cần kiểm tra xem mọi thứ có hoạt động không.

### 4.1 Kiểm tra các node
```bash
kubectl get nodes
```

### 4.2 Tạo ứng dụng Nginx thử nghiệm
```bash
kubectl create deployment my-app --image nginx --replicas 2 --namespace demo-namespace
```

### 4.3 Mở cổng để truy cập ứng dụng
```bash
kubectl expose deployment my-app -n demo-namespace --type NodePort --port 80
```

### 4.4 Xem cổng đã được mở
```bash
kubectl get svc -n demo-namespace
```

## Tổng kết

Sau khi hoàn thành các bước trên, bạn đã có một Kubernetes cluster hoạt động với:
- Master Node điều khiển cluster
- Worker Node(s) chạy các ứng dụng
- Calico network plugin để kết nối các Pod
- Một ứng dụng Nginx demo để test

Cluster của bạn đã sẵn sàng để triển khai các ứng dụng thực tế!