resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = "${var.name_prefix}-postgres"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = false

  settings {
    tier = var.tier

    ip_configuration {
      ipv4_enabled = true

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    backup_configuration {
      enabled = false
    }
  }
}

resource "google_sql_database" "this" {
  project  = var.project_id
  name     = var.database_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "this" {
  project  = var.project_id
  name     = var.database_user
  instance = google_sql_database_instance.this.name
  password = random_password.db_password.result
}
