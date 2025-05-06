resource "azurerm_resource_group" "example" {
  name="${var.rgname}myrg${var.number_type}"
  location = "Central US"
  tags=var.tags
}
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}
 
provider "azurerm" {
  # Configuration options
features{}
}
 
 
output "bool"{
  value=var.boolean_type
}
 
output "list"{
  value=var.list_type
}
 
output "map"{
  value=var.map_type
}
 
output "object"{
  value=var.object_type
}
 
output "tuple"{
  value=var.tuple_type
}
 
output "set"{
  value=var.set_example
}
 
output "map_of_objects"{
  value=var.map_of_objects
}
 
output "list_of_objects"{
  value=var.list_of_objects
}
