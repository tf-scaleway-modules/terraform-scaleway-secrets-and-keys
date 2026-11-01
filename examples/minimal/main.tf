# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              MINIMAL EXAMPLE - SCALEWAY SECRETS AND KEYS MODULE              ║
# ║                                                                                ║
# ║  This example demonstrates the simplest usage of the module:                  ║
# ║  - A single secret with one version                                           ║
# ║  - A single encryption key                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Variables
# ==============================================================================

variable "project_id" {
  description = "Your Scaleway Project ID (null for the provider's default project)"
  type        = string
  default     = null
}

variable "api_key" {
  description = "API key stored as the secret value; ephemeral, so it never reaches the state"
  type        = string
  sensitive   = true
  ephemeral   = true
}

# ==============================================================================
# Module Usage
# ==============================================================================

module "secrets_and_keys" {
  source = "../../"

  project_id = var.project_id

  # Create a simple secret
  secrets = {
    api_key = {
      name        = "my-api-key"
      description = "API key for external service"
      key         = "main"
    }
  }

  # Add the secret value: the payload goes through the ephemeral secret_data
  secret_versions = {
    api_key_v1 = {
      secret_key      = "api_key"
      data_wo_version = 1 # bump to push a new value
    }
  }
  secret_data = {
    api_key_v1 = var.api_key
  }

  # Create an encryption key
  keys = {
    main = {
      name      = "main-encryption-key"
      usage     = "symmetric_encryption"
      algorithm = "aes_256_gcm"
    }
  }
}
