
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0cfe2870-d256-4119-b0a3-16293ac11bdc"
  resource_provider_registrations = "none"
  client_id       = "fea02de5-eb8c-477b-adfa-8048848ace89"
  client_secret   = "5pH8Q~UhcjBfM4BF0efdLnZBxDfqVFTTuF~ntaQz"
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
}

