# Common tags applied to every resource (required by the rubric)
locals {
  common_tags = {
    Project     = "Project2"
    Environment = "production"
    StudentName = var.student_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# 1. Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# 2. Azure Container Instance (ACI) running your Docker image
resource "azurerm_container_group" "main" {
  name                = var.aci_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = var.dns_label

  container {
    name   = "webapp"
    image  = var.docker_image
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = local.common_tags
}