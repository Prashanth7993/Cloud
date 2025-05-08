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
 
# Shared Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "Prashanth-vnet-2"
  location            = "centralus"
  resource_group_name = "Admin-Azure"
  address_space       = ["10.0.0.0/16"]
}
 
# Shared Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
 
# NIC for VM
resource "azurerm_network_interface" "nic_vm" {
  name                = "Prashanth-nic-1"
  location            = azurerm_virtual_network.vnet.location
  resource_group_name = azurerm_virtual_network.vnet.resource_group_name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
 
# Single Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "Prashanth-vm-01"
  resource_group_name = azurerm_virtual_network.vnet.resource_group_name
  location            = azurerm_virtual_network.vnet.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
 
  network_interface_ids = [azurerm_network_interface.nic_vm.id]
 
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
 
  os_disk {
    name                 = "Prashanth-backend-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }
 
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts"
#     version   = "latest"
#   }
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }
 
  tags = {
    environment = "frontend"
    name        = "prashanth"
  }
}