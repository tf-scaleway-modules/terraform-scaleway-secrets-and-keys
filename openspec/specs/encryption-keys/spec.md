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
The module MUST reject a `usage` other than `symmetric_encryption`, `asymmetric_encryption`, `asymmetric_signing` or `key_encapsulation`, and an `algorithm` not allowed for its usage: symmetric encryption `aes_256_gcm`; asymmetric encryption `rsa_oaep_{2048,3072,4096}_sha256`; asymmetric signing `rsa_pkcs1_{2048,3072,4096}_sha256`, `rsa_pss_{2048,3072,4096}_sha256`, `ec_p256_sha256`, `ec_p384_sha384`, `ec_secp256k1_sha256`, `ml_dsa_{44,65,87}`; key encapsulation `ml_kem_768`, `ml_kem_1024`.

#### Scenario: Unknown usage
- **WHEN** `usage = "hashing"`
- **THEN** the plan fails with "Key usage must be one of: symmetric_encryption, asymmetric_encryption, asymmetric_signing, key_encapsulation."

#### Scenario: Algorithm not valid for the usage
- **WHEN** `usage = "symmetric_encryption"` and `algorithm = "ec_p256_sha256"`
- **THEN** the plan fails with "Algorithm must be valid for the specified usage type."

#### Scenario: Signing key
- **WHEN** `usage = "asymmetric_signing"` and `algorithm = "ec_p384_sha384"`
- **THEN** no validation error is raised

#### Scenario: Post-quantum signing key
- **WHEN** `usage = "asymmetric_signing"` and `algorithm = "ml_dsa_65"`
- **THEN** no validation error is raised

#### Scenario: Key encapsulation key
- **WHEN** `usage = "key_encapsulation"` and `algorithm = "ml_kem_768"`
- **THEN** no validation error is raised and the key is planned with that usage and algorithm

#### Scenario: Key encapsulation algorithm on another usage
- **WHEN** `usage = "key_encapsulation"` and `algorithm = "aes_256_gcm"`, or `usage = "asymmetric_signing"` and `algorithm = "ml_kem_768"`
- **THEN** the plan fails with "Algorithm must be valid for the specified usage type."

### Requirement: Protection level
`protection_level` SHALL be passed through to the key when set and MUST be `software` or `hsm`; it is immutable, so changing it recreates the key. When unset the provider default applies.

#### Scenario: HSM key
- **WHEN** `protection_level = "hsm"`
- **THEN** the key is planned with the HSM protection level

#### Scenario: Invalid protection level
- **WHEN** `protection_level = "cloud"`
- **THEN** the plan fails with "Key protection_level must be 'software' or 'hsm'."

### Requirement: Deletion protection flag
The module SHALL pass `unprotected` to the key; its module default is `true` (the key can be deleted), documented as such in the variable description. The `keys` output SHALL expose the provider's `protected` attribute. The module SHALL emit a `check` warning naming every key whose `unprotected` is `true`, set or defaulted.

#### Scenario: Default
- **WHEN** `unprotected` is not set
- **THEN** the key is planned with `unprotected = true` and a check warning names it

#### Scenario: Protected key
- **WHEN** `unprotected = false`
- **THEN** the key is planned with `unprotected = false` and no check warning is emitted for it

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
