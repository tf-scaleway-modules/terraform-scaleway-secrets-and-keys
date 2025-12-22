# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     COMPLETE EXAMPLE - SCALEWAY  MODULE                    ║

# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Variables for the example
# ==============================================================================

variable "organization_id" {
  description = "Your Scaleway Organization ID"
  type        = string
}

variable "project_name" {
  description = "Your Scaleway Project name"
  type        = string
}

# ==============================================================================
# Data Sources
# ==============================================================================
# Look up the project to get the project_id for policy rules

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = var.organization_id
}
