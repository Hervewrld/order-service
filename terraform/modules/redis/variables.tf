variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "network_self_link" {
  type        = string
  description = "VPC self_link to peer this Memorystore instance into"
}

variable "tier" {
  type    = string
  default = "BASIC"
}

variable "memory_size_gb" {
  type    = number
  default = 1
}
