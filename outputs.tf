output "container_public_ip" {
  description = "Public IP address of the container instance"
  value       = azurerm_container_group.main.ip_address
}

output "container_fqdn" {
  description = "Full DNS name of the container"
  value       = azurerm_container_group.main.fqdn
}

output "application_url" {
  description = "URL to open your deployed web app"
  value       = "http://${azurerm_container_group.main.fqdn}"
}

output "resource_group_name" {
  description = "Name of the project resource group"
  value       = azurerm_resource_group.main.name
}