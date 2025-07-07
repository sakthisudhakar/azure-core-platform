resource "azurerm_public_ip" "bastion_pip" {
    count                = var.bastion_subnet_address_prefix != null ? 1 : 0
  name                = "bastion-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"  # Required for Bastion
}
resource "azurerm_bastion_host" "bastion" {
    count                = var.bastion_subnet_address_prefix != null ? 1 : 0
  name                = "bastion-host"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
//  dns_name            = "mybastion-host"  # Change as needed

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }
}