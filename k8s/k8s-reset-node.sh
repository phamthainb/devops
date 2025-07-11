#!/bin/bash
set -e

echo "[INFO] Resetting kubeadm..."
kubeadm reset -f

echo "[INFO] Removing leftover directories..."
rm -rf /etc/kubernetes/
rm -rf /var/lib/etcd/
rm -rf /var/lib/kubelet/*
rm -rf ~/.kube

echo "[INFO] Cleaning up containerd pods and images..."
crictl rmp -fa || true
crictl rmi -a || true

echo "[DONE] Kubernetes node has been reset!"
