terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"

  depends_on = [
    google_project_service.compute_api
  ]
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
