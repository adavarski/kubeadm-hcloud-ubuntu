variable "node_count" {
  description = "Amount of k8s workers to be deployed"
}

variable "node_image" {
  description = "Predefined Image that will be used to spin up the machines (Currently supported: ubuntu-20.04, ubuntu-18.04)"
  default     = "ubuntu-20.04"
}

variable "node_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx21"
}

resource "hcloud_server" "node" {
  count        = var.node_count
  name         = "kube-node-${count.index + 1}"
  server_type  = var.node_type
  image        = var.node_image
  location     = var.hetzner_location
  ssh_keys     = [hcloud_ssh_key.kube_admin.id]
  firewall_ids = [hcloud_firewall.kube_wall_node.id]
}

resource "hcloud_firewall" "kube_wall_node" {
  name = "kube-wall-node"

  # no rules means block everything
}

resource "hcloud_server_network" "node" {
  count     = var.node_count
  server_id = hcloud_server.node[count.index].id
  subnet_id = hcloud_network_subnet.kube_subnet.id
  ip        = "10.0.0.${count.index + 100}"
}

resource "null_resource" "node_bootstrap" {
  count = var.node_count

  connection {
    host        = hcloud_server_network.node[count.index].ip
    type        = "ssh"
    private_key = local.ssh_private_key

    # use first master as bastion
    bastion_host        = hcloud_server.master.0.ipv4_address
    bastion_private_key = local.ssh_private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/bootstrap.sh", {
      kubernetes_version = var.kubernetes_version
    })

    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/bootstrap.sh"]
  }
}

resource "null_resource" "node" {
  count = var.node_count

  connection {
    host        = hcloud_server_network.node[count.index].ip
    type        = "ssh"
    private_key = local.ssh_private_key

    # use first master as bastion
    bastion_host        = hcloud_server.master.0.ipv4_address
    bastion_private_key = local.ssh_private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/kubeadm-join-node-config.yml", {
      ip_private   = hcloud_server_network.node[count.index].ip
      ip_apiserver = hcloud_server_network.master[0].ip
      create_token = chomp(data.local_file.kubeadm_token.content)
      cacert_hash  = chomp(data.local_file.kubeadm_cacert_hash.content)
    })

    destination = "/etc/kubeadm-join-node-config.yml"
  }

  provisioner "remote-exec" {
    inline = ["kubeadm join --config /etc/kubeadm-join-node-config.yml"]
  }

  depends_on = [
    null_resource.node_bootstrap,
  ]
}
