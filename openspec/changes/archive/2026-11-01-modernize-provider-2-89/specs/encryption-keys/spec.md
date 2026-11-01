## MODIFIED Requirements

### Requirement: Keys created from a map
The module SHALL create one `scaleway_key_manager_key` per entry of `var.keys` (map of objects, default `{}`), keyed by the map key, in `var.project_id` and `var.region`. Each entry has `usage` and `algorithm` (required strings) and `name` (defaults to the map key), `description`, `tags` (default `[]`, merged with `var.tags`), `protected` (default `true`), `rotation_period` and `protection_level` (optional).

#### Scenario: Symmetric key
- **WHEN** `keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }`
- **THEN** one key named `main` is planned and `keys["main"].id` is its ID

#### Scenario: No keys
- **WHEN** `keys` is `{}`
- **THEN** no `scaleway_key_manager_key` is planned

### Requirement: Deletion protection flag
The module SHALL expose `protected` (default `true`) and send `unprotected = !protected` to the key, so keys are protected from deletion unless the caller sets `protected = false`. The `keys` output SHALL expose the provider's `protected` attribute. No `check` warning is emitted.

#### Scenario: Default
- **WHEN** `protected` is not set
- **THEN** the key is planned with `unprotected = false`

#### Scenario: Protected key
- **WHEN** `protected = true`
- **THEN** the key is planned with `unprotected = false`

#### Scenario: Deletable key
- **WHEN** `protected = false`
- **THEN** the key is planned with `unprotected = true`

### Requirement: Rotation policy
When `rotation_period` is set the module SHALL add one `rotation_policy` block with that period; when it is `null` no block SHALL be added. The module MUST reject a period that is not a Go duration of whole numbers with `h`, `m` or `s` units. `next_rotation_at` is computed by the API and not configurable.

#### Scenario: Yearly rotation
- **WHEN** `rotation_period = "8760h"`
- **THEN** the key has a rotation policy with period `8760h`

#### Scenario: No rotation
- **WHEN** `rotation_period` is not set
- **THEN** the key has no rotation policy block

#### Scenario: Invalid period
- **WHEN** `rotation_period = "1 year"`
- **THEN** the plan fails with "Key rotation_period must be a duration such as 8760h."

#### Scenario: Computed next rotation
- **WHEN** the API updates `next_rotation_at`
- **THEN** no diff is planned for it
