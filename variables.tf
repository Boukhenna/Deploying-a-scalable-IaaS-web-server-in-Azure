variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "test"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "tenant_id" {
  description = "The Tenant ID should be created."
  default     = "6b078323-48a3-4013-ba4c-883cf9766d91"
}

variable "subscription_id" {
  description = "The Subscription ID should be created."
  default     = "3b2b4316-967b-44a8-9c2f-9f5ff31f09cb"
}

variable "username" {
  description = "The Azure Username in which all resources in this example should be created."
  default     = "ibrahim"
}

variable "password" {
  description = "The Azure Password in which all resources in this example should be created."
  default     = "AZErty123@"
}

variable "vmcount" {
  description = "The Number of VMs that should be created."
  default = "2"
}

variable "imagename" {
  description = "The Name of Image that should be used."
  default = "UdacityProjectPackerImage"
}

variable "imageresourcegroup" {
  description = "The Resource Group of Image that should be used."
  default = "udacity-project-devops-rg"
}

variable "project" {
  description = "The project of this instance."
  default = "azurewebserver"
}

variable "applicationport" {
  description = "The Application port."
  default = "80"
}