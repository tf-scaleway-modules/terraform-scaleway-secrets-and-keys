terraform {
  required_version = ">= 1.11.0" // OpenTofu 1.11+ (write-only arguments)

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.86"
    }
  }
}
