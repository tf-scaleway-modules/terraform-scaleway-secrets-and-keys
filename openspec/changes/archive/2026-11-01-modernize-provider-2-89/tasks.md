# Tasks

Run every tool through `mise exec --`. Do not edit between `BEGIN_TF_DOCS` / `END_TF_DOCS`.

## 1. Inputs (`variables.tf`)

- [x] 1.1 Remove `organization_id` and `project_name`; add `project_id` (string, `null`, UUID validation "Project ID must be a valid UUID.") and `tags` (list(string), `[]`)
- [x] 1.2 `secrets`: `name` optional (effective name `coalesce(name, key)` validated), `key` and `key_id` (exclusive, `key` must exist in `keys`), `path` validation, `ephemeral_policy.ttl` duration validation, tags merge input
- [x] 1.3 `secret_versions`: remove `data`/`data_wo`; `data_wo_version` default `1`; keep `secret_key` validation and whole-number validation
- [x] 1.4 Add `secret_data` (map(string), `{}`, `sensitive = true`, `ephemeral = true`, no default secret): 64 KiB rule, keys must match `secret_versions` both ways
- [x] 1.5 `keys`: `name` optional, `protected` (default `true`) replaces `unprotected`, `rotation_period` duration validation; keep usage/algorithm/protection_level validations
- [x] 1.6 Update descriptions (structure lists, SECURITY note that no payload reaches state)

## 2. Resources and outputs

- [x] 2.1 `main.tf`: `project_id = var.project_id`, merged `tags`, `name = coalesce(...)`, `key_id` from `key`/`key_id`, `data_wo = var.secret_data[each.key]`, `unprotected = !each.value.protected`
- [x] 2.2 Try removing `lifecycle.ignore_changes` on `next_rotation_at`; keep it only if a mock/real second plan shows a diff (removed; the mock cannot prove the second plan, see 7.2)
- [x] 2.3 Delete `data.tf`, `locals.tf`, `checks.tf`
- [x] 2.4 `outputs.tf`: remove `project_id`, `secret_ids`, `key_ids`; keep `secrets`, `secret_versions`, `keys`; fix descriptions
- [x] 2.5 `versions.tf` unchanged (`>= 1.11.0`, `~> 2.89`); confirm

## 3. Unit tests (`tests/main.tftest.hcl`, mock_provider "scaleway")

- [x] 3.1 Drop the `data.scaleway_account_project` override and the `organization_id`/`project_name` variables; use `project_id`
- [x] 3.2 Rejected-input runs: `project_id_rejected`, `secret_name_from_key_rejected`, `secret_path_rejected`, `ephemeral_ttl_rejected`, `secret_key_and_key_id_rejected`, `secret_unknown_key_rejected`, `secret_data_unknown_version_rejected`, `secret_version_without_data_rejected`, `secret_data_over_limit_rejected` (+ multibyte), `data_wo_version_fractional_rejected`, `key_rotation_period_rejected`; keep existing key/type/region rejections
- [x] 3.3 Positive runs: `name_defaults_to_map_key` (secret and key), `tags_merged_distinct`, `key_reference_resolves`, `key_id_passthrough`, `keys_protected_by_default` (`unprotected == false`), `protected_false` (`unprotected == true`), `payload_at_limit`, `outputs_have_no_payload_and_no_removed_outputs`
- [x] 3.4 Remove runs for `data`, both-payloads, `keys_deletable` and `data_wo_version_set` checks
- [x] 3.5 If `secret_data` as an ephemeral variable cannot be set in `tofu test` variables, record it and apply the fallback in design.md (not needed: OpenTofu 1.11.14 accepts it and the cross-key validations run on the ephemeral value)

## 4. Examples and docs

- [x] 4.1 `examples/minimal` and `examples/complete`: `project_id`, `secret_data` from an ephemeral variable, `key = "..."`, `protected`, `tags`; complete shows ephemeral policy, HSM/PQ keys, rotation, key-encrypted secret
- [x] 4.2 README: features table (drop "Project Lookup", add tags/ephemeral payloads), usage, "Upgrading from v2 to v3" listing every breaking change with the consumer edit and the plan diffs expected (new revision for `data`/`null` version, keys now protected)
- [x] 4.3 `SECURITY.md`, `AGENTS.md` and `openspec/config.yaml` context: no `data`, `project_id`, removed files
- [x] 4.4 Move a local `.terraform.lock.hcl` aside, then `mise exec -- pre-commit run -a` (terraform-docs); restore it

## 5. Verification

- [x] 5.1 `mise exec -- tofu fmt -recursive`
- [x] 5.2 `mise exec -- tofu init -backend=false && mise exec -- tofu validate` (delete lock/.terraform afterwards if not wanted)
- [x] 5.3 `mise exec -- tflint --recursive`
- [x] 5.4 `mise exec -- tofu test`
- [x] 5.5 `mise exec -- pre-commit run -a`
- [x] 5.6 `mise exec -- openspec validate modernize-provider-2-89 --strict`

## 6. Commit

- [x] 6.1 Subject: `Send secret payloads write-only through ephemeral secret_data, protect keys by default and use project_id`; body starts with `BREAKING:` and lists the eight consumer edits from the proposal (`.cliff.toml` handles `Send secret payloads write-only through ephemeral secret_data, protect keys by default and use project_id`)

## 7. Real-account checks (separate, only if the user asks; never default)

- [ ] 7.1 Apply v2.0.0 with `data` versions, a `null` `data_wo_version`, an `unprotected` default key, then plan v3: confirm only the diffs listed in design.md and an empty second plan after apply
- [ ] 7.2 Confirm `next_rotation_at` produces no diff without `ignore_changes`
- [ ] 7.3 Confirm the API accepts the ttl/rotation formats and `path` rule; confirm `secret_data` from an ephemeral caller variable
