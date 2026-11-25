# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              INPUT VARIABLES                                  ║
# ║                                                                                ║
# ║  Configurable parameters for Scaleway Secrets and Key Manager resources.      ║
# ║  Variables are organized by category with comprehensive validation.           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project, Tags & Region
# ------------------------------------------------------------------------------
# Where resources are created and the tags every secret and key carries.
# ==============================================================================

variable "project_id" {
  description = "Scaleway Project ID (UUID) where secrets and keys are created. When `null`, the provider's default project applies."
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "Project ID must be a valid UUID."
  }
}

variable "tags" {
  description = "Tags applied to every secret and key, merged without duplicates with the tags of each item. Secret versions carry no tags."
  type        = list(string)
  default     = []
}

variable "region" {
  description = "Scaleway region where resources are created: `fr-par`, `nl-ams` or `pl-waw`. When `null`, the provider's region applies."
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
  description = "Map of secrets to create in Scaleway Secret Manager, keyed by a stable reference used by `secret_versions`. See Input reference in the README for every attribute."
  type = map(object({
    name        = optional(string)
    description = optional(string)
    path        = optional(string, "/")
    protected   = optional(bool, false)
    tags        = optional(list(string), [])
    type        = optional(string, "opaque")
    key         = optional(string)
    key_id      = optional(string)
    ephemeral_policy = optional(object({
      ttl                   = optional(string)
      expires_once_accessed = optional(bool, false)
      action                = optional(string, "delete")
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets : can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,253}[a-zA-Z0-9]$", coalesce(v.name, k))) || length(coalesce(v.name, k)) == 1
    ])
    error_message = "Secret names must be 1-255 characters, alphanumeric with dots, underscores, and hyphens."
  }

  validation {
    condition     = alltrue([for k, v in var.secrets : can(regex("^/[a-zA-Z0-9._/-]*$", v.path))])
    error_message = "Secret path must start with / and use letters, digits, dots, underscores, hyphens and slashes."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : contains(["opaque", "certificate", "key_value", "basic_credentials", "database_credentials", "ssh_key"], v.type)
    ])
    error_message = "Secret type must be one of: opaque, certificate, key_value, basic_credentials, database_credentials, ssh_key."
  }

  validation {
    condition     = alltrue([for k, v in var.secrets : v.key == null || v.key_id == null])
    error_message = "A secret can set key or key_id, not both."
  }

  validation {
    condition     = alltrue([for k, v in var.secrets : v.key == null || contains(keys(var.keys), v.key)])
    error_message = "Each secret key must be a key of the keys variable."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : v.ephemeral_policy == null || contains(["delete", "disable"], v.ephemeral_policy.action)
    ])
    error_message = "Ephemeral policy action must be 'delete' or 'disable'."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : v.ephemeral_policy == null || v.ephemeral_policy.ttl == null || can(regex("^([0-9]+(h|m|s))+$", v.ephemeral_policy.ttl))
    ])
    error_message = "Ephemeral policy ttl must be a duration such as 24h or 1h30m."
  }
}

# ==============================================================================
# Secret Versions Configuration
# ==============================================================================

variable "secret_versions" {
  description = "Map of secret versions to create, keyed by a stable reference shared with `secret_data`, which holds the payload. Each entry points to a secret of `secrets`. See Input reference in the README for every attribute."
  type = map(object({
    secret_key      = string
    data_wo_version = optional(number, 1)
    description     = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.secret_versions : contains(keys(var.secrets), v.secret_key)])
    error_message = "Each secret version secret_key must be a key of the secrets variable."
  }

  validation {
    condition     = alltrue([for k, v in var.secret_versions : try(v.data_wo_version == floor(v.data_wo_version), false)])
    error_message = "Secret version data_wo_version must be a whole number."
  }
}

variable "secret_data" {
  description = "Sensitive and ephemeral map of secret version payloads keyed like `secret_versions`, each at most 64 KiB. Values are sent through the write-only `data_wo` argument and never reach the state or a plan file; a new value is sent only when `data_wo_version` changes."
  type        = map(string)
  default     = {}
  sensitive   = true
  ephemeral   = true

  validation {
    condition     = alltrue([for k in keys(var.secret_data) : contains(keys(var.secret_versions), k)])
    error_message = "Each secret_data key must be a key of the secret_versions variable."
  }

  validation {
    condition     = alltrue([for k in keys(var.secret_versions) : contains(keys(var.secret_data), k)])
    error_message = "Each secret version must have a secret_data entry."
  }

  # Bytes, not characters: base64 encodes the UTF-8 bytes and its unpadded
  # length is ceil(4n/3), i.e. 87382 for 65536 bytes and 87383 for 65537.
  validation {
    condition     = alltrue([for k, d in var.secret_data : length(replace(base64encode(d), "=", "")) <= 87382])
    error_message = "Secret version data must not exceed 64 KiB (65536 bytes)."
  }
}

# ==============================================================================
# Key Manager Configuration
# ==============================================================================

variable "keys" {
  description = "Map of encryption keys to create in Scaleway Key Manager, keyed by a stable reference used by `secrets`. See Input reference in the README for every attribute, valid usage and algorithm pairs."
  type = map(object({
    name             = optional(string)
    usage            = string
    algorithm        = string
    description      = optional(string)
    tags             = optional(list(string), [])
    protected        = optional(bool, true)
    rotation_period  = optional(string)
    protection_level = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.keys : v.rotation_period == null || can(regex("^([0-9]+(h|m|s))+$", v.rotation_period))])
    error_message = "Key rotation_period must be a duration such as 8760h."
  }

  validation {
    condition     = alltrue([for k, v in var.keys : v.protection_level == null || contains(["software", "hsm"], v.protection_level)])
    error_message = "Key protection_level must be 'software' or 'hsm'."
  }

  validation {
    condition = alltrue([
      for k, v in var.keys : contains(["symmetric_encryption", "asymmetric_encryption", "asymmetric_signing", "key_encapsulation"], v.usage)
    ])
    error_message = "Key usage must be one of: symmetric_encryption, asymmetric_encryption, asymmetric_signing, key_encapsulation."
  }

  validation {
    condition = alltrue([
      for k, v in var.keys : contains(lookup({
        symmetric_encryption  = ["aes_256_gcm"]
        asymmetric_encryption = ["rsa_oaep_2048_sha256", "rsa_oaep_3072_sha256", "rsa_oaep_4096_sha256"]
        asymmetric_signing = [
          "ec_p256_sha256", "ec_p384_sha384", "ec_secp256k1_sha256",
          "rsa_pss_2048_sha256", "rsa_pss_3072_sha256", "rsa_pss_4096_sha256",
          "rsa_pkcs1_2048_sha256", "rsa_pkcs1_3072_sha256", "rsa_pkcs1_4096_sha256",
          "ml_dsa_44", "ml_dsa_65", "ml_dsa_87",
        ]
        key_encapsulation = ["ml_kem_768", "ml_kem_1024"]
      }, v.usage, []), v.algorithm)
    ])
    error_message = "Algorithm must be valid for the specified usage type."
  }
}
