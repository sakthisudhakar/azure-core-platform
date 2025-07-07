# resource "azurerm_resource_group" "vnet" {
#   name     = "rg-core-network"
#   location = var.location
#   tags = coalesce(var.tags, {
#     environment = "core-network"
#     created_by  = "terraform"
#     Name        = "core-network"
#   })
# }

# data "azurerm_resource_group" "vnet" {
#   name = "rg-core-network"
# }

module "vnet" {
  source              = "./modules/azurerm-vnet"
  resource_group_name = var.resource_group_name #data.azurerm_resource_group.vnet.name
  location            = var.location #data.azurerm_resource_group.vnet.location
  vnet_name           = "vnet-core-network"
  address_space       = ["10.0.0.0/16"]
  public_subnet_name     = "public-subnet"
  public_subnet_prefix   = ["10.0.1.0/24"]
  private_subnet_name    = "private-subnet"
  private_subnet_prefix  = ["10.0.2.0/24"]

  bastion_subnet_address_prefix  = ["10.0.4.0/27"]
  gateway_subnet_address_prefix  = ["10.0.5.0/27"]
  nat_gateway_enabled = true
}

module "internal_lb" {
  source              = "./modules/azurerm-nlb"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = module.vnet.vnet_name  
  lb_name             = "internal-lb"
  frontend_ip_name    = "InternalFrontendIP"
  backend_pool_name   = "InternalBackendPool"
  private_subnet_id   = module.vnet.private_subnet_id
  public_subnet_id    = module.vnet.public_subnet_id
  create_external_lb  = true
  admin_password = "test1234!" # Use a secure password in production
  depends_on = [ module.vnet ]
}
