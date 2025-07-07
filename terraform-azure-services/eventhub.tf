module "event_hub" {
  source = "./modules/eventhub"
  name                = "eventhub-${random_string.this.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
}