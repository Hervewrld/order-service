variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "tier" {
  type    = string
  default = "db-f1-micro"
}

variable "database_name" {
  type    = string
  default = "orders"
}

variable "database_user" {
  type    = string
  default = "orders_app"
}

variable "authorized_networks" {
  type = list(object({
    name = string
    cidr = string
  }))
  description = "Networks allowed to reach the public IP. Empty by default (deny all) - use the Cloud SQL Auth Proxy instead of opening this up."
  default     = []
}
