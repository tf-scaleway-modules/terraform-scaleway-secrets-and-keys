# secret-versions Specification

## Purpose
Secret versions: exactly one of `data` (stored in state) or write-only `data_wo`, and the 64 KiB payload limit.

## Requirements

### Requirement: Secret versions created from a map
The module SHALL create one `scaleway_secret_version` per entry of `var.secret_versions` (map of objects, default `{}`), attached to the secret created under the entry's `secret_key`, in `var.region`. Each entry has `secret_key` (required string), `data_wo_version` (whole number, default `1`) and `description` (optional). The module MUST reject a `secret_key` that is not a key of `var.secrets`.

#### Scenario: Version of a created secret
- **WHEN** `secrets = { db = {...} }`, `secret_versions = { v1 = { secret_key = "db" } }` and `secret_data = { v1 = "s3cret" }`
- **THEN** one version is planned on the `db` secret

#### Scenario: Unknown secret key
- **WHEN** `secret_key` names a key that is not in `var.secrets`
- **THEN** the plan fails with "Each secret version secret_key must be a key of the secrets variable."

### Requirement: Payload size limit
The module MUST reject a `secret_data` value larger than 65536 bytes (UTF-8); a multi-byte character counts for all its bytes.

#### Scenario: Oversized payload
- **WHEN** a value has 65537 bytes
- **THEN** the plan fails with "Secret version data must not exceed 64 KiB (65536 bytes)."

#### Scenario: Multi-byte payload over the limit
- **WHEN** a value has 40000 characters of 2 bytes each (80000 bytes)
- **THEN** the plan fails with the same error

#### Scenario: Payload at the limit
- **WHEN** a value has exactly 65536 bytes
- **THEN** no validation error is raised

### Requirement: Payload never in state
Every version SHALL send its payload through the write-only `data_wo` argument, fed by `secret_data`, so the payload is never stored in state or plan; `data_wo_version` is passed through and changing it creates a new version. `secret_data` is `sensitive` and `ephemeral`. `SECURITY.md` SHALL say that no payload reaches state and that the caller supplies `secret_data` from an ephemeral source.

#### Scenario: Write-only payload
- **WHEN** a version has `secret_data = { v1 = "s3cret" }` and `data_wo_version = 1`
- **THEN** the payload is sent through the write-only argument and not stored in state

#### Scenario: Rotating a payload
- **WHEN** `data_wo_version` changes from 1 to 2
- **THEN** a new version is created from the new `secret_data` value

#### Scenario: Payload unchanged
- **WHEN** `secret_data` changes but `data_wo_version` does not
- **THEN** no version is created or changed

### Requirement: Version number
`data_wo_version` MUST be a whole number and defaults to `1`, so no `check` warning about a missing version exists.

#### Scenario: Fractional version number
- **WHEN** `data_wo_version = 1.5`
- **THEN** the plan fails with "Secret version data_wo_version must be a whole number."

#### Scenario: Default version number
- **WHEN** a version does not set `data_wo_version`
- **THEN** it is planned with `data_wo_version = 1`

### Requirement: Secret payload input
The module SHALL accept `secret_data` (map of strings, default `{}`, `sensitive` and `ephemeral`) keyed like `secret_versions`. It MUST reject a key without a matching `secret_versions` entry, and a `secret_versions` entry without a payload.

#### Scenario: Payload without version
- **WHEN** `secret_data = { v9 = "x" }` and `secret_versions` has no `v9`
- **THEN** the plan fails with "Each secret_data key must be a key of the secret_versions variable."

#### Scenario: Version without payload
- **WHEN** `secret_versions = { v1 = { secret_key = "db" } }` and `secret_data = {}`
- **THEN** the plan fails with "Each secret version must have a secret_data entry."
