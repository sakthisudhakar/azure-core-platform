variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("[a-zA-Z][a-zA-Z0-9-]{0,48}[a-zA-Z0-9]$", var.name))
    error_message = "The name must be be between 2 and 50 characters, alphanumeric and hyphens.  The name must start with a letter, and may not start or end with a hyphen."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
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
  Customer Managed Key.
  DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
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
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "existing_parent_resource" {
  type = object({
    name = string
  })
  default     = null
  description = "If supplied, this event hub namespace resource will be used by child resources (e.g. event hubs), instead of creating a new event hub namespace."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

# tflint-ignore: terraform_unused_declarations
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
    subresource_name                        = string # NOTE: `subresource_name` can be excluded if the resource does not support multiple sub resource types (e.g. storage account supports blob, queue, etc)
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
    - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - (Optional) The description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    - `condition` - (Optional) The condition which will be used to scope the role assignment.
    - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
    - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
    - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `subresource_name` - The name of the sub resource for the private endpoint.
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
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "sku" {
  description = "Defines which tier to use for the Event Hub Namespace. Valid options are Basic, Standard, and Premium."
  type        = string
  default     = "Standard" # You can set a default value or leave it blank depending on your requirements
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The default_action value must be either `Basic`, `Standard`, or `Premium`."
  }
}

variable "capacity" {
  description = <<DESCRIPTION
Specifies the Capacity / Throughput Units for a Standard SKU namespace.
Default capacity has a maximum of 2, but can be increased in blocks of 2 on a committed purchase basis.
Defaults to 1.
DESCRIPTION
  type        = number
  default     = 1
}

variable "auto_inflate_enabled" {
  description = "Is Auto Inflate enabled for the EventHub Namespace?"
  type        = bool
  default     = false
}

variable "dedicated_cluster_id" {
  description = "Specifies the ID of the EventHub Dedicated Cluster where this Namespace should be created.  Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "maximum_throughput_units" {
  description = "Specifies the maximum number of throughput units when Auto Inflate is Enabled. Valid values range from 1 - 20."
  type        = number
  default     = null

  validation {
    condition     = var.maximum_throughput_units == null ? true : var.maximum_throughput_units < 1 || var.maximum_throughput_units > 20
    error_message = "Maximum throughput units must be in the range of 1 to 20"
  }
}

variable "local_authentication_enabled" {
  description = "Is SAS authentication enabled for the EventHub Namespace?.  Defaults to `false`."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Is public network access enabled for the EventHub Namespace?  Defaults to `false`."
  type        = bool
  default     = false
}

