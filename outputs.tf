# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MODULE OUTPUTS                                   ║
# ║                                                                                ║
# ║  Outputs for secrets, secret versions, and encryption keys.                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Secret Outputs
# ==============================================================================

output "secrets" {
  description = "Map of created secrets keyed like `secrets`, with `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`."
  value = {
    for key, secret in scaleway_secret.this : key => {
      id            = secret.id
      name          = secret.name
      path          = secret.path
      status        = secret.status
      version_count = secret.version_count
      created_at    = secret.created_at
      updated_at    = secret.updated_at
      srn           = secret.srn
    }
  }
}

# ==============================================================================
# Secret Version Outputs
# ==============================================================================

output "secret_versions" {
  description = "Map of created secret versions keyed like `secret_versions`, with `id`, `secret_id`, `revision`, `status`, `created_at`, `updated_at` and `srn`."
  value = {
    for key, version in scaleway_secret_version.this : key => {
      id         = version.id
      secret_id  = version.secret_id
      revision   = version.revision
      status     = version.status
      created_at = version.created_at
      updated_at = version.updated_at
      srn        = version.srn
    }
  }
}

# ==============================================================================
# Key Manager Outputs
# ==============================================================================

output "keys" {
  description = "Map of created encryption keys keyed like `keys`, with `id`, `name`, `usage`, `algorithm`, `state`, `protected`, `rotation_count`, `rotated_at`, `created_at`, `updated_at` and `srn`."
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
      srn            = kms_key.srn
    }
  }
}
