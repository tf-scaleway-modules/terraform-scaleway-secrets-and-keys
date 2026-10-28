# Security

## What lands in state

| Input | In state? | Mitigation |
|-------|-----------|------------|
| `secret_versions[*].data` | Yes (redacted in CLI output, readable in the state file) | Use `data_wo` with `data_wo_version`; encrypt and restrict access to the state backend |
| `secret_versions[*].data_wo` | No (write-only, also absent from plan files) | Supply it from an ephemeral source (`TF_VAR_*`, CI secret, vault); bump `data_wo_version` to push a new value |

`secret_versions` is iterated by `for_each`, so the variable cannot be marked `sensitive`. Do not commit `*.tfvars` or `*.tfstate` files.

## Key deletion protection

`keys[*].unprotected` defaults to `true`: keys can be deleted. A plan warning (`check "keys_deletable"`) lists every such key. Set `unprotected = false` on production keys; deleting a key makes everything encrypted with it unreadable.

## Write-only versions

A `data_wo` change without a `data_wo_version` change creates no new version. A plan warning (`check "data_wo_version_set"`) lists versions missing `data_wo_version`.
