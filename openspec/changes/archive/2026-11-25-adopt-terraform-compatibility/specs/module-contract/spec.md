## MODIFIED Requirements

### Requirement: Tooling and provider constraints
The module SHALL declare `required_version = ">= 1.11.0"` (write-only arguments and ephemeral variables) and the single required provider `scaleway/scaleway` with version constraint `~> 2.89`. Both OpenTofu and Terraform SHALL accept the module at that floor; the single `required_version` constraint serves both and no OpenTofu-only construct is used.

#### Scenario: Older tooling
- **WHEN** the module is used with OpenTofu/Terraform older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Provider constraint
- **WHEN** the module is initialised
- **THEN** the `scaleway/scaleway` provider is selected within `~> 2.89`

#### Scenario: Provider older than the floor
- **WHEN** the calling configuration pins the Scaleway provider to 2.86.x
- **THEN** initialisation fails because no version satisfies both constraints

#### Scenario: Terraform consumer
- **WHEN** the module and each example under `examples/` are initialised with `terraform init -backend=false` and checked with `terraform validate` on Terraform 1.11.0 or later
- **THEN** validation succeeds, exactly as with OpenTofu
