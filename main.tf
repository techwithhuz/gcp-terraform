provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "custom_network" {
  name                    = "custom-network"
  auto_create_subnetworks = false

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnetwork" {
  name          = "custom-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.custom_network.self_link

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "default" {
  name         = "instance-e2-micro"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.self_link
    subnetwork = google_compute_subnetwork.custom_subnetwork.self_link
    access_config {
      // Assign an external IP
    }
  }

  tags = ["ssh-access"]

  labels = {
    creator = "gcp-terraform-agent"
  }
}

variable "project_id" {
  description = "The ID of the project in which to create resources."
  type        = string
}

variable "region" {
  description = "The region to deploy resources in."
  type        = string
  default     = "us-central1"
}

output "instance_name" {
  value = google_compute_instance.default.name
}

output "instance_external_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
