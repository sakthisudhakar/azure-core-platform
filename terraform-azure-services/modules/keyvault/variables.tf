variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Key Vault."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters long and can only contain letters, numbers and dashes."
  }
  validation {
    error_message = "The name must not contain two consecutive dashes"
    condition     = !can(regex("--", var.name))
  }
  validation {
    error_message = "The name must start with a letter"
    condition     = can(regex("^[a-zA-Z]", var.name))
  }
  validation {
    error_message = "The name must end with a letter or number"
    condition     = can(regex("[a-zA-Z0-9]$", var.name))
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.tenant_id))
    error_message = "The tenant ID must be a valid GUID. Letters must be lowercase."
  }
}

variable "contacts" {
  type = map(object({
    email = string
    name  = optional(string, null)
    phone = optional(string, null)
  }))
  default     = {}
  description = "A map of contacts for the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
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

variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault."
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
}

variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault."
}

variable "keys" {
  type = map(object({
    name     = string
    key_type = string
    key_opts = optional(list(string), ["sign", "verify"])

    key_size        = optional(number, null)
    curve           = optional(string, null)
    not_before_date = optional(string, null)
    expiration_date = optional(string, null)
    tags            = optional(map(any), null)

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

    rotation_policy = optional(object({
      automatic = optional(object({
        time_after_creation = optional(string, null)
        time_before_expiry  = optional(string, null)
      }), null)
      expire_after         = optional(string, null)
      notify_before_expiry = optional(string, null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of keys to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - The name of the key.
- `key_type` - The type of the key. Possible values are `EC` and `RSA`.
- `key_opts` - A list of key options. Possible values are `decrypt`, `encrypt`, `sign`, `unwrapKey`, `verify`, and `wrapKey`.
- `key_size` - The size of the key. Required for `RSA` keys.
- `curve` - The curve of the key. Required for `EC` keys.  Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. The API will default to `P-256` if nothing is specified.
- `not_before_date` - The not before date of the key.
- `expiration_date` - The expiration date of the key.
- `tags` - A mapping of tags to assign to the key.
- `rotation_policy` - The rotation policy of the key.
  - `automatic` - The automatic rotation policy of the key.
    - `time_after_creation` - The time after creation of the key before it is automatically rotated.
    - `time_before_expiry` - The time before expiry of the key before it is automatically rotated.
  - `expire_after` - The time after which the key expires.
  - `notify_before_expiry` - The time before expiry of the key when notification emails will be sent.

Supply role assignments in the same way as for `var.role_assignments`.
DESCRIPTION
  nullable    = false
}

variable "legacy_access_policies" {
  type = map(object({
    object_id               = string
    application_id          = optional(string, null)
    certificate_permissions = optional(set(string), [])
    key_permissions         = optional(set(string), [])
    secret_permissions      = optional(set(string), [])
    storage_permissions     = optional(set(string), [])
  }))
  default     = {}
  description = <<DESCRIPTION
A map of legacy access policies to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

Requires `var.legacy_access_policies_enabled` to be `true`.

- `object_id` - (Required) The object ID of the principal to assign the access policy to.
- `application_id` - (Optional) The object ID of an Application in Azure Active Directory. Changing this forces a new resource to be created.
- `certifiate_permissions` - (Optional) A list of certificate permissions. Possible values are: `Backup`, `Create`, `Delete`, `DeleteIssuers`, `Get`, `GetIssuers`, `Import`, `List`, `ListIssuers`, `ManageContacts`, `ManageIssuers`, `Purge`, `Recover`, `Restore`, `SetIssuers`, and `Update`.
- `key_permissions` - (Optional) A list of key permissions. Possible value are: `Backup`, `Create`, `Decrypt`, `Delete`, `Encrypt`, `Get`, `Import`, `List`, `Purge`, `Recover`, `Restore`, `Sign`, `UnwrapKey`, `Update`, `Verify`, `WrapKey`, `Release`, `Rotate`, `GetRotationPolicy`, and `SetRotationPolicy`.
- `secret_permissions` - (Optional) A list of secret permissions. Possible values are: `Backup`, `Delete`, `Get`, `List`, `Purge`, `Recover`, `Restore`, and `Set`.
- `storage_permissions` - (Optional) A list of storage permissions. Possible values are: `Backup`, `Delete`, `DeleteSAS`, `Get`, `GetSAS`, `List`, `ListSAS`, `Purge`, `Recover`, `RegenerateKey`, `Restore`, `Set`, `SetSAS`, and `Update`.
DESCRIPTION
  nullable    = false

  validation {
    error_message = "Object ID must be a valid GUID."
    condition     = alltrue([for _, v in var.legacy_access_policies : can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", v.object_id))])
  }
  validation {
    error_message = "Application ID must be null or a valid GUID."
    condition     = alltrue([for _, v in var.legacy_access_policies : v.application_id == null || can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", v.application_id))])
  }
  validation {
    error_message = "Certificate permissions must be a set composed of: `Backup`, `Create`, `Delete`, `DeleteIssuers`, `Get`, `GetIssuers`, `Import`, `List`, `ListIssuers`, `ManageContacts`, `ManageIssuers`, `Purge`, `Recover`, `Restore`, `SetIssuers`, and `Update`."
    condition     = alltrue([for _, v in var.legacy_access_policies : setintersection(["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"], v.certificate_permissions) == v.certificate_permissions])
  }
  validation {
    error_message = "Key permissions must be a set composed of: `Backup`, `Create`, `Decrypt`, `Delete`, `Encrypt`, `Get`, `Import`, `List`, `Purge`, `Recover`, `Restore`, `Sign`, `UnwrapKey`, `Update`, `Verify`, `WrapKey`, `Release`, `Rotate`, `GetRotationPolicy`, and `SetRotationPolicy`."
    condition     = alltrue([for _, v in var.legacy_access_policies : setintersection(["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"], v.key_permissions) == v.key_permissions])
  }
  validation {
    error_message = "Secret permissions must be a set composed of: `Backup`, `Delete`, `Get`, `List`, `Purge`, `Recover`, `Restore`, and `Set`."
    condition     = alltrue([for _, v in var.legacy_access_policies : setintersection(["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"], v.secret_permissions) == v.secret_permissions])
  }
  validation {
    error_message = "Storage permissions must be a set composed of: `Backup`, `Delete`, `DeleteSAS`, `Get`, `GetSAS`, `List`, `ListSAS`, `Purge`, `Recover`, `RegenerateKey`, `Restore`, `Set`, `SetSAS`, and `Update`."
    condition     = alltrue([for _, v in var.legacy_access_policies : setintersection(["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"], v.storage_permissions) == v.storage_permissions])
  }
  validation {
    error_message = "At least one permission must be set."
    condition     = alltrue([for _, v in var.legacy_access_policies : length(v.certificate_permissions) + length(v.key_permissions) + length(v.secret_permissions) + length(v.storage_permissions) > 0])
  }
}

variable "legacy_access_policies_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether legacy access policies are enabled for this Key Vault. Prevents use of Azure RBAC for data plane."
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "The lock level to apply to the Key Vault. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "network_acls" {
  type = object({
    bypass                     = optional(string, "None")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
The network ACL configuration for the Key Vault.
If not specified then the Key Vault will be created with a firewall that blocks access.
Specify `null` to create the Key Vault with no firewall.

- `bypass` - (Optional) Should Azure Services bypass the ACL. Possible values are `AzureServices` and `None`. Defaults to `None`.
- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
- `virtual_network_subnet_ids` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the Key Vault. Defaults to `[]`.
DESCRIPTION

  validation {
    condition     = var.network_acls == null ? true : contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "The bypass value must be either `AzureServices` or `None`."
  }
  validation {
    condition     = var.network_acls == null ? true : contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
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
A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
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

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether public access is permitted."
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled."
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
A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. If you are using a condition, valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "secrets" {
  type = map(object({
    name            = string
    content_type    = optional(string, null)
    tags            = optional(map(any), null)
    not_before_date = optional(string, null)
    expiration_date = optional(string, null)

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
  }))
  default     = {}
  description = <<DESCRIPTION
A map of secrets to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - The name of the secret.
- `content_type` - The content type of the secret.
- `tags` - A mapping of tags to assign to the secret.
- `not_before_date` - The not before date of the secret.
- `expiration_date` - The expiration date of the secret.

Supply role assignments in the same way as for `var.role_assignments`.

> Note: the `value` of the secret is supplied via the `var.secrets_value` variable. Make sure to use the same map key.
DESCRIPTION
  nullable    = false
}

variable "secrets_value" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
A map of secret keys to values.
The map key is the supplied input to `var.secrets`.
The map value is the secret value.

This is a separate variable to `var.secrets` because it is sensitive and therefore cannot be used in a `for_each` loop.
DESCRIPTION
  sensitive   = true
}

variable "sku_name" {
  type        = string
  default     = "premium"
  description = "The SKU name of the Key Vault. Default is `premium`. Possible values are `standard` and `premium`."

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The SKU name must be either `standard` or `premium`."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = null
  description = <<DESCRIPTION
The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days.
DESCRIPTION

  validation {
    condition     = var.soft_delete_retention_days == null ? true : var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Value must be between 7 and 90."
  }
  validation {
    condition     = var.soft_delete_retention_days == null ? true : ceil(var.soft_delete_retention_days) == var.soft_delete_retention_days
    error_message = "Value must be an integer."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of tags to assign to the Key Vault resource."
}

variable "wait_for_rbac_before_contact_operations" {
  type = object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
  default     = {}
  description = <<DESCRIPTION
This variable controls the amount of time to wait before performing contact operations.
It only applies when `var.role_assignments` and `var.contacts` are both set.
This is useful when you are creating role assignments on the key vault and immediately creating keys in it.
The default is 30 seconds for create and 0 seconds for destroy.
DESCRIPTION
}

variable "wait_for_rbac_before_key_operations" {
  type = object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
  default     = {}
  description = <<DESCRIPTION
This variable controls the amount of time to wait before performing key operations.
It only applies when `var.role_assignments` and `var.keys` are both set.
This is useful when you are creating role assignments on the key vault and immediately creating keys in it.
The default is 30 seconds for create and 0 seconds for destroy.
DESCRIPTION
}

variable "wait_for_rbac_before_secret_operations" {
  type = object({
    create  = optional(string, "30s")
    destroy = optional(string, "0s")
  })
  default     = {}
  description = <<DESCRIPTION
This variable controls the amount of time to wait before performing secret operations.
It only applies when `var.role_assignments` and `var.secrets` are both set.
This is useful when you are creating role assignments on the key vault and immediately creating secrets in it.
The default is 30 seconds for create and 0 seconds for destroy.
DESCRIPTION
  nullable    = false
}

# variable "key_vault_resource_id" {
#   type        = string
#   description = "The ID of the Key Vault where the key should be created."
#   nullable    = false

#   validation {
#     error_message = "Value must be a valid Azure Key Vault resource ID."
#     condition     = can(regex("\\/subscriptions\\/[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}\\/resourceGroups\\/[^\\/]+\\/providers\\/Microsoft.KeyVault\\/vaults\\/[^\\/]+$", var.key_vault_resource_id))
#   }
# }

# variable "name" {
#   type        = string
#   description = "The name of the key."
#   nullable    = false
# }

# variable "type" {
#   type        = string
#   description = "The type of the key. Possible values are `EC` and `RSA`."
#   nullable    = false
# }

# variable "curve" {
#   type        = string
#   default     = null
#   description = "The curve of the EC key. Required if `type` is `EC`. Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. This field will be required in a future release if key_type is EC or EC-HSM. The API will default to `P-256` if nothing is specified."
# }

# variable "expiration_date" {
#   type        = string
#   default     = null
#   description = "The expiration date of the key as a UTC datetime (Y-m-d'T'H:M:S'Z')."

#   validation {
#     error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
#     condition     = var.expiration_date == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.expiration_date))
#   }
# }

# variable "not_before_date" {
#   type        = string
#   default     = null
#   description = "key not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z')."

#   validation {
#     error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
#     condition     = var.not_before_date == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.not_before_date))
#   }
# }

# variable "opts" {
#   type        = list(string)
#   default     = []
#   description = "The options to apply to the key. Possible values are `decrypt`, `encrypt`, `sign`, `wrapKey`, `unwrapKey`, and `verify`."
# }

# variable "role_assignments" {
#   type = map(object({
#     role_definition_id_or_name             = string
#     principal_id                           = string
#     description                            = optional(string, null)
#     skip_service_principal_aad_check       = optional(bool, false)
#     condition                              = optional(string, null)
#     condition_version                      = optional(string, null)
#     delegated_managed_identity_resource_id = optional(string, null)
#     principal_type                         = optional(string, null)
#   }))
#   default     = {}
#   description = <<DESCRIPTION
# A map of role assignments to create on the key. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

# - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
# - `principal_id` - The ID of the principal to assign the role to.
# - `description` - The description of the role assignment.
# - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
# - `condition` - The condition which will be used to scope the role assignment.
# - `condition_version` - The version of the condition syntax. If you are using a condition, valid values are '2.0'.

# > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
# DESCRIPTION
#   nullable    = false
# }

# variable "rotation_policy" {
#   type = object({
#     automatic = optional(object({
#       time_after_creation = optional(string, null)
#       time_before_expiry  = optional(string, null)
#     }), null)
#     expire_after         = optional(string, null)
#     notify_before_expiry = optional(string, null)
#   })
#   default     = null
#   description = <<DESCRIPTION
# The rotation policy of the key:

# - `automatic` - The automatic rotation policy of the key.
#   - `time_after_creation` - The time after creation of the key before it is automatically rotated as an ISO 8601 duration.
#   - `time_before_expiry` - The time before expiry of the key before it is automatically rotated as an ISO 8601 duration.
# - `expire_after` - The time after which the key expires.
# - `notify_before_expiry` - The time before expiry of the key when notification emails will be sent as an ISO 8601 duration.
# DESCRIPTION
# }

# variable "size" {
#   type        = number
#   default     = null
#   description = "The size of the RSA key. Required if `type` is `RSA` or `RSA-HSM`."
# }

# variable "tags" {
#   type        = map(string)
#   default     = null
#   description = "The tags to assign to the key."
# }

# variable "key_vault_resource_id" {
#   type        = string
#   description = "The ID of the Key Vault where the secret should be created."
#   nullable    = false

#   validation {
#     error_message = "Value must be a valid Azure Key Vault resource ID."
#     condition     = can(regex("\\/subscriptions\\/[a-f\\d]{4}(?:[a-f\\d]{4}-){4}[a-f\\d]{12}\\/resourceGroups\\/[^\\/]+\\/providers\\/Microsoft.KeyVault\\/vaults\\/[^\\/]+$", var.key_vault_resource_id))
#   }
# }

# variable "name" {
#   type        = string
#   description = "The name of the secret."
#   nullable    = false

#   validation {
#     error_message = "Secret names may only contain alphanumerics and hyphens, and be between 1 and 127 characters in length."
#     condition     = can(regex("^[A-Za-z0-9-]{1,127}$", var.name))
#   }
# }

# variable "value" {
#   type        = string
#   description = "The value for the secret."
#   sensitive   = true
# }

# variable "content_type" {
#   type        = string
#   default     = null
#   description = "The content type of the secret."
# }

# variable "expiration_date" {
#   type        = string
#   default     = null
#   description = "The expiration date of the secret as a UTC datetime (Y-m-d'T'H:M:S'Z')."

#   validation {
#     error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
#     condition     = var.expiration_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.expiration_date))
#   }
# }

# variable "not_before_date" {
#   type        = string
#   default     = null
#   description = "Secret not usable before as a UTC datetime (Y-m-d'T'H:M:S'Z')."

#   validation {
#     error_message = "Value must be a UTC datetime (Y-m-d'T'H:M:S'Z')."
#     condition     = var.not_before_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.not_before_date))
#   }
# }

# variable "role_assignments" {
#   type = map(object({
#     role_definition_id_or_name             = string
#     principal_id                           = string
#     description                            = optional(string, null)
#     skip_service_principal_aad_check       = optional(bool, false)
#     condition                              = optional(string, null)
#     condition_version                      = optional(string, null)
#     delegated_managed_identity_resource_id = optional(string, null)
#     principal_type                         = optional(string, null)
#   }))
#   default     = {}
#   description = <<DESCRIPTION
# A map of role assignments to create on the secret. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

# - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
# - `principal_id` - The ID of the principal to assign the role to.
# - `description` - The description of the role assignment.
# - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
# - `condition` - The condition which will be used to scope the role assignment.
# - `condition_version` - The version of the condition syntax. If you are using a condition, valid values are '2.0'.

# > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
# DESCRIPTION
#   nullable    = false
# }


# variable "create_secret" {
#   type        = bool
#   default     = false
#   description = "Whether to create a key in the Key Vault. If set to false, no key will be created."
# }

# variable "tags" {
#   type        = map(string)
#   default     = null
#   description = "The tags to assign to the secret."
# }

# variable "create_key {
#   type        = bool
#   default     = false
#   description = "Whether to create a key in the Key Vault. If set to false, no key will be created."  
# }

# variable "create_secret" {
#   type        = bool
#   default     = false
#   description = "Whether to create a secret in the Key Vault. If set to false, no secret will be created."
# }