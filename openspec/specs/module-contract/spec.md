# module-contract Specification

## Purpose
Supported tooling and provider versions, project inputs and resolution, and the outputs of the module.

## Requirements

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

### Requirement: No provider or backend configuration
The module MUST NOT contain `provider` or `backend` blocks; the caller configures the Scaleway provider.

#### Scenario: Caller configures the provider
- **WHEN** the module is called
- **THEN** it uses the Scaleway provider configuration of the calling root module

### Requirement: Organization and project inputs
The module SHALL require `organization_id` (string, no default) and `project_name` (string, no default). It MUST reject an `organization_id` that is not a lowercase UUID and a `project_name` that is not 1 to 63 characters of lowercase letters, digits and hyphens, starting with a letter and ending with a letter or digit (a single letter is accepted).

#### Scenario: Invalid organization ID
- **WHEN** `organization_id = "not-a-uuid"`
- **THEN** the plan fails with "Organization ID must be a valid UUID format."

#### Scenario: Invalid project name
- **WHEN** `project_name = "Prod"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."

#### Scenario: Single character that is not a letter
- **WHEN** `project_name = "1"` or `project_name = "-"`
- **THEN** the plan fails with the same error

#### Scenario: Single letter project name
- **WHEN** `project_name = "a"`
- **THEN** no validation error is raised

### Requirement: Region input
The module SHALL accept an optional `region` (string, default `null`, meaning the provider's region) and MUST reject a value other than `fr-par`, `nl-ams` or `pl-waw`.

#### Scenario: Unsupported region
- **WHEN** `region = "us-east-1"`
- **THEN** the plan fails with "Region must be one of: fr-par, nl-ams, pl-waw."

#### Scenario: Region omitted
- **WHEN** `region` is not set
- **THEN** no validation error is raised and resources receive a null region, so the provider region applies

### Requirement: Project resolution by name
The module SHALL resolve the project through a `scaleway_account_project` data source using `project_name` and `organization_id`, and SHALL create every secret and key in that project. It SHALL expose the resolved ID as the `project_id` output.

#### Scenario: Project looked up by name
- **WHEN** `project_name = "my-project"` and a valid `organization_id` are given
- **THEN** `project_id` equals the ID of that project and secrets and keys are created with it

### Requirement: Outputs
The module SHALL expose the outputs `project_id`, `secrets`, `secret_ids`, `secret_versions`, `keys` and `key_ids`, none of them sensitive. `secret_ids` and `key_ids` SHALL map each input key to the resource ID. No output SHALL contain secret data.

#### Scenario: Default inputs
- **WHEN** `secrets`, `secret_versions` and `keys` are all left at their `{}` default
- **THEN** `secrets`, `secret_ids`, `secret_versions`, `keys` and `key_ids` are empty maps and only `project_id` is populated

#### Scenario: Secret version output without payload
- **WHEN** a secret version is created
- **THEN** the `secret_versions` entry contains no `data` or `data_wo` attribute

### Requirement: Output attributes
`secrets` SHALL map each input key to `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`. `secret_versions` SHALL map each input key to `id`, `secret_id`, `revision`, `status`, `created_at`, `updated_at` and `srn`. `keys` SHALL map each input key to `id`, `name`, `usage`, `algorithm`, `state`, `protected`, `rotation_count`, `rotated_at`, `created_at`, `updated_at` and `srn`. `srn` is the Scaleway Resource Name of the resource and is not secret.

#### Scenario: Attributes of a secret entry
- **WHEN** a secret is created under the key `db`
- **THEN** `secrets["db"]` has exactly the attributes `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`

#### Scenario: SRN of a key
- **WHEN** a key is created under the key `main`
- **THEN** `keys["main"].srn` is the key's Scaleway Resource Name and `keys["main"]` contains no secret data
