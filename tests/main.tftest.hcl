mock_provider "scaleway" {}

override_data {
  target = data.scaleway_account_project.this
  values = {
    id = "11111111-1111-1111-1111-111111111111"
  }
}

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "my-project"
  region          = "fr-par"
}

run "happy_path" {
  command = plan

  variables {
    secrets = {
      db = { name = "db-password" }
    }
    secret_versions = {
      v1 = { secret_key = "db", data_wo = "s3cret", data_wo_version = 1 }
    }
    keys = {
      main = { name = "main", usage = "symmetric_encryption", algorithm = "aes_256_gcm", unprotected = false }
    }
  }

  assert {
    condition     = length(scaleway_secret.this) == 1 && length(scaleway_secret_version.this) == 1 && length(scaleway_key_manager_key.this) == 1
    error_message = "One secret, one version and one key must be planned."
  }

  assert {
    condition     = scaleway_key_manager_key.this["main"].unprotected == false
    error_message = "unprotected = false must be passed to the key."
  }
}

run "no_resources_by_default" {
  command = plan

  assert {
    condition     = length(scaleway_secret.this) == 0 && length(scaleway_secret_version.this) == 0 && length(scaleway_key_manager_key.this) == 0
    error_message = "No resource must be planned with default inputs."
  }
}

run "project_name_single_letter" {
  command = plan

  variables {
    project_name = "a"
  }
}

run "project_name_single_digit_rejected" {
  command = plan

  variables {
    project_name = "1"
  }

  expect_failures = [var.project_name]
}

run "project_name_single_hyphen_rejected" {
  command = plan

  variables {
    project_name = "-"
  }

  expect_failures = [var.project_name]
}

run "project_name_uppercase_rejected" {
  command = plan

  variables {
    project_name = "Prod"
  }

  expect_failures = [var.project_name]
}

run "organization_id_rejected" {
  command = plan

  variables {
    organization_id = "not-a-uuid"
  }

  expect_failures = [var.organization_id]
}

run "region_rejected" {
  command = plan

  variables {
    region = "us-east-1"
  }

  expect_failures = [var.region]
}

run "secret_type_rejected" {
  command = plan

  variables {
    secrets = { db = { name = "db", type = "password" } }
  }

  expect_failures = [var.secrets]
}

run "secret_types_accepted" {
  command = plan

  variables {
    secrets = {
      cert = { name = "cert", type = "certificate" }
      kv   = { name = "kv", type = "key_value" }
      ssh  = { name = "ssh", type = "ssh_key" }
    }
  }

  assert {
    condition = (
      scaleway_secret.this["cert"].type == "certificate" &&
      scaleway_secret.this["kv"].type == "key_value" &&
      scaleway_secret.this["ssh"].type == "ssh_key"
    )
    error_message = "certificate, key_value and ssh_key secret types must be planned as given."
  }
}

run "secret_version_unknown_secret_key_rejected" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "missing", data = "x" } }
  }

  expect_failures = [var.secret_versions]
}

run "secret_version_both_payloads_rejected" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data = "a", data_wo = "b" } }
  }

  expect_failures = [var.secret_versions]
}

# 64 KiB exactly
run "secret_version_payload_at_limit" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data = join("", [for i in range(64) : join("", [for j in range(1024) : "a"])]) } }
  }
}

run "secret_version_payload_over_limit_rejected" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data = "${join("", [for i in range(64) : join("", [for j in range(1024) : "a"])])}a" } }
  }

  expect_failures = [var.secret_versions]
}

# 40000 two-byte characters: 80000 bytes
run "secret_version_multibyte_payload_over_limit_rejected" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data_wo = join("", [for i in range(40) : join("", [for j in range(1000) : "é"])]), data_wo_version = 1 } }
  }

  expect_failures = [var.secret_versions]
}

run "data_wo_version_fractional_rejected" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data_wo = "x", data_wo_version = 1.5 } }
  }

  expect_failures = [var.secret_versions]
}

