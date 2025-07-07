# outputs.tf
output "console_server_public_ip" {
  value = aws_eip.console_eip.public_ip
}

output "data_node_public_ips" {
  value = aws_instance.data_nodes[*].public_ip
}

output "data_node_private_ips" {
  value = aws_instance.data_nodes[*].private_ip
}
