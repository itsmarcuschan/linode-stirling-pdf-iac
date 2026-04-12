terraform {
  required_version = ">= 1.0"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "3.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.8.0"
    }
  }
}