run "data_wo_without_version_warns" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data_wo = "x" } }
  }

  expect_failures = [check.data_wo_version_set]
}

run "data_wo_with_version_does_not_warn" {
  command = plan

  variables {
    secrets         = { db = { name = "db" } }
    secret_versions = { v1 = { secret_key = "db", data_wo = "x", data_wo_version = 1 } }
  }
}

run "key_usage_rejected" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "hashing", algorithm = "aes_256_gcm", unprotected = false } }
  }

  expect_failures = [var.keys]
}

run "key_algorithm_rejected" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "symmetric_encryption", algorithm = "ec_p256_sha256", unprotected = false } }
  }

  expect_failures = [var.keys]
}

run "key_encapsulation_key_accepted" {
  command = plan

  variables {
    keys = {
      kem768  = { name = "kem768", usage = "key_encapsulation", algorithm = "ml_kem_768", unprotected = false }
      kem1024 = { name = "kem1024", usage = "key_encapsulation", algorithm = "ml_kem_1024", unprotected = false }
    }
  }

  assert {
    condition = (
      scaleway_key_manager_key.this["kem768"].usage == "key_encapsulation" &&
      scaleway_key_manager_key.this["kem768"].algorithm == "ml_kem_768" &&
      scaleway_key_manager_key.this["kem1024"].usage == "key_encapsulation" &&
      scaleway_key_manager_key.this["kem1024"].algorithm == "ml_kem_1024"
    )
    error_message = "key_encapsulation keys must be planned with the given usage and algorithm."
  }
}

run "key_new_signing_algorithms_accepted" {
  command = plan

  variables {
    keys = {
      mldsa = { name = "mldsa", usage = "asymmetric_signing", algorithm = "ml_dsa_65", unprotected = false }
      pss   = { name = "pss", usage = "asymmetric_signing", algorithm = "rsa_pss_4096_sha256", unprotected = false }
      k1    = { name = "k1", usage = "asymmetric_signing", algorithm = "ec_secp256k1_sha256", unprotected = false }
    }
  }

  assert {
    condition = (
      scaleway_key_manager_key.this["mldsa"].algorithm == "ml_dsa_65" &&
      scaleway_key_manager_key.this["pss"].algorithm == "rsa_pss_4096_sha256" &&
      scaleway_key_manager_key.this["k1"].algorithm == "ec_secp256k1_sha256"
    )
    error_message = "The new signing algorithms must be planned as given."
  }
}

run "key_encapsulation_with_symmetric_algorithm_rejected" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "key_encapsulation", algorithm = "aes_256_gcm", unprotected = false } }
  }

  expect_failures = [var.keys]
}

run "key_ml_kem_on_signing_rejected" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "asymmetric_signing", algorithm = "ml_kem_768", unprotected = false } }
  }

  expect_failures = [var.keys]
}

# Computed values are unknown at plan time, so this run applies against the mock provider only.
run "srn_outputs_exposed" {
  command = apply

  variables {
    secrets = {
      db = { name = "db-password" }
    }
    secret_versions = {
      v1 = { secret_key = "db", data_wo = "s3cret", data_wo_version = 1 }
    }
    keys = {
      main = { name = "main", usage = "symmetric_encryption", algorithm = "aes_256_gcm", unprotected = false }
    }
  }

  assert {
    condition = (
      length(output.secrets["db"].srn) > 0 &&
      length(output.secret_versions["v1"].srn) > 0 &&
      length(output.keys["main"].srn) > 0
    )
    error_message = "srn must be exposed for the secret, the version and the key."
  }
}

run "key_protection_level_rejected" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "symmetric_encryption", algorithm = "aes_256_gcm", protection_level = "cloud", unprotected = false } }
  }

  expect_failures = [var.keys]
}

run "key_unprotected_by_default_warns" {
  command = plan

  variables {
    keys = { main = { name = "main", usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_key_manager_key.this["main"].unprotected == true
    error_message = "The module default of unprotected must stay true."
  }

  expect_failures = [check.keys_deletable]
}
