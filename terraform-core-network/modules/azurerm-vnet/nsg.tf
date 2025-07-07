#-----------------------------------------------
# Network security group for public subnet
#-----------------------------------------------
resource "azurerm_network_security_group" "nsg_public" {
  name                = lower("nsg-${var.vnet_name}-public")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge({ "ResourceName" = lower("nsg-${var.vnet_name}-public") }, var.tags, )
  dynamic "security_rule" {
    for_each = var.public_nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = "${security_rule.value.direction}_Port_${security_rule.value.destination_port_range}"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-public-assoc" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

variable "public_nsg_rules" {
  description = "Map of security rules for public NSG"
  type = map(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {
    SSH = {
      name                       = "Allow-SSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "22"
      source_address_prefix      = "0.0.0.0/0"
      destination_address_prefix = "*"
    }
    HTTP = {
      name                       = "Allow-HTTP"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "80"
      source_address_prefix      = "0.0.0.0/0"
      destination_address_prefix = "*"
    }
    OUT_ALL = {
      name                       = "Allow-Outbound-All"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}


#-----------------------------------------------
# Network security group for public subnet
#-----------------------------------------------
resource "azurerm_network_security_group" "nsg_private" {
  name                = lower("nsg-${var.vnet_name}-private")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge({ "ResourceName" = lower("nsg-${var.vnet_name}-private") }, var.tags, )
  dynamic "security_rule" {
    for_each = var.private_nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = upper(security_rule.value.direction)
      access                     = upper(security_rule.value.access)
      protocol                   = lower(security_rule.value.protocol)
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = "${security_rule.value.direction}_Port_${security_rule.value.destination_port_range}"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-private-assoc" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.nsg_private.id
}

variable "private_nsg_rules" {
  description = "Map of security rules for public NSG"
  type = map(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {
    HTTP = {
      name                       = "Allow-HTTP"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_address_prefix = "10.0.2.0/24"  # Private subnet CIDR
      destination_port_range     = "80"
      source_address_prefix      = "0.0.0.0/0"      
    }
  }
    
}