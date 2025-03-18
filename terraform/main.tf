#LoadBalancerResource
resource "azurerm_resource_group" "jenkins-ha" {
  name     = "jenkins-ha-rg"
  location = "West Europe"
}

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

