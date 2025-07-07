variable "lb_name" {}
variable "frontend_ip_name" {}
variable "backend_pool_name" {}

variable "resource_group_name" {
  description = "Name of the resource group where the VNet will be created"
  type        = string
  default     = ""
}
variable "location" {
  description = "Location where the VNet will be created"
  type        = string
  default     = "eastus"
}
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = ""
}