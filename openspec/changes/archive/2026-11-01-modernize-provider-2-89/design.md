# Design

## Context

v2.0.0 (provider `~> 2.89`, `required_version >= 1.11.0`) manages `scaleway_secret`, `scaleway_secret_version` and `scaleway_key_manager_key` and reads `data.scaleway_account_project`. Gap analysis against the 2.89.0 schema (`/tmp/scw-schema/schema-2.89.0.json`):

| Object | Surface | Verdict |
|--------|---------|---------|
| `scaleway_secret` | `name`, `description`, `path`, `protected`, `tags`, `type`, `key_id`, `ephemeral_policy{ttl,expires_once_accessed,action}`, `project_id`, `region`; computed `status`, `version_count`, `srn`, `versions` | all exposed; `project_id`/`tags` re-plumbed |
| `scaleway_secret_version` | `secret_id`, `data` (sensitive, state), `data_wo` (write-only), `data_wo_version`, `description`, `region` | keep `data_wo` only |
| `scaleway_key_manager_key` | `usage`, `algorithm`, `protection_level`, `unprotected`, `rotation_policy{rotation_period, next_rotation_at}`, `origin`, `tags`, `project_id`; computed `locked`, `protected`, `srn`, `state` | exposed except `origin`, `next_rotation_at` (rejected) |
| `scaleway_key_manager_key_material` (resource, `key_material_wo`, `salt_wo`) | BYOK import for `origin = "external"` keys | rejected (below) |
| ephemeral `scaleway_secret_version`, `scaleway_key_manager_{encrypt,decrypt,generate_data_key,sign}` | consumer-side reads and crypto operations | rejected |
| data sources `scaleway_secret`, `scaleway_secret_version`, `scaleway_key_manager_key`, `scaleway_key_manager_verify` | lookups | rejected |

Introducing provider versions for the arguments in use: `key_id` (2.86.0, `feat(secret): enable using a kms external key`), `protection_level`, `srn`, `origin`, `next_rotation_at` (2.86.0, per the v2.0.0 design); `data_wo`/`data_wo_version` and write-only support are in the 2.89.0 schema. The exact minor that introduced `scaleway_key_manager_key_material` was not found in the release notes (present in 2.89.0); it is not used.

Standards applied: `terraform-versioning`, `terraform-providers`, `terraform-security`, `terraform-variables`, `terraform-outputs`, `terraform-testing`, `quality-simplicity`, `quality-security`, `quality-production-readiness`.

## Goals / Non-Goals

**Goals:** secrets never reach state; conventions aligned with the sibling modules (`project_id`, `tags`); fewer inputs, outputs and files; safe defaults (protected keys); stricter plan-time validation.

**Non-Goals:** new resources, key import, ephemeral read helpers, per-type payload validation.

## Decisions

