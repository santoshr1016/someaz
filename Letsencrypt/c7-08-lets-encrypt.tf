# Function App, Azure AD App Registration:

resource "azuread_application" "default" {
  display_name    = "Acmebot ${random_string.myrandom.result}"
  identifier_uris = ["api://keyvault-acmebot-${random_string.myrandom.result}"]
  owners          = [data.azuread_client_config.current.object_id]

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access Acmebot on behalf of the signed-in user."
      admin_consent_display_name = "Access Acmebot"
      enabled                    = true
      id                         = random_uuid.user_impersonation.result
      type                       = "User"
      user_consent_description   = "Allow the application to access Acmebot on your behalf."
      user_consent_display_name  = "Access Acmebot"
      value                      = "user_impersonation"
    }
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Allow new and renew certificate"
    display_name         = "Acmebot.IssueCertificate"
    enabled              = true
    value                = "Acmebot.IssueCertificate"
    id                   = random_uuid.app_role_issue.result
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Allow revoke certificate"
    display_name         = "Acmebot.RevokeCertificate"
    enabled              = true
    value                = "Acmebot.RevokeCertificate"
    id                   = random_uuid.app_role_revoke.result
  }

  web {
    redirect_uris = ["https://func-acmebot-${random_string.myrandom.result}.azurewebsites.net/.auth/login/aad/callback"]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }
}

# Create a service principal for an application
resource "azuread_service_principal" "acmebot_sp" {
  # application_id = azuread_application.default.application_id
  client_id = azuread_application.default.client_id
  owners    = [data.azuread_client_config.current.object_id]

  app_role_assignment_required = false
}

resource "azuread_application_password" "default" {
  application_id    = azuread_application.default.id
  end_date_relative = "8640h"

  rotate_when_changed = {
    rotation = time_rotating.default.id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_key_vault" "kv_acmebot" {
  name                = "kv-acmebot-${random_string.myrandom.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku_name = "standard"

  enable_rbac_authorization = true
  tenant_id                 = data.azurerm_client_config.current.tenant_id

  depends_on = [
    azurerm_resource_group.rg,
  ]
}

## TODO add more permission
resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.kv_acmebot.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.acmebot_sp.id

  certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "ManageContacts", "ManageIssuers", "GetIssuers", "SetIssuers", "DeleteIssuers"]
  key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Backup", "Restore", "Recover", "Purge"]
  secret_permissions      = ["Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"]
}

resource "azurerm_role_assignment" "default" {
  scope                = azurerm_key_vault.kv_acmebot.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = module.keyvault_acmebot.principal_id
}

module "keyvault_acmebot" {
  source  = "shibayan/keyvault-acmebot/azurerm"
  version = "~> 3.0"

  app_base_name       = "acmebot-${random_string.myrandom.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mail_address        = var.email_address
  vault_uri           = azurerm_key_vault.kv_acmebot.vault_uri

  azure_dns = {
    subscription_id = data.azurerm_client_config.current.subscription_id
  }

  auth_settings = {
    enabled = true
    active_directory = {
      client_id            = azuread_application.default.client_id
      client_secret        = azuread_application_password.default.value
      tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
    }
  }
}



