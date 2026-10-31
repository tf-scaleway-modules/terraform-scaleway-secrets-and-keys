# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     COMPLETE EXAMPLE - OUTPUTS                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Secret Outputs
# ==============================================================================

output "secrets" {
  description = "All created secrets with their metadata"
  value       = module.secrets_and_keys.secrets
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

# ==============================================================================
# Useful References
# ==============================================================================

output "database_secret_id" {
  description = "ID of the database secret for use in other resources"
  value       = module.secrets_and_keys.secrets["database"].id
}

output "database_secret_srn" {
  description = "SRN of the database secret, e.g. for IAM policies"
  value       = module.secrets_and_keys.secrets["database"].srn
}

output "key_encapsulation_key_srn" {
  description = "SRN of the ML-KEM key encapsulation key"
  value       = module.secrets_and_keys.keys["key_encapsulation"].srn
}

output "data_encryption_key_id" {
  description = "ID of the data encryption key for use in other resources"
  value       = module.secrets_and_keys.keys["data_encryption"].id
}
