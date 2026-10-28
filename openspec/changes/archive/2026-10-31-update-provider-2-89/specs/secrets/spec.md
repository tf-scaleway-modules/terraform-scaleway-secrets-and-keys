## MODIFIED Requirements

### Requirement: Secret type validation
The module MUST reject any secret `type` other than `opaque`, `certificate`, `key_value`, `basic_credentials`, `database_credentials` or `ssh_key`.

#### Scenario: Unknown type
- **WHEN** `secrets = { db = { name = "db", type = "password" } }`
- **THEN** the plan fails with "Secret type must be one of: opaque, certificate, key_value, basic_credentials, database_credentials, ssh_key."

#### Scenario: Database credentials type
- **WHEN** `type = "database_credentials"`
- **THEN** no validation error is raised and the secret is planned with that type

#### Scenario: Newly accepted type
- **WHEN** `type = "ssh_key"` (or `certificate`, or `key_value`)
- **THEN** no validation error is raised and the secret is planned with that type
