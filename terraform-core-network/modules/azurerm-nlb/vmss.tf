############
# Azure LB + Virtual Machine Scale Set (VMSS)
############

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "ngnix-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  upgrade_mode        = "Manual"
  sku                 = "Standard_D2s_v3"
  instances           = 2
  admin_username      = var.admin_username
  disable_password_authentication = false
  admin_password      = var.admin_password

#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
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

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.private_subnet_id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.backend_pool.id
      ]
      primary                                = true
    }
  }
}


resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "autoscale-setting"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "autoscale-profile"

    capacity {
      minimum = "2"
      maximum = "5"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

}
