provider "linode" {}

resource "linode_instance" "stirling-pdf" {
  label           = "stirling-pdf"
  region          = "fr-par"
  type            = "g6-nanode-1"
  image           = "linode/ubuntu24.04"
  authorized_keys = [var.ssh_public_key]
}

resource "local_file" "ansible_inventory" {
  content  = templatefile("../ansible/inventory.tpl", { ip = linode_instance.stirling-pdf.ipv4[0] })
  filename = "../ansible/inventory.ini"
}
