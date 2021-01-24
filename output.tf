output "vpn_public_ip" {
  description = "The VPN Server Public IP."
  value       = azurerm_public_ip.vpn_public_ip.ip_address
}
