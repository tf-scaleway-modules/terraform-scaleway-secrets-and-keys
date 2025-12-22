# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              LOCAL VALUES                                     ║
# ║                                                                                ║
# ║  Computed values and transformations used throughout the module.              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ==============================================================================
  # Project ID Resolution
  # ------------------------------------------------------------------------------
  # Resolves the project ID from the data source when project_name is provided.
  # Returns null if no project_name is specified.
  # ==============================================================================
  project_id = var.project_name != null ? data.scaleway_account_project.project[0].id : null

}
