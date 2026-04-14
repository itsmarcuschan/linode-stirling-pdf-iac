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
        - name: ${var.server_user}
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

resource "linode_instance" "stirling-pdf-dev" {
  label           = "stirling-pdf-dev"
  region          = "fr-par"
  type            = "g6-nanode-1"
  image           = "linode/ubuntu24.04"
  authorized_keys = [var.ssh_public_key]

  metadata {
    user_data = base64encode(<<-EOF
      #cloud-config
      users:
        - name: ${var.server_user}
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

resource "linode_instance" "stirling-pdf-test" {
  label           = "stirling-pdf-test"
  region          = "fr-par"
  type            = "g6-nanode-1"
  image           = "linode/ubuntu24.04"
  authorized_keys = [var.ssh_public_key]

  metadata {
    user_data = base64encode(<<-EOF
      #cloud-config
      users:
        - name: ${var.server_user}
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
