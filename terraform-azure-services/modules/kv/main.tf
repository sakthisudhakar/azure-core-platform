resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = var.sku_name
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled
  enable_rbac_authorization   = true
  tags                        = var.tags
}


resource "azurerm_key_vault_key" "cmk" {
  name         = "storage-cmk-key"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
}

resource "azurerm_role_assignment" "storage_key_permission" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = var.principal_id
}