# encryption-keys Specification

## Purpose
Key Manager keys: usage and algorithm pairing, protection level, deletion protection and rotation policy.

## Requirements

### Requirement: Keys created from a map
The module SHALL create one `scaleway_key_manager_key` per entry of `var.keys` (map of objects, default `{}`), keyed by the map key, in the resolved project and in `var.region`. Each entry has `name`, `usage` and `algorithm` (required strings) and `description`, `tags` (default `[]`), `unprotected`, `rotation_period` and `protection_level` (optional).

#### Scenario: Symmetric key
- **WHEN** `keys = { main = { name = "main", usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }`
- **THEN** one key is planned and `key_ids["main"]` is its ID

#### Scenario: No keys
- **WHEN** `keys` is `{}`
- **THEN** no `scaleway_key_manager_key` is planned

### Requirement: Usage and algorithm validation
The module MUST reject a `usage` other than `symmetric_encryption`, `asymmetric_encryption` or `asymmetric_signing`, and MUST reject an `algorithm` that does not match the usage: `aes_256_gcm` for symmetric encryption; `rsa_oaep_2048_sha256`, `rsa_oaep_3072_sha256` or `rsa_oaep_4096_sha256` for asymmetric encryption; `rsa_pkcs1_2048_sha256`, `rsa_pkcs1_3072_sha256`, `rsa_pkcs1_4096_sha256`, `ec_p256_sha256` or `ec_p384_sha384` for asymmetric signing.

#### Scenario: Unknown usage
- **WHEN** `usage = "hashing"`
- **THEN** the plan fails with "Key usage must be one of: symmetric_encryption, asymmetric_encryption, asymmetric_signing."

#### Scenario: Algorithm not valid for the usage
- **WHEN** `usage = "symmetric_encryption"` and `algorithm = "ec_p256_sha256"`
- **THEN** the plan fails with "Algorithm must be valid for the specified usage type."

#### Scenario: Signing key
- **WHEN** `usage = "asymmetric_signing"` and `algorithm = "ec_p384_sha384"`
- **THEN** no validation error is raised

### Requirement: Protection level
`protection_level` SHALL be passed through to the key when set and MUST be `software` or `hsm`; it is immutable, so changing it recreates the key. When unset the provider default applies.

#### Scenario: HSM key
- **WHEN** `protection_level = "hsm"`
- **THEN** the key is planned with the HSM protection level

#### Scenario: Invalid protection level
- **WHEN** `protection_level = "cloud"`
- **THEN** the plan fails with "Key protection_level must be 'software' or 'hsm'."

### Requirement: Deletion protection flag
The module SHALL pass `unprotected` to the key; its module default is `true` (the key can be deleted). The `keys` output SHALL expose the provider's `protected` attribute.

#### Scenario: Default
- **WHEN** `unprotected` is not set
- **THEN** the key is planned with `unprotected = true`

#### Scenario: Protected key
- **WHEN** `unprotected = false`
- **THEN** the key is planned with `unprotected = false`

### Requirement: Rotation policy
When `rotation_period` is set the module SHALL add one `rotation_policy` block with that period; when it is `null` no block SHALL be added. Changes to `rotation_policy[0].next_rotation_at` SHALL be ignored.

#### Scenario: Yearly rotation
- **WHEN** `rotation_period = "8760h"`
- **THEN** the key has a rotation policy with period `8760h`

#### Scenario: No rotation
- **WHEN** `rotation_period` is not set
- **THEN** the key has no rotation policy block

#### Scenario: Computed next rotation
- **WHEN** the provider updates `next_rotation_at`
- **THEN** no diff is planned for it
