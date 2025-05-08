provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}

variable "regions" {
  default = {
    "eastus"  = { endpoint = "queue.east.example.com" },
    "westus2" = { endpoint = "queue.west.example.com" }
  }
}

resource "azurerm_resource_group" "worker_rg" {
  for_each = var.regions
  name     = "worker-rg-${each.key}"
  location = each.key
}

resource "azurerm_virtual_network" "worker_vnet" {
  for_each            = var.regions
  name                = "worker-vnet-${each.key}"
  resource_group_name = azurerm_resource_group.worker_rg[each.key].name
  location            = azurerm_resource_group.worker_rg[each.key].location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "worker_subnet" {
  for_each             = var.regions
  name                 = "default"
  resource_group_name  = azurerm_resource_group.worker_rg[each.key].name
  virtual_network_name = azurerm_virtual_network.worker_vnet[each.key].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "worker_nic" {
  for_each            = var.regions
  name                = "worker-nic-${each.key}"
  resource_group_name = azurerm_resource_group.worker_rg[each.key].name
  location            = azurerm_resource_group.worker_rg[each.key].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker_subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "worker" {
  for_each            = var.regions
  name                = "worker-vm-${each.key}"
  resource_group_name = azurerm_resource_group.worker_rg[each.key].name
  location            = azurerm_resource_group.worker_rg[each.key].location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.worker_nic[each.key].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Replace with your public key path
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#!/bin/bash
apt-get update
apt-get install -y redis-tools
echo "Connecting to ${each.value.endpoint}" > /etc/worker.conf
redis-cli -h ${each.value.endpoint} ping
EOF
  )

#   lifecycle {
#     prevent_destroy = true
#   }
}