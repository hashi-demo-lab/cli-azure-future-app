variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "cli-demo"
}

variable "tenant_id" {
  description = "azure tenant_id"
  default     = "0e3e2e88-8caf-41ca-b4da-e3b33b6c52ec"
}

variable "subscription_id" {
  description = "azure tenant_id"
  default     = "14692f20-9428-451b-8298-102ed4e39c2a"
}

variable "extension_name" {
  description = "my"
  default     = "tffut"
}

variable "location" {
  description = "The region where the virtual network is created."
  default     = "Australia East"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_B1ms"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "16.04-LTS"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name for linux and mysql"
  default     = "hashicorp"
}

variable "admin_password" {
  description = "Administrator password for linux and mysql"
  sensitive   = true
  default     = "Demolabpass1!"
}

variable "hcp_project_id" {
  description = "HCP Project Id"
  default     = "8f401e26-b086-451f-b61a-4ffb6dd26304"
}