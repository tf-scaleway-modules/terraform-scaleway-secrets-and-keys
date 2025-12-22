# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              LOCAL VALUES                                     ║
# ║                                                                                ║
# ║  Computed values and transformations used throughout the module.              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ==============================================================================
  # Project ID Resolution
  # ------------------------------------------------------------------------------
  # Resolves the project ID from the data source.
  # ==============================================================================
  project_id = data.scaleway_account_project.this.id

  # ==============================================================================
  # Secret ID Mapping
  # ------------------------------------------------------------------------------
  # Maps secret keys to their created IDs for easy reference.
  # ==============================================================================
  secret_ids = {
    for key, secret in scaleway_secret.this : key => secret.id
  }

  # ==============================================================================
  # Secret Version Mapping
  # ------------------------------------------------------------------------------
  # Maps version keys to their revision numbers.
  # ==============================================================================
  secret_version_revisions = {
    for key, version in scaleway_secret_version.this : key => version.revision
  }

  # ==============================================================================
  # Key ID Mapping
  # ------------------------------------------------------------------------------
  # Maps key keys to their created IDs for easy reference.
  # ==============================================================================
  key_ids = {
    for key, kms_key in scaleway_key_manager_key.this : key => kms_key.id
  }
}
