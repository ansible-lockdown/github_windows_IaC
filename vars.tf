variable "prefix" {
  default     = "Lockdown_Github_Repo_Workflow_Win"
  description = "The prefix which should be used for all resources in this example"
  type        = string
}

variable "location" {
  default     = "eastus2"
  description = "The Azure Region in which all resources in this example should be created."
  type        = string
}

variable "tagname" {
  default     = "ansible_lockdown_actions"
  description = "The Tagname in which all resources in this example should be created."
  type        = string
}

variable "system_size" {
  default     = "Standard_D4s_v3"
  description = "The size of the system deployed in which all resources in this example should be created."
  type        = string
}

variable "system_release" {
  description = "The OS release in which all resources in this example should be created."
  type        = string
}

variable "hostname" {
  description = "The hostname for the virtual machine in this release"
  type        = string
}

variable "OS_publisher" {
  description = "The version of the OS, also known as publisher in Template azure file"
  type        = string
}

variable "OS_version" {
  description = "The version of the OS, also this is combined with system_release to give you the sku in the template."
  type        = string
}

variable "product_id" {
  description = "This is the offer that azure gives you for the image"
  type        = string
}

variable "benchmark_type" {
  description = "This will pull the vars.BENCHMARK_TYPE from github and enter it into the template."
  type        = string
}

variable "repository" {
  description = "The repository thats being tested"
  type        = string
}

variable "windows_prefix" {
  default     = "test"
  description = "Specify the Windows version (e.g., win19cis or win22cis)"
  type        = string
}

variable "additional_inventory_settings" {
  type        = string
  default     = "" # Default to empty if no additional settings are specified
  description = "Additional settings for the inventory file"
}

variable "resource_group_style" {
  type        = string
  default     = "" # Default to empty if no additional settings are specified
  description = "This Will apply a unique identifier to keep resource group collisions from happening."
}
