#--------------------------------------------------------------------------------------------------------
# Internal Load Balancer Configuration
#--------------------------------------------------------------------------------------------------------

resource "azurerm_lb" "internal_lb" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = var.frontend_ip_name
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  # internal LB is private by default (no public IP)
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = var.backend_pool_name
  loadbalancer_id     = azurerm_lb.internal_lb.id

}

resource "azurerm_lb_probe" "private_tcp_probe" { 
  name                = "tcp-probe"
  loadbalancer_id     = azurerm_lb.internal_lb.id
  protocol            = "Tcp"
  port                = 80
}

resource "azurerm_lb_rule" "private_http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.internal_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "InternalFrontendIP"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.private_tcp_probe.id
}
