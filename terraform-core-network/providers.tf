
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0cfe2870-d256-4119-b0a3-16293ac11bdc"
  resource_provider_registrations = "none"
  client_id       = "74a28bbc-bec2-4206-ab0a-17067ed11f15"
  client_secret   = "iV28Q~KAaZsI2u3Qsr0rTi0IwXx_kpRrzeuzbcm-"
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
}

