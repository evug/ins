#!/bin/sh
set -x
if [ "$(lsb_release -cs)" != "jammy" ]; then
  echo "This script is only for Ubuntu 22.10"; exit 1
fi
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl git jq
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/kubernetes.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

version=$(apt-cache policy kubeadm | grep Candidate | awk '{print $2}')
echo "Installing kubernetes ${version%-*}" 
sleep 5
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


echo "Turn off swap"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

sudo modprobe overlay
sudo modprobe br_netfilter

echo "Containerd"
sudo tee /etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null  
sudo apt update
sudo apt install containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml 1>/dev/null
sudo systemctl enable containerd
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable kubelet
echo "image pull and cluster setup"
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v"${version%-*}"
sudo kubeadm init   --pod-network-cidr=10.244.0.0/16   --upload-certs --kubernetes-version=v"${version%-*}"  --control-plane-endpoint=$(hostname) --ignore-preflight-errors=all  --cri-socket unix:///run/containerd/containerd.sock
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# export KUBECONFIG=/etc/kubernetes/admin.conf
echo "Apply flannel network"
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
