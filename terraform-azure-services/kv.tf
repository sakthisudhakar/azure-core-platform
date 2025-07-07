# module "avm_res_keyvault_vault" {
#   source  = "./modules/keyvault"

#   location            = var.location
#   name                = "key-vault-test-${random_string.this.result}"
#   resource_group_name = var.resource_group_name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name = "standard"
#   soft_delete_retention_days  = 7
#   public_network_access_enabled = false
# #   network_acls = {
# #     default_action = "Allow"
# #   }
#   role_assignments = {
#     # deployment_user_secrets = {
#     #   role_definition_id_or_name = "Key Vault Administrator"
#     #   principal_id               = data.azurerm_client_config.current.object_id
#     # }

#     customer_managed_key = {
#       role_definition_id_or_name = "Key Vault Crypto Officer"
#       principal_id               = azurerm_user_assigned_identity.storage_msi.principal_id
#     }
#   }
#   keys = {
#     cmk_for_storage_account = {
#       key_opts = [
#         "decrypt",
#         "encrypt",
#         "sign",
#         "unwrapKey",
#         "verify",
#         "wrapKey"
#       ]
#       key_type = "RSA"
#       name     = "cmk-for-storage-account"
#       key_size = 2048
#     }
#   }

#   tags = {
#     env = "Dev"
#   }
# #   wait_for_rbac_before_secret_operations = {
# #     create = "60s"
# #   }
# }


# module "keyvault" {
#   source              = "./modules/kv"
#   name                = "kv-my-app-${random_string.this.result}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   principal_id       = azurerm_user_assigned_identity.storage_msi.principal_id
# }
