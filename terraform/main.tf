#Create a RG
resource "azurerm_resource_group" "jenkins-ha" {
  name     = "jenkins-ha-rg"
  location = "West Europe"
}

#Get the current tenant_id and object_id
data "azurerm_client_config" "current" {}

#Create a KeyVault
resource "azurerm_key_vault" "jenkins-ha" {
  name                     = "jenkins-ha-kv"
  location                 = azurerm_resource_group.jenkins-ha.location
  resource_group_name      = azurerm_resource_group.jenkins-ha.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

#Generate an SSH key pair
resource "tls_private_key" "jenkins-ha" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Upload SSH public key to KeyVault
resource "azurerm_key_vault_secret" "jenkins-ha-ssh" {
  name         = "jenkins-ha-ssh"
  value        = tls_private_key.jenkins-ha.public_key_openssh
  key_vault_id = azurerm_key_vault.jenkins-ha.id
}

#LoadBalancerResource
resource "azurerm_public_ip" "jenkins-ha" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.jenkins-ha.location
  resource_group_name = azurerm_resource_group.jenkins-ha.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "jenkins-ha" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.jenkins-ha.location
  resource_group_name = azurerm_resource_group.jenkins-ha.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.jenkins-ha.id
  }
}

#Deploy VMSS
resource "azurerm_virtual_network" "jenkins-ha" {
  name                = "jenkins-ha-vnet"
  resource_group_name = azurerm_resource_group.jenkins-ha.name
  location            = azurerm_resource_group.jenkins-ha.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.jenkins-ha.name
  virtual_network_name = azurerm_virtual_network.jenkins-ha.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_linux_virtual_machine_scale_set" "jenkins-ha" {
  name                = "jenkins-ha-vmss"
  resource_group_name = azurerm_resource_group.jenkins-ha.name
  location            = azurerm_resource_group.jenkins-ha.location

  sku            = "Standard_B2s"
  instances      = 2
  admin_username = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.jenkins-ha.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "jenkins-ha-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}

resource "azurerm_network_security_group" "jenkins-ha-nsg" {
  name                = "jenkins-ha-nsg"
  location            = azurerm_resource_group.jenkins-ha.location
  resource_group_name = azurerm_resource_group.jenkins-ha.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "jenkins-ha" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.jenkins-ha-nsg.id
}