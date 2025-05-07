# provider "azurerm" {
#   features {}
# }

# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#       version = "4.27.0"
#     }
#   }
# }

# # Data source to fetch the current client IP address
# data "http" "client_ip" {
#   url = "https://api.ipify.org"
# }

# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

# resource "azurerm_mssql_server" "sql_server" {
#   name                         = var.sql_server_name
#   resource_group_name          = azurerm_resource_group.rg.name
#   location                     = azurerm_resource_group.rg.location
#   version                      = "12.0"
#   administrator_login          = var.admin_username
#   administrator_login_password = var.admin_password
#   public_network_access_enabled = true
# }

# resource "azurerm_mssql_database" "db" {
#   name                = var.sql_db_name
#   server_id         = azurerm_mssql_server.sql_server.id
#   license_type = "LicenseIncluded"
#   max_size_gb  = 2
#   sku_name     = "S0"
#   enclave_type = "VBS"
#   depends_on = [azurerm_mssql_server.sql_server]
# }

# # Firewall rule to allow Azure services
# resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
#   name                = "AllowAzureServices"
#   server_id           = azurerm_mssql_server.sql_server.id
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "255.255.255.255"
# }

# # Firewall rule for the current client IP
# resource "azurerm_mssql_firewall_rule" "allow_client_ip" {
#   name                = "AllowClientIP"
#   server_id           = azurerm_mssql_server.sql_server.id
#   start_ip_address    = data.http.client_ip.response_body
#   end_ip_address      = data.http.client_ip.response_body
# }

# resource "azurerm_service_plan" "plan" {
#   name                = var.app_service_plan_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   os_type             = "Linux"
#   sku_name            = "B1"
# }

# resource "azurerm_linux_web_app" "app" {
#   name                = var.app_service_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   service_plan_id     = azurerm_service_plan.plan.id

#   site_config {}

#   app_settings = {
#     "WEBSITE_RUN_FROM_PACKAGE" = "1"
#   }

#   connection_string {
#     name  = "DatabaseConnection"
#     type  = "SQLAzure"
#     value = "jdbc:sqlserver://${var.sql_server_name}.database.windows.net:1433;database=${var.sql_db_name};user=${var.admin_username}@${var.sql_server_name};password=${var.admin_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
#   }

#   depends_on = [azurerm_mssql_database.db]
# }

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

# Data source to fetch the current client IP address
data "http" "client_ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
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

# Add a delay to ensure SQL Server is fully provisioned
resource "time_sleep" "wait_for_server" {
  depends_on = [azurerm_mssql_server.sql_server]
  create_duration = "60s"  # Wait 60 seconds
}

resource "azurerm_mssql_database" "db" {
  name                = var.sql_db_name
  server_id           = azurerm_mssql_server.sql_server.id
  license_type        = "LicenseIncluded"
  max_size_gb         = 2
  sku_name            = "S0"
  enclave_type        = "VBS"
  depends_on          = [azurerm_mssql_server.sql_server, time_sleep.wait_for_server]
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"  # Corrected from 255.255.255.255
  depends_on          = [azurerm_mssql_server.sql_server]
}

# Firewall rule for the current client IP
resource "azurerm_mssql_firewall_rule" "allow_client_ip" {
  name                = "AllowClientIP"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = data.http.client_ip.response_body
  end_ip_address      = data.http.client_ip.response_body
  depends_on          = [azurerm_mssql_server.sql_server]
}

resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {}

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  connection_string {
    name  = "DatabaseConnection"
    type  = "SQLAzure"
    value = "jdbc:sqlserver://${azurerm_mssql_server.sql_server.fully_qualified_domain_name}:1433;database=${var.sql_db_name};user=${var.admin_username}@${var.sql_server_name};password=${var.admin_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
  }

  depends_on = [azurerm_mssql_database.db]
}

