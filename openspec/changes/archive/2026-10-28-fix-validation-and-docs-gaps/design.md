# Design

## Context

Descriptions, error messages and code of `variables.tf` disagree in places. Standards applied: `terraform-versioning` (classification), `terraform-variables` (validation, sensitive), `terraform-security` (state, guardrails), `terraform-testing`, `quality-security`, `quality-simplicity`.

## Decisions

- **`unprotected` default stays `true`.** Flipping it is major (resources change). A `check "keys_deletable"` in a new `checks.tf` warns, naming the keys with `unprotected = true`; `terraform-security` prescribes `check` for dangerous but legal configurations. `SECURITY.md` documents it and the path to protection (`unprotected = false`). The warning fires on defaults, which is the point: the default is the surprise. `scaleway_key_manager_key.unprotected` has no provider default, so the module default is the only source.
- **No `sensitive`/`ephemeral` on `secret_versions`.** The map is iterated by `for_each`; a sensitive collection cannot be a `for_each` argument, and an ephemeral variable cannot feed `data`. The description is corrected instead. The provider schema marks `data` and `data_wo` `sensitive` (redacted in CLI output) and `data_wo` `write_only` (never stored); `data` is stored in state. `SECURITY.md` records it (`terraform-security`: what lands in state).
- **`project_name` pattern** `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$` replaces the regex plus the `length == 1` escape hatch. Single letters stay valid, so the 1-63 message was right and the description (2-63) was wrong.
- **Byte limit.** OpenTofu has no byte-length function. `base64encode` encodes the UTF-8 bytes; the unpadded length is `ceil(4n/3)`, strictly increasing at the boundary: `n = 65536` gives 87382, `n = 65537` gives 87383. So `length(replace(base64encode(d), "=", "")) <= 87382` is exactly `n <= 65536`.
- **`secret_key` validation** is a second validation on `secret_versions` using `contains(keys(var.secrets), ...)`. Cross-variable validation references need OpenTofu/Terraform >= 1.9; the floor is 1.11, so no version change.
- **`data_wo_version`.** A hard requirement alongside `data_wo` would reject configs that work (a first version without it), so it is a `check "data_wo_version_set"` warning (rotation silently does nothing without it, provider doc: "To update the `data_wo`, you must also update the `data_wo_version`"). A validation requires it to be a whole number (the provider attribute is an integer).
- **Dead local** `secret_version_revisions` removed. **README** pre-commit list matches `.pre-commit-config.yaml` (`terraform_fmt`, `terraform_docs`, `terraform_tflint`).

## Avoiding perpetual diffs and state migration

No resource, argument or address changes: no `moved` block, no replacement, no in-place update. Checks and validations only act at plan time.

## Risks

- A `check` warning is not fatal and may be ignored; accepted, the alternative is a breaking change.
- The base64 trick is non-obvious; a comment explains it and the test covers 65536 / 65537 bytes with a multi-byte character.
