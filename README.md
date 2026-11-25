# Scaleway Secrets and Keys Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A **production-ready** Terraform/OpenTofu module for creating and managing Scaleway Secret Manager and Key Manager resources.

## Overview

This module provides comprehensive management for Scaleway security resources, enabling you to:

- **Securely store sensitive data** using Scaleway Secret Manager
- **Manage encryption keys** using Scaleway Key Manager
- **Implement secret versioning** for audit trails and rollbacks
- **Configure ephemeral secrets** with automatic expiration
- **Set up key rotation policies** for enhanced security

### Key Features

| Feature | Description |
|---------|-------------|
| **Secret Management** | Create and manage secrets with versioning, paths, and protection |
| **Secret Types** | Support for `opaque`, `basic_credentials`, and `database_credentials` |
| **Ephemeral Secrets** | Configure TTL and one-time access secrets |
| **Key Manager** | Create symmetric and asymmetric encryption keys |
| **Key Rotation** | Automatic key rotation with configurable periods |
| **Input Validation** | Comprehensive validation for all inputs |
| **Project & Tags** | Optional `project_id` and common `tags` merged into every secret and key |
| **Ephemeral Payloads** | Secret values go through the ephemeral `secret_data` into write-only `data_wo`: never in state or plan |
| **Safe Defaults** | Keys are protected from deletion unless `protected = false` |

## Quick Start

### Prerequisites

