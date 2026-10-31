# Design

## Context

The module validates `keys[*].usage`/`algorithm` and `secrets[*].type` against hard-coded lists in `variables.tf` and passes them straight to `scaleway_key_manager_key` and `scaleway_secret`. The lists lag the provider. Gap analysis of provider 2.86.0 vs 2.89.0 (docs diff of `key_manager_key`, `secret`, `secret_version`; provider source for the secret `type` enum) for the four objects the module uses:

| Object | Provider surface not exposed by the module | Verdict |
|--------|---------------------------------------------|---------|
| `scaleway_key_manager_key` | `usage = key_encapsulation`, `ml_kem_768`/`ml_kem_1024` (2.87.0); signing algorithms `rsa_pss_2048/3072/4096_sha256`, `ec_secp256k1_sha256`, `ml_dsa_44/65/87` (in 2.89.0 docs, not in 2.86.0 docs); `srn` (2.86.0); `origin` (2.86.0); `rotation_policy.next_rotation_at` (2.86.0) | adopt usage, algorithms, `srn`; defer `origin`, `next_rotation_at` |
| `scaleway_secret` | `type` values `certificate`, `key_value`, `ssh_key` (SDK enum, 2.86.0); `srn` (2.86.0) | adopt both |
| `scaleway_secret_version` | `srn` (2.86.0); 2.87.0 fix for the *ephemeral* resource only | adopt `srn`; nothing else |
| `data.scaleway_account_project` | computed `srn` (2.87.0) | not needed, the module only uses `id` |

Already exposed (no work): `protection_level` and secret `key_id` (2.86.0), `path`, `protected`, `ephemeral_policy`, `unprotected`, `rotation_policy.rotation_period`. 2.87.0's Key Manager retry on transient IAM 403 is internal to the provider and arrives with the floor.

Standards applied: `terraform-versioning` and `terraform-providers` (raised floor is major, design names argument and version), `terraform-variables` (validation blocks name accepted values, each covered by a rejected-input test), `terraform-outputs` (new map keys in outputs are minor), `terraform-testing`, `terraform-security` (state), `quality-simplicity`, `quality-security`, `quality-production-readiness`.

## Goals / Non-Goals

**Goals:**
- Let consumers create post-quantum (ML-KEM, ML-DSA) and the other newly supported key types and all six secret types.
- Expose `srn` so consumers can build IAM policies / references without string-building.
- Keep the module small: extend lists, no new inputs, no new resources.

**Non-Goals / Deferred:**
- `keys[*].origin = "external"` (key import): needs a key-material import flow (`scaleway_key_manager_key` alone creates an empty external key that must be loaded out of band); not low-risk or simple, and would put key material questions into the module. Deferred.
- `rotation_policy.next_rotation_at`: computed by the API from `rotation_period`; the module already ignores it. Exposing it adds an input that creates a perpetual-diff risk. Rejected.
- `protection_level`/`origin` in the `keys` output: `protection_level` is the caller's own input (immutable), so the output adds nothing. Rejected (YAGNI).
- Removing the module-side usage/algorithm validation because the provider now validates at plan time: the provider only emits a warning for unrecognised values, while the module fails the plan early with an error naming the accepted values (`terraform-variables`). Kept and extended. Cost: the lists need a manual refresh per provider release (this change is that refresh).
- `data.scaleway_account_project.srn`: unused by the module. Rejected.
- Making `secret_versions` optional or adding secret-ID outputs for the `scaleway-iam` sibling (`scaleway_iam_api_key.secret_id`, 2.88): already supported. `secret_versions` defaults to `{}`, so a secret can exist with no managed version, and `secret_ids` / `secrets[*].id` already output the ID. The sibling can pass `module.x.secret_ids["key"]`; the modules are not coupled. No change.
- Ephemeral `scaleway_secret_version` resource (revision/region fix, `srn`, 2.87.0): the module keeps the regular resource with `data_wo`, which keeps the payload out of state; the ephemeral resource is a different thing (reads). Not applicable.
- Secret `type` and `ephemeral_policy.action` values beyond what the SDK enum offers for `type` (`unknown_type` is excluded on purpose, it is not creatable).

## Decisions

