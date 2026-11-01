## MODIFIED Requirements

### Requirement: Secrets created from a map
The module SHALL create one `scaleway_secret` per entry of `var.secrets` (map of objects, default `{}`), keyed by the map key, in `var.project_id` and `var.region`. Each entry has `name` (optional, defaults to the map key), `description`, `path` (default `"/"`), `protected` (default `false`), `tags` (default `[]`, merged with `var.tags`), `type` (default `"opaque"`), `key`, `key_id` and `ephemeral_policy` (optional).

#### Scenario: Minimal secret
- **WHEN** `secrets = { db = { name = "db-password" } }`
- **THEN** one secret named `db-password` is planned with path `/`, `protected = false`, no tags and type `opaque`

#### Scenario: Name defaults to the map key
- **WHEN** `secrets = { db = {} }`
- **THEN** one secret named `db` is planned

#### Scenario: No secrets
- **WHEN** `secrets` is `{}`
- **THEN** no `scaleway_secret` is planned

### Requirement: Secret name validation
The module MUST reject a secret name (the `name`, or the map key when `name` is unset) that is not 1 to 255 characters made of letters, digits, dots, underscores and hyphens, starting and ending with a letter or digit (a single-character name is accepted).

#### Scenario: Invalid name
- **WHEN** `secrets = { db = { name = "-bad name" } }`
- **THEN** the plan fails with "Secret names must be 1-255 characters, alphanumeric with dots, underscores, and hyphens."

#### Scenario: Valid dotted name
- **WHEN** `secrets = { db = { name = "app.db_password-1" } }`
- **THEN** no validation error is raised

#### Scenario: Invalid map key used as name
- **WHEN** `secrets = { "bad key" = {} }`
- **THEN** the plan fails with the same error

### Requirement: Ephemeral policy
When `ephemeral_policy` is set, the module SHALL add one `ephemeral_policy` block with `ttl`, `expires_once_accessed` (default `false`) and `action` (default `"delete"`). When it is `null` no block SHALL be added. The module MUST reject an `action` other than `delete` or `disable` and a `ttl` that is not a Go duration made of whole numbers with `h`, `m` or `s` units.

#### Scenario: Policy with defaults
- **WHEN** `ephemeral_policy = { ttl = "24h" }`
- **THEN** the secret has an ephemeral policy with ttl `24h`, `expires_once_accessed = false` and action `delete`

#### Scenario: Invalid action
- **WHEN** `ephemeral_policy = { ttl = "24h", action = "archive" }`
- **THEN** the plan fails with "Ephemeral policy action must be 'delete' or 'disable'."

#### Scenario: Invalid ttl
- **WHEN** `ephemeral_policy = { ttl = "one day" }`
- **THEN** the plan fails with "Ephemeral policy ttl must be a duration such as 24h or 1h30m."

#### Scenario: No policy
- **WHEN** `ephemeral_policy` is not set
- **THEN** the secret has no ephemeral policy block

### Requirement: Key Manager key for a secret
A secret SHALL be encrypted with a Key Manager key chosen by `key` (a map key of `var.keys`, resolved to the ID of the key created by this module) or `key_id` (an existing key ID, passed through unchanged); with neither the Secret Manager internal key is used. The module MUST reject setting both, and a `key` that is not a key of `var.keys`. Changing the key recreates the secret.

#### Scenario: Key from the keys variable
- **WHEN** `keys = { main = {...} }` and `secrets = { db = { key = "main" } }`
- **THEN** the secret is encrypted with the key created for `main`

#### Scenario: Existing key ID
- **WHEN** `key_id` is set to an existing key's ID
- **THEN** that value is passed to the secret unchanged

#### Scenario: Both key and key_id
- **WHEN** a secret sets `key = "main"` and `key_id = "fr-par/..."`
- **THEN** the plan fails with "A secret can set key or key_id, not both."

#### Scenario: Unknown key
- **WHEN** `key = "missing"` and `missing` is not in `var.keys`
- **THEN** the plan fails with "Each secret key must be a key of the keys variable."

#### Scenario: No key
- **WHEN** neither is set
- **THEN** the secret is created without a `key_id`

## ADDED Requirements

### Requirement: Secret path validation
The module MUST reject a secret `path` that does not start with `/` or contains characters other than letters, digits, dots, underscores, hyphens and `/`.

#### Scenario: Path without leading slash
- **WHEN** `path = "production/api"`
- **THEN** the plan fails with "Secret path must start with / and use letters, digits, dots, underscores, hyphens and slashes."

#### Scenario: Nested path
- **WHEN** `path = "/production/api"`
- **THEN** no validation error is raised
