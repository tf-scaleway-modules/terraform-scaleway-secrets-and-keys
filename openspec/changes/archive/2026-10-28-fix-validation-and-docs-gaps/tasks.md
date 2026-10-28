# Tasks

## 1. Variables and locals

- [x] 1.1 `project_name`: fix pattern and description (1-63)
- [x] 1.2 `secret_versions`: byte-based size check, `secret_key` validation, `data_wo_version` validation, corrected description
- [x] 1.3 `keys`: correct `unprotected` description
- [x] 1.4 Remove the commented-out `secret_version_revisions` local

## 2. Checks and documentation

- [x] 2.1 Add `checks.tf` (`keys_deletable`, `data_wo_version_set`)
- [x] 2.2 Create `SECURITY.md` (what lands in state, deletable keys)
- [x] 2.3 README: fix the pre-commit hook list

## 3. Tests and examples

- [x] 3.1 `tests/main.tftest.hcl`: happy path, one rejected run per validation, one run per check
- [x] 3.2 `examples/complete` and `examples/minimal`: explicit `unprotected`, `data_wo` with `data_wo_version`

## 4. Verification

- [x] 4.1 `tofu fmt -recursive`, `tofu validate`, `tofu test`
- [x] 4.2 `tflint --recursive`, `pre-commit run -a`
- [x] 4.3 `openspec validate --all --strict`, archive the change
- [x] 4.4 Commit subject: "Fix validation and documentation gaps in variables, add key and write-only version warnings" (CHANGELOG line, no upgrade notes needed)
