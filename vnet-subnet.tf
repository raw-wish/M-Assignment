provider "azurerm" {
  version = "= 2.0.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "tf-rg"
  location = "centralus"
}

resource "azurerm_virtual_network" "myvnet" {
  name = "my-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

variable "subnet_prefix" {
  type = "list"
  default = [
    {
      ip      = "10.0.1.0/24"
      name     = "subnet-1"
    },
    {
      ip      = "10.0.2.0/24"
      name     = "subnet-2"
    }
   ]
}

resource "azurerm_subnet" "subnets" {
    name = "${lookup(element(var.subnet_prefix, count.index), "name")}"
    count = "${length(var.subnet_prefix)}"
    resource_group_name =  azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.myvnet.name
    address_prefix = "${lookup(element(var.subnet_prefix, count.index), "ip")}"
}

resource "azurerm_network_security_group" "example" {
  name                = "myNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  nsgs = [
    {
      name = "test-in-nsg"
      rules = [
        {
          name                                  = "httpallowinbound"
          priority                              = 101
          direction                             = "Inbound"
          access                                = "Allow"
          protocol                              = "Tcp"
          source_port_range                     = "80"
          destination_port_range                = "*"
          source_application_security_group_ids = "test-in-asg"

        },
        {
          name                                       = "httpallowinbound"
          priority                                   = 100
          direction                                  = "Inbound"
          access                                     = "Allow"
          protocol                                   = "Tcp"
          source_port_range                          = "443"
          destination_port_range                     = "*"
          source_address_prefix                      = "*"
          destination_address_prefix                 = "*"
          destination_application_security_group_ids = "test-out-asg"
        },
      ]
    },
   ]
   tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "myvm1publicip" {
  name = "pip1"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_network_interface" "myvm1nic" {
  name = "myvm1-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.frontendsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myvm1publicip.id
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                  = "myvm1"  
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.myvm1nic.id]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "Password123!"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
