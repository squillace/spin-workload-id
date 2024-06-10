variable "prefix" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "app-image-ref" {
  description = "The application image reference to use to test workload identity."
  default     = "ghcr.io/azure/azure-workload-identity/msal-go"
}
