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