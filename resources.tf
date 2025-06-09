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

    access_config {
      // Ephemeral external IP
    }
  }

  tags = ["allow-ssh"]

  labels = {
    creator = "gcp-terraform-agent"
  }
}
