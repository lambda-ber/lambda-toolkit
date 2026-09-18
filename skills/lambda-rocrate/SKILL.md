---
name: lambda-rocrate
description: >
  Build, inspect, or repair a LAMBDA Core RO-Crate: the ro-crate-metadata.json manifest that
  packages a structural biology dataset for federated search and handoff. Use this whenever the
  user mentions an RO-Crate, ro-crate-metadata.json, a data package or manifest for LAMBDA or
  BER structural biology data, wants to package files from a beamline or archive (ALS, SSRL,
  SIBYLS, EMSL, SASBDB, PDB) with checksums, asks what to put in a crate, needs to declare
  missing fields or sufficiency tiers, or wants to turn a lambda-ber-schema record into a
  publishable package. Validation of an existing crate is the lambda-validate skill; this one
  is for authoring and reading.
---

# LAMBDA Core RO-Crate: authoring a manifest

A crate is a search row plus a file list plus pointers to the fuller record. Keep that in
mind and most decisions make themselves: if a value helps someone decide whether to open the
dataset, it goes in the crate; if it only matters after that decision, it goes in the linked
schema record.

## Set up

```bash
eval "$(<toolkit>/scripts/lambda_env.sh)"
```

`<toolkit>` is the directory holding this repository. Then read
`references/profile-digest.md` in this skill. It is short. The full normative text is
`$LAMBDA_SCHEMA_DIR/profiles/core/0.3.2/lambda-core-rocrate-profile-v0.3.2.md`; open it
for §7 (pointers), §8 (absence), or §12 (rules) when the digest is not enough. Worked
crates that validate live in `$LAMBDA_SCHEMA_DIR/tests/data/rocrate/valid/`.

## Building a crate from a directory of files

1. **Start from the template.** Copy `references/minimal-crate.json` (the smallest
   conformant crate) into the target directory as `ro-crate-metadata.json`. Do not write
   the context or descriptor from memory.
2. **Fill the root.** `name`, `description`, `facility_name`, `technique` (a schema enum
   value), `instrumentName`, `sample_code`. `datePublished` and `license` if known;
   otherwise a `missing` entry for each, with a reason and `blocks`. Where the date is a
   deposition date rather than a publication, use `dateCreated` and declare
   `datePublished` absent.
3. **List the files.** Run the bundled script rather than hashing by hand:
   ```bash
   python <toolkit>/skills/lambda-rocrate/scripts/crate_parts.py path/to/crate-dir > parts.json
   ```
   It emits `File` entities with `contentSize` and `sha256`. Add them to `@graph` and their
   `@id`s to the root's `hasPart`. Then add `file_format`, `data_type`, and
   `processing_level` to each, since those are judgments about what the file is, and mark
   the ones a reader should open first with `isDesignated: true`.
4. **Point at the fuller record.** If a `lambda-ber-schema` record exists (or you make one
   with the `lambda-etl` or `lambda-schema` skill), put it in the crate as a `File`, and
   add a `Dataset` part with `schemaRecord` and `schemaVersion` pointing at it. For data
   held in a public archive, add a `Dataset` part with `identifier` and `url` (mechanism
   3) and declare `sha256` missing if the archive publishes none.
5. **Add specimen and molecules.** A `SampleEntity` for the thing in the tube; a
   `ProteinEntity` per protein with UniProt IRI as `@id` and `uniprot_id` as CURIE; a
   `NucleicAcidEntity` per strand. Link them from the sample with `hasBioChemEntityPart`.
   One protein entity serves every sample that contains it.
6. **Declare what is not there.** Raw frames not deposited, proposal id unreachable, no
   licence on the archive page. Each is a `missing` entry. Set `sufficiency` honestly;
   `s2AcquisitionComplete: false` with a declared reason is the normal state for a public
   deposit.
7. **Validate** with the `lambda-validate` skill (`lambda-ber-schema rocrate validate`).
   Fix the findings and re-run until exit 0.

## Reading a crate for someone

Report in this order: what body of data it is (root `name`, facility, technique, specimen),
which tiers it claims, what files it holds and which are designated, where the fuller record
lives (which pointer mechanism), and what it declares missing. Then say whether it validates.
Point out silent gaps (a root with no `license` and no `missing` for it) as findings, not as
things to quietly patch.

## Things to not do

- Do not invent a checksum, a size, or a licence. Compute or declare missing.
- Do not use `DataFile` as an RO-Crate type. It is not in the context. Use `File`.
- Do not put technique numbers (Rg, resolution, dose) as bare root properties. They nest
  inside `resultSummary`, and the technique extension gives them shape.
- Do not restate the schema record's contents in the crate. Point at it.
- Do not coerce a value to the nearest enum term. Use `vocabEntry` and tell the user.
