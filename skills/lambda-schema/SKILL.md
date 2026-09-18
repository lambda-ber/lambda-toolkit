---
name: lambda-schema
description: >
  Understand, author, and edit LAMBDA structural biology records (lambda-ber-schema, LinkML).
  Use this whenever the user is writing or reading a LAMBDA Dataset in YAML or JSON, asks what
  class or slot to use for a sample, protein, nucleic acid, instrument, experiment run, workflow
  run, or data file, needs the right enum value (technique, sample_type, file_format, etc.),
  wants to link entities through association tables, or mentions cryo-EM, X-ray crystallography,
  SAXS, SANS, SSRL, SIBYLS, ALS, EMSL, PDB, SASBDB, or UniProt data in a LAMBDA or BER context.
  Also use it before any other lambda-* skill touches a record, so the record is shaped right.
---

# LAMBDA schema: reading and writing records

`lambda-ber-schema` is one LinkML schema for structural biology data across techniques:
cryo-EM, X-ray crystallography, SAXS/WAXS, SANS, cryo-ET. A record is a `Dataset`. The
Dataset holds flat lists of entities and flat lists of associations that join them. Think of
it as a small relational database serialized to YAML: tables, not a tree.

## Set up

```bash
eval "$(<toolkit>/scripts/lambda_env.sh)"   # finds or installs lambda-ber-schema
echo "$LAMBDA_SCHEMA_DIR"                   # checkout path, empty if installed from git
```

`<toolkit>` is the directory holding this repository. `$LAMBDA_RUN` is the prefix that runs
the CLI (`uv run --directory ...` for a checkout, empty when installed on PATH).

## Where the truth lives

Read these in this order, and only as far as the task needs:

1. `references/schema-reference.md` in this skill. Generated from the schema. Every class,
   every slot, required slots starred, every enum with its values. Has a table of contents;
   jump to the class you need rather than reading it top to bottom.
2. `$LAMBDA_SCHEMA_DIR/src/lambda_ber_schema/schema/lambda_ber_schema.yaml` for slot
   descriptions, examples, and comments the reference trims.
3. `$LAMBDA_SCHEMA_DIR/examples/Dataset-*.yaml` for shapes that already validate. Copy a
   nearby example before writing from scratch. `Dataset-berkeley-tfiid.yaml` and
   `Dataset-integrative.yaml` are the fullest; `Dataset-hemoglobin-protein-entities.yaml`
   and `Dataset-cas9-nucleic-acid-entities.yaml` show the protein and nucleic acid patterns.
4. Online docs: https://lambda-ber.github.io/lambda-ber-schema/

If the reference looks stale next to the YAML, regenerate it:
`python <toolkit>/scripts/gen_schema_reference.py`.

## The shape of a record

```yaml
id: lambda:dataset-example
title: ...
proteins:            [ {id: uniprot:P69905, protein_name: ...} ]
nucleic_acids:       [ {id: ..., nucleic_acid_type: dna} ]
samples:             [ {id: ..., sample_code: ..., sample_type: ...} ]
sample_preparations: [ {id: ..., preparation_type: ..., sample_id: ...} ]
instruments:         [ {id: ..., instrument_code: ...} ]
experiment_runs:     [ {id: ..., experiment_code: ..., technique: saxs} ]
workflow_runs:       [ {id: ..., workflow_code: ..., workflow_type: ..., software_name: ...} ]
data_files:          [ {id: ..., file_name: ..., file_format: ...} ]
sample_protein_associations:        [ {sample_id: ..., protein_id: uniprot:P69905, role: ...} ]
experiment_sample_associations:     [ {experiment_id: ..., sample_id: ...} ]
experiment_instrument_associations: [ {experiment_id: ..., instrument_id: ...} ]
workflow_input_associations:        [ {workflow_id: ..., data_file_id: ...} ]
```

Entities never point at each other with foreign keys. The joins live in the association
lists, and an association can carry facts about the relationship itself (role, copy number,
residue range). Ask "is this a fact about the protein, or about this sample's use of the
protein?" and put it on the entity or the association accordingly.

## Rules that bite

These come from the schema repo's own guidance and from what fails validation in practice.

- **Required slots.** Protein `id`. NucleicAcid `id`, `nucleic_acid_type`. Sample
  `sample_code`, `sample_type`. SamplePreparation `preparation_type`, `sample_id`.
  Instrument `instrument_code`. ExperimentRun `experiment_code`, `technique`. WorkflowRun
  `workflow_code`, `workflow_type`, `software_name`. DataFile `file_name`, `file_format`.
  Image `file_name`. Check the reference for the rest.
- **UniProt as CURIE.** `Protein.id` and `uniprot_id` are `uniprot:P69905`, never bare
  `P69905`. One Protein row per protein, shared by every sample that contains it.
- **Nucleic acids.** Registry CURIE where one exists (`rnacentral:URS...`, RefSeq, INSDC),
  else a `lambda:` or `pdb:` id, since most strands are synthetic oligos. Two different
  strands in a duplex are two rows. A self-complementary duplex is one row with
  `copy_number: 2` on the association. Pairing (`structural_form`), synthesis
  (`source_method`), and labels or backbone chemistry (`modifications`) belong on
  `SampleNucleicAcidAssociation`, not on `NucleicAcid`.
- **ProteinConstruct.** Set `protein_id` when the Dataset carries the Protein row. Use
  `uniprot_id` alone only when it does not. Where both appear they must agree.
- **Dates are strings.** No strict datetime typing anywhere; write ISO 8601 text.
- **No scientific notation in YAML.** `2.0e12` breaks JSON Schema generation. Write
  `2000000000000`.
- **Enums are closed.** `technique` is one of `cryo_em`, `xray_crystallography`, `saxs`,
  `waxs`, `sans`, `cryo_et`, and so on. Look up the enum in the reference before guessing.
  If a real value has no term, do not coerce it to the nearest neighbour. Say so to the
  user and suggest a schema change request (the RO-Crate profile has `vocabEntry` for this).
- **Ids are CURIEs or IRIs.** Local ids use a `lambda:` prefix or a source prefix
  (`pdb:1HHO`, `sasbdb:SASDA52`, `emsl:...`).

## Workflow for authoring a record

1. Identify the technique and the source. That picks the example to copy and the
   Instrument subclass (`CryoEMInstrument`, `XRayInstrument`, `SAXSInstrument`,
   `BeamlineInstrument`).
2. List the entities: which proteins, strands, samples, runs, files. Give each an id.
3. Write entity rows with the required slots first, then whatever the source actually
   states. Do not invent values to fill slots. Leave a slot out rather than guess.
4. Write the associations that join them. Every sample in an experiment gets an
   `ExperimentSampleAssociation`; every protein in a sample gets a
   `SampleProteinAssociation`.
5. Validate with the `lambda-validate` skill. Fix what it reports. Do not hand back an
   unvalidated record.

## Answering questions about the schema

When asked "where does X go" or "what is the slot for Y", find the class in the reference,
quote the slot name, its range, and whether it is required, and say which entity or
association it belongs on and why. If two placements are plausible, give both with the
distinction. Cite the class and slot names exactly as the schema spells them.
