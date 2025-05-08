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

#------------
#Format function
locals {
 string1       = "str1"
 string2       = "str2"
 int1          = 3
 apply_format  = format("This is %s", local.string1)
 apply_format2 = format("%s_%s_%d", local.string1, local.string2, local.int1)
}

# output "apply_format" {
#  value = local.apply_format
# }
# output "apply_format2" {
#  value = local.apply_format2
# }

#-------------------
#formatlist
locals {
 format_list = formatlist("Hello, %s!", ["A", "B", "C"])
}

# output "format_list" {
#  value = local.format_list
# }

#-----------------
#length(list / string / map)
locals {
 list_length   = length([10, 20, 30])
 string_length = length("abcdefghij")
}

# output "lengths" {
#  value = format("List length is %d. String length is %d", local.list_length, local.string_length)
# }

#-----------------
# join(separator, list)
locals {
 join_string = join(":", ["a", "b", "c"])
}

# output "join_string" {
#  value = local.join_string
# }

#-----------------
#try(value, fallback)
locals {
 map_var = {
   test = "this"
   test1 = "this1"
 }
 try1 = try(local.map_var.test2, "fallback")
}

# output "try1" {
#  value = local.try1
# }

#---------------
#can
# variable "a" {
#  type = string
#  validation {
#    condition     = can(tonumber(var.a))
#    error_message = format("This is not a number: %v", var.a)
#  }
#  default = "String"
# }

#---------------
#flatten list
locals {
 unflatten_list = [[1, 2, 3], [4, 5], [6]]
 flatten_list   = flatten(local.unflatten_list)
}

# output "flatten_list" {
#  value = local.flatten_list
# }

#---------------
# key (map) & value (map)

locals {
 key_value_map = {
   "key1" : "value1",
   "key2" : "value2"
 }
 key_list   = keys(local.key_value_map)
 value_list = values(local.key_value_map)
}

# output "key_list" {
#  value = local.key_list
# }

# output "value_list" {
#  value = local.value_list
# }

#-----------------
#Slice
locals {
 slice_list = slice([1, 2, 3, 4], 2, 4)
}


# output "slice_list" {
#  value = local.slice_list
# }

#---------------
#range
locals {
 range_one_arg    = range(3)
 range_two_args   = range(1, 3)
 range_three_args = range(1, 13, 3)
}

# output "ranges" {
#  value = format("Range one arg: %v. Range two args: %v. Range three args: %v", local.range_one_arg, local.range_two_args, local.range_three_args)
# }


#----------------
#lookup
locals {
 a_map = {
   "key1" : "value1",
   "key2" : "value2"
 }
 lookup_in_a_map = lookup(local.a_map, "key2", "test")
}


# output "lookup_in_a_map" {
#  value = local.lookup_in_a_map
# }

#---------------
#Concat
locals {
 concat_list = concat([1, 2, 3], [4, 5, 6])
}


# output "concat_list" {
#  value = local.concat_list
# }

#---------------
#merge
locals {
 b_map = {
   "key1" : "value1",
   "key2" : "value2"
 }
 c_map = {
   "key3" : "value3",
   "key4" : "value4"
 }
 final_map = merge(local.b_map, local.c_map)
}


# output "final_map" {
#  value = local.final_map
# }

#-------------
#ZipMap

locals {
 key_zip    = ["a", "b", "c"]
 values_zip = [1, 2, 3]
 zip_map    = zipmap(local.key_zip, local.values_zip)
}

# output "zip_map" {
#  value = local.zip_map
# }


