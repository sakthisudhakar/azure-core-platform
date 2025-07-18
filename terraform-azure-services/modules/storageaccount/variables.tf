variable "location" {
  type        = string
  description = <<DESCRIPTION
Azure region where the resource should be deployed.
If null, the location will be inferred from the resource group location.
DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the resource."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters, valid characters are lowercase letters and numbers."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
    Defines a customer managed key to use for encryption.

    object({
      key_vault_resource_id              = (Required) - The full Azure Resource ID of the key_vault where the customer managed key will be referenced from.
      key_name                           = (Required) - The key name for the customer managed key in the key vault.
      key_version                        = (Optional) - The version of the key to use
      user_assigned_identity_resource_id = (Optional) - The user assigned identity to use when access the key vault
    })

    Example Inputs:
    ```terraform
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/0000000-0000-0000-0000-000000000000/resourceGroups/test-resource-group/providers/Microsoft.KeyVault/vaults/example-key-vault"
      key_name              = "sample-customer-key"
    }
    ```
   DESCRIPTION
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = string
  })
  default     = null
  description = "The lock level to apply. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `subresource_name` - The service name of the private endpoint.  Possible value are `blob`, 'dfs', 'file', `queue`, `table`, and `web`.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Custom tags to apply to the resource."
}

variable "blob_properties" {
  type = object({
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool)
    versioning_enabled            = optional(bool, true)
    container_delete_retention_policy = optional(object({
      days = optional(number, 7)

    }), { days = 7 })

    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), { days = 7 })
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      resource_id                              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    restore_policy = optional(object({
      days = number
    }))
  })
  default     = null
  description = <<-EOT
 - `change_feed_enabled` - (Optional) Is the blob service properties for change feed events enabled? Default to `false`.
 - `change_feed_retention_in_days` - (Optional) The duration of change feed events retention in days. The possible values are between 1 and 146000 days (400 years). Setting this to null (or omit this in the configuration file) indicates an infinite retention of the change feed.
 - `default_service_version` - (Optional) The API Version which should be used by default for requests to the Data Plane API if an incoming request doesn't specify an API Version.
 - `last_access_time_enabled` - (Optional) Is the last access time based tracking enabled? Default to `false`.
 - `versioning_enabled` - (Optional) Is versioning enabled? Default to `false`.

 ---
 `container_delete_retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the container should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `delete_retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the blob should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `diagnostic_settings` block supports the following:
 - `name` - (Optional) The name of the diagnostic setting. Defaults to `null`.
 - `log_categories` - (Optional) A set of log categories to enable. Defaults to an empty set.
 - `log_groups` - (Optional) A set of log groups to enable. Defaults to `["allLogs"]`.
 - `metric_categories` - (Optional) A set of metric categories to enable. Defaults to `["AllMetrics"]`.
 - `log_analytics_destination_type` - (Optional) The destination type for log analytics. Defaults to `"Dedicated"`.
 - `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace. Defaults to `null`.
 - `resource_id` - (Optional) The resource ID of the target resource for diagnostics. Defaults to `null`.
 - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the Event Hub authorization rule. Defaults to `null`.
 - `event_hub_name` - (Optional) The name of the Event Hub. Defaults to `null`.
 - `marketplace_partner_resource_id` - (Optional) The resource ID of the marketplace partner. Defaults to `null`.

 ---
 `restore_policy` block supports the following:
 - `days` - (Required) Specifies the number of days that the blob can be restored, between `1` and `365` days. This must be less than the `days` specified for `delete_retention_policy`.
EOT
}

variable "containers" {
  type = map(object({
    public_access                  = optional(string, "None")
    metadata                       = optional(map(string))
    name                           = string
    default_encryption_scope       = optional(string)
    deny_encryption_scope_override = optional(bool)
    enable_nfs_v3_all_squash       = optional(bool)
    enable_nfs_v3_root_squash      = optional(bool)
    immutable_storage_with_versioning = optional(object({
      enabled = bool
    }))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `container_access_type` - (Optional) The Access Level configured for this Container. Possible values are `Blob`, `Container` or `None`. Defaults to `None`.
 - `metadata` - (Optional) A mapping of MetaData for this Container. All metadata keys should be lowercase.
 - `name` - (Required) The name of the Container which should be created within the Storage Account. Changing this forces a new resource to be created.

 Supply role assignments in the same way as for `var.role_assignments`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Container.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Container.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Container.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Container.
EOT
  nullable    = false
}

variable "immutability_policy" {
  type = object({
    allow_protected_append_writes = bool
    period_since_creation_in_days = number
    state                         = string
  })
  default     = null
  description = <<-EOT
 - `allow_protected_append_writes` - (Required) When enabled, new blocks can be written to an append blob while maintaining immutability protection and compliance. Only new blocks can be added and any existing blocks cannot be modified or deleted.
 - `period_since_creation_in_days` - (Required) The immutability period for the blobs in the container since the policy creation, in days.
 - `state` - (Required) Defines the mode of the policy. `Disabled` state disables the policy, `Unlocked` state allows increase and decrease of immutability retention time and also allows toggling allowProtectedAppendWrites property, `Locked` state only allows the increase of the immutability retention time. A policy can only be created in a Disabled or Unlocked state and can be toggled between the two states. Only a policy in an Unlocked state can transition to a Locked state which cannot be reverted.
EOT
}

variable "is_hns_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2 ([see here for more information](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-quickstart-create-account/)). Changing this forces a new resource to be created."
}

variable "access_tier" {
  type        = string
  default     = "Hot"
  description = "(Optional) Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot, Cool, Cold and Premium. Defaults to Hot."

  validation {
    condition     = contains(["Hot", "Cool", "Premium", "Cold"], var.access_tier)
    error_message = "Invalid value for access tier. Valid options are 'Hot', 'Cool','Premium' or 'Cold'."
  }
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "(Optional) Defines the Kind of account. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`."

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Invalid value for account kind. Valid options are `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage` and `StorageV2`. Defaults to `StorageV2`."
  }
}

