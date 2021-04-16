provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location

  tags = {
    project = var.project
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-resources-ansg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.project
  }
}

resource "azurerm_network_security_rule" "main_in" {
  name                        = "${var.prefix}-rule-deny-internet-access"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name

  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "main_out" {
  name                         = "${var.prefix}-rule-allow-access-vms-subnet"
  resource_group_name          = azurerm_resource_group.main.name
  network_security_group_name  = azurerm_network_security_group.main.name

  priority                     = 200
  direction                    = "Outbound"
  access                       = "Allow"
  protocol                     = "*"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = ["10.0.2.0/24"]
  destination_address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    project = var.project
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-public-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  frontend_ip_configuration {
    name                 = "${var.prefix}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    project = var.project
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name                = "${var.prefix}-backend-address-pool"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vmcount
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "${var.prefix}-ip-configuration-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-lb-probe"
  port                = var.applicationport
}

resource "azurerm_lb_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.applicationport
  backend_port                   = var.applicationport
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
  frontend_ip_configuration_name = "${var.prefix}-frontend-ip"
  probe_id                       = azurerm_lb_probe.main.id
}

resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  platform_fault_domain_count = 3

  tags = {
    project = var.project
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.project
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count               = var.vmcount
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.prefix}-ip-configuration-${count.index}"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project = var.project
  }
}

resource "azurerm_managed_disk" "main" {
  count                = var.vmcount
  name                 = "${var.prefix}-managed_disk_${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    project = var.project
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count                = var.vmcount
  managed_disk_id      = element(azurerm_managed_disk.main.*.id, count.index)
  virtual_machine_id   = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                  = "10"
  caching              = "ReadWrite"
}

data "azurerm_image" "main" {
  name                = var.imagename
  resource_group_name = var.imageresourcegroup
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vmcount
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  availability_set_id             = azurerm_availability_set.main.id
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids           = [element(azurerm_network_interface.main.*.id, count.index)]

  source_image_id                 = data.azurerm_image.main.id

  # os_disk or
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    project = var.project
  }
}