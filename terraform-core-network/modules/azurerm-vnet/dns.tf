resource "azurerm_private_dns_zone" "private_dns" {
  name                = "privatelink.demo.internal"
  resource_group_name = var.resource_group_name
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = true  # true = auto-register VMs in zone (only 1 link can have this per zone)
}