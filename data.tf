# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              DATA SOURCES                                     ║
# ║                                                                                ║
# ║  External data lookups for existing Scaleway resources.                       ║
# ║  These provide information needed for resource configuration.                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Data Source
# ------------------------------------------------------------------------------
# Looks up the Scaleway project by name to get the project ID.
# This allows users to reference projects by name instead of ID.
# ==============================================================================

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = var.organization_id
}
