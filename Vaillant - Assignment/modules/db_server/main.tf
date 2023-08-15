variable "resource_group_name" {
  description = "Resource group name defined, in this case azurerm_resource_group.my_resource_group.name"
}

variable "location" {
  description = "Defined location, in this case East US"
}

variable "availability_zone" {
  description = "Availability Zones for the resources"
  type        = list(string)
}

resource "azurerm_virtual_network" "db_vnet" {
  name                = "db-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = var.resource_group_name # Reference to variable "resource_group_name"
  virtual_network_name = azurerm_virtual_network.db_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_machine" "db_vm" {
  name                 = "db-vm"
  location             = var.location
  resource_group_name  = var.resource_group_name # Reference to variable "resource_group_name"
  network_interface_ids = [azurerm_network_interface.db_nic.id]
  vm_size              = "Standard_D2s_v3"
  availability_set_id  = azurerm_availability_set.db_availability_set.id

  storage_os_disk {
    name              = "db-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "Standard"
    version   = "latest"
  }

  os_profile {
    computer_name  = "dbserver"
    admin_username = "SA"
    admin_password = "Password"  
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "db_nic" {
  name                = "db-nic"
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "db_availability_set" {
  name                = "db-availability-set"
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"
}

