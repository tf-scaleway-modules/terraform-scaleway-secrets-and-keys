# Tasks

## 1. Tooling

- [x] 1.1 Pin `openspec` and node in `mise.toml`; add `spec-validate` and `spec-setup` tasks
- [x] 1.2 Add `scripts/openspec-setup.sh`, `.gitlab/specs.yml` and `OPENSPEC_VERSION`
- [x] 1.3 Install the `openspec-*` skills for Claude Code and OpenCode

## 2. Configuration

- [x] 2.1 Fill `openspec/config.yaml` context, rules and operations for this module (CHANGELOG via git-cliff, no `tests/` yet)
- [x] 2.2 Fill `AGENTS.md` and add `CLAUDE.md`

## 3. Baseline specs

- [x] 3.1 `module-contract`
- [x] 3.2 `secrets`
- [x] 3.3 `secret-versions`
- [x] 3.4 `encryption-keys`

## 4. Documentation and validation

- [x] 4.1 README "Contributing" points to the OpenSpec workflow
- [x] 4.2 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 4.3 `pre-commit run` passes on the changed files
