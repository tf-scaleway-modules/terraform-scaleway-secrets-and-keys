# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     MINIMAL EXAMPLE - OUTPUTS                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

output "project_id" {
  description = "The resolved project ID"
  value       = module.secrets_and_keys.project_id
}

output "secret_ids" {
  description = "IDs of created secrets"
  value       = module.secrets_and_keys.secret_ids
}

output "key_ids" {
  description = "IDs of created keys"
  value       = module.secrets_and_keys.key_ids
}
