# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║             COMPLETE EXAMPLE - SCALEWAY SECRETS AND KEYS MODULE              ║
# ║                                                                              ║
# ║  This example demonstrates all features of the module:                       ║
# ║  - Multiple secrets with different configurations                            ║
# ║  - Ephemeral secrets with TTL                                                ║
# ║  - Protected secrets                                                         ║
# ║  - Multiple encryption keys with different algorithms                        ║
# ║  - Key rotation policies                                                     ║
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

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

# ==============================================================================
# Module Usage
# ==============================================================================

module "secrets_and_keys" {
  source = "../../"

  organization_id = var.organization_id
  project_name    = var.project_name
  region          = var.region

  # ===========================================================================
  # Secrets Configuration
  # ===========================================================================
  secrets = {
    # Standard secret for API credentials
    api_credentials = {
      name        = "production-api-credentials"
      description = "API credentials for production environment"
      path        = "/production/api"
      tags        = ["production", "api", "managed-by-terraform"]
      type        = "opaque"
    }

    # Database credentials with specific type
    database = {
      name        = "production-database"
      description = "Database connection credentials"
      path        = "/production/database"
      tags        = ["production", "database", "managed-by-terraform"]
      type        = "database_credentials"
    }

    # Protected secret that cannot be accidentally deleted
    critical_key = {
      name        = "critical-encryption-key"
      description = "Critical encryption key - protected from deletion"
      path        = "/production/encryption"
      protected   = false
      tags        = ["production", "critical", "managed-by-terraform"]
    }

    # Ephemeral secret that expires after 24 hours
    temporary_token = {
      name        = "temporary-access-token"
      description = "Temporary token that expires after 24 hours"
      path        = "/temporary"
      tags        = ["temporary", "auto-expire"]
      ephemeral_policy = {
        ttl                   = "24h"
        expires_once_accessed = false
        action                = "delete"
      }
    }

    # One-time secret that expires after first access
    one_time_password = {
      name        = "one-time-password"
      description = "Password that can only be read once"
      path        = "/temporary"
      tags        = ["one-time", "auto-expire"]
      ephemeral_policy = {
        expires_once_accessed = true
        action                = "disable"
      }
    }
  }

  # ===========================================================================
  # Secret Versions
  # ===========================================================================
  secret_versions = {
    api_credentials_v1 = {
      secret_key  = "api_credentials"
      data        = "api-key-12345-secret-value"
      description = "Initial API credentials"
    }

    database_v1 = {
      secret_key  = "database"
      data        = "{\"engine\": \"postgres\", \"host\": \"db.example.com\", \"dbname\": \"myapp\", \"port\": \"5432\", \"username\": \"dbuser\", \"password\": \"secure-password-123\"}"
      description = "Database credentials v1"
    }

    critical_key_v1 = {
      secret_key  = "critical_key"
      data        = "base64-encoded-encryption-key"
      description = "Primary encryption key"
    }

    temporary_token_v1 = {
      secret_key = "temporary_token"
      data       = "temp-token-xyz-789"
    }

    one_time_password_v1 = {
      secret_key = "one_time_password"
      data       = "one-time-secret-password"
    }
  }

  # ===========================================================================
  # Key Manager Keys
  # ===========================================================================
  keys = {
    # AES-256 symmetric key for data encryption
    data_encryption = {
      name        = "data-encryption-key"
      usage       = "symmetric_encryption"
      algorithm   = "aes_256_gcm"
      description = "Primary symmetric key for data encryption"
      tags        = ["production", "encryption", "managed-by-terraform"]
    }

    # RSA key for asymmetric encryption
    asymmetric_encryption = {
      name        = "asymmetric-encryption-key"
      usage       = "asymmetric_encryption"
      algorithm   = "rsa_oaep_4096_sha256"
      description = "RSA-4096 key for asymmetric encryption"
      tags        = ["production", "encryption", "managed-by-terraform"]
    }

    # Signing key for digital signatures
    signing = {
      name        = "document-signing-key"
      usage       = "asymmetric_signing"
      algorithm   = "ec_p384_sha384"
      description = "ECDSA P-384 key for document signing"
      tags        = ["production", "signing", "managed-by-terraform"]
    }

    # Key with automatic rotation (rotates yearly)
    rotating_key = {
      name            = "auto-rotating-key"
      usage           = "symmetric_encryption"
      algorithm       = "aes_256_gcm"
      description     = "Symmetric key with automatic yearly rotation"
      tags            = ["production", "auto-rotate", "managed-by-terraform"]
      rotation_period = "8760h" # 1 year (365 days * 24 hours)
    }

    # Unprotected key (can be deleted)
    development = {
      name        = "development-key"
      usage       = "symmetric_encryption"
      algorithm   = "aes_256_gcm"
      description = "Development key - not protected"
      tags        = ["development", "managed-by-terraform"]
      unprotected = true
    }
  }
}
