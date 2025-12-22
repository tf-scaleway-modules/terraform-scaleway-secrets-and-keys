# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              INPUT VARIABLES                                  ║
# ║                                                                                ║
# ║  All configurable parameters for the Scaleway IAM module.                     ║
# ║  Variables are organized by category with comprehensive validation.           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Organization & Project
# ------------------------------------------------------------------------------
# Required identifiers for Scaleway resource organization.
# These determine where resources are created and billed.
# ==============================================================================

variable "organization_id" {
  description = <<-EOT
    Scaleway Organization ID.

    The organization is the top-level entity in Scaleway's hierarchy.
    Find this in the Scaleway Console under Organization Settings.

    Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Organization ID must be a valid UUID format."
  }
}

variable "project_name" {
  description = <<-EOT
    Scaleway Project name where project-scoped resources will be created.

    Projects provide logical isolation within an organization.
    SSH keys and some resources are created at project level.

    Set to null if you only want to manage organization-level IAM resources.

    Naming rules:
    - Must start with a lowercase letter
    - Can contain lowercase letters, numbers, and hyphens
    - Must be 2-63 characters long
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.project_name == null || can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 2-63 characters."
  }
}
