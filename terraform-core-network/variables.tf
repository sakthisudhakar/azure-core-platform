variable "location" {
  description = "The Azure Region where the resources will be created."
  type        = string
  default     = "eastus"  
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
  
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created."
  type        = string
  default     = "1-165672b9-playground-sandbox"
  
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "28e1e42a-4438-4c30-9a5f-7d7b488fd883"
  
}