variable "number_type" {
description = "This is a variable of type number"
type        = number
default     = 42
}
 
variable "boolean_type" {
description = "This is a variable of type bool"
type        = bool
default     = true
}
 
variable "list_type" {
description = "This is a variable of type list"
type        = list(string)
default     = ["string1", "string2", "string3"]
}
 
variable "map_type" {
description = "This is a variable of type map"
type        = map(string)
default     = {
   key1 = "value1"
   key2 = "value2"
}
}
 
variable "object_type" {
description = "This is a variable of type object"
type        = object({
   name    = string
   age     = number
   enabled = bool
})
default = {
   name    = "John Doe"
   age     = 30
   enabled = true
}
}
 
variable "tuple_type" {
description = "This is a variable of type tuple"
type        = tuple([string, number, bool])
default     = ["item1", 42, true]
}
 
variable "set_example" {
description = "This is a variable of type set"
type        = set(string)
default     = ["item1", "item2", "item3"]
}
 
variable "map_of_objects" {
  description = "This is a variable of type Map of objects"
  type = map(object({
    name = string,
    cidr = string
  }))
  default = {
    "subnet_a" = {
    name = "Subnet A",
    cidr = "10.10.1.0/24"
    },
  "subnet_b" = {
    name = "Subnet B",
    cidr = "10.10.2.0/24"
    },
  "subnet_c" = {
    name = "Subnet C",
    cidr = "10.10.3.0/24"
    }
  }
}
 
variable "list_of_objects" {
  description = "This is a variable of type List of objects"
  type = list(object({
    name = string,
    cidr = string
  }))
  default = [
    {
      name = "Subnet A",
      cidr = "10.10.1.0/24"
    },
    {
      name = "Subnet B",
      cidr = "10.10.2.0/24"
    },
    {
      name = "Subnet C",
      cidr = "10.10.3.0/24"
    }
  ]
}
 
variable "rgname" {
type        = string
description = "should start with ust-"
#default     = "ami-0d26eb3972b7f8c96"
 
validation {
   condition     = length(var.rgname) > 4 && substr(var.rgname, 0, 4) == "ust-"
   error_message = "Please provide a valid value for rg name."
}
}
 
variable "tags" {
type = object({
   name = string
   env  = string
})
description = "Tags for the azure vm instance"
default = {
   name = "My Virtual Machine"
   env  = "Dev"
}
}
 