- **`project_id` (nullable UUID) replaces `organization_id` + `project_name`.** Removes `data.tf` and a plan-time API call; `null` yields the provider default project. Alternative: keep the lookup as an option. Rejected: dual inputs (`quality-simplicity`).
- **Payloads as ephemeral `secret_data`.** `for_each` cannot iterate an ephemeral or sensitive map, so the old single map forced `data_wo` into a plain variable. The payload is split off: `secret_versions` (iterable, non-secret: `secret_key`, `data_wo_version`, `description`) and `secret_data = map(string)` with `sensitive = true` and `ephemeral = true`, same keys. The resource sets `data_wo = var.secret_data[each.key]` (write-only arguments accept ephemeral values). Validations on `secret_data` use the 64 KiB base64-length rule from v2 and compare `keys()` with `secret_versions`. Alternatives: keep the combined map (payload in a non-sensitive variable, rejected by `terraform-security`); keep `data` as an escape hatch (payload in state, rejected). Risk: an ephemeral input must come from an ephemeral source in the caller (an `ephemeral` variable or ephemeral resource); documented in README and `SECURITY.md`. Fallback if `tofu test`/validation proves an ephemeral variable cannot be referenced in cross-variable validation: drop the cross-key validation and rely on the resource lookup failing at plan.
- **`data_wo_version` default `1`.** Removes the `data_wo_version_set` check; unset versions in v2 had `null` in state, so they get one new revision on first apply (documented). Alternative: keep `null` default and the check; rejected as a footgun the type system can remove.
- **`secrets[*].key` vs `key_id`.** v2's value was either a map key or an ID, decided with `try()` (ambiguous if an ID equals a map key). Now `key` references `scaleway_key_manager_key.this[...].id` directly and `key_id` is passed as is; both set is rejected. `locals.tf` goes away.
- **`keys[*].protected` (default `true`).** Safe default instead of a deletable-by-default key plus a warning; the module sends `unprotected = !protected`. Existing keys on the old default get an in-place update to protected; deleting such a key later needs `protected = false` applied first. Alternative: keep `unprotected`. Rejected (`quality-security`: safe defaults, no warning needed).
- **Optional `name`.** `name = optional(string)`, resource uses `coalesce(each.value.name, each.key)`; validation runs on the effective name.
- **`tags`.** `distinct(concat(var.tags, each.value.tags))` on secrets and keys.
- **Output surface.** `secrets`, `secret_versions`, `keys` only; `secret_ids`, `key_ids`, `project_id` are redundant (`secrets[k].id`, own input).
- **Format validations** (`path`, `ephemeral_policy.ttl`, `rotation_period`) fail at plan with the accepted shape instead of at apply (`terraform-variables`). Duration regex: `^([0-9]+(h|m|s))+$`; path regex: `^/[a-zA-Z0-9._/-]*$`. They deliberately reject fractional or `ms`/`us` units the API has no use for; verify against the API in the real-account group.
- **No exception to the fixed decisions.** No `iam` resource, so `organization_id` is dropped; the module derives no names, so no `name` prefix input is added (`name` is per item).

## Avoiding perpetual diffs and state migration

- Addresses (`scaleway_secret.this[k]`, `scaleway_secret_version.this[k]`, `scaleway_key_manager_key.this[k]`) are unchanged: no `moved` block, no `state mv`.
- Unchanged infrastructure, expected second plan: empty after the migration edits **except**: (1) versions that used `data`: switching to `data_wo` forces a new revision (the provider replaces the version; old revision is destroyed, `latest` moves); (2) versions with `data_wo_version = null`: one new revision; (3) keys that relied on `unprotected = true`: in-place update to `unprotected = false`.
- `project_id`: explicit ID equal to the resolved one produces no diff; `null` yields the provider default and, if it differs from the previously looked-up project, forces replacement. Callers pass the same project.
- Tags: `distinct(concat(...))` keeps the order `var.tags` then item tags; v2 had only item tags, so adding `var.tags` is an in-place update only when used.
- `rotation_policy[0].next_rotation_at` is optional + computed in the schema, so with no value in config there is no diff; the `ignore_changes` shim is removed. If the real-account second plan shows a diff, keep the shim (tasks).
- `data_wo`/`secret_data` never appear in plan or state; changes to a payload without a version bump are intentionally invisible.
- No `provider {}` or `backend {}`; no CLI calls.

## Risks / Trade-offs

- [Consumers on `data` get a new secret revision] → documented; the old revision is replaced; consumers reading `latest` see the same value.
- [Ephemeral input requires an ephemeral caller source] → README example uses an ephemeral variable.
- [Protected-by-default keys block destroy] → upgrade note and variable description.
- [Mock provider cannot prove API acceptance] → real-account group, skipped unless the user runs it.

## Migration Plan

1. Release v3.0.0; follow README "Upgrading from v2 to v3": replace `organization_id`/`project_name`, move payloads to `secret_data`, rename `key_id` to `key` for module keys, `unprotected` to `protected`, use `secrets[k].id`.
2. `tofu plan`: expect only the diffs listed above.
3. Rollback: pin v2.0.0; nothing outside the listed diffs was written to state.
