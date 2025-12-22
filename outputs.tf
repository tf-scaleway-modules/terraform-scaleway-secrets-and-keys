# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MODULE OUTPUTS                                   ║
# ║                                                                                ║
# ║  Outputs for secrets, secret versions, and encryption keys.                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Output
# ==============================================================================

output "project_id" {
  description = "The ID of the Scaleway project (resolved from project_name)."
  value       = local.project_id
}

# ==============================================================================
# Secret Outputs
# ==============================================================================

output "secrets" {
  description = <<-EOT
    Map of created secrets with their attributes.

    Each entry contains:
    - id: The unique identifier of the secret
    - name: The name of the secret
    - path: The path hierarchy
    - status: Current status of the secret
    - version_count: Number of versions
    - created_at: Creation timestamp (RFC 3339)
    - updated_at: Last update timestamp (RFC 3339)
  EOT
  value = {
    for key, secret in scaleway_secret.this : key => {
      id            = secret.id
      name          = secret.name
      path          = secret.path
      status        = secret.status
      version_count = secret.version_count
      created_at    = secret.created_at
      updated_at    = secret.updated_at
    }
  }
}

output "secret_ids" {
  description = "Map of secret keys to their IDs for easy reference."
  value       = local.secret_ids
}

# ==============================================================================
# Secret Version Outputs
# ==============================================================================

output "secret_versions" {
  description = <<-EOT
    Map of created secret versions with their attributes.

    Each entry contains:
    - id: The unique identifier of the version
    - secret_id: The ID of the parent secret
    - revision: The revision number
    - status: Current status of the version
    - created_at: Creation timestamp (RFC 3339)
    - updated_at: Last update timestamp (RFC 3339)
  EOT
  value = {
    for key, version in scaleway_secret_version.this : key => {
      id         = version.id
      secret_id  = version.secret_id
      revision   = version.revision
      status     = version.status
      created_at = version.created_at
      updated_at = version.updated_at
    }
  }
}

# ==============================================================================
# Key Manager Outputs
# ==============================================================================

output "keys" {
  description = <<-EOT
    Map of created encryption keys with their attributes.

    Each entry contains:
    - id: The unique identifier of the key
    - name: The name of the key
    - usage: The usage type (symmetric_encryption, asymmetric_encryption, asymmetric_signing)
    - algorithm: The cryptographic algorithm
    - state: Current state of the key
    - protected: Whether the key is protected from deletion
    - rotation_count: Number of rotations performed
    - rotated_at: Last rotation timestamp
    - created_at: Creation timestamp (RFC 3339)
    - updated_at: Last update timestamp (RFC 3339)
  EOT
  value = {
    for key, kms_key in scaleway_key_manager_key.this : key => {
      id             = kms_key.id
      name           = kms_key.name
      usage          = kms_key.usage
      algorithm      = kms_key.algorithm
      state          = kms_key.state
      protected      = kms_key.protected
      rotation_count = kms_key.rotation_count
      rotated_at     = kms_key.rotated_at
      created_at     = kms_key.created_at
      updated_at     = kms_key.updated_at
    }
  }
}

output "key_ids" {
  description = "Map of key keys to their IDs for easy reference."
  value       = local.key_ids
}
