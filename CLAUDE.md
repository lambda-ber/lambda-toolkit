# CLAUDE.md

Guidance for agents working *on* this repository (as opposed to using its skills).

## What this is

A collection of Agent Skills for LAMBDA structural biology data, plus helper scripts. The
data model is `lambda-ber-schema` (LinkML); the packaging format is the LAMBDA Core RO-Crate
profile. Both live in https://github.com/lambda-ber/lambda-ber-schema. This repo teaches
agents to use them; it does not redefine them.

## Ground rules

- **The schema repo is the source of truth.** Commands come from `lambda-ber-schema --help`.
  Classes, slots, and enums come from the schema YAML. Do not write a value into a skill from
  memory; check it against a checkout first (`scripts/lambda_env.sh` finds one).
- **Regenerate, do not hand-edit** `skills/lambda-schema/references/schema-reference.md`.
  Run `python scripts/gen_schema_reference.py` after any schema change.
- **One skill, one job.** A skill's description says what it does and when to trigger.
  Long reference material goes in `references/`, runnable code in `scripts/`. Keep
  `SKILL.md` under about 500 lines.
- **Skills hand off by name.** `lambda-etl` → `lambda-schema` → `lambda-rocrate` →
  `lambda-validate`. When adding a skill, say which existing ones it calls and which call it.
- **Register new skills** in `.claude-plugin/marketplace.json` and the README table.
- **Do not commit pulled data.** Loader output, caches, and eval workspaces are gitignored.

## Testing a skill

The `skill-creator` skill (Anthropic's) runs a skill against test prompts with and without
the skill and shows the difference. Workspaces land in `skills/<name>-workspace/`, which is
gitignored. A cheaper check: read the SKILL.md as if you had never seen the schema, run every
command it shows against a checkout, and confirm each one works as written.

## Layout

```
.claude-plugin/marketplace.json   plugin manifest
scripts/lambda_env.sh             locate or install lambda-ber-schema
scripts/gen_schema_reference.py   regenerate the schema cheat sheet
skills/lambda-schema/             authoring records
skills/lambda-validate/           validating records and crates
skills/lambda-etl/                importing from archives
skills/lambda-rocrate/            building crates
```
