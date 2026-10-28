# Proposal

## Why

Writing the baseline specs (`adopt-openspec`) surfaced eight gaps between what the module says (descriptions, README, error messages) and what the code does, some of them security relevant: keys are deletable by default while the description says the opposite, and the description of `secret_versions` claims the payload is sensitive although a plain `data` payload is stored in state. This change closes them without breaking existing consumers (`terraform-versioning`, `quality-security`).

## What Changes

| # | Issue | Decision | Breaking |
|---|-------|----------|----------|
| 1 | `keys[*].unprotected` description says default `false`, code default is `true` | Keep the default; correct the description; add a `check` that warns for every key left deletable; document in `SECURITY.md`. | No |
| 2 | `secret_versions` description says `data` is "marked as sensitive" | Correct the description (the provider redacts `data` in CLI output but stores it in state; `data_wo` is never stored); create `SECURITY.md` with the what-lands-in-state table. No `sensitive`/`ephemeral` on the input. | No |
| 3 | `project_name` check accepts any single character; description says 2-63, message says 1-63 | Fix the pattern to `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$` (1-63, starts with a letter, ends with a letter or digit); description now says 1-63. | No: only rejects `-`, digits and uppercase single characters, which the documented rules already excluded |
| 4 | 64 KiB check counts characters, message says bytes | Count bytes (through the base64 length). | No: rejects only multi-byte payloads over 64 KiB, which the API refuses |
| 5 | Unknown `secret_versions[*].secret_key` fails with an index error | Add a validation on `secret_versions` naming the offending key. | No: the input already failed |
| 6 | `data_wo_version` unchecked and not required with `data_wo` | Validate it is a whole number; add a `check` that warns when `data_wo` is set without `data_wo_version`. Not a hard requirement: a first version without `data_wo_version` works today. | No |
| 7 | Commented-out `secret_version_revisions` local | Remove the dead code. | No |
| 8 | README lists `git-cliff` as a pre-commit hook | Fix the README list to the real hooks (`.pre-commit-config.yaml`); git-cliff runs through `mise run changelog`. | No |

Why issue 1 is not a default flip: changing `unprotected` to `false` alters resources of every consumer using the default (key becomes protected on next apply), which is **major** per `terraform-versioning`. A deletable key is an availability risk, not a confidentiality one, and a `check` warning plus documentation is the non-breaking alternative required by the decision rules. Flipping the default is left for the next planned major release.

What lands in state: unchanged. `secret_versions[*].data` is stored in state (redacted in CLI output by the provider); `secret_versions[*].data_wo` is never stored. No new secret-bearing input.

Semver: **patch** at the contract level (fixes, descriptions, validations that reject only inputs that already failed) plus new `check` warnings, which never fail a plan. Recommended release: **patch** (a new warning is not a new input, output or resource).

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `module-contract`: `project_name` rules (1-63 characters, no stray single characters).
- `secret-versions`: unknown `secret_key` message, byte-based size limit, `data_wo_version` validation and warning, state description.
- `encryption-keys`: documented default of `unprotected` and the warning for deletable keys.

## Impact

- Modified: `variables.tf`, `locals.tf`, README (pre-commit list; generated block), `examples/complete/main.tf`, `examples/minimal/main.tf`.
- Added: `checks.tf`, `tests/main.tftest.hcl`, `SECURITY.md`.
- Module consumers: none must act. Consumers that keep `unprotected` at its default now see a plan warning; they can silence it by setting `unprotected = false`.
