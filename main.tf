terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  labels = {
    creator = "gcp-terraform-agent"
  }
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

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  project = var.project_id
  disable_on_destroy = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_network" "vpc_network" {
  name = "custom-vpc-network"
  auto_create_subnetworks = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-ssh"]
  direction   = "INGRESS"
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "default" {
  name         = "tf-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["allow-ssh"]
  labels = {
    creator = "gcp-terraform-agent"
  }

  depends_on = [google_project_service.compute_api]
}

output "instance_name" {
  value = google_compute_instance.default.name
  description = "The name of the VM instance"
}

output "instance_external_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
  description = "The external IP address of the VM"
}
