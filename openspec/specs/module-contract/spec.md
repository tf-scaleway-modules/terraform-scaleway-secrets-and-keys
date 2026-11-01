# module-contract Specification

## Purpose
Supported tooling and provider versions, project inputs and resolution, and the outputs of the module.

## Requirements

### Requirement: Tooling and provider constraints
The module SHALL declare `required_version = ">= 1.11.0"` (write-only arguments and ephemeral variables) and the single required provider `scaleway/scaleway` with version constraint `~> 2.89`.

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

### Requirement: Region input
The module SHALL accept an optional `region` (string, default `null`, meaning the provider's region) and MUST reject a value other than `fr-par`, `nl-ams` or `pl-waw`. It is passed to every secret, version and key.

#### Scenario: Unsupported region
- **WHEN** `region = "us-east-1"`
- **THEN** the plan fails with "Region must be one of: fr-par, nl-ams, pl-waw."

#### Scenario: Region omitted
- **WHEN** `region` is not set
- **THEN** no validation error is raised and resources receive a null region, so the provider region applies

### Requirement: Outputs
The module SHALL expose the outputs `secrets`, `secret_versions` and `keys`, none of them sensitive; each maps an input key to the attributes listed in the output attributes requirement, so IDs are read as `secrets["k"].id` and `keys["k"].id`. No output SHALL contain secret data.

#### Scenario: Default inputs
- **WHEN** `secrets`, `secret_versions` and `keys` are all left at their `{}` default
- **THEN** all three outputs are empty maps

#### Scenario: Secret version output without payload
- **WHEN** a secret version is created
- **THEN** the `secret_versions` entry contains no `data` or `data_wo` attribute

#### Scenario: Outputs of v2 are gone
- **WHEN** the outputs of the module are listed
- **THEN** `project_id`, `secret_ids` and `key_ids` are not among them

### Requirement: Output attributes
`secrets` SHALL map each input key to `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`. `secret_versions` SHALL map each input key to `id`, `secret_id`, `revision`, `status`, `created_at`, `updated_at` and `srn`. `keys` SHALL map each input key to `id`, `name`, `usage`, `algorithm`, `state`, `protected`, `rotation_count`, `rotated_at`, `created_at`, `updated_at` and `srn`. `srn` is the Scaleway Resource Name of the resource and is not secret.

#### Scenario: Attributes of a secret entry
- **WHEN** a secret is created under the key `db`
- **THEN** `secrets["db"]` has exactly the attributes `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`

#### Scenario: SRN of a key
- **WHEN** a key is created under the key `main`
- **THEN** `keys["main"].srn` is the key's Scaleway Resource Name and `keys["main"]` contains no secret data

### Requirement: Project input
The module SHALL accept an optional `project_id` (string, default `null`, meaning the provider's default project) and pass it to every secret and key. It MUST reject a value that is not a lowercase UUID. The module SHALL NOT look up a project by name.

#### Scenario: Explicit project
- **WHEN** `project_id = "11111111-1111-1111-1111-111111111111"`
- **THEN** every secret and key is planned with that project ID

#### Scenario: Project omitted
- **WHEN** `project_id` is not set
- **THEN** no validation error is raised and the provider's default project applies

#### Scenario: Invalid project ID
- **WHEN** `project_id = "my-project"`
- **THEN** the plan fails with "Project ID must be a valid UUID."

### Requirement: Common tags input
The module SHALL accept `tags` (list of strings, default `[]`) and apply it to every secret and key, merged with the item's own `tags` without duplicates. Secret versions carry no tags.

#### Scenario: Merged tags
- **WHEN** `tags = ["env:prod"]` and a secret sets `tags = ["app:db", "env:prod"]`
- **THEN** the secret is planned with tags `env:prod` and `app:db`, each once

#### Scenario: No tags
- **WHEN** neither `tags` nor an item's tags are set
- **THEN** the resource is planned with no tags
