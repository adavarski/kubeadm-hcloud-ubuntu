# Terraform Kubernetes on Hetzner Cloud

This repository helps us to setup an opionated Kubernetes Cluster with [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) on [Hetzner Cloud](https://www.hetzner.com/cloud).

## Components

- Kubernetes 1.20
- kubeadm
- Containerd (installation without docker)
- Flannel CNI
- Hetzner private network for node communication
- Hetzner firewall to protect nodes (only master ports 22, 6443 are opened)
- Hetzner cloud-controller-manager to set external node-ips, create loadbalancers and update private network routes
- Hetzner CSI to use Hetzner volumes in Kubernetes

## Inspired by

- https://github.com/solidnerd/terraform-k8s-hcloud @solidnerd
- https://github.com/jpsikorra/k8s-hetzner-test @jpsikorra

## Usage

Copy `.env.example` to `.env` and update its values.

```
$ terraform init
$ terraform plan -var-file=production.tfvars -out terraform.tfplan
$ terraform apply "terraform.tfplan"
$ KUBECONFIG=tmp/admin.conf kubectl get nodes
```

## Variables

All variables cloud be passed through `environment variables` or a `terraform.tfvars` file.
