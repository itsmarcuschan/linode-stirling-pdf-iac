terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "3.9.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

resource "linode_instance" "iac-Stirling-pdf" {
  label  = "iac-stirling-pdf"
  region = "fr-par"
  type   = "g6-nanode-1"
  image  = "linode/debian13"
  authorized_keys = [file("${path.module}/ssh/id_linode.pub")]
}
