resource "azurerm_public_ip" "nat_ip" {
    count                = var.nat_gateway_enabled ? 1 : 0
  name                = "${var.vnet_name}-nat-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
    count                = var.nat_gateway_enabled ? 1 : 0
  name                = "${var.vnet_name}-natgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
#  zones                   = ["1"]

}

resource "azurerm_nat_gateway_public_ip_association" "natip_association" {
    count                = var.nat_gateway_enabled ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat[count.index].id
  public_ip_address_id = azurerm_public_ip.nat_ip[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "natgw_association" {
  count                = var.nat_gateway_enabled ? 1 : 0
  subnet_id            = azurerm_subnet.private.id  
  nat_gateway_id       = azurerm_nat_gateway.nat[count.index].id
}

variable "nat_gateway_enabled" {
  description = "Enable NAT Gateway for the public subnet"
  type        = bool
  default     = false
  
}