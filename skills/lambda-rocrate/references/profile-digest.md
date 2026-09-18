# LAMBDA Core RO-Crate profile 0.3.2, digest

Condensed from `profiles/core/0.3.2/lambda-core-rocrate-profile-v0.3.2.md` in lambda-ber-schema.
Read the full profile for anything this leaves out; section numbers below refer to it.
Profile URI: `https://w3id.org/lambda/profile/core/0.3.2`.

## What a crate is for (§1, §2)

A crate is a **manifest**: the smallest record a program needs to decide whether a dataset is
worth opening, plus pointers to the fuller record. It is not a second copy of the schema
record. If a crate restates buffer conditions or per-frame parameters it is doing the
schema's job badly. One crate, one coherent body of data; a federated search returns one row
per crate.

## Required entities (§6.1, §6.4)

| entity | `@type` | must carry |
|---|---|---|
| descriptor | `CreativeWork`, `@id` exactly `ro-crate-metadata.json` | `conformsTo` RO-Crate 1.2, `about` → `./` |
| root | `["Dataset", "lambda:Dataset"]`, `@id` `./` | `name`, `description`, `conformsTo` (both RO-Crate 1.2 and the profile URI), `hasPart`; `datePublished` and `license` or a `missing` entry for each |
| file | `File` (never `DataFile`) | `name`, `encodingFormat`, `contentSize`, `sha256` |
| dataset part | `Dataset` | at least one metadata pointer (§7) or a `missing` entry saying why none |

Context: `["https://w3id.org/ro/crate/1.2/context", {"lambda": "http://w3id.org/lambda/", "lambdarc": "http://w3id.org/lambda/rocrate/"}]`.

Casing tells the layer: terms that project onto a schema slot keep snake_case
(`sample_code`, `technique`, `facility_name`, `file_format`, `data_type`); profile-local and
schema.org terms are camelCase (`instrumentName`, `packageTier`, `datePublished`,
`encodingFormat`, `contentSize`).

## Optional contextual entities (§6.2)

`Person`, `Organization`, `SampleEntity` (`["BioChemEntity", "lambda:Sample"]`),
`ProteinEntity` (`["Protein", "lambda:Protein"]`), `NucleicAcidEntity`
(`["BioChemEntity", "lambda:NucleicAcid"]`), `InstrumentEntity`, `ExperimentRunAction`,
`WorkflowRunAction` (`CreateAction`), `SoftwareApplication`, `DefinedTerm`, `PropertyValue`.

Sample and protein are separate entities. The sample lists its proteins and strands under
`hasBioChemEntityPart`. A protein's `@id` should be its UniProt IRI
(`http://purl.uniprot.org/uniprot/P69905`) and it carries `uniprot_id: uniprot:P69905`; if
there is no accession, declare `uniprot_id` in `missing`. A nucleic acid carries at least one
of `rnacentral_id`, `sequence_accession`, `nucleotide_sequence`, or declares one missing.
Facility and technique are better as `DefinedTerm` entities than bare strings.

## Metadata pointers for dataset parts (§7)

A `Dataset` part must resolve at least one:

1. **Nested crate**: `conformsTo` a LAMBDA profile plus a `hasPart` ending in
   `ro-crate-metadata.json`, or an absolute `@id` to a remote crate.
2. **Schema record**: `schemaRecord: {"@id": "path/record.yaml"}` plus `schemaVersion`. The
   referenced file is itself a `File` entity with a checksum.
3. **Remote registration**: `identifier: [{"@type": "PropertyValue", "propertyID": "SASBDB", "value": "SASDD42"}]` and `url`, plus a `missing` for `sha256` if the archive publishes none.

Or declare `missing: [{"field": "schemaRecord", "reason": "not-applicable", "note": "..."}]`
when another entity in the same crate describes it.

## Declared absence (§8)

```json
"missing": [{"field": "raw_frame_series", "reason": "not-deposited", "blocks": "S2-acquisition", "note": "..."}]
```

Reasons: `not-registered` (no upstream system ever held it), `not-available` (exists, this
build could not reach it), `not-deposited` (archive did not include it), `embargoed`,
`not-applicable` (nothing is missing). `blocks` is required except for `not-applicable`. A
field is never both present and declared missing. Never invent a stand-in for an absent
artefact.

`vocabEntry` is the opposite case: a real value with no enum term.
`{"module": "lambda-ber-schema", "enum": "BeamlineEnum", "key": "DORIS3_X33", "note": "..."}`.

## Sufficiency tiers (§3)

- **S1 findable**: identity, facility, technique, instrument, specimen, dates, access resolve.
- **S2-core retrievable**: every present file has locator, size, valid sha256; every dataset
  part has a pointer. Required for conformance.
- **S2-acquisition**: raw acquisition present and verifiable. Optional, absence declared.
- **S3 interpretable**: derived numbers name their estimator (mostly technique extensions).

Root should carry `sufficiency: {s1Findable, s2CoreComplete, s2AcquisitionComplete, s3Interpretable}`.
Most public deposits are S2-core without S2-acquisition. That is honest, not a failure.

## Graph rules the validator enforces (§12)

1. descriptor exists, `about` resolves; 2. root typed `lambda:Dataset`; 3. every `hasPart`
and `hasBioChemEntityPart` target exists in the graph; 4. every dataset part has a pointer or
a declared reason; 5. every `missing` has `blocks` unless `not-applicable`; 6. no field both
present and missing; 7. root `conformsTo` names RO-Crate and the profile; 8. files typed
`File`; 9. `license` and `datePublished` present or declared missing; 10. `ProteinEntity`
has `uniprot_id` or declares it; 11. `NucleicAcidEntity` has an identity field or declares it.

Entity classes are closed. An undeclared property fails at the `[entity]` layer. Technique
quantities go inside `resultSummary`, not as bare properties on the root.