variable "account_replication_type" {
  type        = string
  default     = "ZRS"
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`.  Defaults to `ZRS`"
  nullable    = false

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid value for replication type. Valid options are `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS` and `RAGZRS`."
  }
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "(Required) Defines the Tier to use for this storage account. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Invalid value for account tier. Valid options are `Standard` and `Premium`. For `BlockBlobStorage` and `FileStorage` accounts only `Premium` is valid. Changing this forces a new resource to be created."
  }
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "(Optional) Allow or disallow nested items within this Account to opt into being public. Defaults to `false`."
}

variable "allowed_copy_scope" {
  type        = string
  default     = null
  description = "(Optional) Restrict copy to and from Storage Accounts within an AAD tenant or with Private Links to the same VNet. Possible values are `AAD` and `PrivateLink`."
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Should cross Tenant replication be enabled? Defaults to `false`."
}

variable "custom_domain" {
  type = object({
    name          = string
    use_subdomain = optional(bool)
  })
  default     = null
  description = <<-EOT
 - `name` - (Required) The Custom Domain Name to use for the Storage Account, which will be validated by Azure.
 - `use_subdomain` - (Optional) Should the Custom Domain Name be validated by using indirect CNAME validation?
EOT
}

variable "default_to_oauth_authentication" {
  type        = bool
  default     = null
  description = "(Optional) Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account. The default value is `false`"
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Storage Account should exist. Changing this forces a new Storage Account to be created."
}

variable "https_traffic_only_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag which forces HTTPS if enabled, see [here](https://docs.microsoft.com/azure/storage/storage-require-secure-transfer/) for more information. Defaults to `true`."
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is infrastructure encryption enabled? Changing this forces a new resource to be created. Defaults to `false`."
}

variable "local_user" {
  type = map(object({
    home_directory       = optional(string)
    name                 = string
    ssh_key_enabled      = optional(bool)
    ssh_password_enabled = optional(bool)
    permission_scope = optional(list(object({
      resource_name = string
      service       = string
      permissions = object({
        create = optional(bool)
        delete = optional(bool)
        list   = optional(bool)
        read   = optional(bool)
        write  = optional(bool)
      })
    })))
    ssh_authorized_key = optional(list(object({
      description = optional(string)
      key         = string
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `home_directory` - (Optional) The home directory of the Storage Account Local User.
 - `name` - (Required) The name which should be used for this Storage Account Local User. Changing this forces a new Storage Account Local User to be created.
 - `ssh_key_enabled` - (Optional) Specifies whether SSH Key Authentication is enabled. Defaults to `false`.
 - `ssh_password_enabled` - (Optional) Specifies whether SSH Password Authentication is enabled. Defaults to `false`.

 ---
 `permission_scope` block supports the following:
 - `resource_name` - (Required) The container name (when `service` is set to `blob`) or the file share name (when `service` is set to `file`), used by the Storage Account Local User.
 - `service` - (Required) The storage service used by this Storage Account Local User. Possible values are `blob` and `file`.

 ---
 `permissions` block supports the following:
 - `create` - (Optional) Specifies if the Local User has the create permission for this scope. Defaults to `false`.
 - `delete` - (Optional) Specifies if the Local User has the delete permission for this scope. Defaults to `false`.
 - `list` - (Optional) Specifies if the Local User has the list permission for this scope. Defaults to `false`.
 - `read` - (Optional) Specifies if the Local User has the read permission for this scope. Defaults to `false`.
 - `write` - (Optional) Specifies if the Local User has the write permission for this scope. Defaults to `false`.

 ---
 `ssh_authorized_key` block supports the following:
 - `description` - (Optional) The description of this SSH authorized key.
 - `key` - (Required) The public key value of this SSH authorized key.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Account Local User.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Account Local User.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account Local User.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Account Local User.
EOT
  nullable    = false
}

variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "(Optional) The minimum supported TLS version for the storage account. Possible values are `TLS1_0`, `TLS1_1`, and `TLS1_2`. Defaults to `TLS1_2` for new storage accounts."
}

variable "network_rules" {
  type = object({
    bypass                     = optional(set(string), ["AzureServices"])
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = {}
  description = <<-EOT
 > Note the default value for this variable will block all public access to the storage account. If you want to disable all network rules, set this value to `null`.

 - `bypass` - (Optional) Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of `Logging`, `Metrics`, `AzureServices`, or `None`.
 - `default_action` - (Required) Specifies the default action of allow or deny when no other rules match. Valid options are `Deny` or `Allow`.
 - `ip_rules` - (Optional) List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed. Private IP address ranges (as defined in [RFC 1918](https://tools.ietf.org/html/rfc1918#section-3)) are not allowed.
 - `storage_account_id` - (Required) Specifies the ID of the storage account. Changing this forces a new resource to be created.
 - `virtual_network_subnet_ids` - (Optional) A list of virtual network subnet ids to secure the storage account.

 ---
 `private_link_access` block supports the following:
 - `endpoint_resource_id` - (Required) The resource id of the resource access rule to be granted access.
 - `endpoint_tenant_id` - (Optional) The tenant id of the resource of the resource access rule to be granted access. Defaults to the current tenant id.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 60 minutes) Used when creating the  Network Rules for this Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Network Rules for this Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Network Rules for this Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Network Rules for this Storage Account.
EOT
}

variable "nfsv3_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to `false`."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether the public network access is enabled? Defaults to `false`."
}

variable "routing" {
  type = object({
    choice                      = optional(string, "MicrosoftRouting")
    publish_internet_endpoints  = optional(bool, false)
    publish_microsoft_endpoints = optional(bool, false)
  })
  default     = null
  description = <<-EOT
 - `choice` - (Optional) Specifies the kind of network routing opted by the user. Possible values are `InternetRouting` and `MicrosoftRouting`. Defaults to `MicrosoftRouting`.
 - `publish_internet_endpoints` - (Optional) Should internet routing storage endpoints be published? Defaults to `false`.
 - `publish_microsoft_endpoints` - (Optional) Should Microsoft routing storage endpoints be published? Defaults to `false`.
EOT
}

variable "sas_policy" {
  type = object({
    expiration_action = optional(string, "Log")
    expiration_period = string
  })
  default     = null
  description = <<-EOT
 - `expiration_action` - (Optional) The SAS expiration action. The only possible value is `Log` at this moment. Defaults to `Log`.
 - `expiration_period` - (Required) The SAS expiration period in format of `DD.HH:MM:SS`.
EOT
}

variable "sftp_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, enable SFTP for the storage account.  Defaults to `false`."
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is `false`."
}

variable "static_website" {
  type = map(object({
    error_404_document = optional(string)
    index_document     = optional(string)
  }))
  default     = null
  description = <<-EOT
 - `error_404_document` - (Optional) The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file.
 - `index_document` - (Optional) The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive.
EOT
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Storage Account.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Storage Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account.
 - `update` - (Defaults to 60 minutes) Used when updating the Storage Account.
EOT
}

variable "azure_files_authentication" {
  type = object({
    directory_type                 = optional(string, "AADKERB")
    default_share_level_permission = optional(string)

    active_directory = optional(object({
      domain_guid         = string
      domain_name         = string
      domain_sid          = string
      forest_name         = string
      netbios_domain_name = string
      storage_sid         = string
    }))
  })
  default     = null
  description = <<-EOT
 - `directory_type` - (Required) Specifies the directory service used. Possible values are `AADDS`, `AD` and `AADKERB`.
 - `default_share_level_permission` - (Optional) Specifies the default share level permissions applied to all users. Possible values are StorageFileDataSmbShareReader, StorageFileDataSmbShareContributor, StorageFileDataSmbShareElevatedContributor, or None.

 ---
 `active_directory` block supports the following:
 - `domain_guid` - (Required) Specifies the domain GUID.
 - `domain_name` - (Required) Specifies the primary domain that the AD DNS server is authoritative for.
 - `domain_sid` - (Required) Specifies the security identifier (SID).
 - `forest_name` - (Required) Specifies the Active Directory forest.
 - `netbios_domain_name` - (Required) Specifies the NetBIOS domain name.
 - `storage_sid` - (Required) Specifies the security identifier (SID) for Azure Storage.
EOT
}

variable "large_file_share_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is Large File Share Enabled?"
}

variable "share_properties" {
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    diagnostic_settings = optional(map(object({
      name                                     = optional(string, null)
      log_categories                           = optional(set(string), [])
      log_groups                               = optional(set(string), ["allLogs"])
      metric_categories                        = optional(set(string), ["AllMetrics"])
      log_analytics_destination_type           = optional(string, "Dedicated")
      workspace_resource_id                    = optional(string, null)
      resource_id                              = optional(string, null)
      event_hub_authorization_rule_resource_id = optional(string, null)
      event_hub_name                           = optional(string, null)
      marketplace_partner_resource_id          = optional(string, null)
    })), {})
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      authentication_types            = optional(set(string))
      channel_encryption_type         = optional(set(string))
      kerberos_ticket_encryption_type = optional(set(string))
      multichannel_enabled            = optional(bool)
      versions                        = optional(set(string))
    }))
  })
  default     = null
  description = <<-EOT

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `diagnostic_settings` block supports the following:
 - `name` - (Optional) The name of the diagnostic setting. Defaults to `null`.
 - `log_categories` - (Optional) A set of log categories to enable. Defaults to an empty set.
 - `log_groups` - (Optional) A set of log groups to enable. Defaults to `["allLogs"]`.
 - `metric_categories` - (Optional) A set of metric categories to enable. Defaults to `["AllMetrics"]`.
 - `log_analytics_destination_type` - (Optional) The destination type for log analytics. Defaults to `"Dedicated"`.
 - `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace. Defaults to `null`.
 - `resource_id` - (Optional) The resource ID of the target resource for diagnostics. Defaults to `null`.
 - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the Event Hub authorization rule. Defaults to `null`.
 - `event_hub_name` - (Optional) The name of the Event Hub. Defaults to `null`.
 - `marketplace_partner_resource_id` - (Optional) The resource ID of the marketplace partner. Defaults to `null`.

 ---
 `retention_policy` block supports the following:
 - `days` - (Optional) Specifies the number of days that the `azurerm_shares` should be retained, between `1` and `365` days. Defaults to `7`.

 ---
 `smb` block supports the following:
 - `authentication_types` - (Optional) A set of SMB authentication methods. Possible values are `NTLMv2`, and `Kerberos`.
 - `channel_encryption_type` - (Optional) A set of SMB channel encryption. Possible values are `AES-128-CCM`, `AES-128-GCM`, and `AES-256-GCM`.
 - `kerberos_ticket_encryption_type` - (Optional) A set of Kerberos ticket encryption. Possible values are `RC4-HMAC`, and `AES-256`.
 - `multichannel_enabled` - (Optional) Indicates whether multichannel is enabled. Defaults to `false`. This is only supported on Premium storage accounts.
 - `versions` - (Optional) A set of SMB protocol versions. Possible values are `SMB2.1`, `SMB3.0`, and `SMB3.1.1`.
EOT
}

