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
| **Project Lookup** | Automatic project ID resolution from project name |

## Quick Start

### Prerequisites

- Terraform >= 1.10.7 or OpenTofu >= 1.10.7
- Scaleway account with appropriate permissions
- Organization ID from Scaleway Console

### Minimal Example

```hcl
module "secrets_and_keys" {
  source = "path/to/module"

  organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  project_name    = "my-project"

  # Create a secret
  secrets = {
    api_key = {
      name        = "my-api-key"
      description = "API key for external service"
    }
  }

  # Add the secret value
  secret_versions = {
    api_key_v1 = {
      secret_key = "api_key"
      data       = "super-secret-api-key-value"
    }
  }

  # Create an encryption key
  keys = {
    main = {
      name      = "main-encryption-key"
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

  # Key with automatic rotation
  rotating = {
    name            = "auto-rotating-key"
    usage           = "symmetric_encryption"
    algorithm       = "aes_256_gcm"
    rotation_period = "8760h"  # 1 year
  }
}
```

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

## Examples

- [Minimal](./examples/minimal/) - Simple secret and key creation
- [Complete](./examples/complete/) - All features including ephemeral secrets, protected secrets, multiple key types, and rotation policies

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.64 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_key_manager_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/key_manager_key) | resource |
| [scaleway_secret.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/secret) | resource |
| [scaleway_secret_version.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/secret_version) | resource |
| [scaleway_account_project.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_keys"></a> [keys](#input\_keys) | Map of encryption keys to create in Scaleway Key Manager.<br/><br/>Keys are used for cryptographic operations like encryption, decryption,<br/>and digital signing.<br/><br/>Structure:<br/>- name: Key name (required)<br/>- usage: Key usage type (required)<br/>  - "symmetric\_encryption": For symmetric encrypt/decrypt operations<br/>  - "asymmetric\_encryption": For asymmetric encrypt/decrypt operations<br/>  - "asymmetric\_signing": For digital signatures<br/>- algorithm: Cryptographic algorithm (required, depends on usage)<br/>  - For symmetric\_encryption: "aes\_256\_gcm"<br/>  - For asymmetric\_encryption: "rsa\_oaep\_2048\_sha256", "rsa\_oaep\_3072\_sha256", "rsa\_oaep\_4096\_sha256"<br/>  - For asymmetric\_signing: "rsa\_pkcs1\_2048\_sha256", "rsa\_pkcs1\_3072\_sha256", "rsa\_pkcs1\_4096\_sha256", "ec\_p256\_sha256", "ec\_p384\_sha384"<br/>- description: Human-readable description<br/>- tags: List of tags for categorization<br/>- unprotected: If true, allows key deletion (defaults to false - protected)<br/>- rotation\_period: Automatic rotation period in Go duration format (e.g., "8760h" for 1 year) | <pre>map(object({<br/>    name            = string<br/>    usage           = string<br/>    algorithm       = string<br/>    description     = optional(string)<br/>    tags            = optional(list(string), [])<br/>    unprotected     = optional(bool, true)<br/>    rotation_period = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway Organization ID.<br/><br/>The organization is the top-level entity in Scaleway's hierarchy.<br/>Find this in the Scaleway Console under Organization Settings.<br/><br/>Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Scaleway Project name where resources will be created.<br/><br/>Projects provide logical isolation within an organization.<br/>The project ID will be automatically resolved from this name.<br/><br/>Naming rules:<br/>- Must start with a lowercase letter<br/>- Can contain lowercase letters, numbers, and hyphens<br/>- Must be 2-63 characters long | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Scaleway region where resources will be created.<br/><br/>If not provided, defaults to the provider's region configuration.<br/><br/>Valid regions: fr-par, nl-ams, pl-waw | `string` | `null` | no |
| <a name="input_secret_versions"></a> [secret\_versions](#input\_secret\_versions) | Map of secret versions to create.<br/><br/>Each version is linked to a secret defined in the 'secrets' variable.<br/>The 'data' field contains the actual secret value.<br/><br/>SECURITY: The data field is marked as sensitive and will not appear in logs.<br/>Maximum data size is 64 KiB.<br/><br/>Structure:<br/>- secret\_key: Key referencing a secret in the 'secrets' variable<br/>- data: The secret data payload (sensitive)<br/>- description: Optional description of this version | <pre>map(object({<br/>    secret_key  = string<br/>    data        = string<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets to create in Scaleway Secret Manager.<br/><br/>Each secret can have multiple versions managed separately via the<br/>'secret\_versions' variable.<br/><br/>Structure:<br/>- name: Secret name (required, used as identifier)<br/>- description: Human-readable description<br/>- path: Path hierarchy (defaults to "/")<br/>- protected: If true, prevents deletion (defaults to false)<br/>- tags: List of tags for categorization<br/>- type: Secret type - "opaque" (default), "basic\_credentials", or "database\_credentials"<br/>- ephemeral\_policy: Optional ephemeral configuration<br/>  - ttl: Time-to-live in Go duration format (e.g., "24h", "168h")<br/>  - expires\_once\_accessed: If true, expires after first access<br/>  - action: Action on expiry - "delete" or "disable" | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    path        = optional(string, "/")<br/>    protected   = optional(bool, false)<br/>    tags        = optional(list(string), [])<br/>    type        = optional(string, "opaque")<br/>    ephemeral_policy = optional(object({<br/>      ttl                   = optional(string)<br/>      expires_once_accessed = optional(bool, false)<br/>      action                = optional(string, "delete")<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_ids"></a> [key\_ids](#output\_key\_ids) | Map of key keys to their IDs for easy reference. |
| <a name="output_keys"></a> [keys](#output\_keys) | Map of created encryption keys with their attributes.<br/><br/>Each entry contains:<br/>- id: The unique identifier of the key<br/>- name: The name of the key<br/>- usage: The usage type (symmetric\_encryption, asymmetric\_encryption, asymmetric\_signing)<br/>- algorithm: The cryptographic algorithm<br/>- state: Current state of the key<br/>- protected: Whether the key is protected from deletion<br/>- rotation\_count: Number of rotations performed<br/>- rotated\_at: Last rotation timestamp<br/>- created\_at: Creation timestamp (RFC 3339)<br/>- updated\_at: Last update timestamp (RFC 3339) |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The ID of the Scaleway project (resolved from project\_name). |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of secret keys to their IDs for easy reference. |
| <a name="output_secret_versions"></a> [secret\_versions](#output\_secret\_versions) | Map of created secret versions with their attributes.<br/><br/>Each entry contains:<br/>- id: The unique identifier of the version<br/>- secret\_id: The ID of the parent secret<br/>- revision: The revision number<br/>- status: Current status of the version<br/>- created\_at: Creation timestamp (RFC 3339)<br/>- updated\_at: Last update timestamp (RFC 3339) |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | Map of created secrets with their attributes.<br/><br/>Each entry contains:<br/>- id: The unique identifier of the secret<br/>- name: The name of the secret<br/>- path: The path hierarchy<br/>- status: Current status of the secret<br/>- version\_count: Number of versions<br/>- created\_at: Creation timestamp (RFC 3339)<br/>- updated\_at: Last update timestamp (RFC 3339) |
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation:
   ```bash
   tofu fmt -recursive
   tofu validate
   ```
5. Pre-commit hooks will automatically run on commit:
   - `tofu fmt` - Format Terraform/OpenTofu files
   - `terraform-docs` - Update README.md documentation
   - `git-cliff` - Update CHANGELOG.md
6. Submit a merge request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind. Always test in non-production environments first.

---

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.64-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-secrets-and-keys?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-secrets-and-keys/-/releases
