## ADDED Requirements

### Requirement: Secret versions created from a map
The module SHALL create one `scaleway_secret_version` per entry of `var.secret_versions` (map of objects, default `{}`), attached to the secret created under the entry's `secret_key`, in `var.region`. Each entry has `secret_key` (required string), `data`, `data_wo`, `data_wo_version` (number) and `description`, all optional except `secret_key`.

#### Scenario: Version of a created secret
- **WHEN** `secrets = { db = {...} }` and `secret_versions = { v1 = { secret_key = "db", data = "s3cret" } }`
- **THEN** one version is planned on the `db` secret

#### Scenario: Unknown secret key
- **WHEN** `secret_key` names a key that is not in `var.secrets`
- **THEN** the plan fails because no such secret exists

### Requirement: Exactly one payload argument
The module MUST reject a secret version that sets both or neither of `data` and `data_wo`.

#### Scenario: Both set
- **WHEN** a version sets `data = "a"` and `data_wo = "b"`
- **THEN** the plan fails with "Each secret version must set exactly one of data or data_wo."

#### Scenario: Neither set
- **WHEN** a version sets only `secret_key`
- **THEN** the plan fails with the same error

### Requirement: What lands in state
A version created with `data` SHALL carry its payload in the resource, so the payload is stored in the state. A version created with `data_wo` SHALL send the payload through the provider's write-only argument, so the payload is never stored in the state or the plan; `data_wo_version` SHALL be passed through, and changing it creates a new version from the new `data_wo`. The module does not mark `secret_versions` as `sensitive` or `ephemeral`.

#### Scenario: Write-only payload
- **WHEN** a version sets `data_wo = "s3cret"` and `data_wo_version = 1`
- **THEN** the payload is sent through the write-only argument and not stored in state

#### Scenario: Rotating a write-only payload
- **WHEN** `data_wo_version` changes from 1 to 2
- **THEN** a new version is created from the new `data_wo`

#### Scenario: Plain payload
- **WHEN** a version sets `data = "s3cret"`
- **THEN** the payload is part of the resource and is stored in state

### Requirement: Payload size limit
The module MUST reject a `data` or `data_wo` value longer than 65536 characters.

#### Scenario: Oversized payload
- **WHEN** `data` has 65537 characters
- **THEN** the plan fails with "Secret version data must not exceed 64 KiB (65536 bytes)."

#### Scenario: Payload at the limit
- **WHEN** `data_wo` has exactly 65536 characters
- **THEN** no validation error is raised
