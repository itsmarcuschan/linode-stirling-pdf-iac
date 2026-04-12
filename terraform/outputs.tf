output "instance_ip" {
  value     = tolist(linode_instance.stirling-pdf.ipv4)[0]
  sensitive = true
}
