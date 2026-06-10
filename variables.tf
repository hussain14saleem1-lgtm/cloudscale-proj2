variable "resource_group_name" {
  description = "Name of the project resource group"
  type        = string
  default     = "hussain-proj2-aci-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "switzerlandnorth"
}

variable "aci_name" {
  description = "Name of the Azure Container Instance"
  type        = string
  default     = "hussain-proj2-aci"
}

variable "dns_label" {
  description = "DNS name label for the container's public IP"
  type        = string
  default     = "hussain-proj2-app"
}

variable "docker_image" {
  description = "Docker Hub image to deploy to the container"
  type        = string
  default     = "hussain1s/cloudscale-proj2:latest"
}

variable "student_name" {
  description = "Student name used for resource tagging"
  type        = string
  default     = "Hussain Saleem"
}