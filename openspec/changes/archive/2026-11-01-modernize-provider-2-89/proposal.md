# Proposal

## Why

v2.0.0 already sits on provider `~> 2.89`, but the module still carries v1-era shapes: a project looked up by `organization_id` + `project_name` through a data source, a secret payload split between a state-resident `data` and a write-only `data_wo` inside one non-sensitive map, a `key_id` that is either a map key or an ID, a deletable-by-default key with a warning check to compensate, duplicated ID outputs and a lifecycle shim. A major release is allowed, so this change aligns the module with the cross-module conventions (`project_id`, `tags`, secrets as ephemeral write-only inputs) and removes what the 2.89.0 schema makes unnecessary, with no new resource.

## What Changes

### Adopted features

| # | Item | Resource / argument | Provider version |
|---|------|---------------------|------------------|
| 1 | Secret payloads only through write-only `data_wo`, fed by a new ephemeral, sensitive input `secret_data` (never in state, plan or logs) | `scaleway_secret_version.data_wo`, `data_wo_version`; ephemeral variable (OpenTofu/Terraform 1.10+) | `data_wo` present in 2.89.0 schema; module already needs `>= 1.11.0` |
| 2 | `project_id` input (nullable, provider default project) | `scaleway_secret.project_id`, `scaleway_key_manager_key.project_id` | 2.86.0 |
| 3 | `tags` input merged (distinct) with per-item `tags` | `scaleway_secret.tags`, `scaleway_key_manager_key.tags` | 2.86.0 |
| 4 | `name` optional per secret/key, defaults to the map key | `scaleway_secret.name`, `scaleway_key_manager_key.name` | 2.86.0 |
| 5 | `secrets[*].key` (map key of `keys`) and `secrets[*].key_id` (existing key ID) as two explicit, exclusive inputs | `scaleway_secret.key_id` | 2.86.0 |
| 6 | Validation of `path`, `ephemeral_policy.ttl` and `rotation_period` formats | no new argument | n/a |
| 7 | `keys[*].protected` (default `true`) replaces `unprotected` (default `true`) | `scaleway_key_manager_key.unprotected = !protected` | 2.86.0 |

### Breaking changes

