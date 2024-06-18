variable "business_division" {
  description = "Business Division"
  type = string
  default = "ghd"
}

variable "environment" {
  description = "Which env"
  default = "dev"
}

variable "resource_group_name" {
  description = "Resource group name in Azure"
  default = "rg-default"
}

variable "resource_group_location" {
  description = "RG region"
  default = "eastus2"
}

