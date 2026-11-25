# Changelog

All notable changes to this project will be documented in this file.

## [3.0.1] - 2026-11-25
- Validate the module with Terraform and pin both toolchains
- Regenerate the README input and output tables with terraform-docs
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry
- Send secret payloads write-only through ephemeral secret_data, protect keys by default and use project_id

BREAKING: v3.0.0.

- organization_id and project_name are replaced by project_id; output
  project_id is removed.
- secret_versions[*].data and data_wo are removed: payloads come from the
  ephemeral secret_data map (same keys) through data_wo and never reach
  state; moving off data creates one new revision.
- data_wo_version defaults to 1.
- secrets[*].key_id takes only an existing key ID; module keys are
  referenced with secrets[*].key.
- keys[*].unprotected becomes protected (default true): keys that relied
  on the old default become protected in place.
- Outputs secret_ids and key_ids are removed: use secrets[k].id and
  keys[k].id. The keys_deletable and data_wo_version_set checks are gone.
- New tags input, optional names (default to the map key), path, TTL and
  rotation period validation.

See "Upgrading from v2 to v3" in the README.
- Raise Scaleway provider to ~> 2.89, add key_encapsulation (ML-KEM) and new signing algorithms, secret types and srn outputs

BREAKING: the Scaleway provider floor rises from ~> 2.86 to ~> 2.89
(key_encapsulation keys need provider 2.87.0).

Upgrade notes:
- Consumers pinning the provider below 2.89 must raise the pin and run
  `tofu init -upgrade`.
- No input, output or state change otherwise; the secrets, secret_versions
  and keys outputs gain an srn attribute.
- Newly accepted: keys usage key_encapsulation (ml_kem_768, ml_kem_1024),
  signing algorithms rsa_pss_*_sha256, ec_secp256k1_sha256, ml_dsa_44/65/87,
  secret types certificate, key_value and ssh_key.
- Fix validation and documentation gaps, warn on deletable keys and unversioned write-only data

- Fix the project_name pattern (1-63 characters, a single non-letter is rejected).
- Count the 64 KiB secret payload limit in bytes.
- Reject a secret_versions[*].secret_key that is not in secrets.
- Require data_wo_version to be a whole number.
- Warn at plan time for keys left deletable (unprotected defaults to true) and for data_wo without data_wo_version.
- Correct the unprotected description and the state handling of data.
- Add SECURITY.md and unit tests; remove a dead local; fix the README pre-commit list.
No upgrade action needed. Setting unprotected = false on keys silences the new warning.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Key the pre-commit cache on mise.toml and .pre-commit-config.yaml

The cache was keyed on the branch, so a branch kept tools installed by the previous mise, which the new one no longer puts on PATH (tofu not found). Keying it on the files that define the toolchain, as in scaleway-compute and scaleway-storage, starts a fresh cache whenever the toolchain changes and shares it across branches and tags.
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Adopt OpenSpec and publish the baseline specs

Planning adopts OpenSpec, aligned with the other leminnov Terraform
modules: the engineering standards come from the quality, repository and
terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- feat: add secret KMS key, HSM key protection and write-only secret data

- secrets: add key_id (a key of var.keys or an existing Key Manager key)
  to encrypt secret versions.
- keys: add protection_level (software or hsm).
- secret_versions: add data_wo (+ data_wo_version), never stored in the
  state; data is now optional (set exactly one).
- Require OpenTofu/Terraform >= 1.11 (write-only arguments).
- Bump the scaleway provider constraint to ~> 2.86 (module and examples).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
- Adjust Scaleway provider constraint and disable unused local
- Updates scaleway provider version

Updates the scaleway provider version in the README to the latest released version.
- Updates key algorithm naming and defaults

Standardizes key algorithm names for consistency.

Changes default protection behavior, to allow deletion of keys by default, to improve usability and flexibility.

Ignores changes to the `next_rotation_at` attribute in the scaleway_key_manager_key resource to prevent drift caused by computed values.
- Refactors module for secrets and keys management

This commit introduces a comprehensive refactor of the module, focusing on enhanced functionality, improved organization, and user experience.

- Changes from a project-scoped to a more general-purpose module for managing secrets and keys.
- Adds complete and minimal examples to demonstrate module usage.
- Introduces local values to consolidate project ID resolution and secret/key ID mapping.
- Implements resources for managing secrets, secret versions, and key manager keys.
- Implements input variables for configuring secrets and key manager resources.
- Introduces outputs for secrets, secret versions, and encryption keys.
- first commit of template
- Initial commit

