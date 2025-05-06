provider "azurerm" {
  features {}
}

# Existing Resource Group
resource "azurerm_resource_group" "rg" {
  name = var.name
  #name = "prashanth_${var.name}" 
  location = "eastus"
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}
