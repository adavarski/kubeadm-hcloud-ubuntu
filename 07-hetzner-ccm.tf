# Deploy hetzner cloud-controller-manager
# SOURCE: https://github.com/hetznercloud/hcloud-cloud-controller-manager

variable "hetzner_ccm_manifest" {
  type        = string
  description = "Hetzner CCM Manifest."
  default     = "https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/ccm-networks.yaml"
}

resource "null_resource" "hetzner_ccm" {
  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = local.ssh_private_key
  }

  # Patch the flannel deployment to tolerate the uninitialized taint
  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system patch ds kube-flannel-ds --type json -p '[{\"op\":\"add\",\"path\":\"/spec/template/spec/tolerations/-\",\"value\":{\"key\":\"node.cloudprovider.kubernetes.io/uninitialized\",\"value\":\"true\",\"effect\":\"NoSchedule\"}}]'"]
  }

  # Create a secret containing your Hetzner Cloud API token
  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=kube-net"]
  }

  # Deploy the hcloud-cloud-controller-manager
  provisioner "remote-exec" {
    inline = ["kubectl apply -f ${var.hetzner_ccm_manifest}"]
  }

  # Set default load-balancer location and use-private-ip
  provisioner "remote-exec" {
    inline = [
      "kubectl set env -n kube-system deployment/hcloud-cloud-controller-manager HCLOUD_LOAD_BALANCERS_LOCATION=${var.hetzner_location}",
      "kubectl set env -n kube-system deployment/hcloud-cloud-controller-manager HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP=true",
    ]
  }

  depends_on = [null_resource.cni_flannel, null_resource.master]
}
