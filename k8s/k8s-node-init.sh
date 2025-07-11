# 1. Tắt swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Bật các kernel module cần thiết
modprobe overlay
modprobe br_netfilter

# 3. Ghi cấu hình module để tự load khi reboot
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

# 4. Cấu hình sysctl cho mạng
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system


# Cài container runtime (containerd)
apt update && apt install -y containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd && systemctl enable containerd

# Cài kubeadm, kubelet, kubectl ->> v1.30
apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
