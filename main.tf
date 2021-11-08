terraform {
  required_version = ">= 0.12"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.25.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }

}

variable "hcloud_token" {
  description = "Hetzner Cloud Api token"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "local" {
}
