#Create a RG
resource "azurerm_resource_group" "jenkins-ha" {
  name     = "jenkins-ha-rg"
  location = "West Europe"
}

#Get the current tenant_id and object_id
data "azurerm_client_config" "current" {}