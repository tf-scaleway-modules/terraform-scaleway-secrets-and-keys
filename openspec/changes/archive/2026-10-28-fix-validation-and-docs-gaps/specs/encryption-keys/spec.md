## MODIFIED Requirements

### Requirement: Deletion protection flag
The module SHALL pass `unprotected` to the key; its module default is `true` (the key can be deleted), documented as such in the variable description. The `keys` output SHALL expose the provider's `protected` attribute. The module SHALL emit a `check` warning naming every key whose `unprotected` is `true`, set or defaulted.

#### Scenario: Default
- **WHEN** `unprotected` is not set
- **THEN** the key is planned with `unprotected = true` and a check warning names it

#### Scenario: Protected key
- **WHEN** `unprotected = false`
- **THEN** the key is planned with `unprotected = false` and no check warning is emitted for it
