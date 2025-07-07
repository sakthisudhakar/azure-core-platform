data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

data "azurerm_eventhub_namespace" "this" {
  count = var.existing_parent_resource != null ? 1 : 0

  name                = var.existing_parent_resource.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_namespace" "this" {
  count = var.existing_parent_resource == null ? 1 : 0

  location                      = coalesce(var.location, local.resource_group_location)
  name                          = var.name # calling code must supply the name
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  auto_inflate_enabled          = var.auto_inflate_enabled
  capacity                      = var.capacity
  dedicated_cluster_id          = var.dedicated_cluster_id
  local_authentication_enabled  = var.local_authentication_enabled
  maximum_throughput_units      = var.maximum_throughput_units
  minimum_tls_version           = 1.2
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.managed_identities != {} ? { this = var.managed_identities } : {}

    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "network_rulesets" {
    for_each = var.network_rulesets != null ? { this = var.network_rulesets } : {}

    content {
      default_action                 = network_rulesets.value.default_action
      public_network_access_enabled  = network_rulesets.value.public_network_access_enabled
      trusted_service_access_enabled = network_rulesets.value.trusted_service_access_enabled

      dynamic "ip_rule" {
        for_each = network_rulesets.value.ip_rule

        content {
          action  = ip_rule.value.action
          ip_mask = ip_rule.value.ip_mask
        }
      }
      dynamic "virtual_network_rule" {
        for_each = network_rulesets.value.virtual_network_rule

        content {
          ignore_missing_virtual_network_service_endpoint = virtual_network_rule.value.ignore_missing_virtual_network_service_endpoint
          subnet_id                                       = virtual_network_rule.value.subnet_id
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.maximum_throughput_units == null && !var.auto_inflate_enabled
      error_message = "Cannot set MaximumThroughputUnits property if AutoInflate is not enabled."
    }
  }
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_eventhub_namespace.this[0].id
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_eventhub_namespace.this[0].id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "azurerm_eventhub" "this" {
  for_each = var.event_hubs

  message_retention   = each.value.message_retention
  name                = each.key
  partition_count     = each.value.partition_count
  namespace_name      = try(data.azurerm_eventhub_namespace.this[0].name, azurerm_eventhub_namespace.this[0].name)
  resource_group_name = var.resource_group_name
  status              = each.value.status

  dynamic "capture_description" {
    for_each = each.value.capture_description != null ? { this = each.value.capture_description } : {}

    content {
      enabled             = each.value.capture_description.enabled
      encoding            = each.value.capture_description.encoding
      interval_in_seconds = each.value.capture_description.interval_in_seconds
      size_limit_in_bytes = each.value.capture_description.size_limit_in_bytes
      skip_empty_archives = each.value.capture_description.skip_empty_archives

      destination {
        archive_name_format = each.value.capture_description.destination.archive_name_format
        blob_container_name = each.value.capture_description.destination.blob_container_name
        name                = each.value.capture_description.destination.name
        storage_account_id  = each.value.capture_description.destination.storage_account_id
      }
    }
  }
}

resource "azurerm_role_assignment" "event_hubs" {
  for_each = local.event_hub_role_assignments

  principal_id                           = each.value.role_assignment.principal_id
  scope                                  = azurerm_eventhub.this[each.value.event_hub_key].id
  condition                              = each.value.role_assignment.condition
  condition_version                      = each.value.role_assignment.condition_version
  delegated_managed_identity_resource_id = each.value.role_assignment.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_assignment.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.role_assignment.skip_service_principal_aad_check
}