- **Provider floor `~> 2.89`, major.** `key_encapsulation`/`ml_kem_*` exist from provider 2.87.0 and the extra signing algorithms are only documented from 2.87-2.89, so the 2.86.0 provider would reject (or warn about) them. Per the user-approved policy the floor is raised only because adopted values need it; the minimum the code needs is 2.87.0, the constraint becomes `~> 2.89` for consistency with sibling modules and to take the 2.87.0 Key Manager IAM-403 retry. `terraform-versioning`: raised floor is major; the commit body and README upgrade note say so with the reason. `required_version >= 1.11.0` unchanged.
- **`keys[*].usage`** gains `key_encapsulation` (provider 2.87.0). The algorithm validation becomes a map-free `contains` per usage, extended: signing adds `rsa_pss_2048_sha256`, `rsa_pss_3072_sha256`, `rsa_pss_4096_sha256`, `ec_secp256k1_sha256`, `ml_dsa_44`, `ml_dsa_65`, `ml_dsa_87`; key encapsulation allows `ml_kem_768`, `ml_kem_1024`. Implementation note: replace the three-branch `||` expression by a local/inline map `usage => list(algorithm)` and `contains(lookup(map, v.usage, []), v.algorithm)` to keep the validation readable (`quality-simplicity`); error messages keep their text, the usage message lists the new value. Variable description lists the algorithms per usage and says ML-* are post-quantum.
- **`secrets[*].type`** allows `opaque`, `certificate`, `key_value`, `basic_credentials`, `database_credentials`, `ssh_key`. Provider side these have been valid since before 2.86 (SDK enum `secret.SecretType`; the provider validates with `ValidateEnum`), so no floor is needed for this item. The module does not validate the payload shape for typed secrets (the API does).
- **`srn` outputs**: add `srn = secret.srn` / `version.srn` / `kms_key.srn` to the existing per-entry objects. A new map key in an output is minor (`terraform-outputs`, `terraform-versioning`). `srn` is computed, non-sensitive, no payload (`terraform-security`). Output descriptions list it.
- **No new inputs, resources or checks**: the new values flow through existing attributes; the existing `keys_deletable` check still guards deletion.

## Avoiding perpetual diffs and state migration

- No resource address changes: no `moved` block, no replacement, no `state mv`. Existing state plans empty after `init -upgrade`: the attributes the module sends for existing entries are unchanged, and `srn` is a new computed output read from attributes the 2.86.0 schema already stored (it is refreshed on the first plan, output only, no resource change).
- Newly accepted values are opt-in; an existing key or secret is not touched unless its `usage`, `algorithm` or `type` is edited. Editing `usage`/`algorithm` of an existing key and `type` of an existing secret is forced replacement by the provider (immutable at the API for keys); callers should expect that and `unprotected = false` keys need a manual step before deletion (existing behaviour, documented in the key docs). `protected` secrets cannot be recreated without setting `protected = false` first.
- Algorithm and usage are sent as given, so no normalisation is needed; `rotation_policy[0].next_rotation_at` keeps its `ignore_changes`.
- `provider {}` and `backend {}` stay out of the module; the module shells out to nothing.

## Risks / Trade-offs

- [Consumers pinned below 2.89 break at `init`] → major bump, README upgrade note, commit body explains the reason and the fix (`tofu init -upgrade`, raise the provider pin).
- [Algorithm lists drift from the provider again] → accepted; error is plan-time and names accepted values; the provider's own warning is the second line. Update the list when bumping the provider floor.
- [New algorithms are only in the 2.89.0 docs, exact introducing minor unverified] → the floor is 2.89, so every listed value is known to the minimum provider. Whether the API enables a given algorithm in a region/protection level is not validated by the module (an `hsm` + ML-* combination may be refused by the API at apply). Documented in the variable description; not duplicated in validation.
- [Unit tests use a mock provider, so API acceptance of new values is unproven] → the integration/example apply is a manual release step; this change records it as skipped unless the user runs it (no `tofu apply` by default).

## Migration Plan

1. Release as a new major tag; consumers raise their provider pin to `~> 2.89` (or leave `~> 2.86` and run `tofu init -upgrade`), then `tofu plan` shows no changes.
2. Rollback: pin the previous module tag and provider; nothing was written to state besides the computed `srn`, which the older module ignores.

## Implementation notes

- `srn_outputs_exposed` uses `command = apply` against the mock provider: `srn` is computed, so it is unknown at plan time and cannot be asserted in a plan run. No real resource or credential is involved.
- Beyond the task list: the `~> 2.86` mention in `AGENTS.md` and `openspec/config.yaml` follows the new floor; `openspec/specs/` is updated at archive time.
