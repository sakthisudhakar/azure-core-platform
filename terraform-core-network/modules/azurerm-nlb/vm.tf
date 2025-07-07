resource "azurerm_network_interface" "vm_nic" {
  name                = "nginx-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"

  #  gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.external_lb[0].frontend_ip_configuration[0].id

  }
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_backend_association" {
  network_interface_id    = azurerm_network_interface.vm_nic.id
  ip_configuration_name   = "internal"  # Must match the name in NIC
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_backend_pool[0].id  # Use the first instance of the backend pool if external LB is created
}



resource "azurerm_linux_virtual_machine" "vm" {
  name                = "nginx-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  disable_password_authentication = false
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-demo-vm"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
EOF
  )

  tags = {
    environment = "demo"
  }
}


variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password (only for demo use — use SSH key in production)"
  sensitive   = true
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}
