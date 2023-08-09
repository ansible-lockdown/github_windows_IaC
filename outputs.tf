output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "Username" {
  description = "Username password for the Virtual Machine"
  value       = data.external.win_account.result.username
}

output "Password" {
  description = "Administrator password for the Virtual Machine"
  value       = data.external.win_account.result.password
  sensitive   = true
}

