mock_provider "scaleway" {
  mock_resource "scaleway_key_manager_key" {
    defaults = {
      id = "fr-par/33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  project_id = "11111111-1111-1111-1111-111111111111"
  region     = "fr-par"
}

run "happy_path" {
  command = plan

  variables {
    secrets = {
      db = { name = "db-password" }
    }
    secret_data = { v1 = "s3cret" }
    secret_versions = {
      v1 = { secret_key = "db", data_wo_version = 1 }
    }
    keys = {
      main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" }
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
    secrets = { db = { type = "password" } }
  }

  expect_failures = [var.secrets]
}

run "secret_types_accepted" {
  command = plan

  variables {
    secrets = {
      cert = { type = "certificate" }
      kv   = { type = "key_value" }
      ssh  = { type = "ssh_key" }
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

run "project_id_omitted" {
  command = plan

  variables {
    project_id = null
  }
}

run "project_id_rejected" {
  command = plan

  variables {
    project_id = "my-project"
  }

  expect_failures = [var.project_id]
}

run "project_id_passed_to_resources" {
  command = plan

  variables {
    secrets = { db = {} }
    keys    = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_secret.this["db"].project_id == var.project_id && scaleway_key_manager_key.this["main"].project_id == var.project_id
    error_message = "project_id must be passed to every secret and key."
  }
}

run "name_defaults_to_map_key" {
  command = plan

  variables {
    secrets = { db = {} }
    keys    = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_secret.this["db"].name == "db" && scaleway_key_manager_key.this["main"].name == "main"
    error_message = "name must default to the map key."
  }
}

run "secret_name_from_key_rejected" {
  command = plan

  variables {
    secrets = { "bad key" = {} }
  }

  expect_failures = [var.secrets]
}

run "secret_name_rejected" {
  command = plan

  variables {
    secrets = { db = { name = "-bad name" } }
  }

  expect_failures = [var.secrets]
}

run "secret_path_rejected" {
  command = plan

  variables {
    secrets = { db = { path = "production/api" } }
  }

  expect_failures = [var.secrets]
}

run "secret_path_nested_accepted" {
  command = plan

  variables {
    secrets = { db = { path = "/production/api" } }
  }
}

run "ephemeral_ttl_rejected" {
  command = plan

  variables {
    secrets = { db = { ephemeral_policy = { ttl = "one day" } } }
  }

  expect_failures = [var.secrets]
}

run "ephemeral_ttl_accepted" {
  command = plan

  variables {
    secrets = { db = { ephemeral_policy = { ttl = "1h30m" } } }
  }

  assert {
    condition     = one(scaleway_secret.this["db"].ephemeral_policy).ttl == "1h30m" && one(scaleway_secret.this["db"].ephemeral_policy).action == "delete"
    error_message = "ttl must be passed and action default to delete."
  }
}

run "ephemeral_action_rejected" {
  command = plan

  variables {
    secrets = { db = { ephemeral_policy = { ttl = "24h", action = "archive" } } }
  }

  expect_failures = [var.secrets]
}

run "tags_merged_distinct" {
  command = plan

  variables {
    tags    = ["env:prod"]
    secrets = { db = { tags = ["app:db", "env:prod"] } }
    keys    = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_secret.this["db"].tags == tolist(["env:prod", "app:db"]) && scaleway_key_manager_key.this["main"].tags == tolist(["env:prod"])
    error_message = "tags must be merged without duplicates."
  }
}

run "secret_key_and_key_id_rejected" {
  command = plan

  variables {
    secrets = { db = { key = "main", key_id = "fr-par/22222222-2222-2222-2222-222222222222" } }
    keys    = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  expect_failures = [var.secrets]
}

run "secret_unknown_key_rejected" {
  command = plan

  variables {
    secrets = { db = { key = "missing" } }
  }

  expect_failures = [var.secrets]
}

# The key ID is computed, so this run applies against the mock provider only.
run "key_reference_resolves" {
  command = apply

  variables {
    secrets = { db = { key = "main" } }
    keys    = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_secret.this["db"].key_id == scaleway_key_manager_key.this["main"].id
    error_message = "key must resolve to the ID of the key created for it."
  }
}

run "key_id_passthrough" {
  command = plan

  variables {
    secrets = { db = { key_id = "fr-par/22222222-2222-2222-2222-222222222222" } }
  }

  assert {
    condition     = scaleway_secret.this["db"].key_id == "fr-par/22222222-2222-2222-2222-222222222222"
    error_message = "key_id must be passed unchanged."
  }
}

run "secret_version_unknown_secret_key_rejected" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = "x" }
    secret_versions = { v1 = { secret_key = "missing" } }
  }

  expect_failures = [var.secret_versions]
}

run "secret_data_unknown_version_rejected" {
  command = plan

  variables {
    secret_data = { v9 = "x" }
  }

  expect_failures = [var.secret_data]
}

run "secret_version_without_data_rejected" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_versions = { v1 = { secret_key = "db" } }
  }

  expect_failures = [var.secret_data]
}

run "data_wo_version_defaults_to_one" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = "x" }
    secret_versions = { v1 = { secret_key = "db" } }
  }

  assert {
    condition     = scaleway_secret_version.this["v1"].data_wo_version == 1
    error_message = "data_wo_version must default to 1."
  }
}

