terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
  depends_on = []
  labels = {
    creator = "gcp-terraform-agent"
  }
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
  network       = google_compute_network.custom_network.id
  region        = var.region
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "allow-ssh"
  network = google_compute_network.custom_network.name
  allows {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  direction    = "INGRESS"
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "default" {
  name         = "vm-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.name
    subnetwork = google_compute_subnetwork.custom_subnetwork.name

    access_config {
      // Ephemeral public IP
    }
  }

  labels = {
    creator = "gcp-terraform-agent"
  }

  depends_on = [google_project_service.compute_api]
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

output "instance_ip" {
  description = "The external IP of the VM instance"
  value       = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
