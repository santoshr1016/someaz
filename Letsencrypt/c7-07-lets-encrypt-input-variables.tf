resource "random_uuid" "user_impersonation" {}

resource "random_uuid" "app_role_issue" {}

resource "random_uuid" "app_role_revoke" {}

resource "time_rotating" "default" {
  rotation_days = 180
}

variable "email_address" {
  description = "kv acmebot email registration"
  type = string
  default = "EMAIL.ADDRESS@gmai.com"
}

data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}
