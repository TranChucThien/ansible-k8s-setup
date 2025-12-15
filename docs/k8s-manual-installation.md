# Kubernetes (K8s) Installation Guide on Ubuntu 24.04

This document provides detailed instructions for installing Kubernetes on Ubuntu 24.04, divided into 3 main sections: Common Configuration, Master Setup, and Worker Setup.

## Part 1: Environment Preparation (Execute on ALL Nodes)

These steps ensure the operating system is ready for K8s operation. You need to run these commands on both Master Node and Worker Nodes.

### 1.1 Hostname and Network Configuration

Kubernetes needs to identify machines by hostname rather than just IP addresses.

#### Edit hosts file to declare IP and machine names
```bash
sudo nano /etc/hosts
```
Add the following lines:
```
<IP_Master> k8s-master-node
<IP_Worker1> k8s-worker-node-1
```

#### Set hostname for each machine
```bash
# On Master machine
sudo hostnamectl set-hostname "k8s-master-node"

# On Worker 1 machine
sudo hostnamectl set-hostname "k8s-worker-node-1"
```

#### Disable swap
K8s requires disabling virtual memory for accurate resource management:
```bash
sudo swapoff -a
```
**Note:** You need to edit `/etc/fstab` and comment out the swap line to prevent it from re-enabling on reboot.

### 1.2 Kernel and Network Configuration

K8s needs special Linux kernel modules to manage networking between Containers.

#### Load overlay and br_netfilter modules
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

#### Save configuration to auto-load on reboot
```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

#### Configure iptables to see bridge traffic
```bash
sudo nano /etc/sysctl.d/k8s.conf
```
Add the following content to the file:
```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
```

#### Apply configuration immediately
```bash
sudo sysctl --system
```

### 1.3 Install Container Runtime (Docker/Containerd)

K8s needs a container runtime. Here we use Docker (includes containerd).

#### Install Docker
```bash
sudo apt update
sudo apt install docker.io -y
```

#### Enable Docker to start with system
```bash
sudo systemctl enable docker
```

#### Configure containerd to use SystemdCgroup
```bash
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"

# Change SystemdCgroup = false to true
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
```

#### Restart containerd
```bash
sudo systemctl restart containerd.service
```

### 1.4 Install Kubernetes Tools

#### Install supporting packages
```bash
sudo apt-get install curl ca-certificates apt-transport-https -y
```

#### Add Kubernetes GPG Key
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

#### Add K8s Repository
```bash
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

#### Install 3 main tools
```bash
sudo apt update
sudo apt install kubelet kubeadm kubectl -y
```

## Part 2: Initialize Cluster (ONLY execute on Master Node)

This step transforms the Ubuntu server into the control plane (brain).

### 2.1 Initialize Cluster
```bash
sudo kubeadm init --pod-network-cidr=10.10.0.0/16
```
**NOTE:** After this command, the screen will show a `kubeadm join...` command, copy it!

### 2.2 Grant permissions to user account
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 2.3 Install Calico (Network Plugin)

#### Download Calico configuration file
```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml -O
```

#### Install Operator
```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
```

#### Modify network range in Calico configuration
```bash
sed -i 's/cidr: 192.168.0.0\/16/cidr: 10.10.0.0\/16/g' custom-resources.yaml
```

#### Apply network configuration
```bash
kubectl create -f custom-resources.yaml
```

## Part 3: Connect Worker Nodes (ONLY execute on Worker Nodes)

This step brings worker machines under Master management.

### 3.1 Join Worker Node to Cluster
Paste the command you copied from the "kubeadm init" step above:
```bash
kubeadm join <IP_MASTER>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

## Part 4: Check and Test (On Master Node)

After installation, you need to verify everything is working.

### 4.1 Check nodes
```bash
kubectl get nodes
```

### 4.2 Create test Nginx application
```bash
kubectl create deployment my-app --image nginx --replicas 2 --namespace demo-namespace
```

### 4.3 Expose port to access application
```bash
kubectl expose deployment my-app -n demo-namespace --type NodePort --port 80
```

### 4.4 View opened port
```bash
kubectl get svc -n demo-namespace
```

## Summary

After completing the above steps, you have a working Kubernetes cluster with:
- Master Node controlling the cluster
- Worker Node(s) running applications
- Calico network plugin for Pod connectivity
- A demo Nginx application for testing

Your cluster is ready to deploy real applications!