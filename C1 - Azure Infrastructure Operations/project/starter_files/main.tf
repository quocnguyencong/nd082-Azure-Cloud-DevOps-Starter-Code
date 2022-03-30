provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "main" {
    name = "${var.prefix}-resources"
    location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count = 2
  name                = "${var.prefix}-nic_${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name = "${var.prefix}-public_ip"
  resource_group_name = azurerm_resource_group.main.name
  location = "${var.location}"
  allocation_method = "Dynamic"
}

data "azurerm_image" "search" {
  name                = "myPackerImage"
  resource_group_name = "${var.packerResourceGroup}"
}

resource "azurerm_availability_set" "avset" {
   name                         = "${var.prefix}-avset"
   location                     = azurerm_resource_group.main.location
   resource_group_name          = azurerm_resource_group.main.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
 }

resource "azurerm_virtual_machine" "main" {
  count = 2
  name                            = "${var.prefix}-vm_${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  availability_set_id   = azurerm_availability_set.avset.id
  vm_size                            = "Standard_D2s_v3"
  #admin_username                  = "${var.username}"
  #admin_password                  = "${var.password}"
  #disable_password_authentication = false
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  #network_interface_ids = [
    #azurerm_network_interface.main.id,
  #]

  storage_image_reference {
    id = "${var.packerImageId}"
  }

  storage_os_disk {
    #storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    create_option     = "FromImage"
    name              = "${var.prefix}-image-storage_${count.index}"
  }

  storage_data_disk {
     name            = element(azurerm_managed_disk.main.*.name, count.index)
     managed_disk_id = element(azurerm_managed_disk.main.*.id, count.index)
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = element(azurerm_managed_disk.main.*.disk_size_gb, count.index)
   }

   os_profile {
    computer_name  = "Admin"
    admin_username       = var.username
    admin_password       = var.password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_managed_disk" "main" {
  count = 2
  name                 = "${var.prefix}-disk1_${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.location

  frontend_ip_configuration {
     name                 = "publicIPAddress"
     public_ip_address_id = azurerm_public_ip.public_ip.id
   }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-BackEndAddressPool"
  loadbalancer_id = azurerm_lb.main.id
}



resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  frontend_ip_configuration_name = "publicIPAddress"
  probe_id                       = azurerm_lb_probe.main.id
}
