# Design

## Context

The module is small (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `data.tf`) and has no tests and no prior spec workflow. Its contract must be captured without changing it. Where the code and its documentation disagree, the specs follow the code and the disagreement is reported rather than fixed.

## Goals / Non-Goals

**Goals:**
- Baseline specs for the released behaviour, with a scenario for every `validation` block.
- Same OpenSpec tooling as the sibling modules.

**Non-Goals:**
- Any change to `.tf` files, defaults, validations or outputs.
- Adding `tests/` or `checks.tf` (the module has no `check` blocks).

## Decisions

- **Stores via the profile.** `openspec/config.yaml` references `quality`, `repository` and `terraform` at the tags of the `terraform-module` profile; standards are fetched on demand, not copied.
- **Skills for both agents.** The `openspec-*` skills are installed for Claude Code and OpenCode; `AGENTS.md` is the shared entry point and `CLAUDE.md` imports it.
- **CI.** The `validate:specs` job runs `openspec validate --all --strict`, the same command as `mise run spec-validate`.
- **Capability split.** `module-contract` holds what applies to the whole module (versions, shared inputs, outputs); one capability per resource type (`secrets`, `secret-versions`, `encryption-keys`) because each has its own inputs, validations and conditional creation.
- **State vs write-only.** `secret-versions` states plainly that `data` is part of the resource and lands in state, while `data_wo` is write-only and never stored.
- **CHANGELOG stays generated.** git-cliff builds `CHANGELOG.md` from commit subjects (`mise run changelog`); the OpenSpec rules ask for subjects that read as CHANGELOG lines instead of a hand-edited `[Unreleased]` section.

## Risks / Trade-offs

- Some inconsistencies between descriptions and code are not specified (reported in the task summary, not fixed here), so a later change must decide the intended behaviour.
