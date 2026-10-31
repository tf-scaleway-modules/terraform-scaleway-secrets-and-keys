# Security

## What lands in state

| Input | In state? | Mitigation |
|-------|-----------|------------|
| `secret_data` | No (ephemeral, sent through the write-only `data_wo`; also absent from plan files) | Supply it from an ephemeral source (an `ephemeral` variable of the root module, an ephemeral resource); bump `secret_versions[*].data_wo_version` to push a new value |

No payload reaches the state: the module has no state-resident `data` path. `secret_data` is `sensitive` and `ephemeral`, so the caller MUST feed it from an ephemeral source. Do not commit `*.tfvars` or `*.tfstate` files.

## Key deletion protection

`keys[*].protected` defaults to `true`: keys cannot be deleted. To destroy a key, set `protected = false` and apply first. Deleting a key makes everything encrypted with it unreadable.

## Write-only versions

A `secret_data` change without a `data_wo_version` change creates no new version; `data_wo_version` defaults to `1`.
