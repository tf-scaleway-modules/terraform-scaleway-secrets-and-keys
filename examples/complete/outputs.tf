# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     COMPLETE EXAMPLE - OUTPUTS                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Output
# ==============================================================================

output "project_id" {
  description = "The resolved project ID"
  value       = module.secrets_and_keys.project_id
}

# ==============================================================================
# Secret Outputs
# ==============================================================================

output "secrets" {
  description = "All created secrets with their metadata"
  value       = module.secrets_and_keys.secrets
}

output "secret_ids" {
  description = "Map of secret keys to their IDs"
  value       = module.secrets_and_keys.secret_ids
}

output "secret_versions" {
  description = "All created secret versions with their metadata"
  value       = module.secrets_and_keys.secret_versions
}

# ==============================================================================
# Key Outputs
# ==============================================================================

output "keys" {
  description = "All created encryption keys with their metadata"
  value       = module.secrets_and_keys.keys
}

output "key_ids" {
  description = "Map of key keys to their IDs"
  value       = module.secrets_and_keys.key_ids
}

# ==============================================================================
# Useful References
# ==============================================================================

output "database_secret_id" {
  description = "ID of the database secret for use in other resources"
  value       = module.secrets_and_keys.secret_ids["database"]
}

output "data_encryption_key_id" {
  description = "ID of the data encryption key for use in other resources"
  value       = module.secrets_and_keys.key_ids["data_encryption"]
}
