provider "linode" {
  token = var.linode_token
}

resource "linode_instance" "stirling-pdf" {
  label           = "stirling-pdf"
  region          = "fr-par"
  type            = "g6-nanode-1"
  image           = "linode/ubuntu24.04"
  authorized_keys = [var.ssh_public_key]

  metadata {
    user_data = base64encode(<<-EOF
      #cloud-config
      users:
        - name: marcus
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      
      runcmd:
        - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        - systemctl restart ssh
    EOF
    )
  }
}

resource "local_file" "ansible_inventory" {
  content  = templatefile("${path.module}/ansible/inventory.tpl", { ip = tolist(linode_instance.stirling-pdf.ipv4)[0] })
  filename = "${path.module}/ansible/inventory.ini"
}
