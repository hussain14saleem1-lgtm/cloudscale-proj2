terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Remote backend: stores the state file in Azure Storage
  backend "azurerm" {
    resource_group_name  = "hussain-tfstate-rg"
    storage_account_name = "hussaintfstate2026"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}