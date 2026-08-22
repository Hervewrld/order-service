resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = "${var.name_prefix}-gke"
  location = var.zone

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Node pool is managed separately below; remove the default one.
  # GKE still briefly provisions the default pool's node(s) before Terraform
  # removes it, so shrink its footprint - otherwise it uses a 100GB default
  # disk and can blow a regional SSD quota for no reason.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 20
  }

  deletion_protection = false
}

resource "google_container_node_pool" "primary" {
  project    = var.project_id
  name       = "${var.name_prefix}-pool"
  location   = var.zone
  cluster    = google_container_cluster.this.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    preemptible  = var.preemptible
    disk_size_gb = 30

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
