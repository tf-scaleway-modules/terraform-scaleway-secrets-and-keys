# secret-versions Specification

## Purpose
Secret versions: exactly one of `data` (stored in state) or write-only `data_wo`, and the 64 KiB payload limit.

## Requirements

### Requirement: Secret versions created from a map
The module SHALL create one `scaleway_secret_version` per entry of `var.secret_versions` (map of objects, default `{}`), attached to the secret created under the entry's `secret_key`, in `var.region`. Each entry has `secret_key` (required string), `data`, `data_wo`, `data_wo_version` (number) and `description`, all optional except `secret_key`. The module MUST reject a `secret_key` that is not a key of `var.secrets`.

#### Scenario: Version of a created secret
- **WHEN** `secrets = { db = {...} }` and `secret_versions = { v1 = { secret_key = "db", data = "s3cret" } }`
- **THEN** one version is planned on the `db` secret

#### Scenario: Unknown secret key
- **WHEN** `secret_key` names a key that is not in `var.secrets`
- **THEN** the plan fails with "Each secret version secret_key must be a key of the secrets variable."

### Requirement: Exactly one payload argument
The module MUST reject a secret version that sets both or neither of `data` and `data_wo`.

#### Scenario: Both set
- **WHEN** a version sets `data = "a"` and `data_wo = "b"`
- **THEN** the plan fails with "Each secret version must set exactly one of data or data_wo."

#### Scenario: Neither set
- **WHEN** a version sets only `secret_key`
- **THEN** the plan fails with the same error

### Requirement: What lands in state
A version created with `data` SHALL be stored in the state (the provider only redacts it in CLI output). A version created with `data_wo` SHALL use the write-only argument, so its payload is never stored in the state or the plan; `data_wo_version` SHALL be passed through, and changing it creates a new version. `secret_versions` is not `sensitive` or `ephemeral` because it is iterated by `for_each`; its description and `SECURITY.md` SHALL say that `data` lands in state.

#### Scenario: Write-only payload
- **WHEN** a version sets `data_wo = "s3cret"` and `data_wo_version = 1`
- **THEN** the payload is sent through the write-only argument and not stored in state

#### Scenario: Rotating a write-only payload
- **WHEN** `data_wo_version` changes from 1 to 2
- **THEN** a new version is created from the new `data_wo`

#### Scenario: Plain payload
- **WHEN** a version sets `data = "s3cret"`
- **THEN** the payload is part of the resource and is stored in state, and `SECURITY.md` and the variable description say so

### Requirement: Payload size limit
The module MUST reject a `data` or `data_wo` value larger than 65536 bytes (UTF-8); a multi-byte character counts for all its bytes.

#### Scenario: Oversized payload
- **WHEN** `data` has 65537 bytes
- **THEN** the plan fails with "Secret version data must not exceed 64 KiB (65536 bytes)."

#### Scenario: Multi-byte payload over the limit
- **WHEN** `data_wo` has 40000 characters of 2 bytes each (80000 bytes)
- **THEN** the plan fails with the same error

#### Scenario: Payload at the limit
- **WHEN** `data_wo` has exactly 65536 bytes
- **THEN** no validation error is raised

### Requirement: Write-only version number
`data_wo_version` MUST be a whole number when set. The module SHALL emit a `check` warning, naming the versions, for every version that sets `data_wo` without `data_wo_version`, because changing `data_wo` alone does not create a new version.

#### Scenario: Fractional version number
- **WHEN** `data_wo_version = 1.5`
- **THEN** the plan fails with "Secret version data_wo_version must be a whole number."

#### Scenario: Write-only payload without version number
- **WHEN** a version sets `data_wo` and no `data_wo_version`
- **THEN** the plan succeeds with a check warning naming that version

#### Scenario: Write-only payload with version number
- **WHEN** a version sets `data_wo` and `data_wo_version = 1`
- **THEN** no check warning is emitted
