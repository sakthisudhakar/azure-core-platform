#--------------------------------------------

resource "azurerm_network_watcher" "nwatcher" {
  count               = var.create_network_watcher != false ? 1 : 0
  name                = "NetworkWatcher_${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge({ "Name" = format("%s", "NetworkWatcher_${var.location}") }, var.tags, )
}

variable "create_network_watcher" {
  description = "Create Network Watcher"
  type        = bool
  default     = false 
}
