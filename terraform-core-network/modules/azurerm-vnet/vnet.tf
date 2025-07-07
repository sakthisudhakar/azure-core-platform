#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------

locals {
  if_ddos_enabled = var.enable_ddos_protection ? [1] : []
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
//  dns_servers         = var.dns_servers
  tags                = merge({ "Name" = format("%s", var.vnet_name) }, var.tags, )
  dynamic "ddos_protection_plan" {
    for_each = local.if_ddos_enabled

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }
}

#--------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where the VNet will be created"
  type        = string
  default     = ""
}
variable "location" {
  description = "Location where the VNet will be created"
  type        = string
  default     = "eastus"
}
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = ""
}
variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = []
}