#--------------------------------------------------------------------------------------------------------
# External Load Balancer Configuration
#--------------------------------------------------------------------------------------------------------


resource "azurerm_public_ip" "lb_ip" {
    count                = var.create_external_lb ? 1 : 0
  name                = "${var.vnet_name}-lb-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "external_lb" {
    count = var.create_external_lb ? 1 : 0
  name                = var.external_lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_ip[count.index].id
  }

}

resource "azurerm_lb_backend_address_pool" "public_backend_pool" {
  count               = var.create_external_lb ? 1 : 0
  name                = var.public_backend_pool_name
  loadbalancer_id     = azurerm_lb.external_lb[count.index].id
}


resource "azurerm_lb_probe" "tcp_probe" { 
    count               = var.create_external_lb ? 1 : 0
  name                = "tcp-probe"
  loadbalancer_id     = azurerm_lb.external_lb[count.index].id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "http_rule" {
    count               = var.create_external_lb ? 1 : 0
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.external_lb[count.index].id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.public_backend_pool[count.index].id]
  probe_id                       = azurerm_lb_probe.tcp_probe[count.index].id
}

variable "create_external_lb" {
  description = "Create an external load balancer"
  type        = bool
  default     = false
  
}

variable "external_lb_name" {
  description = "Name of the external load balancer"
  type        = string
  default     = "external-lb"
  
}

variable "public_backend_pool_name" {
  description = "Name of the backend pool for the external load balancer"
  type        = string
  default     = "public-backend-pool"
  
}

variable "private_subnet_id" {
  description = "ID of the private subnet where the internal load balancer will be associated"
  type        = string
  default     = ""
  
}

variable "public_subnet_id" {
  description = "ID of the private subnet where the internal load balancer will be associated"
  type        = string
  default     = ""
  
}