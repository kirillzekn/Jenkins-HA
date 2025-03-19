variable "TERRAFORM_AZURE_RG_NAME" {
  type        = string
  description = "The name of the resource group to deploy the AKS cluster"

}

variable "TERRAFORM_AZURE_STORAGE_ACCOUNT_NAME" {
  type        = string
  description = "The name of the storage account to store the Terraform state file"

}

variable "TERRAFORM_AZURE_STORAGE_CONTAINER_NAME" {
  type        = string
  description = "The name of the storage container to store the Terraform state file"

}

variable "AZURE_DEFAULT_REGION" {
  type        = string
  description = "The Azure region to deploy the AKS cluster"
  default     = "West Europe"

}