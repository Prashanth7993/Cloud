variable "databases" {
  type = map(object({
    name   = string
    sku = string
  }))
  description = "Map of database names and editions"
  default = {
    "db1" = { name = "microservice1db", sku = "Basic" }
    "db2" = { name = "microservice2db", sku = "BC_Gen5_2" }
  }
}
variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
  #default     = "prashanth-rg"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  #default     = "East US"
}

variable "sql_server_name" {
  type        = string
  description = "Name of the Azure SQL Server"
  validation {
    condition     = length(var.sql_server_name) >= 3 && length(var.sql_server_name) <= 63
    error_message = "SQL Server name must be between 3 and 63 characters."
  }
}

# variable "sql_db_name" {
#   type        = string
#   description = "Name of the Azure SQL Database"
#   #default     = "prashanthappdb"
# }

variable "admin_username" {
  type        = string
  description = "SQL Server admin username"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "SQL Server admin password"
  sensitive   = true
}