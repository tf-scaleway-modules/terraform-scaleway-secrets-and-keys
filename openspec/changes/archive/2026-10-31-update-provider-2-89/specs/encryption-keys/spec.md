## MODIFIED Requirements

### Requirement: Usage and algorithm validation
The module MUST reject a `usage` other than `symmetric_encryption`, `asymmetric_encryption`, `asymmetric_signing` or `key_encapsulation`, and MUST reject an `algorithm` that does not match the usage: `aes_256_gcm` for symmetric encryption; `rsa_oaep_2048_sha256`, `rsa_oaep_3072_sha256` or `rsa_oaep_4096_sha256` for asymmetric encryption; `rsa_pkcs1_2048_sha256`, `rsa_pkcs1_3072_sha256`, `rsa_pkcs1_4096_sha256`, `rsa_pss_2048_sha256`, `rsa_pss_3072_sha256`, `rsa_pss_4096_sha256`, `ec_p256_sha256`, `ec_p384_sha384`, `ec_secp256k1_sha256`, `ml_dsa_44`, `ml_dsa_65` or `ml_dsa_87` for asymmetric signing; `ml_kem_768` or `ml_kem_1024` for key encapsulation.

#### Scenario: Unknown usage
- **WHEN** `usage = "hashing"`
- **THEN** the plan fails with "Key usage must be one of: symmetric_encryption, asymmetric_encryption, asymmetric_signing, key_encapsulation."

#### Scenario: Algorithm not valid for the usage
- **WHEN** `usage = "symmetric_encryption"` and `algorithm = "ec_p256_sha256"`
- **THEN** the plan fails with "Algorithm must be valid for the specified usage type."

#### Scenario: Signing key
- **WHEN** `usage = "asymmetric_signing"` and `algorithm = "ec_p384_sha384"`
- **THEN** no validation error is raised

#### Scenario: Post-quantum signing key
- **WHEN** `usage = "asymmetric_signing"` and `algorithm = "ml_dsa_65"`
- **THEN** no validation error is raised

#### Scenario: Key encapsulation key
- **WHEN** `usage = "key_encapsulation"` and `algorithm = "ml_kem_768"`
- **THEN** no validation error is raised and the key is planned with that usage and algorithm

#### Scenario: Key encapsulation algorithm on another usage
- **WHEN** `usage = "key_encapsulation"` and `algorithm = "aes_256_gcm"`, or `usage = "asymmetric_signing"` and `algorithm = "ml_kem_768"`
- **THEN** the plan fails with "Algorithm must be valid for the specified usage type."
