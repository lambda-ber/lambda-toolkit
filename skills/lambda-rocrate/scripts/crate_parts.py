#!/usr/bin/env python3
"""List the files under a crate directory as LAMBDA Core `File` entities.

    python crate_parts.py path/to/crate-dir [--exclude ro-crate-metadata.json] > parts.json

Prints a JSON array. Each item has @id (path relative to the crate root), @type "File",
name, contentSize (bytes, as a string, which is what schema.org wants), sha256, and an
encodingFormat guessed from the extension. Copy the items into @graph and add the @ids to
the root's hasPart. Fill in file_format, data_type, and processing_level yourself; those
are judgments this script does not make.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
from pathlib import Path

# Extensions the stdlib does not know, common in structural biology.
EXTRA_TYPES = {
    ".mtz": "application/x-mtz",
    ".cif": "chemical/x-cif",
    ".mmcif": "chemical/x-mmcif",
    ".pdb": "chemical/x-pdb",
    ".mrc": "application/x-mrc",
    ".mrcs": "application/x-mrc",
    ".map": "application/x-mrc",
    ".star": "text/x-star",
    ".dat": "text/plain",
    ".h5": "application/x-hdf5",
    ".hdf5": "application/x-hdf5",
    ".nxs": "application/x-hdf5",
    ".tif": "image/tiff",
    ".tiff": "image/tiff",
    ".yaml": "application/yaml",
    ".yml": "application/yaml",
}


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def encoding_format(path: Path) -> str:
    if path.suffix.lower() in EXTRA_TYPES:
        return EXTRA_TYPES[path.suffix.lower()]
    guess, _ = mimetypes.guess_type(path.name)
    return guess or "application/octet-stream"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("crate_dir", type=Path)
    ap.add_argument("--exclude", action="append", default=["ro-crate-metadata.json"],
                    help="relative paths to skip (repeatable)")
    args = ap.parse_args()
    root = args.crate_dir.resolve()
    items = []
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(root).as_posix()
        if rel in args.exclude or any(part.startswith(".") for part in p.relative_to(root).parts):
            continue
        items.append({
            "@id": rel,
            "@type": "File",
            "name": p.name,
            "encodingFormat": encoding_format(p),
            "contentSize": str(p.stat().st_size),
            "sha256": sha256_of(p),
        })
    print(json.dumps(items, indent=2))


if __name__ == "__main__":
    main()
