# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     MINIMAL EXAMPLE - SCALEWAY  MODULE                     ║

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