variable "network_rulesets" {
  type = object({
    default_action                 = optional(string, "Deny")
    public_network_access_enabled  = bool
    trusted_service_access_enabled = bool
    ip_rule = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      action  = optional(string, "Allow")
      ip_mask = string
    })), [])
    virtual_network_rule = optional(list(object({
      # since the `action` property only permits `Allow`, this is hard-coded.
      ignore_missing_virtual_network_service_endpoint = optional(bool)
      subnet_id                                       = string
    })), [])
  })
  default = null
  validation {
    condition     = var.network_rulesets == null ? true : contains(["Allow", "Deny"], var.network_rulesets.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
  description = <<DESCRIPTION
The network rule set configuration for the resource.
Requires Premium SKU.

- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rule` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
  - `action` - Only "Allow" is permitted
  - `ip_mask` - The CIDR block from which requests will match the rule.
- `virtual_network_rule` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the resource. Defaults to `[]`.
  - `ignore_missing_virtual_network_service_endpoint` - Are missing virtual network service endpoints ignored?
  - `subnet_id` - The subnet id from which requests will match the rule.

DESCRIPTION
}

variable "event_hubs" {
  type = map(object({
    namespace_name      = string
    resource_group_name = string
    partition_count     = number
    message_retention   = number
    capture_description = optional(object({
      enabled             = bool
      encoding            = string
      interval_in_seconds = optional(number)
      size_limit_in_bytes = optional(number)
      skip_empty_archives = optional(bool)
      destination = object({
        name                = optional(string, "EventHubArchive.AzureBlockBlob")
        archive_name_format = string
        blob_container_name = string
        storage_account_id  = string
      })
    }))
    status = optional(string)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
  default = {}

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : contains(["Avro", "AvroDeflate"], config.capture_description.encoding)
      )
    ])
    error_message = "Invalid encoding value for Event Hub capture encoding. Allowed values are Avro and AvroDeflate."
  }

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.size_limit_in_bytes == null ? true : config.capture_description.size_limit_in_bytes >= 314572800 && config.capture_description.size_limit_in_bytes <= 524288000
      )
    ])
    error_message = "Invalid size_limit_in_bytes value.  If specified, it must be between 10485760 and 524288000 bytes."
  }

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.interval_in_seconds == null ? true : config.capture_description.interval_in_seconds <= 900 && config.capture_description.interval_in_seconds >= 60
      )
    ])
    error_message = "Invalid interval_in_seconds value.  If specified, it must be between 60 and 900 seconds."
  }

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.capture_description == null ? true : config.capture_description.destination.name == null ? true : config.capture_description.destination.name == "EventHubArchive.AzureBlockBlob"
      )
    ])
    error_message = "Invalid capture destination. At this time, only EventHubArchive.AzureBlockBlob is supported."
  }

  validation {
    condition = can([
      for event_hub, config in var.event_hubs : (
        config.status == null ? true : contains(["Active", "Disabled", "SendDisabled"], config.status)
      )
    ])
    error_message = "Invalid status value. If supplied, possible values are Active, Disabled, and SendDisabled."
  }

  description = <<DESCRIPTION
Map of Azure Event Hubs configurations.

- `name` - (Required) Specifies the name of the Event Hub resource. Changing this forces a new resource to be created.
- `namespace_name` - (Required) Specifies the name of the Event Hub Namespace. Changing this forces a new resource to be created.
- `resource_group_name` - (Required) The name of the resource group in which the Event Hub's parent Namespace exists. Changing this forces a new resource to be created.
- `partition_count` - (Required) Specifies the current number of shards on the Event Hub. Cannot be changed unless Event Hub Namespace SKU is Premium and cannot be decreased. Defaults to 1.
  - Note: When using a dedicated Event Hubs cluster, the maximum value of partition_count is 1024. When using a shared parent EventHub Namespace, the maximum value is 32.
- `message_retention` - (Required) Specifies the number of days to retain the events for this Event Hub. Defaults to 7 days for shared parent EventHub Namespace with Basic SKU, 1 day for others.
  - Note: When using a dedicated Event Hubs cluster, the maximum value of message_retention is 90 days. When using a shared parent EventHub Namespace, the maximum value is 7 days; or 1 day when using a Basic SKU for the shared parent EventHub Namespace.
- `capture_description` - (Optional) A capture_description block as defined below.
  - `enabled` - (Required) Specifies if the Capture Description is Enabled.
  - `encoding` - (Required) Specifies the Encoding used for the Capture Description. Possible values are Avro and AvroDeflate.
  - `interval_in_seconds` - (Optional) Specifies the time interval in seconds at which the capture will happen. Values can be between 60 and 900 seconds. Defaults to 300 seconds.
  - `size_limit_in_bytes` - (Optional) Specifies the amount of data built up in your EventHub before a Capture Operation occurs. Value should be between 10485760 and 524288000 bytes. Defaults to 314572800 bytes.
  - `skip_empty_archives` - (Optional) Specifies if empty files should not be emitted if no events occur during the Capture time window. Defaults to false.
  - `destination` - (Required) A destination block as defined below.
    - `name` - (Required) The Name of the Destination where the capture should take place. At this time, the only supported value is EventHubArchive.AzureBlockBlob.
      - Note: At this time, it's only possible to Capture EventHub messages to Blob Storage.
    - `archive_name_format` - (Required) The Blob naming convention for archiving. e.g. {Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}. Here, all the parameters (Namespace, EventHub, etc.) are mandatory irrespective of order.
    - `blob_container_name` - (Required) The name of the Container within the Blob Storage Account where messages should be archived.
    - `storage_account_id` - (Required) The ID of the Blob Storage Account where messages should be archived.
- `status` - (Optional) Specifies the status of the Event Hub resource. Possible values are Active, Disabled, and SendDisabled. Defaults to Active.
- `role_assignments` - (Optional) RBAC permissions applied to the event hub resource.
DESCRIPTION 
}
