terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "custom_vpc" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.custom_vpc.id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-ssh"]

  description = "Allow SSH from anywhere"

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc.id
    subnetwork = google_compute_subnetwork.custom_subnet.id

    access_config {}
  }

  tags = ["allow-ssh"]

  labels = {
    creator = "gcp-terraform-agent"
  }
}

variable "project_id" {
  description = "The project ID to deploy resources"
  type        = string
}

variable "region" {
  description = "The region to host the VM"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to host the VM"
  type        = string
  default     = "us-central1-a"
}
