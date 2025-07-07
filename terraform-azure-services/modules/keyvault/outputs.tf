

output "keys_resource_ids" {
  description = "A map of key keys to resource ids."
  value = { for kk, kv in azurerm_key_vault_key.this : kk => {
    resource_id             = kv.id
    resource_versionless_id = kv.versionless_id
    id                      = kv.id
    versionless_id          = kv.versionless_id
    }
  }
}

output "name" {
  description = "The name of the key vault."
  value       = azurerm_key_vault.this.name
}

# output "private_endpoints" {
#   description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
#   value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
# }

output "resource_id" {
  description = "The Azure resource id of the key vault."
  value       = azurerm_key_vault.this.id
}



# output "id" {
#   description = "The Key Vault Key ID"
#   value       = azurerm_key_vault_key.this[each.key].id
# }



