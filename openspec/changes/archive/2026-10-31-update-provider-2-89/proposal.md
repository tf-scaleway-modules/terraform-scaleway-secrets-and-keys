# Proposal

## Why

Scaleway provider 2.89.0 (released 2026-10-27) adds post-quantum Key Manager keys (`key_encapsulation`, ML-KEM, since 2.87.0) and more signing algorithms (ML-DSA, RSA-PSS, secp256k1), none of which the module's validation lets through; the module also rejects three Secret Manager secret types the provider has supported since before 2.86 (`certificate`, `key_value`, `ssh_key`). The module pins `~> 2.86`. Adopting the new key usage needs the provider floor raised, which `terraform-versioning` / `terraform-providers` classify as major.

## What Changes

| # | Item | Provider version | Breaking |
|---|------|------------------|----------|
| 1 | `keys[*].usage` accepts `key_encapsulation` with algorithms `ml_kem_768`, `ml_kem_1024` | 2.87.0 | No (input widened) |
| 2 | `asymmetric_signing` accepts `rsa_pss_2048_sha256`, `rsa_pss_3072_sha256`, `rsa_pss_4096_sha256`, `ec_secp256k1_sha256`, `ml_dsa_44`, `ml_dsa_65`, `ml_dsa_87` | listed in the 2.89.0 docs, absent from the 2.86.0 docs (2.87.0-2.89.0) | No |
| 3 | `secrets[*].type` accepts `certificate`, `key_value`, `ssh_key` (all six provider values are now allowed) | already in 2.86.0 (SDK enum) | No |
| 4 | `secrets`, `secret_versions` and `keys` outputs gain `srn` (Scaleway Resource Name) | already in 2.86.0 | No (new map key in outputs) |
| 5 | `versions.tf`: `~> 2.86` becomes `~> 2.89` | n/a | **BREAKING** (provider floor) |

**BREAKING**: the provider floor moves from `~> 2.86` to `~> 2.89`. Consumers that pin the provider below 2.89 (for example `= 2.86.x` or `~> 2.86.0`) must upgrade it; consumers with `~> 2.86` or looser already resolve to 2.89 on `init -upgrade`. Reason: item 1 (and the algorithms of item 2) use values that the 2.86.0 provider does not know. No input or output is removed, renamed or retyped; no default changes.

Semver: **major** (raised provider floor, `terraform-versioning`: "Provider floor raised"). The floor is raised to 2.89 rather than 2.87 for consistency with the sibling modules (a floor equal to the version the sibling modules test against), although 2.87.0 is the minimum the code needs.

What lands in state: unchanged. `secret_versions[*].data` is stored in state; `data_wo` never is. No new secret-bearing input. `srn` is a non-secret identifier.

Considered and not adopted (one-line reasons in design.md): `origin = "external"` key import, `next_rotation_at`, per-module `protection_level` output, `key_id` for versions, secret-without-version support (already works), module-side validation removal, `data.scaleway_account_project.srn`.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `module-contract`: provider constraint `~> 2.89`; `secrets`, `secret_versions` and `keys` output attributes include `srn`.
- `secrets`: accepted secret `type` values.
- `encryption-keys`: accepted `usage` values and usage/algorithm pairs.

## Impact

- Modified: `versions.tf`, `variables.tf` (descriptions and three validations), `outputs.tf` (descriptions and `srn`), `tests/main.tftest.hcl`, `examples/complete/main.tf`, README (generated block, provider badge, upgrade note).
- Consumers: must be able to install provider >= 2.89 (< 3.0). Nothing else to change; the new values are opt-in. Existing state: no diff (see design.md).
