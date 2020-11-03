terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tf-remote-state-rg"
    storage_account_name = "bptfremotestate"
    container_name       = "la-manage-az-infra-tf"
    key                  = "terrafor.tfstate"
  }
}

provider "azurerm" {
  features {}
}

## Resource group ##

resource "azurerm_resource_group" "rg" {
  name     = "tf-la-learn-rg"
  location = "westeurope"

  tags = {
    "provider"    = "Linux Academy"
    "environment" = "development"
  }
}

## Storage account ##
resource "azurerm_storage_account" "sa" {
  name                     = "bptflalearnsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "provider"    = "Linux Academy"
    "environment" = "development"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "myblobs"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "share" {
  name                 = "myfileshare"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 1
}

resource "azurerm_storage_share_directory" "directory" {
  name                 = "mydirectory"
  share_name           = azurerm_storage_share.share.name
  storage_account_name = azurerm_storage_account.sa.name
}

## Virtual network ##
resource "azurerm_virtual_network" "vnet" {
  name                = "mynetwork"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "fe-nsg" {
  name                = "fe-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "allow-rdp" {
  name                        = "allow-rdp"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.fe-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "frontend-fe-nsg" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.fe-nsg.id
}

resource "azurerm_network_security_group" "be-nsg" {
  name                = "be-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "backend-be-nsg" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.be-nsg.id
}

## Virtual machine - frontend ##
resource "azurerm_network_interface" "fe-vm-nic" {
  name                = "fe-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fe-vm-pip.id
  }
}

resource "azurerm_public_ip" "fe-vm-pip" {
  name                = "fe-vm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

data "azurerm_public_ip" "fe-vm-pip" {
  name                = azurerm_public_ip.fe-vm-pip.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_windows_virtual_machine" "fe-vm" {
  name                = "fe-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.fe-vm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}