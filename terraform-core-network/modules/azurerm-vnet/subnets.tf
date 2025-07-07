#--------------------------------------------------------------------------------------------------------
# Subnets Creation with, private link endpoint/servie network policies, service endpoints and Deligation.
#--------------------------------------------------------------------------------------------------------



resource "azurerm_subnet" "public" {
  name                 = var.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public_subnet_prefix
  default_outbound_access_enabled = true
  service_endpoints    = var.service_endpoints
  service_endpoint_policy_ids = var.service_endpoint_policy_ids
  private_endpoint_network_policies = "Disabled"
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "private" {
  name                 = var.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_subnet_prefix
  default_outbound_access_enabled = false
  service_endpoints    = var.service_endpoints
  service_endpoint_policy_ids = var.service_endpoint_policy_ids
  private_endpoint_network_policies = "Disabled"
  private_link_service_network_policies_enabled = false
  # delegation {
  #   name = "natDelegation"
  #   service_delegation {
  #     name = "Microsoft.Network/natGateways"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  #   }
  # }
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
  default     = "public-subnet"  
}

variable "public_subnet_prefix" {
  description = "Address prefix for the public subnet"
  type        = list(string)
  default     = []
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
  default     = "public-subnet"  
}

variable "private_subnet_prefix" {
  description = "Address prefix for the private subnet"
  type        = list(string)
  default     = []
}

variable "service_endpoints" {
  description = "Service endpoints for the public subnet"
  type        = list(string)
  default     = []
}

variable "service_endpoint_policy_ids" {
  description = "Service endpoint policy IDs for the public subnet"
  type        = list(string)
  default     = []
}


###################

resource "azurerm_subnet" "fw-snet" {
  count                = length (var.firewall_subnet_address_prefix) > 0 ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.firewall_subnet_address_prefix #[cidrsubnet(element(var.vnet_address_space, 0), 10, 0)]
  service_endpoints    = var.firewall_service_endpoints
}

resource "azurerm_subnet" "gw_snet" {
  count                = var.gateway_subnet_address_prefix != null ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.gateway_subnet_address_prefix #[cidrsubnet(element(var.vnet_address_space, 0), 8, 1)]
  service_endpoints    = var.gateway_service_endpoints
}

# Bastion Subnet (required name: AzureBastionSubnet)
resource "azurerm_subnet" "bastion" {
  count                = var.bastion_subnet_address_prefix != null ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.bastion_subnet_address_prefix
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for the Azure Firewall subnet"
  type        = list(string)
  default     = []
}
variable "firewall_service_endpoints" {
  description = "Service endpoints for the Azure Firewall subnet"
  type        = list(string)
  default     = []
}
variable "gateway_subnet_address_prefix" {
  description = "Address prefix for the Gateway subnet"
  type        = list(string)
  default     = []
}
variable "gateway_service_endpoints" {
  description = "Service endpoints for the Gateway subnet"
  type        = list(string)
  default     = []
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for the Bastion subnet"
  type        = list(string)
  default     = []
}

