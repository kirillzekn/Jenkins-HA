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
  name                = "jenkinshavmss"
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

    #IP configuration for loadbalancer

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.jenkins-ha.id]
      #load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_rule.jenkins-ha.id, azurerm_lb_nat_rule.jenkins-ha-8080.id, azurerm_lb_nat_rule.jenkins-ha-50000.id]
    }
  }
  depends_on = [azurerm_lb_backend_address_pool.jenkins-ha, azurerm_lb_rule.jenkins-ha-8080, azurerm_lb_nat_rule.jenkins-ha-22]
}

resource "azurerm_network_security_group" "jenkins-ha-nsg" {
  name                = "jenkins-ha-nsg"
  location            = azurerm_resource_group.jenkins-ha.location
  resource_group_name = azurerm_resource_group.jenkins-ha.name

  security_rule {
    name                       = "AllowAnyConnectionForLB"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_public_ip.jenkins-ha.ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAnyConnectionForMyIP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.MY_IP
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "jenkins-ha" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.jenkins-ha-nsg.id
}

#Azure VMSS Extension vmss script
resource "azurerm_virtual_machine_scale_set_extension" "jenkins-ha" {
  name                         = "jenkins-ha-vmss-script"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.jenkins-ha.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "script": "{base64encode(file("scripts/vmss_script.sh"))}"
    }
  PROTECTED_SETTINGS
}