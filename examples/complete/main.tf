# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║             COMPLETE EXAMPLE - SCALEWAY SECRETS AND KEYS MODULE              ║
# ║                                                                              ║
# ║  This example demonstrates all features of the module:                       ║
# ║  - Multiple secrets with different configurations                            ║
# ║  - Ephemeral secrets with TTL                                                ║
# ║  - Protected secrets                                                         ║
# ║  - Multiple encryption keys with different algorithms                        ║
# ║  - Key rotation policies                                                     ║
# ║  - Ephemeral write-only payloads, common tags, key-encrypted secret          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Variables
# ==============================================================================

variable "project_id" {
  description = "Your Scaleway Project ID (null for the provider's default project)"
  type        = string
  default     = null
}

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "secret_values" {
  description = "Secret payloads keyed like the secret versions; ephemeral, so they never reach the state"
  type        = map(string)
  sensitive   = true
  ephemeral   = true
}

# ==============================================================================
# Module Usage
# ==============================================================================

module "secrets_and_keys" {
  source = "../../"

  project_id = var.project_id
  region     = var.region
  tags       = ["production"]

  # ===========================================================================
  # Secrets Configuration
  # ===========================================================================
  secrets = {
    # Standard secret for API credentials
    api_credentials = {
      name        = "production-api-credentials"
      description = "API credentials for production environment"
      path        = "/production/api"
      tags        = ["api"]
      type        = "opaque"
    }

    # Database credentials encrypted with a key created by this module
    database = {
      name        = "production-database"
      key         = "data_encryption"
      description = "Database connection credentials"
      path        = "/production/database"
      tags        = ["database"]
      type        = "database_credentials"
    }

    # SSH private key stored with its dedicated type
    deploy_ssh_key = {
      name        = "production-deploy-ssh-key"
      description = "SSH key used by deployments"
      path        = "/production/ssh"
      tags        = ["ssh"]
      type        = "ssh_key"
    }

    # Protected secret that cannot be accidentally deleted
    critical_key = {
      name        = "critical-encryption-key"
      description = "Critical encryption key - protected from deletion"
      path        = "/production/encryption"
      protected   = true
      tags        = ["critical"]
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
      description = "Initial API credentials"
    }

    database_v1 = {
      secret_key      = "database"
      data_wo_version = 1 # bump to push a new value
      description     = "Database credentials v1"
    }

    critical_key_v1 = {
      secret_key  = "critical_key"
      description = "Primary encryption key"
    }

    temporary_token_v1 = {
      secret_key = "temporary_token"
    }

    one_time_password_v1 = {
      secret_key = "one_time_password"
    }
  }

  # Payloads: same keys as secret_versions, from an ephemeral source
  secret_data = var.secret_values

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
      tags        = ["encryption"]
    }

    # RSA key for asymmetric encryption
    asymmetric_encryption = {
      name        = "asymmetric-encryption-key"
      usage       = "asymmetric_encryption"
      algorithm   = "rsa_oaep_4096_sha256"
      description = "RSA-4096 key for asymmetric encryption"
      tags        = ["encryption"]
    }

    # Signing key for digital signatures
    signing = {
      name        = "document-signing-key"
      usage       = "asymmetric_signing"
      algorithm   = "ec_p384_sha384"
      description = "ECDSA P-384 key for document signing"
      tags        = ["signing"]
    }

    # Post-quantum signing key (ML-DSA)
    pq_signing = {
      name        = "post-quantum-signing-key"
      usage       = "asymmetric_signing"
      algorithm   = "ml_dsa_65"
      description = "ML-DSA-65 key for post-quantum signatures"
      tags        = ["signing"]
    }

    # Post-quantum key encapsulation key (ML-KEM)
    key_encapsulation = {
      name        = "key-encapsulation-key"
      usage       = "key_encapsulation"
      algorithm   = "ml_kem_768"
      description = "ML-KEM-768 key for post-quantum key encapsulation"
      tags        = ["encryption"]
    }

    # Key with automatic rotation (rotates yearly)
    rotating_key = {
      name            = "auto-rotating-key"
      usage           = "symmetric_encryption"
      algorithm       = "aes_256_gcm"
      description     = "Symmetric key with automatic yearly rotation"
      tags            = ["auto-rotate"]
      rotation_period = "8760h" # 1 year (365 days * 24 hours)
    }

    # Hardware Security Module key
    hsm = {
      name             = "hsm-key"
      usage            = "symmetric_encryption"
      algorithm        = "aes_256_gcm"
      description      = "Key backed by a dedicated HSM"
      protection_level = "hsm"
    }

    # Deletable key (protected = false)
    development = {
      name        = "development-key"
      usage       = "symmetric_encryption"
      algorithm   = "aes_256_gcm"
      description = "Development key - not protected"
      tags        = ["development"]
      protected   = false
    }
  }
}
