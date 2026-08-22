output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_endpoint" {
  value = module.gke.endpoint
}

output "redis_host" {
  value = module.redis.host
}

output "redis_port" {
  value = module.redis.port
}

output "postgres_connection_name" {
  value = module.postgres.connection_name
}

output "postgres_database" {
  value = module.postgres.database_name
}

output "postgres_user" {
  value = module.postgres.database_user
}

output "postgres_password" {
  value     = module.postgres.database_password
  sensitive = true
}
