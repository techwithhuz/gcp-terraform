resource "google_compute_network" "custom_network" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_subnetwork" "custom_subnetwork" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.custom_network.id
  region        = var.region
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"

  target_tags = ["ssh"]
  labels = {
    creator = "gcp-terraform-agent"
  }
}

resource "google_compute_instance" "default" {
  name         = "debian-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    labels = {
      creator = "gcp-terraform-agent"
    }
  }

  network_interface {
    network    = google_compute_network.custom_network.name
    subnetwork = google_compute_subnetwork.custom_subnetwork.name

    access_config {
      // Assign a one-to-one NAT IP to the instance
    }
  }

  tags = ["ssh"]

  labels = {
    creator = "gcp-terraform-agent"
  }
}
