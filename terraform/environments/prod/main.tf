module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "order-service-prod"
}

module "gke" {
  source = "../../modules/gke"

  project_id        = var.project_id
  zone              = var.zone
  name_prefix       = "order-service-prod"
  network_self_link = module.network.network_self_link
  subnet_self_link  = module.network.subnet_self_link
  node_count        = 3
  machine_type      = "e2-medium"
  preemptible       = false
}

module "redis" {
  source = "../../modules/redis"

  project_id        = var.project_id
  region            = var.region
  name_prefix       = "order-service-prod"
  network_self_link = module.network.network_self_link
  tier              = "STANDARD_HA"
  memory_size_gb    = 4
}

module "postgres" {
  source = "../../modules/postgres"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "order-service-prod"
  tier        = "db-custom-2-7680"
}