run "data_wo_version_fractional_rejected" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = "x" }
    secret_versions = { v1 = { secret_key = "db", data_wo_version = 1.5 } }
  }

  expect_failures = [var.secret_versions]
}

# 64 KiB exactly
run "secret_data_payload_at_limit" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = join("", [for i in range(64) : join("", [for j in range(1024) : "a"])]) }
    secret_versions = { v1 = { secret_key = "db" } }
  }
}

run "secret_data_over_limit_rejected" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = "${join("", [for i in range(64) : join("", [for j in range(1024) : "a"])])}a" }
    secret_versions = { v1 = { secret_key = "db" } }
  }

  expect_failures = [var.secret_data]
}

# 40000 two-byte characters: 80000 bytes
run "secret_data_multibyte_over_limit_rejected" {
  command = plan

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = join("", [for i in range(40) : join("", [for j in range(1000) : "é"])]) }
    secret_versions = { v1 = { secret_key = "db" } }
  }

  expect_failures = [var.secret_data]
}

# The payload is write-only: it must not appear in the plan, state or outputs.
run "outputs_have_no_payload_and_no_removed_outputs" {
  command = apply

  variables {
    secrets         = { db = {} }
    secret_data     = { v1 = "s3cret" }
    secret_versions = { v1 = { secret_key = "db" } }
    keys            = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = !contains(keys(output.secret_versions["v1"]), "data") && !contains(keys(output.secret_versions["v1"]), "data_wo")
    error_message = "The secret_versions output must not carry a payload."
  }

  assert {
    condition     = length(setintersection(keys(output.keys["main"]), ["data", "data_wo"])) == 0
    error_message = "No output may carry secret data."
  }
}

run "key_usage_rejected" {
  command = plan

  variables {
    keys = { main = { usage = "hashing", algorithm = "aes_256_gcm" } }
  }

  expect_failures = [var.keys]
}

run "key_algorithm_rejected" {
  command = plan

  variables {
    keys = { main = { usage = "symmetric_encryption", algorithm = "ec_p256_sha256" } }
  }

  expect_failures = [var.keys]
}

run "key_encapsulation_key_accepted" {
  command = plan

  variables {
    keys = {
      kem768  = { name = "kem768", usage = "key_encapsulation", algorithm = "ml_kem_768" }
      kem1024 = { name = "kem1024", usage = "key_encapsulation", algorithm = "ml_kem_1024" }
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
      mldsa = { name = "mldsa", usage = "asymmetric_signing", algorithm = "ml_dsa_65" }
      pss   = { name = "pss", usage = "asymmetric_signing", algorithm = "rsa_pss_4096_sha256" }
      k1    = { name = "k1", usage = "asymmetric_signing", algorithm = "ec_secp256k1_sha256" }
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
    keys = { main = { usage = "key_encapsulation", algorithm = "aes_256_gcm" } }
  }

  expect_failures = [var.keys]
}

run "key_ml_kem_on_signing_rejected" {
  command = plan

  variables {
    keys = { main = { usage = "asymmetric_signing", algorithm = "ml_kem_768" } }
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
    secret_data = { v1 = "s3cret" }
    secret_versions = {
      v1 = { secret_key = "db", data_wo_version = 1 }
    }
    keys = {
      main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" }
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
    keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm", protection_level = "cloud" } }
  }

  expect_failures = [var.keys]
}

run "keys_protected_by_default" {
  command = plan

  variables {
    keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm" } }
  }

  assert {
    condition     = scaleway_key_manager_key.this["main"].unprotected == false
    error_message = "A key must be protected by default (unprotected = false)."
  }
}

run "protected_false" {
  command = plan

  variables {
    keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm", protected = false } }
  }

  assert {
    condition     = scaleway_key_manager_key.this["main"].unprotected == true
    error_message = "protected = false must send unprotected = true."
  }
}

run "key_rotation_period_rejected" {
  command = plan

  variables {
    keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm", rotation_period = "1 year" } }
  }

  expect_failures = [var.keys]
}

run "key_rotation_period_accepted" {
  command = plan

  variables {
    keys = { main = { usage = "symmetric_encryption", algorithm = "aes_256_gcm", rotation_period = "8760h" } }
  }

  assert {
    condition     = one(scaleway_key_manager_key.this["main"].rotation_policy).rotation_period == "8760h"
    error_message = "rotation_period must be passed to the rotation policy."
  }
}