| # | Change | Consumer edit |
|---|--------|---------------|
| 1 | `organization_id` and `project_name` removed; `project_id` added; `data.scaleway_account_project` removed | Pass `project_id = "<uuid>"` (or `null` for the provider's default project). Drop `organization_id`, `project_name`. |
| 2 | Output `project_id` removed | Use your own `project_id` value. |
| 3 | `secret_versions[*].data` and `data_wo` removed; payloads move to ephemeral variable `secret_data` (same keys as `secret_versions`) | `secret_versions = { v1 = { secret_key = "db", data_wo_version = 1 } }` and `secret_data = { v1 = var.db_password }`. Pass `secret_data` from an ephemeral source (`ephemeral = true` variable or ephemeral resource). |
| 4 | `secret_versions[*].data_wo_version`: default `1` (was `null`) | Set it explicitly; a version that had `null` gets one new revision on the first apply. |
| 5 | `secrets[*].key_id` accepts only an existing key ID; module keys go through new `secrets[*].key` | `key_id = "main"` becomes `key = "main"`. |
| 6 | `keys[*].unprotected` (default `true`) replaced by `protected` (default `true`) | `unprotected = false` becomes omitted; `unprotected = true` becomes `protected = false`. Keys that relied on the old default become protected in place. |
| 7 | Outputs `secret_ids` and `key_ids` removed | `module.x.secret_ids["k"]` becomes `module.x.secrets["k"].id`; `key_ids["k"]` becomes `keys["k"].id`. |
| 8 | Check `keys_deletable` and `data_wo_version_set` removed (safe default / default version make them moot) | None. |

### Simplifications

| # | Item |
|---|------|
| 1 | Delete `data.tf` and `locals.tf` (project lookup, ID maps); resources reference each other directly. |
| 2 | Drop the "exactly one of `data`/`data_wo`" validation and the 64 KiB rule for `data` (single payload path). |
| 3 | Remove `lifecycle.ignore_changes = [rotation_policy[0].next_rotation_at]` if the second plan stays empty without it (optional + computed argument; verified in the real-account group). |
| 4 | Remove the double lookup `try(local.key_ids[...], value)` ambiguity (item 5 above). |
| 5 | Replace per-resource `region`/`project_id` plumbing by the two module-level inputs. |

### Deferred / Rejected

| Item | Reason |
|------|--------|
| Ephemeral `scaleway_secret_version` as a module read path | A module cannot read secrets for the consumer without turning them into outputs; consumers declare the ephemeral block themselves. Out of scope. |
| Ephemeral `scaleway_key_manager_{encrypt,decrypt,generate_data_key,sign}` | Runtime cryptographic operations, not infrastructure; no module value. |
| `scaleway_key_manager_key_material` and `keys[*].origin = "external"` (BYOK) | Previously deferred (needed a key-import flow). The write-only `key_material_wo` removes the state concern, but it needs another ephemeral input map plus salt and a key lifecycle; niche. Revisit on demand. |
| `rotation_policy.next_rotation_at` input | API-computed; setting it risks a perpetual diff (unchanged reason). |
| `locked`, `origin`, `protection_level` in the `keys` output | Read-only or caller-supplied; no consumer need (`quality-simplicity`). |
| Payload shape validation per secret `type` | The API validates it; duplicating schemas in the module drifts. |
| Data sources `scaleway_secret`, `scaleway_secret_version`, `scaleway_key_manager_key`, `scaleway_key_manager_verify` | Lookups belong to the consumer, not to a creating module. |
| Removing the usage/algorithm lists in favour of provider validation | The provider only warns; plan-time error kept (unchanged). |

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `module-contract`: project and tags inputs, removed organization/project-name lookup, outputs.
- `secrets`: optional `name`, `tags`, `key`/`key_id`, `path` and `ttl` validation.
- `secret-versions`: ephemeral `secret_data`, mandatory write-only path.
- `encryption-keys`: `protected` replaces `unprotected`, optional `name`, rotation format validation.

## Semver

**Major** (`terraform-versioning`: inputs removed or retyped, outputs removed, defaults changed). Inputs whose type, default or meaning changes: `organization_id` (removed), `project_name` (removed), `project_id` (new), `tags` (new), `secret_data` (new, ephemeral), `secrets[*].name` (optional), `secrets[*].key_id` (existing ID only), `secrets[*].key` (new), `secret_versions[*].data`/`data_wo` (removed), `secret_versions[*].data_wo_version` (default `1`), `keys[*].name` (optional), `keys[*].unprotected` (removed), `keys[*].protected` (new, default `true`). Outputs removed: `project_id`, `secret_ids`, `key_ids`. `required_version` stays `>= 1.11.0`; provider stays `~> 2.89`.

## State

Resource addresses are unchanged (`for_each` over the same map keys), so no `moved` block is needed. `secret_versions` no longer stores any payload: `data` was in state, `data_wo` never was. Moving a version from `data` to `data_wo` forces a new revision of that version (the provider replaces it); `scaleway_secret_version.data_wo` and `secret_data` never reach state or plan. No output carries secret data.

## Impact

- Modified: `versions.tf` (unchanged content), `variables.tf`, `main.tf`, `outputs.tf`, `checks.tf` (emptied, file deleted), deleted `data.tf`, `locals.tf`; `tests/main.tftest.hcl`, `examples/minimal`, `examples/complete`, README (generated block, features table, "Upgrading from v2 to v3"), `SECURITY.md`, `AGENTS.md`, `openspec/config.yaml` context.
- Specs: all four capabilities (deltas in this change).
- Standards: `terraform-versioning`, `terraform-providers`, `terraform-security`, `terraform-variables`, `terraform-outputs`, `terraform-testing`, `quality-simplicity`, `quality-security`, `quality-production-readiness`.
