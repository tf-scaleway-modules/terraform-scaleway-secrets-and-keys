# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              INPUT VARIABLES                                  ║
# ║                                                                                ║
# ║  Configurable parameters for Scaleway Secrets and Key Manager resources.      ║
# ║  Variables are organized by category with comprehensive validation.           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Organization & Project
# ------------------------------------------------------------------------------
# Required identifiers for Scaleway resource organization.
# These determine where resources are created and billed.
# ==============================================================================

variable "organization_id" {
  description = <<-EOT
    Scaleway Organization ID.

    The organization is the top-level entity in Scaleway's hierarchy.
    Find this in the Scaleway Console under Organization Settings.

    Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Organization ID must be a valid UUID format."
  }
}

variable "project_name" {
  description = <<-EOT
    Scaleway Project name where resources will be created.

    Projects provide logical isolation within an organization.
    The project ID will be automatically resolved from this name.

    Naming rules:
    - Must start with a lowercase letter
    - Can contain lowercase letters, numbers, and hyphens
    - Must be 2-63 characters long
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.project_name)) || length(var.project_name) == 1
    error_message = "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."
  }
}

variable "region" {
  description = <<-EOT
    Scaleway region where resources will be created.

    If not provided, defaults to the provider's region configuration.

    Valid regions: fr-par, nl-ams, pl-waw
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.region == null || contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "Region must be one of: fr-par, nl-ams, pl-waw."
  }
}

# ==============================================================================
# Secrets Configuration
# ==============================================================================

variable "secrets" {
  description = <<-EOT
    Map of secrets to create in Scaleway Secret Manager.

    Each secret can have multiple versions managed separately via the
    'secret_versions' variable.

    Structure:
    - name: Secret name (required, used as identifier)
    - description: Human-readable description
    - path: Path hierarchy (defaults to "/")
    - protected: If true, prevents deletion (defaults to false)
    - tags: List of tags for categorization
    - type: Secret type - "opaque" (default), "basic_credentials", or "database_credentials"
    - ephemeral_policy: Optional ephemeral configuration
      - ttl: Time-to-live in Go duration format (e.g., "24h", "168h")
      - expires_once_accessed: If true, expires after first access
      - action: Action on expiry - "delete" or "disable"
  EOT
  type = map(object({
    name        = string
    description = optional(string)
    path        = optional(string, "/")
    protected   = optional(bool, false)
    tags        = optional(list(string), [])
    type        = optional(string, "opaque")
    ephemeral_policy = optional(object({
      ttl                   = optional(string)
      expires_once_accessed = optional(bool, false)
      action                = optional(string, "delete")
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets : can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,253}[a-zA-Z0-9]$", v.name)) || length(v.name) == 1
    ])
    error_message = "Secret names must be 1-255 characters, alphanumeric with dots, underscores, and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : contains(["opaque", "basic_credentials", "database_credentials"], v.type)
    ])
    error_message = "Secret type must be one of: opaque, basic_credentials, database_credentials."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : v.ephemeral_policy == null || contains(["delete", "disable"], try(v.ephemeral_policy.action, "delete"))
    ])
    error_message = "Ephemeral policy action must be 'delete' or 'disable'."
  }
}

# ==============================================================================
# Secret Versions Configuration
# ==============================================================================

variable "secret_versions" {
  description = <<-EOT
    Map of secret versions to create.

    Each version is linked to a secret defined in the 'secrets' variable.
    The 'data' field contains the actual secret value.

    SECURITY: The data field is marked as sensitive and will not appear in logs.
    Maximum data size is 64 KiB.

    Structure:
    - secret_key: Key referencing a secret in the 'secrets' variable
    - data: The secret data payload (sensitive)
    - description: Optional description of this version
  EOT
  type = map(object({
    secret_key  = string
    data        = string
    description = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secret_versions : length(v.data) <= 65536
    ])
    error_message = "Secret version data must not exceed 64 KiB (65536 bytes)."
  }
}

# ==============================================================================
# Key Manager Configuration
# ==============================================================================

variable "keys" {
  description = <<-EOT
    Map of encryption keys to create in Scaleway Key Manager.

    Keys are used for cryptographic operations like encryption, decryption,
    and digital signing.

    Structure:
    - name: Key name (required)
    - usage: Key usage type (required)
      - "symmetric_encryption": For symmetric encrypt/decrypt operations
      - "asymmetric_encryption": For asymmetric encrypt/decrypt operations
      - "asymmetric_signing": For digital signatures
    - algorithm: Cryptographic algorithm (required, depends on usage)
      - For symmetric_encryption: "aes256_gcm"
      - For asymmetric_encryption: "rsa2048_oaep_sha256", "rsa3072_oaep_sha256", "rsa4096_oaep_sha256"
      - For asymmetric_signing: "rsa2048_pkcs1v15_sha256", "rsa3072_pkcs1v15_sha256", "rsa4096_pkcs1v15_sha256", "ec_p256_sha256", "ec_p384_sha384"
    - description: Human-readable description
    - tags: List of tags for categorization
    - unprotected: If true, allows key deletion (defaults to false - protected)
    - rotation_period: Automatic rotation period in Go duration format (e.g., "8760h" for 1 year)
  EOT
  type = map(object({
    name            = string
    usage           = string
    algorithm       = string
    description     = optional(string)
    tags            = optional(list(string), [])
    unprotected     = optional(bool, false)
    rotation_period = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.keys : contains(["symmetric_encryption", "asymmetric_encryption", "asymmetric_signing"], v.usage)
    ])
    error_message = "Key usage must be one of: symmetric_encryption, asymmetric_encryption, asymmetric_signing."
  }

  validation {
    condition = alltrue([
      for k, v in var.keys : (
        (v.usage == "symmetric_encryption" && contains(["aes256_gcm"], v.algorithm)) ||
        (v.usage == "asymmetric_encryption" && contains(["rsa2048_oaep_sha256", "rsa3072_oaep_sha256", "rsa4096_oaep_sha256"], v.algorithm)) ||
        (v.usage == "asymmetric_signing" && contains(["rsa2048_pkcs1v15_sha256", "rsa3072_pkcs1v15_sha256", "rsa4096_pkcs1v15_sha256", "ec_p256_sha256", "ec_p384_sha384"], v.algorithm))
      )
    ])
    error_message = "Algorithm must be valid for the specified usage type."
  }
}
