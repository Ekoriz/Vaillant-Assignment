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

variable "app_instance_count" {
  description = "Number of application instances"
}

resource "azurerm_virtual_network" "app_vnet" {
  name                = "app-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = var.resource_group_name # Reference to variable "resource_group_name"
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "app_nic" {
  count               = var.app_instance_count
  name                = "app-nic-${count.index}"
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "app_vm" {
  count                = var.app_instance_count
  name                 = "app-vm-${count.index}"
  location             = var.location            # Reference to variable "location"
  resource_group_name  = var.resource_group_name # Reference to variable "resource_group_name"
  network_interface_ids = [azurerm_network_interface.app_nic[count.index].id]
  vm_size              = "Standard_B2s"
  availability_set_id  = azurerm_availability_set.app_availability_set.id

  storage_os_disk {
    name              = "app-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "appserver-${count.index}"
    admin_username = "Admin"
    admin_password = "Password"  
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_availability_set" "app_availability_set" {
  name                = "app-availability-set"
  location            = var.location            # Reference to variable "location"
  resource_group_name = var.resource_group_name # Reference to variable "resource_group_name"
}

output "public_ip_addresses" {
  value = azurerm_public_ip.app_public_ip.ip_address
}

