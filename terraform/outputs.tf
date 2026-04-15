output "instance_ip" {
  value     = tolist(linode_instance.stirling_pdf.ipv4)[0]
  sensitive = true
}

output "instance_user" {
  value = var.server_user
}
