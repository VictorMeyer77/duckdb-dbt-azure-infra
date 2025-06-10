variable "containers" {
  type        = list(string)
  description = "(Optional) List of containers to create in storage"
  default     = ["raw", "bronze", "silver", "gold"]
}