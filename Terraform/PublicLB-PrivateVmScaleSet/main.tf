terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"  # Supports Trusted Launch features
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "bf7e75db-e819-49ca-b6d2-69c32a2353fe"
}

resource "azurerm_resource_group" "three_tier_rg" {
  name     = "Project-3Tier"
  location = "Central India"
}

resource "azurerm_virtual_network" "Vnet" {
  name                = "Virtual-network-3Tier"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.three_tier_rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.three_tier_rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer
resource "azurerm_lb" "loadbalancer" {
  name                = "lb-name"
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Backend Address Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "lb-backend" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "backend-pool"
}

# Health Probe for Load Balancer
resource "azurerm_lb_probe" "Health-Prob-lob" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load Balancer Rule
resource "azurerm_lb_rule" "lb-rule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb-backend.id]
  probe_id                       = azurerm_lb_probe.Health-Prob-lob.id
}

resource "azurerm_network_security_group" "lb_nsg" {
  name                = "lb-nsg"
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.lb_nsg.id
}

data "azurerm_shared_image_version" "img" {
  name                = "1.0.0"
  gallery_name        = "PrashanthTestImg"
  image_name          = "PrashanthDefImg"
  resource_group_name = "Project-Test-rg"
}

resource "azurerm_network_security_group" "private_nsg" {
  name                = "private-nsg"
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_linux_virtual_machine_scale_set" "Vmscaleset" {
  name                = "Prashanth-vmss"
  location            = azurerm_resource_group.three_tier_rg.location
  resource_group_name = azurerm_resource_group.three_tier_rg.name
  sku                 = "Standard_B1s"
  instances           = 2
  secure_boot_enabled = true  # Enables Trusted Launch for gallery image

  source_image_id = data.azurerm_shared_image_version.img.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "Prahanth-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.private.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb-backend.id]
    }
  }

  admin_username                  = "adminuser"
  admin_password                  = "Password1234!"  # Replace with SSH keys for security
  disable_password_authentication = false

  upgrade_mode = "Manual"
}
resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}


output "load_balancer_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}