terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "gcs" {
    bucket = "order-service-tfstate-494251076287"
    prefix = "prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
