provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my_resource_group" {
  name     = "my-resource-group"
  location = "East US"  
}

module "app_server" {
  source                = "./modules/app_server"  
  resource_group_name   = azurerm_resource_group.my_resource_group.name
  location              = "East US" 
  availability_zone     = ["1", "2"]  
  app_instance_count    = 2  
}

module "db_server" {
  source                = "./modules/db_server"  
  resource_group_name   = azurerm_resource_group.my_resource_group.name
  location              = "East US"  
  availability_zone     = ["1", "2"]  
}

output "app_server_ips" {
  value = module.app_server.public_ip_addresses
}
