## MODIFIED Requirements

### Requirement: Tooling and provider constraints
The module SHALL declare `required_version = ">= 1.11.0"` (OpenTofu/Terraform with write-only arguments) and the single required provider `scaleway/scaleway` with version constraint `~> 2.89`.

#### Scenario: Older tooling
- **WHEN** the module is used with OpenTofu/Terraform older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Provider constraint
- **WHEN** the module is initialised
- **THEN** the `scaleway/scaleway` provider is selected within `~> 2.89`

#### Scenario: Provider older than the floor
- **WHEN** the calling configuration pins the Scaleway provider to 2.86.x
- **THEN** initialisation fails because no version satisfies both constraints

### Requirement: Output attributes
`secrets` SHALL map each input key to `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`. `secret_versions` SHALL map each input key to `id`, `secret_id`, `revision`, `status`, `created_at`, `updated_at` and `srn`. `keys` SHALL map each input key to `id`, `name`, `usage`, `algorithm`, `state`, `protected`, `rotation_count`, `rotated_at`, `created_at`, `updated_at` and `srn`. `srn` is the Scaleway Resource Name of the resource and is not secret.

#### Scenario: Attributes of a secret entry
- **WHEN** a secret is created under the key `db`
- **THEN** `secrets["db"]` has exactly the attributes `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`

#### Scenario: SRN of a key
- **WHEN** a key is created under the key `main`
- **THEN** `keys["main"].srn` is the key's Scaleway Resource Name and `keys["main"]` contains no secret data
