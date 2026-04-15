variable "ssh_public_key" {
  type = string
}

variable "linode_token" {
  type      = string
  sensitive = true
}

variable "server_user" {
  type        = string
  description = "Non-root user to create on the server"
}

variable "environment" {
  description = "Environment name (prod or dev)"
  type        = string
}
