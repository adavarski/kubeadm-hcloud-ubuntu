variable "master_count" {
  description = "Amount of k8s masters to be deployed"
}

variable "master_image" {
  description = "Predefined Image that will be used to spin up the machines (Currently supported: ubuntu-20.04, ubuntu-18.04)"
  default     = "ubuntu-20.04"
}

variable "master_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx21"
}

resource "hcloud_server" "master" {
  count        = var.master_count
  name         = "kube-master-${count.index + 1}"
  server_type  = var.master_type
  image        = var.master_image
  location     = var.hetzner_location
  ssh_keys     = [hcloud_ssh_key.kube_admin.id]
  firewall_ids = [hcloud_firewall.kube_wall_master.id]
}

resource "hcloud_firewall" "kube_wall_master" {
  name = "kube-wall-master"

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    port = "22"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    port = "6443"
  }
}

resource "hcloud_server_network" "master" {
  count     = var.master_count
  server_id = hcloud_server.master[count.index].id
  subnet_id = hcloud_network_subnet.kube_subnet.id
  ip        = "10.0.0.${count.index + 10}"
}

resource "null_resource" "master_bootstrap" {
  count = var.master_count

  connection {
    host        = hcloud_server.master[count.index].ipv4_address
    type        = "ssh"
    private_key = local.ssh_private_key
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

resource "null_resource" "master_first" {
  count = 1

  connection {
    host        = hcloud_server.master[count.index].ipv4_address
    type        = "ssh"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/kubeadm-init-config.yml", {
      ip_private = hcloud_server_network.master[count.index].ip
      ip_public  = hcloud_server.master[count.index].ipv4_address
    })

    destination = "/etc/kubeadm-init-config.yml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master.sh"
    destination = "/root/master.sh"
  }

  # init cluster
  provisioner "remote-exec" {
    inline = [
      "export FEATURE_GATES=${var.feature_gates}",
      "bash /root/master.sh"
    ]
  }

  # copy join token
  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/copy-kubeadm-token.sh"

    environment = {
      SSH_PRIVATE_KEY = local.ssh_private_key
      SSH_USERNAME    = "root"
      SSH_HOST        = hcloud_server.master[0].ipv4_address
      TARGET          = "${path.module}/tmp"
    }
  }

  depends_on = [
    null_resource.master_bootstrap,
  ]
}

data "local_file" "kubeadm_token" {
  filename = "${path.module}/tmp/kubeadm_token"

  depends_on = [
    null_resource.master_first,
  ]
}

data "local_file" "kubeadm_upload_certs_key" {
  filename = "${path.module}/tmp/kubeadm_upload_certs_key"

  depends_on = [
    null_resource.master_first,
  ]
}

data "local_file" "kubeadm_cacert_hash" {
  filename = "${path.module}/tmp/kubeadm_cacert_hash"

  depends_on = [
    null_resource.master_first,
  ]
}

resource "null_resource" "master_following" {
  count = var.master_count - 1

  connection {
    host        = hcloud_server.master[count.index].ipv4_address
    type        = "ssh"
    private_key = local.ssh_private_key
  }

  # join to first master
  provisioner "file" {
    content = templatefile("${path.module}/templates/kubeadm-join-master-config.yml", {
      ip_private   = hcloud_server_network.master[count.index].ip
      ip_apiserver = hcloud_server_network.master[0].ip
      create_token = chomp(data.local_file.kubeadm_token.content)
      upload_certs = chomp(data.local_file.kubeadm_upload_certs_key.content)
      cacert_hash  = chomp(data.local_file.kubeadm_cacert_hash.content)
    })

    destination = "/etc/kubeadm-join-master-config.yml"
  }

  provisioner "remote-exec" {
    inline = ["kubeadm join --config /etc/kubeadm-join-master-config.yml"]
  }

  depends_on = [
    null_resource.master_bootstrap,
    null_resource.master_first,
  ]
}

resource "null_resource" "master" {
  depends_on = [
    null_resource.master_first,
    null_resource.master_following,
  ]
}
