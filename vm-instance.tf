terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "region" {
  description = "The region in which resources will be created."
  type        = string
  default     = "us-central1"
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_network" "vpc_network" {
  name = "custom-vpc-network"
  auto_create_subnetworks = false

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  direction = "INGRESS"

  target_tags = ["ssh-access"]

  description = "Allow SSH from anywhere"

  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id

    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["ssh-access"]

  labels = {
    creator = "gcp-terraform-agent"
  }

  depends_on = [
    google_project_service.compute_api
  ]
}

output "instance_name" {
  value = google_compute_instance.vm_instance.name
}

output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
