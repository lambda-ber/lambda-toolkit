---
name: lambda-validate
description: >
  Validate LAMBDA structural biology data: a lambda-ber-schema Dataset in YAML or JSON, or an
  RO-Crate (ro-crate-metadata.json or crate directory) against the LAMBDA Core RO-Crate profile.
  Use this whenever the user asks to check, validate, lint, or verify a LAMBDA record or crate,
  asks why a record fails, wants a conformance report before publishing or depositing, or has
  just written or transformed LAMBDA data and needs it checked. Run it as the last step of any
  lambda-schema, lambda-etl, or lambda-rocrate task too.
---

# Validating LAMBDA data

Two kinds of thing get validated, and they take different tools. A plain schema record is a
LinkML instance and `linkml-validate` handles it. An RO-Crate is one JSON-LD document with a
flat graph, and `linkml-validate` cannot read it; the schema package ships its own checker.

## Set up

```bash
eval "$(<toolkit>/scripts/lambda_env.sh)"
```

`<toolkit>` is the directory holding this repository. The helper exports `$LAMBDA_RUN` (a
command prefix, possibly empty) and `$LAMBDA_SCHEMA_DIR` (a checkout path, or empty if the
package was installed from git). It clones and installs if nothing is found.

## Which one do I have?

- Contains `@context` and `@graph` at the top, or the file is named `ro-crate-metadata.json`,
  or the target is a directory holding one: it is a **crate**. Go to "Crate".
- Otherwise it is a **schema record** (a `Dataset`, or a single class instance such as a
  `Sample`). Go to "Record".

## Record

```bash
$LAMBDA_RUN linkml-validate \
  -s "$LAMBDA_SCHEMA_DIR/src/lambda_ber_schema/schema/lambda_ber_schema.yaml" \
  -C Dataset path/to/record.yaml
```

Change `-C` to the class name when the file is a single instance rather than a Dataset.
Without a checkout the schema YAML lives inside the installed package:

```bash
python -c 'import lambda_ber_schema, pathlib; print(pathlib.Path(lambda_ber_schema.__file__).parent / "schema/lambda_ber_schema.yaml")'
```

`linkml-validate` prints one line per problem with a JSON path. Common ones and what they
mean:

| message | cause |
|---|---|
| `'x' is not one of [...]` | enum value not in the permissible list; look it up in the lambda-schema reference |
| `'sample_code' is a required property` | missing required slot on that class |
| `Additional properties are not allowed ('foo' was unexpected)` | slot does not exist on that class; often it belongs on an association instead |
| `2e+12 is not of type 'integer'` | scientific notation in YAML; write the full number |

## Crate

```bash
$LAMBDA_RUN lambda-ber-schema rocrate validate path/to/ro-crate-metadata.json
$LAMBDA_RUN lambda-ber-schema rocrate validate path/to/crate-dir/
$LAMBDA_RUN lambda-ber-schema rocrate validate crate.json --json      # machine-readable
$LAMBDA_RUN lambda-ber-schema rocrate validate crate.json --layer graph
```

Exit code 0 means conformant, 1 means not, 2 means unreadable. Every finding is tagged with
its layer:

- `[document]`: the overall JSON shape (context, graph, descriptor).
- `[entity]`: a term or value a profile class does not allow. Profile classes are closed,
  so a stray property fails here.
- `[graph]`: a rule about relationships. Dangling `hasPart` or `hasBioChemEntityPart`
  targets, a dataset part with no metadata pointer, a `missing` entry with no `blocks`
  tier, `license` or `datePublished` absent and undeclared, a `ProteinEntity` without
  `uniprot_id`, files typed `DataFile` instead of `File`.

The full rule list is §12 of the profile. Read it when a `[graph]` finding is unclear:
`$LAMBDA_SCHEMA_DIR/profiles/core/0.3.2/lambda-core-rocrate-profile-v0.3.2.md`, or the
digest in the `lambda-rocrate` skill's `references/profile-digest.md`.

## Reporting back

Give the verdict first, then the findings grouped by layer, then the fix for each. Quote
the offending path or entity `@id`. When the fix is a judgment call (which enum term, which
`missing` reason), say what the options are and which one the source data supports. Do not
silently edit values to make validation pass; a record that validates but says something
untrue is worse than one that fails. Re-run after fixing and show the clean result.
