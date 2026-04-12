variable "ssh_public_key" {
  type = string
}

variable "linode_token" {
  type      = string
  sensitive = true
}
