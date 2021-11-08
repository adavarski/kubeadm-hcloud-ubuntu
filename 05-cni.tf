# Deploy flannel cni

resource "null_resource" "cni_flannel" {
  connection {
    host        = hcloud_server.master.0.ipv4_address
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/kube-flannel.yml", {
      # nothing to replace for now
    })

    destination = "/tmp/kube-flannel.yml"
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f /tmp/kube-flannel.yml"]
  }

  depends_on = [null_resource.master]
}
