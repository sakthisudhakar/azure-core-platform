#--------------------------------------------
# Ddos protection plan - Default is "false"
#--------------------------------------------

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = var.ddos_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge({ "Name" = format("%s", var.ddos_plan_name) }, var.tags, )
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection for the Virtual Network"
  type        = bool
  default     = false  
}

variable "ddos_plan_name" {
  description = "Name of the DDoS Protection Plan"
  type        = string
  default     = "ddos-protection-plan"
  
}