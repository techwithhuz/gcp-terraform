resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
  project = var.project_id
  labels = {
    creator = "gcp-terraform-agent"
  }
}

variable "project_id" {
  description = "The GCP project ID"
  type = string
}
