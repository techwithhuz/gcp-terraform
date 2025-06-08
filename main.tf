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
  depends_on = []
}

resource "google_compute_network" "custom_network" {
  name                    = "custom-network"
  auto_create_subnetworks = false
  project                 = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.custom_network.id
  region        = var.region
  project       = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall-rule"
  network = google_compute_network.custom_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  direction = "INGRESS"
  target_tags = ["ssh-access"]
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "e2-micro-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project_id

  tags = ["ssh-access"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id

    access_config {
      // Ephemeral external IP
    }
  }

  labels = {
    creator = "gcp-terraform-agent"
  }
}

output "instance_name" {
  description = "The name of the VM instance"
  value       = google_compute_instance.vm_instance.name
}

output "instance_ip" {
  description = "The external IP of the VM instance"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
