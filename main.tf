# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MAIN RESOURCES                                   ║
# ║                                                                                ║
# ║  Scaleway Secret Manager and Key Manager resources.                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Secrets
# ------------------------------------------------------------------------------
# Creates secrets in Scaleway Secret Manager.
# Secrets are containers that hold versioned secret data.
# ==============================================================================

resource "scaleway_secret" "this" {
  for_each = var.secrets

  name        = coalesce(each.value.name, each.key)
  description = each.value.description
  path        = each.value.path
  protected   = each.value.protected
  tags        = distinct(concat(var.tags, each.value.tags))
  type        = each.value.type
  region      = var.region
  project_id  = var.project_id

  # Key created by this module (by map key) or an existing Key Manager key ID
  key_id = each.value.key != null ? scaleway_key_manager_key.this[each.value.key].id : each.value.key_id

  dynamic "ephemeral_policy" {
    for_each = each.value.ephemeral_policy != null ? [each.value.ephemeral_policy] : []

    content {
      ttl                   = ephemeral_policy.value.ttl
      expires_once_accessed = ephemeral_policy.value.expires_once_accessed
      action                = ephemeral_policy.value.action
    }
  }
}

# ==============================================================================
# Secret Versions
# ------------------------------------------------------------------------------
# Creates versions for secrets.
# The payload comes from the ephemeral var.secret_data through the write-only
# data_wo argument, so it never reaches the state. Maximum size is 64 KiB.
# ==============================================================================

resource "scaleway_secret_version" "this" {
  for_each = var.secret_versions

  secret_id       = scaleway_secret.this[each.value.secret_key].id
  data_wo         = var.secret_data[each.key]
  data_wo_version = each.value.data_wo_version
  description     = each.value.description
  region          = var.region
}

# ==============================================================================
# Key Manager Keys
# ------------------------------------------------------------------------------
# Creates encryption keys in Scaleway Key Manager.
# Keys are used for cryptographic operations.
# ==============================================================================

resource "scaleway_key_manager_key" "this" {
  for_each = var.keys

  name             = coalesce(each.value.name, each.key)
  usage            = each.value.usage
  algorithm        = each.value.algorithm
  description      = each.value.description
  tags             = distinct(concat(var.tags, each.value.tags))
  unprotected      = !each.value.protected
  protection_level = each.value.protection_level
  region           = var.region
  project_id       = var.project_id

  dynamic "rotation_policy" {
    for_each = each.value.rotation_period != null ? [each.value.rotation_period] : []

    content {
      rotation_period = rotation_policy.value
    }
  }
}
