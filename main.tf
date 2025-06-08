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

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  project = var.project_id
  disable_on_destroy = false
  depends_on = [google_project_service.compute_api]
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_project_service" "compute_service" {
  service = "compute.googleapis.com"
  project = var.project_id
  disable_on_destroy = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_network" "custom_vpc" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.custom_vpc.id
  project       = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "allow-ssh"
  network = google_compute_network.custom_vpc.id
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

resource "google_compute_address" "external_ip" {
  name    = "external-ip"
  project = var.project_id
  region  = var.region
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-instance"
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_vpc.name
    subnetwork = google_compute_subnetwork.custom_subnet.name

    access_config {
      nat_ip = google_compute_address.external_ip.address
    }
  }

  labels = {
    creator = "gcp-terraform-agent"
  }
}
