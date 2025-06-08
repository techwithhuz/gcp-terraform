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

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  depends_on = []
  disable_on_destroy = false
}

resource "google_compute_network" "custom_network" {
  name                    = "custom-vpc-network"
  auto_create_subnetworks = false
  project                 = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.custom_network.id
  project       = var.project_id

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_network.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]

  direction = "INGRESS"
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-e2-micro"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    access_config {}
  }

  labels = {
    creator = "gcp-terraform-agent"
  }
}
