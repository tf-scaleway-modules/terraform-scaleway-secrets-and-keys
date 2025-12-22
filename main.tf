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

  name        = each.value.name
  description = each.value.description
  path        = each.value.path
  protected   = each.value.protected
  tags        = each.value.tags
  type        = each.value.type
  region      = var.region
  project_id  = local.project_id

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
# Each version contains the actual secret data payload.
# Maximum data size is 64 KiB.
# ==============================================================================

resource "scaleway_secret_version" "this" {
  for_each = var.secret_versions

  secret_id   = scaleway_secret.this[each.value.secret_key].id
  data        = each.value.data
  description = each.value.description
  region      = var.region
}

# ==============================================================================
# Key Manager Keys
# ------------------------------------------------------------------------------
# Creates encryption keys in Scaleway Key Manager.
# Keys are used for cryptographic operations.
# ==============================================================================

resource "scaleway_key_manager_key" "this" {
  for_each = var.keys

  name        = each.value.name
  usage       = each.value.usage
  algorithm   = each.value.algorithm
  description = each.value.description
  tags        = each.value.tags
  unprotected = each.value.unprotected
  region      = var.region
  project_id  = local.project_id

  dynamic "rotation_policy" {
    for_each = each.value.rotation_period != null ? [each.value.rotation_period] : []

    content {
      rotation_period = rotation_policy.value
    }
  }

  # Ignore changes to computed attributes that cause drift
  lifecycle {
    ignore_changes = [
      rotation_policy[0].next_rotation_at,
    ]
  }
}
