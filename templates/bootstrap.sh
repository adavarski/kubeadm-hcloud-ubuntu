#!/bin/bash
set -eu

waitforapt(){
	while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
		echo "Waiting for other software managers to finish ..."
		sleep 1
	done
}

install_containerd() {
	cat > /etc/modules-load.d/containerd.conf <<-EOF
	overlay
	br_netfilter
	EOF

	modprobe overlay
	modprobe br_netfilter

	# Setup required sysctl params, these persist across reboots.
	cat > /etc/sysctl.d/99-kubernetes-cri.conf <<-EOF
	net.bridge.bridge-nf-call-iptables  = 1
	net.ipv4.ip_forward                 = 1
	net.bridge.bridge-nf-call-ip6tables = 1
	EOF

	# Apply sysctl params without reboot
	sysctl --system

	# Install containerd
	apt-get -qq update
	apt-get -qq install -y containerd

	# Configure containerd
	mkdir -p /etc/containerd
	containerd config default | tee /etc/containerd/config.toml

	# Restart containerd
	systemctl restart containerd

	systemctl enable containerd
}

install_kube() {
	echo "Installing kubelet & kubeadm version: ${kubernetes_version}"

	cat > /etc/apt/sources.list.d/kubernetes.list <<-EOF
	deb https://packages.cloud.google.com/apt/ kubernetes-xenial main
	EOF

	cat > /etc/apt/preferences.d/kubelet <<-EOF
	Package: kubelet
	Pin: version ${kubernetes_version}-*
	Pin-Priority: 1000
	EOF

	cat > /etc/apt/preferences.d/kubeadm <<-EOF
	Package: kubeadm
	Pin: version ${kubernetes_version}-*
	Pin-Priority: 1000
	EOF

	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

	apt-get -qq update
	apt-get -qq install -y kubelet kubeadm
	apt-mark hold kubelet kubeadm

	systemctl enable kubelet
}

# disable swap
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

# Install packages to allow apt to use a repository over HTTPS
waitforapt
apt-get -qq update
apt-get -qq install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

install_containerd
install_kube

systemctl daemon-reload
systemctl restart kubelet

kubeadm config images pull
