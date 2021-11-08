resource "hcloud_network" "kube_net" {
  name     = "kube-net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "kube_subnet" {
  network_id   = hcloud_network.kube_net.id
  ip_range     = "10.0.0.0/24"
  type         = "server"
  network_zone = "eu-central"
}
