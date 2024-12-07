variable "prefix" {
  description = "A prefix used for all resources in this example"
  default     = "test-ralph"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
  default     = "westus2"
}

variable "app-image-ref" {
  description = "The application image reference to use to test workload identity."
  default     = "ghcr.io/squillace/cosmosworkload:0.1.0"
}

variable "node_sku" {
  description = "The azure vm sku name. The sku must be available in the region you select in the location variable."
  default = Standard_DS2_v2
}
