variable "project" {
  description = "Your GCP Project ID"
  default     = "de-zoomcamp-507105"
}

variable "region" {
  description = "Region for GCP resources"
  default     = "us-central1"
}

variable "credentials" {
  description = "Path to the GCP service account JSON key"
  default     = "../../.gcp/gcp-credentials.json"
}

variable "dataset_name" {
  description = "BigQuery dataset name"
  default     = "trips_data_all"
}