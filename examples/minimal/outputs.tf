# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     MINIMAL EXAMPLE - OUTPUTS                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

output "secret_ids" {
  description = "IDs of created secrets"
  value       = { for k, v in module.secrets_and_keys.secrets : k => v.id }
}

output "key_ids" {
  description = "IDs of created keys"
  value       = { for k, v in module.secrets_and_keys.keys : k => v.id }
}
