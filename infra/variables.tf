variable "prefix" {
  description = "A prefix used for all resources in this example"
  default     = "test"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
  default     = "westus3"
}

variable "app-image-ref" {
  description = "The application image reference to use to test workload identity."
  default     = "docker.io/devigned/spin-kv-test:0.0.8"
}
