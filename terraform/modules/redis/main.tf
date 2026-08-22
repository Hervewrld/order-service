resource "google_redis_instance" "this" {
  project        = var.project_id
  name           = "${var.name_prefix}-redis"
  region         = var.region
  tier           = var.tier
  memory_size_gb = var.memory_size_gb

  authorized_network = var.network_self_link
  redis_version      = "REDIS_7_0"
}
