output "instance_ip_prod" {
  value     = tolist(linode_instance.stirling-pdf.ipv4)[0]
  sensitive = true
}

output "instance_ip_dev" {
  value     = tolist(linode_instance.stirling-pdf-dev.ipv4)[0]
  sensitive = true
}

output "instance_user" {
  value = var.server_user
}
