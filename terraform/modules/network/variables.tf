variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for the subnet"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names, e.g. order-service-dev"
}

variable "subnet_cidr" {
  type        = string
  description = "Primary CIDR range for the subnet"
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  type        = string
  description = "Secondary CIDR range for GKE pods"
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  type        = string
  description = "Secondary CIDR range for GKE services"
  default     = "10.2.0.0/20"
}
