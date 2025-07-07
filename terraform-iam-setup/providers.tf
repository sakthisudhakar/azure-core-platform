
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}


# variable "client_secret" {
# }


# # Authenticating using a Service Principal with a Client Secret
# provider "azurerm" {
#   features {}

#   client_id       = "00000000-0000-0000-0000-000000000000"
#   client_secret   = var.client_secret
#   tenant_id       = "10000000-0000-0000-0000-000000000000"
#   subscription_id = "20000000-0000-0000-0000-000000000000"
# }

# Configure the Microsoft Azure Provider using CLI

# az account set --subscription="SUBSCRIPTION_ID"
# az login
# az login --service-principal -u "CLIENT_ID" -p "CLIENT_SECRET" --tenant "TENANT_ID"
# az login --service-principal -u "CLIENT_ID" --tenant "TENANT_ID"

provider "azurerm" {
  features {}

}


# export ARM_USE_MSI=true
# export ARM_SUBSCRIPTION_ID=159f2485-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# export ARM_TENANT_ID=72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# export ARM_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # only necessary for user assigned identity
# export ARM_MSI_ENDPOINT=$MSI_ENDPOINT # only necessary when the msi endpoint is different than the well-known one
# export ARM_MSI_API_VERSION="2019-08-01" # optional, defaults to 2018-02-01. Some Azure services require a newer API version due to local implementation conditions. e.g. Running in Azure Container Apps requires `2019-08-01`.