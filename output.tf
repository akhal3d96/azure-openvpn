output "vpn_ssh_command" {
  description = "Comand to access your server"
  value       = "ssh -i vpn_ssh ${var.vpn_server_username}@${azurerm_public_ip.vpn_public_ip.ip_address} -o IdentitiesOnly=yes"
}
