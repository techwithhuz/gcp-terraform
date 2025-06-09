variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone where VM instance will be created."
  type        = string
  default     = "us-central1-a"
}
