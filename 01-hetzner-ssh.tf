variable "ssh_private_key" {
  description = "Private Key as string to access the machines"
  default     = ""
}

variable "ssh_public_key" {
  description = "Public Key as string or file path to authorize the access for the machines"
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Private Key as file path to access the machines"
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Public Key as file path to authorize the access for the machines"
  default     = ""
}

locals {
  ssh_public_key  = var.ssh_public_key_path != "" ? file(var.ssh_public_key_path) : var.ssh_public_key
  ssh_private_key = var.ssh_private_key_path != "" ? file(var.ssh_private_key_path) : var.ssh_private_key
}

resource "hcloud_ssh_key" "kube_admin" {
  name       = "kube-admin"
  public_key = local.ssh_public_key
}