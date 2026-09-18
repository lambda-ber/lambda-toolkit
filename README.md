# lambda-toolkit

Skills, methods, and processes for working with [LAMBDA](https://github.com/lambda-ber) data.

LAMBDA data is described by [`lambda-ber-schema`](https://github.com/lambda-ber/lambda-ber-schema),
a LinkML schema for structural biology across cryo-EM, X-ray crystallography, SAXS/WAXS, SANS,
and cryo-ET, and packaged as RO-Crates under the LAMBDA Core RO-Crate profile. This repository
holds [Agent Skills](https://code.claude.com/docs/en/skills) that teach an agent how to read,
write, validate, import, and package that data, plus the small helper scripts the skills lean on.

## Skills

| skill | what it does |
|---|---|
| [`lambda-schema`](skills/lambda-schema/SKILL.md) | Understand and author `lambda-ber-schema` records: which class, which slot, which enum, which association table. Carries a generated reference of every class and enum. |
| [`lambda-validate`](skills/lambda-validate/SKILL.md) | Validate a schema record with `linkml-validate` or an RO-Crate with `lambda-ber-schema rocrate validate`, and explain the findings. |
| [`lambda-etl`](skills/lambda-etl/SKILL.md) | Import entries from PDB, SASBDB, Simple Scattering, EMSL, and SSRL MX into schema records with the `lambda-ber-schema etl` loaders, including bulk dumps. |
| [`lambda-rocrate`](skills/lambda-rocrate/SKILL.md) | Build or read a LAMBDA Core RO-Crate manifest: files with checksums, pointers to the fuller record, declared absence, sufficiency tiers. |

The skills hand off to each other: `lambda-etl` produces a record, `lambda-schema` shapes it,
`lambda-rocrate` packages it, `lambda-validate` checks it at every step.

## Installation

In Claude Code:

```text
/plugin marketplace add lambda-ber/lambda-toolkit
/plugin install lambda-toolkit@lambda-toolkit
```

Or copy any `skills/<name>/` directory into `~/.claude/skills/` (or a project's
`.claude/skills/`). Other agent frameworks that read `SKILL.md` files work the same way.

### The schema package

`lambda-ber-schema` is not on PyPI yet. Every skill starts with

```bash
eval "$(scripts/lambda_env.sh)"
```

which looks for a checkout (`$LAMBDA_BER_SCHEMA_DIR`, then `../lambda-ber-schema`, then
`~/lambda-ber-schema`), then for the CLI on `PATH`, and otherwise installs it from GitHub into
`~/.cache/lambda-toolkit/venv` with [uv](https://docs.astral.sh/uv/). It exports `LAMBDA_RUN`
(the command prefix for the CLI) and `LAMBDA_SCHEMA_DIR` (the checkout, if any). A checkout is
better than an install: the skills point at its examples, fixtures, and the profile text.

## Helper scripts

| script | purpose |
|---|---|
| `scripts/lambda_env.sh` | locate or install `lambda-ber-schema`; see above |
| `scripts/gen_schema_reference.py` | regenerate `skills/lambda-schema/references/schema-reference.md` from the schema YAML. Run it whenever the schema changes. |
| `skills/lambda-rocrate/scripts/crate_parts.py` | list a directory's files as RO-Crate `File` entities with size and sha256 |

## Layout

```
.claude-plugin/marketplace.json   plugin manifest
scripts/                          helpers shared across skills
skills/<name>/SKILL.md            one skill per directory
skills/<name>/references/         documents a skill loads on demand
skills/<name>/scripts/            code a skill runs
```

## Contributing a skill

Make a directory under `skills/` with a `SKILL.md` whose frontmatter has `name` and
`description`. The description is what decides whether an agent picks the skill up, so say
both what it does and when to reach for it. Keep the body under about 500 lines and push
long material into `references/`. Add the path to `.claude-plugin/marketplace.json`. Ground
every command in the real `lambda-ber-schema` CLI (`--help` is the source of truth) and every
schema claim in the generated reference.
