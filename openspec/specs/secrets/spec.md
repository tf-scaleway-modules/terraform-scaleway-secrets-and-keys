# secrets Specification

## Purpose
Secret Manager secrets: naming, type, ephemeral policy and the optional Key Manager key that encrypts their versions.

## Requirements

### Requirement: Secrets created from a map
The module SHALL create one `scaleway_secret` per entry of `var.secrets` (map of objects, default `{}`), keyed by the map key, in the resolved project and in `var.region`. Each entry has the attributes `name` (required string), `description` (optional), `path` (default `"/"`), `protected` (default `false`), `tags` (default `[]`), `type` (default `"opaque"`), `key_id` (optional) and `ephemeral_policy` (optional object).

#### Scenario: Minimal secret
- **WHEN** `secrets = { db = { name = "db-password" } }`
- **THEN** one secret named `db-password` is planned with path `/`, `protected = false`, no tags and type `opaque`

#### Scenario: No secrets
- **WHEN** `secrets` is `{}`
- **THEN** no `scaleway_secret` is planned

### Requirement: Secret name validation
The module MUST reject any secret name that is not 1 to 255 characters made of letters, digits, dots, underscores and hyphens, starting and ending with a letter or digit (a single-character name is accepted).

#### Scenario: Invalid name
- **WHEN** `secrets = { db = { name = "-bad name" } }`
- **THEN** the plan fails with "Secret names must be 1-255 characters, alphanumeric with dots, underscores, and hyphens."

#### Scenario: Valid dotted name
- **WHEN** `secrets = { db = { name = "app.db_password-1" } }`
- **THEN** no validation error is raised

### Requirement: Secret type validation
The module MUST reject any secret `type` other than `opaque`, `basic_credentials` or `database_credentials`.

#### Scenario: Unknown type
- **WHEN** `secrets = { db = { name = "db", type = "certificate" } }`
- **THEN** the plan fails with "Secret type must be one of: opaque, basic_credentials, database_credentials."

#### Scenario: Database credentials type
- **WHEN** `type = "database_credentials"`
- **THEN** no validation error is raised and the secret is planned with that type

### Requirement: Ephemeral policy
When `ephemeral_policy` is set, the module SHALL add one `ephemeral_policy` block with `ttl`, `expires_once_accessed` (default `false`) and `action` (default `"delete"`). When it is `null` no block SHALL be added. The module MUST reject an `action` other than `delete` or `disable`.

#### Scenario: Policy with defaults
- **WHEN** `ephemeral_policy = { ttl = "24h" }`
- **THEN** the secret has an ephemeral policy with ttl `24h`, `expires_once_accessed = false` and action `delete`

#### Scenario: Invalid action
- **WHEN** `ephemeral_policy = { ttl = "24h", action = "archive" }`
- **THEN** the plan fails with "Ephemeral policy action must be 'delete' or 'disable'."

#### Scenario: No policy
- **WHEN** `ephemeral_policy` is not set
- **THEN** the secret has no ephemeral policy block

### Requirement: Key Manager key for a secret
The secret's `key_id` SHALL be resolved as follows: if the value equals a map key of `var.keys`, the ID of the key created by this module is used; otherwise the value is passed through as an existing Key Manager key ID; if it is unset the secret uses the Secret Manager internal key. Changing it recreates the secret.

#### Scenario: Key from the keys variable
- **WHEN** `keys = { main = {...} }` and `secrets = { db = { name = "db", key_id = "main" } }`
- **THEN** the secret is encrypted with the key created for `main`

#### Scenario: Existing key ID
- **WHEN** `key_id` is set to an ID that is not a key of `var.keys`
- **THEN** that value is passed to the secret unchanged

#### Scenario: No key
- **WHEN** `key_id` is not set
- **THEN** the secret is created without a `key_id`
