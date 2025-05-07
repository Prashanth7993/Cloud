provider "azurerm" {
  features {}
}
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}
 
variable "server_config" {
  description = "Configuration for the Azure Virtual Machines"
  type = map(object({
    os_type   = string
    publisher = string
    offer     = string
    sku       = string
    vm_size   = string
  }))
  default = {
    "web-server-a" = {
      os_type   = "Linux"
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      vm_size   = "Standard_B1s"
    },
    "app-server-b" = {
      os_type   = "Windows"
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      vm_size   =  "Standard_B2ms"
    }
  }
}
 
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "PrashanthResourceGroup"
}
 
variable "location" {
  description = "Location for the resources"
  type        = string
  default     = "WestUS"
}
 
# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
 
# Virtual Network and Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "PrashanthmyVNet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}
 
resource "azurerm_subnet" "subnet" {
  name                 = "PrashanthmySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}
 
# Public IP
resource "azurerm_public_ip" "public_ip" {
  for_each            = var.server_config
  name                = "${each.key}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
 
# Network Interface
resource "azurerm_network_interface" "nic" {
  for_each            = var.server_config
  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
  }
}
 
# Linux VMs
resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each = { for k, v in var.server_config : k => v if v.os_type == "Linux" }
 
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = each.value.vm_size
  admin_username      = "azureuser"
  disable_password_authentication = true
 
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
 
  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }
 
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}
 
# Windows VMs
resource "azurerm_windows_virtual_machine" "windows_vm" {
  for_each = { for k, v in var.server_config : k => v if v.os_type == "Windows" }
 
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = each.value.vm_size
  admin_username      = "myadmin"
  admin_password      = "Gowri1234!" # Do not hardcode in production
 
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
 
  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }
}