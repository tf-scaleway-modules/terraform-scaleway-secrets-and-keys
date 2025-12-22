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

variable "organization_id" {
  description = "Your Scaleway Organization ID"
  type        = string
}

variable "project_name" {
  description = "Your Scaleway Project name"
  type        = string
}

# ==============================================================================
# Module Usage
# ==============================================================================

module "secrets_and_keys" {
  source = "../../"

  organization_id = var.organization_id
  project_name    = var.project_name

  # Create a simple secret
  secrets = {
    api_key = {
      name        = "my-api-key"
      description = "API key for external service"
    }
  }

  # Add the secret value
  secret_versions = {
    api_key_v1 = {
      secret_key = "api_key"
      data       = "super-secret-api-key-value"
    }
  }

  # Create an encryption key
  keys = {
    main = {
      name      = "main-encryption-key"
      usage     = "symmetric_encryption"
      algorithm = "aes256_gcm"
    }
  }
}
