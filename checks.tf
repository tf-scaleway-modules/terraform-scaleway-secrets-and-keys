# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              CHECKS                                           ║
# ║                                                                                ║
# ║  Plan-time warnings for legal but risky configurations.                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

check "keys_deletable" {
  assert {
    condition     = alltrue([for k, v in var.keys : !v.unprotected])
    error_message = "Keys can be deleted (unprotected = true, the module default): ${join(", ", [for k, v in var.keys : k if v.unprotected])}. Set unprotected = false to protect them."
  }
}

check "data_wo_version_set" {
  assert {
    condition     = alltrue([for k, v in var.secret_versions : v.data_wo == null || v.data_wo_version != null])
    error_message = "Secret versions with data_wo but no data_wo_version never get a new version when data_wo changes: ${join(", ", [for k, v in var.secret_versions : k if v.data_wo != null && v.data_wo_version == null])}."
  }
}
