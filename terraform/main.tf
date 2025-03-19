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
module "vmscaleset" {
  source = "Azure/vm-scale-sets/azurerm"

  # Resource Group and location, VNet and Subnet detials (Required)
  resource_group_name  = azurerm_resource_group.jenkins-ha.name
  location            = azurerm_resource_group.jenkins-ha.location
  virtual_network_name = "vnet-default-hub-westeurope"
  subnet_name          = "snet-management-default-hub-westeurope"
  vmscaleset_name      = "jenkins-ha-vmss"
  virtual_machine_size = "Standard_DS2_v2"


  # This module support multiple Pre-Defined Linux and Windows Distributions.
  # These distributions support the Automatic OS image upgrades in virtual machine scale sets
  # Linux images: ubuntu1804, ubuntu1604, centos75, coreos
  # Windows Images: windows2012r2dc, windows2016dc, windows2019dc, windows2016dccore
  # Specify the RSA key for production workloads and set generate_admin_ssh_key argument to false
  # When you use Autoscaling feature, instances_count will become default and minimum instance count. 
  os_flavor               = "linux"
  linux_distribution_name = "ubuntu1804"
  generate_admin_ssh_key  = false
  admin_ssh_key_data      = tls_private_key.jenkins-ha.public_key_openssh
  instances_count         = 2

  # Public and private load balancer support for VM scale sets
  # Specify health probe port to allow LB to detect the backend endpoint status
  # Standard Load Balancer helps load-balance TCP and UDP flows on all ports simultaneously
  # Specify the list of ports based on your requirement for Load balanced ports
  # for additional data disks, provide the list for required size for the disk. 
  load_balancer_type              = "public"
  load_balancer_health_probe_port = 80
  load_balanced_port_list         = [80, 443]
  additional_data_disks           = [100, 200]

  # Enable Auto scaling feature for VM scaleset by set argument to true. 
  # Instances_count in VMSS will become default and minimum instance count.
  # Automatically scale out the number of VM instances based on CPU Average only.    
  enable_autoscale_for_vmss          = true
  minimum_instances_count            = 1
  maximum_instances_count            = 2
  scale_out_cpu_percentage_threshold = 80
  scale_in_cpu_percentage_threshold  = 20

  # Network Seurity group port allow definitions for each Virtual Machine
  # NSG association to be added automatically for all network interfaces.
  # SSH port 22 and 3389 is exposed to the Internet recommended for only testing. 
  # For production environments, we recommend using a VPN or private connection
  nsg_inbound_rules = [
    {
      name                   = "http"
      destination_port_range = "80"
      source_address_prefix  = "*"
    },

    {
      name                   = "https"
      destination_port_range = "443"
      source_address_prefix  = "*"
    },
  ]

}