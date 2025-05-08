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

variable "environment" {
  default = "Prashanth"
}
resource "azurerm_resource_group" "rg" {
  name     = "test"
  location = "eastus"
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "web-vm-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name # Replace with your resource group name
  location            = azurerm_resource_group.rg.location              # Replace with your desired Azure region
  size                = "Standard_B1s"        # Equivalent to t2.micro
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" # Choose your desired Ubuntu version
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  custom_data = base64encode(data.template_file.user_data.rendered)

  lifecycle {
    ignore_changes = [size]
  }
}
resource "azurerm_network_security_group" "ssh_nsg" {
  name                = "ssh-nsg-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*" # Consider restricting to your IP range
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.ssh_nsg.name
}
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AllowHttp"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*" # Consider restricting to your IP range
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.ssh_nsg.name
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.ssh_nsg.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "web-public-ip-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" # Recommended for production to avoid IP changes
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "web-nic-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "web-vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

data "template_file" "user_data" {
  template = file("${path.module}/install-jenkins.sh.tpl")
  vars = {
    environment = var.environment
  }
}
output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.public_ip.ip_address
}
