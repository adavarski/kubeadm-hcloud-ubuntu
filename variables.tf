variable "hetzner_location" {
  description = "Location at hetzner of servers and load-balancers"
  default     = "fsn1"
}

variable "kubernetes_version" {
  default = "1.20.2"
}

variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}