variable "shares" {
  type = map(object({
    access_tier      = optional(string)
    enabled_protocol = optional(string)
    metadata         = optional(map(string))
    name             = string
    quota            = number
    root_squash      = optional(string)
    signed_identifiers = optional(list(object({
      id = string
      access_policy = optional(object({
        expiry_time = string
        permission  = string
        start_time  = string
      }))
    })))
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `access_tier` - (Optional) The access tier of the File Share. Possible values are `Hot`, `Cool` and `TransactionOptimized`, `Premium`.
 - `enabled_protocol` - (Optional) The protocol used for the share. Possible values are `SMB` and `NFS`. The `SMB` indicates the share can be accessed by SMBv3.0, SMBv2.1 and REST. The `NFS` indicates the share can be accessed by NFSv4.1. Defaults to `SMB`. Changing this forces a new resource to be created.
 - `metadata` - (Optional) A mapping of MetaData for this File Share.
 - `name` - (Required) The name of the share. Must be unique within the storage account where the share is located. Changing this forces a new resource to be created.
 - `quota` - (Required) The maximum size of the share, in gigabytes. For Standard storage accounts, this must be `1`GB (or higher) and at most `5120` GB (`5` TB). For Premium FileStorage storage accounts, this must be greater than 100 GB and at most `102400` GB (`100` TB).

 ---
 `acl` block supports the following:
 - `id` - (Required) The ID which should be used for this Shared Identifier.

 ---
 `access_policy` block supports the following:
 - `expiry` - (Optional) The time at which this Access Policy should be valid until, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.
 - `permissions` - (Required) The permissions which should be associated with this Shared Identifier. Possible value is combination of `r` (read), `w` (write), `d` (delete), and `l` (list).
 - `start` - (Optional) The time at which this Access Policy should be valid from, in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) format.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Share.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Share.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Share.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Share.

Supply role assignments in the same way as for `var.role_assignments`.

EOT
  nullable    = false
}

variable "queue_encryption_key_type" {
  type        = string
  default     = null
  description = "(Optional) The encryption type of the queue service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`."
}

variable "queue_properties" {
  type = map(object({
    cors_rule = optional(map(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), {})
    # diagnostic_settings = optional(map(object({
    #   name                                     = optional(string, null)
    #   log_categories                           = optional(set(string), [])
    #   log_groups                               = optional(set(string), ["allLogs"])
    #   metric_categories                        = optional(set(string), ["AllMetrics"])
    #   log_analytics_destination_type           = optional(string, "Dedicated")
    #   workspace_resource_id                    = optional(string, null)
    #   resource_id                              = optional(string, null)
    #   event_hub_authorization_rule_resource_id = optional(string, null)
    #   event_hub_name                           = optional(string, null)
    #   marketplace_partner_resource_id          = optional(string, null)
    # })), {})
    hour_metrics = optional(object({
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
      version               = string
    }))
    logging = optional(object({
      delete                = bool
      read                  = bool
      retention_policy_days = optional(number)
      version               = string
      write                 = bool
    }))
    minute_metrics = optional(object({
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
      version               = string
    }))
  }))
  default     = {}
  description = <<-EOT

 ---
 `cors_rule` block supports the following:
 - `allowed_headers` - (Required) A list of headers that are allowed to be a part of the cross-origin request.
 - `allowed_methods` - (Required) A list of HTTP methods that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
 - `allowed_origins` - (Required) A list of origin domains that will be allowed by CORS.
 - `exposed_headers` - (Required) A list of response headers that are exposed to CORS clients.
 - `max_age_in_seconds` - (Required) The number of seconds the client should cache a preflight response.

 ---
 `diagnostic_settings` block supports the following:
 - `name` - (Optional) The name of the diagnostic setting. Defaults to `null`.
 - `log_categories` - (Optional) A set of log categories to enable. Defaults to an empty set.
 - `log_groups` - (Optional) A set of log groups to enable. Defaults to `["allLogs"]`.
 - `metric_categories` - (Optional) A set of metric categories to enable. Defaults to `["AllMetrics"]`.
 - `log_analytics_destination_type` - (Optional) The destination type for log analytics. Defaults to `"Dedicated"`.
 - `workspace_resource_id` - (Optional) The resource ID of the Log Analytics workspace. Defaults to `null`.
 - `resource_id` - (Optional) The resource ID of the target resource for diagnostics. Defaults to `null`.
 - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the Event Hub authorization rule. Defaults to `null`.
 - `event_hub_name` - (Optional) The name of the Event Hub. Defaults to `null`.
 - `marketplace_partner_resource_id` - (Optional) The resource ID of the marketplace partner. Defaults to `null`.

 ---
 `hour_metrics` block supports the following:
 - `enabled` - (Required) Indicates whether hour metrics are enabled for the Queue service.
 - `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.

 ---
 `logging` block supports the following:
 - `delete` - (Required) Indicates whether all delete requests should be logged.
 - `read` - (Required) Indicates whether all read requests should be logged.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.
 - `write` - (Required) Indicates whether all write requests should be logged.

 ---
 `minute_metrics` block supports the following:
 - `enabled` - (Required) Indicates whether minute metrics are enabled for the Queue service.
 - `include_apis` - (Optional) Indicates whether metrics should generate summary statistics for called API operations.
 - `retention_policy_days` - (Optional) Specifies the number of days that logs will be retained.
 - `version` - (Required) The version of storage analytics to configure.

EOT
}

variable "queues" {
  type = map(object({
    metadata = optional(map(string))
    name     = string
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `metadata` - (Optional) A mapping of MetaData which should be assigned to this Storage Queue.
 - `name` - (Required) The name of the Queue which should be created within the Storage Account. Must be unique within the storage account the queue is located. Changing this forces a new resource to be created.

Supply role assignments in the same way as for `var.role_assignments`.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Queue.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Queue.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Queue.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Queue.
EOT
  nullable    = false
}

variable "table_encryption_key_type" {
  type        = string
  default     = null
  description = "(Optional) The encryption type of the table service. Possible values are `Service` and `Account`. Changing this forces a new resource to be created. Default value is `Service`."
}

variable "tables" {
  type = map(object({
    name = string
    signed_identifiers = optional(list(object({
      id = string
      access_policy = optional(object({
        expiry_time = string
        permission  = string
        start_time  = string
      }))
    })))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
  default     = {}
  description = <<-EOT
 - `name` - (Required) The name of the storage table. Only Alphanumeric characters allowed, starting with a letter. Must be unique within the storage account the table is located. Changing this forces a new resource to be created.

 ---
 `acl` block supports the following:
 - `id` - (Required) The ID which should be used for this Shared Identifier.

 ---
 `access_policy` block supports the following:
 - `expiry` - (Required) The ISO8061 UTC time at which this Access Policy should be valid until.
 - `permissions` - (Required) The permissions which should associated with this Shared Identifier.
 - `start` - (Required) The ISO8061 UTC time at which this Access Policy should be valid from.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Table.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Table.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Table.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Table.

Supply role assignments in the same way as for `var.role_assignments`.

EOT
  nullable    = false
}

variable "storage_management_policy_rule" {
  type = map(object({
    enabled = bool
    name    = string
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
    filters = object({
      blob_types   = set(string)
      prefix_match = optional(set(string))
      match_blob_index_tag = optional(set(object({
        name      = string
        operation = optional(string)
        value     = string
      })))
    })
  }))
  default     = {}
  description = <<-EOT
 - `enabled` - (Required) Boolean to specify whether the rule is enabled.
 - `name` - (Required) The name of the rule. Rule name is case-sensitive. It must be unique within a policy.

 ---
 `actions` block supports the following:

 ---
 `base_blob` block supports the following:
 - `auto_tier_to_hot_from_cool_enabled` - (Optional) Whether a blob should automatically be tiered from cool back to hot if it's accessed again after being tiered to cool. Defaults to `false`.
 - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob. Must be between `0` and `99999`. Defaults to `-1`.
 - `delete_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to delete the blob. Must be between `0` and `99999`. Defaults to `-1`.
 - `delete_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to delete the blob. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_creation_greater_than` - (Optional) The age in days after creation to archive storage. Supports blob currently at Hot or Cool tier. Must be between `0` and`99999`. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between `0` and`99999`. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to archive storage. Supports blob currently at Hot or Cool tier. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cold_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cold_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cold storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cool_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cool storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cool_after_days_since_last_access_time_greater_than` - (Optional) The age in days after last access time to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.
 - `tier_to_cool_after_days_since_modification_greater_than` - (Optional) The age in days after last modification to tier blobs to cool storage. Supports blob currently at Hot tier. Must be between 0 and 99999. Defaults to `-1`.

 ---
 `snapshot` block supports the following:
 - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to archive storage. Must be between 0 and 99999. Defaults to `-1`.
 - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days after creation to tier blob snapshot to cool storage. Must be between 0 and 99999. Defaults to `-1`.
 - `delete_after_days_since_creation_greater_than` - (Optional) The age in days after creation to delete the blob snapshot. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.

 ---
 `version` block supports the following:
 - `change_tier_to_archive_after_days_since_creation` - (Optional) The age in days after creation to tier blob version to archive storage. Must be between 0 and 99999. Defaults to `-1`.
 - `change_tier_to_cool_after_days_since_creation` - (Optional) The age in days creation create to tier blob version to cool storage. Must be between 0 and 99999. Defaults to `-1`.
 - `delete_after_days_since_creation` - (Optional) The age in days after creation to delete the blob version. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_archive_after_days_since_last_tier_change_greater_than` - (Optional) The age in days after last tier change to the blobs to skip to be archved. Must be between 0 and 99999. Defaults to `-1`.
 - `tier_to_cold_after_days_since_creation_greater_than` - (Optional) The age in days after creation to cold storage. Supports blob currently at Hot tier. Must be between `0` and `99999`. Defaults to `-1`.

 ---
 `filters` block supports the following:
 - `blob_types` - (Required) An array of predefined values. Valid options are `blockBlob` and `appendBlob`.
 - `prefix_match` - (Optional) An array of strings for prefixes to be matched.

 ---
 `match_blob_index_tag` block supports the following:
 - `name` - (Required) The filter tag name used for tag based filtering for blob objects.
 - `operation` - (Optional) The comparison operator which is used for object comparison and filtering. Possible value is `==`. Defaults to `==`.
 - `value` - (Required) The filter tag value used for tag based filtering for blob objects.
EOT
  nullable    = false
}

variable "storage_management_policy_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the Storage Account Management Policy.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Storage Account Management Policy.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Storage Account Management Policy.
 - `update` - (Defaults to 30 minutes) Used when updating the Storage Account Management Policy.
EOT
}
