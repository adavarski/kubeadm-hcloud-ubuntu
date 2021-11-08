# Deploy hetzner container storage interface
# SOURCE: https://github.com/hetznercloud/csi-driver

variable "hetzner_csi_manifest" {
  type        = string
  description = "Hetzner CSI Manifest."
  default     = "https://raw.githubusercontent.com/hetznercloud/csi-driver/master/deploy/kubernetes/hcloud-csi.yml"
}

resource "null_resource" "hetzner_csi" {
  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = local.ssh_private_key
  }

  # Create a secret containing your Hetzner Cloud API token
  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}"]
  }

  # Deploy the CSI driver and wait until everything is up and running
  provisioner "remote-exec" {
    inline = ["kubectl apply -f ${var.hetzner_csi_manifest}"]
  }

  depends_on = [null_resource.master]
}
