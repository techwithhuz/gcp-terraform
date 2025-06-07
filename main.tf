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
  name                    = "custom-vpc-network"
  auto_create_subnetworks = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.custom_network.id
  region        = var.region
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "default_ssh" {
  name    = "default-allow-ssh"
  network = google_compute_network.custom_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
  direction    = "INGRESS"
  priority     = 1000
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "e2-micro-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.name

    access_config {
      // Allocate ephemeral external IP
    }
  }

  tags = ["allow-ssh"]

  labels = {
    creator = "gcp-terraform-agent"
  }
}

variable "project_id" {
  description = "The ID of the GCP project"
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

output "instance_name" {
  value = google_compute_instance.vm_instance.name
}

output "instance_external_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
