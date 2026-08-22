module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "order-service-dev"
}

module "gke" {
  source = "../../modules/gke"

  project_id        = var.project_id
  zone              = var.zone
  name_prefix       = "order-service-dev"
  network_self_link = module.network.network_self_link
  subnet_self_link  = module.network.subnet_self_link
  node_count        = 1
  machine_type      = "e2-small"
  preemptible       = true
}

module "redis" {
  source = "../../modules/redis"

  project_id        = var.project_id
  region            = var.region
  name_prefix       = "order-service-dev"
  network_self_link = module.network.network_self_link
  tier              = "BASIC"
  memory_size_gb    = 1
}

module "postgres" {
  source = "../../modules/postgres"

  project_id  = var.project_id
  region      = var.region
  name_prefix = "order-service-dev"
  tier        = "db-f1-micro"
}
