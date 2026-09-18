---
name: lambda-etl
description: >
  Pull structural biology entries from external archives into lambda-ber-schema format using
  the lambda-ber-schema CLI loaders: PDB (RCSB), SASBDB, Simple Scattering (SIBYLS SEC-SAXS),
  EMSL transactions, and SSRL macromolecular crystallography snapshots. Use this whenever the
  user asks to load, fetch, import, convert, or ingest an entry or a batch by accession
  (e.g. "1HHO", "SASDA52", an EMSL transaction id, a DCSS snapshot), wants a LAMBDA Dataset
  for a deposited structure, or asks what sources LAMBDA can import from. Also use for bulk
  dumps and for resuming or retrying a dump.
---

# LAMBDA ETL: archives to schema records

The schema package carries loaders that read an archive's public API and write a `Dataset`.
This skill runs them. It does not reimplement them; if a loader lacks a field the user
wants, say so and point at `src/lambda_ber_schema/loaders/<source>.py` in the checkout.

## Set up

```bash
eval "$(<toolkit>/scripts/lambda_env.sh)"
$LAMBDA_RUN lambda-ber-schema etl --help
```

`<toolkit>` is the directory holding this repository.

## Sources

| source | command | identifier | notes |
|---|---|---|---|
| PDB | `etl pdb --entry 1HHO` | 4-char PDB id | RCSB API; X-ray, EM, NMR |
| SASBDB | `etl sasbdb --entry SASDA52` | SASD... code | small-angle scattering deposits |
| Simple Scattering | `etl simplescattering --dataset xsbhevph` | dataset code | SIBYLS SEC-SAXS |
| EMSL | `etl emsl --sample <query> [--transaction-id <id>]` | free-text sample query | searches transactions, then loads one; `--token` (JWT) unlocks acquisition detail, `--extract-epu` pulls EPU session metadata |
| SSRL MX | `etl ssrl-mx --snapshot dcss.json [--metadata m.json] [--processing p.json]` | local files | DCSS snapshot plus sidecars |

Common flags on the single-entry commands: `--output PATH` (default stdout),
`--format yaml|json` (default yaml), `--cache/--no-cache` and `--cache-dir` (HTTP response
cache, off by default). Turn the cache on for anything you may run twice.

```bash
$LAMBDA_RUN lambda-ber-schema etl pdb --entry 1HHO --cache --output 1HHO.yaml
$LAMBDA_RUN lambda-ber-schema etl sasbdb --entry SASDA52 --format json
```

The loader prints warnings on stderr for fields it could not map. Relay those to the user;
they are the honest gaps in the record.

## Listing what an archive has

```bash
$LAMBDA_RUN lambda-ber-schema etl list pdb --method X-RAY --limit 20
$LAMBDA_RUN lambda-ber-schema etl list sasbdb --type protein --limit 20
$LAMBDA_RUN lambda-ber-schema etl list emsl --sample apo
$LAMBDA_RUN lambda-ber-schema etl list ssrl-mx --directory path/to/snapshots
```

## Bulk dumps

`etl dump-pdb`, `etl dump-sasbdb`, `etl dump-simplescattering`, `etl dump-ssrl-mx` write one
file per entry into `--output-dir`, keep a `progress.json`, and skip entries already done,
so rerunning the same command resumes. `--rate` sets requests per second, `--workers` the
parallelism, `--retry-failed` reruns the entries that errored, `--limit` caps a test run. PDB is around 248k entries; at the default 2 requests per second that is close to
two days. Say that before starting it, run it in the background, and keep the `.cache/`
directory, since the second pass over cached responses is fast.

If the checkout has a `justfile` with `pdb-dump-start`, `pdb-dump-status`, and friends,
those wrap the same commands with background and monitoring; prefer them inside a checkout.

## After loading

1. Open the output and read it against the source page. Loaders map what the API gives;
   check the protein rows carry `uniprot:` CURIEs, the technique enum is right, and the
   files listed are the ones the archive actually publishes.
2. Validate it with the `lambda-validate` skill. A loader bug shows up here first.
3. If the user wants a crate rather than a record, hand off to `lambda-rocrate`; the
   record becomes the crate's schema record (mechanism 2) and the archive URL its remote
   registration (mechanism 3).

## Failures

Exit 1 with `failed to fetch` is an HTTP problem (bad id, archive down, rate limit). Exit 2
with `not found or invalid` means the id parsed but the archive has no such entry. Check
the id's spelling and case against the archive site before retrying, and do not loop on a
404.
