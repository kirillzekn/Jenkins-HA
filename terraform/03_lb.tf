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

resource "azurerm_lb_backend_address_pool" "jenkins-ha" {
  name            = "backendAddressPool"
  loadbalancer_id = azurerm_lb.jenkins-ha.id
}

#nat azure load balanceer rule
resource "azurerm_lb_nat_rule" "jenkins-ha" {
  name                           = "SSH_22"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
  loadbalancer_id                = azurerm_lb.jenkins-ha.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.jenkins-ha.id
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
  resource_group_name            = azurerm_resource_group.jenkins-ha.name

}


# resource "azurerm_lb_nat_rule" "jenkins-ha" {
#   name          = "SSH"
#   protocol      = "Tcp"
#   frontend_port = 22
#   backend_port  = 22
#   #frontend_ip_configuration_id   = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].id
#   loadbalancer_id                = azurerm_lb.jenkins-ha.id
#   frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
#   resource_group_name            = azurerm_resource_group.jenkins-ha.name
# }

# resource "azurerm_lb_nat_rule" "jenkins-ha-8080" {
#   name          = "Jenkins"
#   protocol      = "Tcp"
#   frontend_port = 8080
#   backend_port  = 8080
#   #frontend_ip_configuration_id   = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].id
#   loadbalancer_id                = azurerm_lb.jenkins-ha.id
#   frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
#   resource_group_name            = azurerm_resource_group.jenkins-ha.name
# }

# resource "azurerm_lb_nat_rule" "jenkins-ha-50000" {
#   name          = "Jenkins50000"
#   protocol      = "Tcp"
#   frontend_port = 50000
#   backend_port  = 50000
#   #frontend_ip_configuration_id   = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].id
#   loadbalancer_id                = azurerm_lb.jenkins-ha.id
#   frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
#   resource_group_name            = azurerm_resource_group.jenkins-ha.name
# }

resource "azurerm_lb_rule" "jenkins-ha-8080" {
  name                           = "HTTP_8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
  loadbalancer_id                = azurerm_lb.jenkins-ha.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.jenkins-ha.id]
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false

}

resource "azurerm_lb_rule" "jenkins-ha-22" {
  name                           = "SSH_22"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.jenkins-ha.frontend_ip_configuration[0].name
  loadbalancer_id                = azurerm_lb.jenkins-ha.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.jenkins-ha.id]
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false

}


