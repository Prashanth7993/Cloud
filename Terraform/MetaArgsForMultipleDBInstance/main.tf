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

data "http" "client_ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#This resource block wil be depends on mssql server block
resource "azurerm_mssql_database" "db" {
  for_each            = var.databases
  name                = each.value.name
  server_id         = azurerm_mssql_server.sql_server.id
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = each.value.sku
  enclave_type = "VBS"
  depends_on = [azurerm_mssql_server.sql_server] 
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  public_network_access_enabled = true
}



# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# Firewall rule for the current client IP
resource "azurerm_mssql_firewall_rule" "allow_client_ip" {
  name                = "AllowClientIP"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = data.http.client_ip.response_body
  end_ip_address      = data.http.client_ip.response_body
}

