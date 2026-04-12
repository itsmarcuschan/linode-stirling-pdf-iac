output "instance_ip" {
  value = linode_instance.stirling-pdf.ipv4[0]
}
