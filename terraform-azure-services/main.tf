resource "azurerm_user_assigned_identity" "storage_msi" {
  name                = "msi-storage-keyvault"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "random_string" "this" {
  length = 4
}

module "storageaccount" {
  source = "./modules/storageaccount"

  location                 = var.location
  name                     = lower("storageaccount${random_string.this.result}")
  resource_group_name      = var.resource_group_name
  account_kind             = "StorageV2"
  account_replication_type = "ZRS" # zone-redunant storage
  account_tier             = "Standard"
  https_traffic_only_enabled = true
  min_tls_version = "TLS1_2"
  public_network_access_enabled = false

  blob_properties = {
    versioning_enabled = true
  }
  containers = {
    blob_container0 = {
      name = "blob-container-${random_string.this.result}-0"
    }
  }
  infrastructure_encryption_enabled = true
  # customer_managed_key = {
  #   key_vault_resource_id  = module.avm_res_keyvault_vault.resource.id
  #   key_name               = azurerm_key_vault_key.example.name
  #   user_assigned_identity = { resource_id = azurerm_user_assigned_identity.example_identity.id }

  # }
  
  
  
  
  
  role_assignments = {
    # role_assignment_1 = {
    #   role_definition_id_or_name       = data.azurerm_role_definition.example.name
    #   principal_id                     = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
    #   skip_service_principal_aad_check = false
    # },
    role_assignment_2 = {
      role_definition_id_or_name       = "Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },

  }
  shared_access_key_enabled = true # Needed access key for the Splunk integration
#   shares = {
#     share0 = {
#       name  = "share-${random_string.this.result}-0"
#       quota = 10
#       signed_identifiers = [
#         {
#           id = "1"
#           access_policy = {
#             expiry_time = "2025-01-01T00:00:00Z"
#             permission  = "r"
#             start_time  = "2024-01-01T00:00:00Z"
#           }
#         }
#       ]
#     }
#     share1 = {
#       name        = "share-${random_string.this.result}-1"
#       quota       = 10
#       access_tier = "Hot"
#       metadata = {
#         key1 = "value1"
#         key2 = "value2"
#       }
#     }
#   }
  
  
  tags = {
    env   = "Dev"
  }
}




# /*

# azure_files_authentication = {
#     default_share_level_permission = "StorageFileDataSmbShareReader"
#     directory_type                 = "AADKERB"
#   }

#   managed_identities = {
#     system_assigned            = true
#     user_assigned_resource_ids = [azurerm_user_assigned_identity.example_identity.id]
#   }

#   network_rules = {
#     bypass                     = ["AzureServices"]
#     default_action             = "Deny"
#     ip_rules                   = [try(module.public_ip[0].public_ip, var.bypass_ip_cidr)]
#     virtual_network_subnet_ids = toset([azurerm_subnet.private.id])
#   }

# # allow_nested_items_to_be_public = false
  
#   queues = {
#     queue0 = {
#       name = "queue-${random_string.this.result}-0"

#     }
#     queue1 = {
#       name = "queue-${random_string.this.result}-1"

#       metadata = {
#         key1 = "value1"
#         key2 = "value2"
#       }
#     }
#   }

# tables = {
#     table0 = {
#       name = "table${random_string.this.result}0"
#       signed_identifiers = [
#         {
#           id = "1"
#           access_policy = {
#             expiry_time = "2025-01-01T00:00:00Z"
#             permission  = "r"
#             start_time  = "2024-01-01T00:00:00Z"
#           }
#         }
#       ]
#     }
#     table1 = {
#       name = "table${random_string.this.result}1"

#       signed_identifiers = [
#         {
#           id = "1"
#           access_policy = {
#             expiry_time = "2025-01-01T00:00:00Z"
#             permission  = "r"
#             start_time  = "2024-01-01T00:00:00Z"
#           }
#         }
#       ]
#     }
#     }

#   */