- Terraform >= 1.11 or OpenTofu >= 1.11
- Scaleway account with appropriate permissions
- Project ID from Scaleway Console (optional, the provider's default project applies otherwise)

### Minimal Example

```hcl
variable "api_key" {
  type      = string
  sensitive = true
  ephemeral = true # secret_data only accepts ephemeral values
}

module "secrets_and_keys" {
  source = "path/to/module"

  project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # optional

  # Create a secret
  secrets = {
    api_key = {
      name        = "my-api-key"
      description = "API key for external service"
    }
  }

  # Add the secret value: payload in secret_data, never in state
  secret_versions = {
    api_key_v1 = {
      secret_key      = "api_key"
      data_wo_version = 1 # bump to push a new value
    }
  }
  secret_data = {
    api_key_v1 = var.api_key
  }

  # Create an encryption key (protected from deletion by default)
  keys = {
    main = {
      usage     = "symmetric_encryption"
      algorithm = "aes_256_gcm"
    }
  }
}
```

## Usage Examples

### Creating Secrets with Different Types

```hcl
secrets = {
  # Standard opaque secret
  api_credentials = {
    name        = "api-credentials"
    description = "API credentials"
    path        = "/production/api"
    tags        = ["production", "api"]
    type        = "opaque"
  }

  # Database credentials
  database = {
    name = "database-credentials"
    type = "database_credentials"
    path = "/production/database"
  }

  # Protected secret (cannot be deleted)
  critical = {
    name      = "critical-secret"
    protected = true
  }
}
```

### Creating Ephemeral Secrets

```hcl
secrets = {
  # Secret that expires after 24 hours
  temporary_token = {
    name = "temporary-token"
    ephemeral_policy = {
      ttl    = "24h"
      action = "delete"
    }
  }

  # One-time secret (expires after first access)
  one_time_password = {
    name = "one-time-password"
    ephemeral_policy = {
      expires_once_accessed = true
      action                = "disable"
    }
  }
}
```

### Creating Encryption Keys

```hcl
keys = {
  # Symmetric encryption key (AES-256)
  data_encryption = {
    name      = "data-encryption-key"
    usage     = "symmetric_encryption"
    algorithm = "aes_256_gcm"
  }

  # Asymmetric encryption key (RSA-4096)
  asymmetric = {
    name      = "asymmetric-key"
    usage     = "asymmetric_encryption"
    algorithm = "rsa_oaep_4096_sha256"
  }

  # Signing key (ECDSA P-384)
  signing = {
    name      = "signing-key"
    usage     = "asymmetric_signing"
    algorithm = "ec_p384_sha384"
  }

  # Post-quantum signing key (ML-DSA)
  pq_signing = {
    name      = "pq-signing-key"
    usage     = "asymmetric_signing"
    algorithm = "ml_dsa_65"
  }

  # Post-quantum key encapsulation key (ML-KEM)
  kem = {
    name      = "kem-key"
    usage     = "key_encapsulation"
    algorithm = "ml_kem_768"
  }

  # Key with automatic rotation
  rotating = {
    name            = "auto-rotating-key"
    usage           = "symmetric_encryption"
    algorithm       = "aes_256_gcm"
    rotation_period = "8760h"  # 1 year
  }

  # Key backed by a dedicated Hardware Security Module
  hsm = {
    name             = "hsm-key"
    usage            = "symmetric_encryption"
    algorithm        = "aes_256_gcm"
    protection_level = "hsm"
  }
}
```

### Encrypting Secrets with Your Own Key and Keeping Data Out of the State

```hcl
secrets = {
  db_password = {
    name = "db-password"
    key  = "data_encryption" # a key of var.keys; use key_id for an existing Key Manager key ID
  }
}

secret_versions = {
  db_password_v1 = {
    secret_key      = "db_password"
    data_wo_version = 1 # bump to push a new value
  }
}

secret_data = {
  db_password_v1 = var.db_password # ephemeral: never stored in the state
}
```

### Input reference

#### secrets

Map of secrets to create in Scaleway Secret Manager. Each secret can have multiple versions managed separately through `secret_versions`. The map key is the reference used by `secret_versions`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | map key | Secret name, 1-255 characters: alphanumerics, dots, underscores and hyphens. |
| `description` | `string` | `null` | Human-readable description. |
| `path` | `string` | `"/"` | Path hierarchy, starting with `/`. |
| `protected` | `bool` | `false` | If `true`, prevents deletion. |
| `tags` | `list(string)` | `[]` | Tags for categorization, merged with the `tags` variable. |
| `type` | `string` | `"opaque"` | One of `opaque`, `certificate`, `key_value`, `basic_credentials`, `database_credentials`, `ssh_key`. |
| `key` | `string` | `null` | Key of the `keys` variable whose Key Manager key encrypts the secret's versions. Exclusive with `key_id`. |
| `key_id` | `string` | `null` | ID of an existing Key Manager key encrypting the secret's versions. Exclusive with `key`. With neither, the Secret Manager internal key is used. Changing the key recreates the secret. |
| `ephemeral_policy` | `object` | `null` | Optional ephemeral configuration, see below. |

`ephemeral_policy` attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `ttl` | `string` | `null` | Time-to-live in Go duration format, e.g. `24h` or `1h30m`. |
| `expires_once_accessed` | `bool` | `false` | If `true`, the secret expires after its first access. |
| `action` | `string` | `"delete"` | Action on expiry: `delete` or `disable`. |

#### secret_versions

Map of secret versions to create. Each version is linked to a secret of `secrets`. The payload is not part of this variable: it is the entry of the same key in `secret_data`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `secret_key` | `string` | required | Key referencing a secret in the `secrets` variable. |
| `data_wo_version` | `number` | `1` | Whole number; bump it to create a new version from a new `secret_data` value. |
| `description` | `string` | `null` | Description of this version. |

#### secret_data

Map of secret version payloads, keyed like `secret_versions`. The variable is sensitive and ephemeral: each value is sent through the write-only `data_wo` argument and never reaches the state or a plan file. Supply it from an ephemeral source (an ephemeral variable of the root module, an ephemeral resource). The maximum size per value is 64 KiB (bytes). A new value is only sent when `data_wo_version` of its version changes.

#### keys

Map of encryption keys to create in Scaleway Key Manager, used for cryptographic operations such as encryption, decryption and digital signing. The map key is the reference used by `secrets`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | map key | Key name. |
| `usage` | `string` | required | Key usage type, see the table below. |
| `algorithm` | `string` | required | Cryptographic algorithm, valid values depend on `usage`. |
| `description` | `string` | `null` | Human-readable description. |
| `tags` | `list(string)` | `[]` | Tags for categorization, merged with the `tags` variable. |
| `protected` | `bool` | `true` | If `true`, the key cannot be deleted; set `false` and apply before destroying the key. Deleting a key makes everything encrypted with it unreadable. |
| `rotation_period` | `string` | `null` | Automatic rotation period in Go duration format, e.g. `8760h` for 1 year. |
| `protection_level` | `string` | `null` (`software`) | `software` (default) or `hsm` (dedicated Hardware Security Module). Immutable: changing it recreates the key. |

| `usage` | Purpose | Valid `algorithm` values |
|---------|---------|--------------------------|
| `symmetric_encryption` | Symmetric encrypt/decrypt operations | `aes_256_gcm` |
| `asymmetric_encryption` | Asymmetric encrypt/decrypt operations | `rsa_oaep_2048_sha256`, `rsa_oaep_3072_sha256`, `rsa_oaep_4096_sha256` |
| `asymmetric_signing` | Digital signatures | `ec_p256_sha256`, `ec_p384_sha384`, `ec_secp256k1_sha256`, `rsa_pss_2048_sha256`, `rsa_pss_3072_sha256`, `rsa_pss_4096_sha256`, `rsa_pkcs1_2048_sha256`, `rsa_pkcs1_3072_sha256`, `rsa_pkcs1_4096_sha256`, `ml_dsa_44`, `ml_dsa_65`, `ml_dsa_87` |
| `key_encapsulation` | Key encapsulation (post-quantum ML-KEM) | `ml_kem_768`, `ml_kem_1024` |

ML-KEM and ML-DSA are post-quantum algorithms. Whether the API offers an algorithm for a region or protection level is decided by the API, not validated here.

### Output reference

Each output is a map keyed like the input it comes from.

| Output | Attributes per entry |
|--------|----------------------|
| `secrets` | `id`, `name`, `path`, `status`, `version_count` (number of versions), `created_at` and `updated_at` (RFC 3339), `srn` (Scaleway Resource Name) |
| `secret_versions` | `id`, `secret_id` (parent secret), `revision`, `status`, `created_at` and `updated_at` (RFC 3339), `srn` |
| `keys` | `id`, `name`, `usage`, `algorithm`, `state`, `protected` (protected from deletion), `rotation_count`, `rotated_at`, `created_at` and `updated_at` (RFC 3339), `srn` |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Scaleway Organization                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      Project                               │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────┐   │  │
│  │  │   Secret Manager    │    │     Key Manager         │   │  │
│  │  │  ┌───────────────┐  │    │  ┌─────────────────┐    │   │  │
│  │  │  │    Secret     │  │    │  │  Symmetric Key  │    │   │  │
│  │  │  │  ┌─────────┐  │  │    │  │   (AES-256)     │    │   │  │
│  │  │  │  │ Version │  │  │    │  └─────────────────┘    │   │  │
│  │  │  │  │   1     │  │  │    │  ┌─────────────────┐    │   │  │
│  │  │  │  └─────────┘  │  │    │  │ Asymmetric Key  │    │   │  │
│  │  │  │  ┌─────────┐  │  │    │  │  (RSA/ECDSA)    │    │   │  │
│  │  │  │  │ Version │  │  │    │  └─────────────────┘    │   │  │
│  │  │  │  │   2     │  │  │    │  ┌─────────────────┐    │   │  │
│  │  │  │  └─────────┘  │  │    │  │  Signing Key    │    │   │  │
│  │  │  └───────────────┘  │    │  │  (RSA/ECDSA)    │    │   │  │
│  │  └─────────────────────┘    │  └─────────────────┘    │   │  │
│  │                              └─────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Upgrading from v2 to v3

v3 is a major release. Resource addresses are unchanged (no `moved` block needed).

| v2 | v3 |
|----|----|
| `organization_id`, `project_name` | `project_id = "<uuid>"` (or `null` for the provider's default project); drop the other two |
| output `project_id` | use your own `project_id` value |
| `secret_versions[*].data` / `data_wo` | `secret_data = { <version key> = <value> }` from an ephemeral source (`ephemeral = true` variable or ephemeral resource) |
| `data_wo_version` default `null` | default `1`; set it explicitly |
| `secrets[*].key_id = "main"` (module key) | `key = "main"`; `key_id` is now an existing key ID only |
| `keys[*].unprotected` (default `true`) | `protected` (default `true`): `unprotected = false` is omitted, `unprotected = true` becomes `protected = false` |
| outputs `secret_ids`, `key_ids` | `secrets["k"].id`, `keys["k"].id` |
| checks `keys_deletable`, `data_wo_version_set` | removed (safe default, default version) |

Expected diffs on the first plan: a new revision for each version that used `data` or had no `data_wo_version`, and an in-place update to protected for keys that relied on the old default. Delete a protected key by applying `protected = false` first. Pass the same project as before: a different one forces replacement.

## Examples

- [Minimal](./examples/minimal/) - Simple secret and key creation
- [Complete](./examples/complete/) - All features including ephemeral secrets, protected secrets, multiple key types, and rotation policies

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [scaleway_key_manager_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/key_manager_key) | resource |
| [scaleway_secret.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/secret) | resource |
| [scaleway_secret_version.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_keys"></a> [keys](#input\_keys) | Map of encryption keys to create in Scaleway Key Manager, keyed by a stable reference used by `secrets`. See Input reference in the README for every attribute, valid usage and algorithm pairs. | <pre>map(object({<br/>    name             = optional(string)<br/>    usage            = string<br/>    algorithm        = string<br/>    description      = optional(string)<br/>    tags             = optional(list(string), [])<br/>    protected        = optional(bool, true)<br/>    rotation_period  = optional(string)<br/>    protection_level = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway Project ID (UUID) where secrets and keys are created. When `null`, the provider's default project applies. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Scaleway region where resources are created: `fr-par`, `nl-ams` or `pl-waw`. When `null`, the provider's region applies. | `string` | `null` | no |
| <a name="input_secret_data"></a> [secret\_data](#input\_secret\_data) | Sensitive and ephemeral map of secret version payloads keyed like `secret_versions`, each at most 64 KiB. Values are sent through the write-only `data_wo` argument and never reach the state or a plan file; a new value is sent only when `data_wo_version` changes. | `map(string)` | `{}` | no |
| <a name="input_secret_versions"></a> [secret\_versions](#input\_secret\_versions) | Map of secret versions to create, keyed by a stable reference shared with `secret_data`, which holds the payload. Each entry points to a secret of `secrets`. See Input reference in the README for every attribute. | <pre>map(object({<br/>    secret_key      = string<br/>    data_wo_version = optional(number, 1)<br/>    description     = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets to create in Scaleway Secret Manager, keyed by a stable reference used by `secret_versions`. See Input reference in the README for every attribute. | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    path        = optional(string, "/")<br/>    protected   = optional(bool, false)<br/>    tags        = optional(list(string), [])<br/>    type        = optional(string, "opaque")<br/>    key         = optional(string)<br/>    key_id      = optional(string)<br/>    ephemeral_policy = optional(object({<br/>      ttl                   = optional(string)<br/>      expires_once_accessed = optional(bool, false)<br/>      action                = optional(string, "delete")<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every secret and key, merged without duplicates with the tags of each item. Secret versions carry no tags. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_keys"></a> [keys](#output\_keys) | Map of created encryption keys keyed like `keys`, with `id`, `name`, `usage`, `algorithm`, `state`, `protected`, `rotation_count`, `rotated_at`, `created_at`, `updated_at` and `srn`. |
| <a name="output_secret_versions"></a> [secret\_versions](#output\_secret\_versions) | Map of created secret versions keyed like `secret_versions`, with `id`, `secret_id`, `revision`, `status`, `created_at`, `updated_at` and `srn`. |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | Map of created secrets keyed like `secrets`, with `id`, `name`, `path`, `status`, `version_count`, `created_at`, `updated_at` and `srn`. |
<!-- END_TF_DOCS -->

## Contributing

### Prerequisites

This module uses [mise](https://mise.jdx.dev/) for tool management. Install the required tools:

```bash
# Install mise (if not already installed)
curl https://mise.run | sh

# Install required tools
mise install

# Install pre-commit hooks
pre-commit install --install-hooks
```

### Development Workflow

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code. Run `mise run spec-setup` once per machine to register the standards stores.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation:
   ```bash
   tofu fmt -recursive
   tofu validate
   mise run spec-validate
   ```
5. Pre-commit hooks will automatically run on commit:
   - `tofu fmt` - Format Terraform/OpenTofu files
   - `terraform-docs` - Update README.md documentation
   - `terraform_tflint` - Lint the module

   The changelog is generated from commit subjects with `mise run changelog`.
6. Submit a merge request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind. Always test in non-production environments first.

---

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.11-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-secrets-and-keys?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-secrets-and-keys/-/releases
