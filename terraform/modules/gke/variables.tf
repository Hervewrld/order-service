variable "project_id" {
  type = string
}

variable "zone" {
  type        = string
  description = "Zone for the (zonal) cluster - keeps it eligible for the free tier"
}

variable "name_prefix" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "subnet_self_link" {
  type = string
}

variable "node_count" {
  type    = number
  default = 1
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "preemptible" {
  type    = bool
  default = true
}
