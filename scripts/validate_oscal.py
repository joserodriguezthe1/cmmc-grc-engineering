#!/usr/bin/env python3
"""
Validate every OSCAL file in oscal/ against the official NIST OSCAL JSON schema.

Downloads (and caches) the complete OSCAL schema from the usnistgov/OSCAL release
assets, then validates catalog/profile/component-definition/ssp/poam documents.

Usage:
    python scripts/validate_oscal.py
Exit code is non-zero if any document fails — suitable as a CI gate.
"""
import glob
import json
import os
import sys
import urllib.request

SCHEMA_URL = (
    "https://github.com/usnistgov/OSCAL/releases/download/v1.2.2/"
    "oscal_complete_schema.json"
)
CACHE = os.path.join(os.path.dirname(__file__), ".oscal_complete_schema.json")
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def load_schema():
    if not os.path.exists(CACHE):
        print(f"Downloading OSCAL schema -> {CACHE}")
        urllib.request.urlretrieve(SCHEMA_URL, CACHE)
    schema = json.load(open(CACHE, encoding="utf-8"))
    # Two pre-processing fixes for Python's jsonschema:
    #  1. Drop fragment-style "$id" values so "#/definitions/..." $refs resolve
    #     against the root document.
    #  2. Drop "pattern" constraints — OSCAL uses XSD-style \p{...} Unicode
    #     property escapes that Python's `re` cannot compile. This preserves
    #     structural validation (required, types, additionalProperties, enums,
    #     oneOf) while skipping regex string checks (UUID/date formatting).
    #     For authoritative regex/format validation, use oscal-cli (see CI).
    def clean(o):
        if isinstance(o, dict):
            o.pop("$id", None)
            o.pop("pattern", None)
            for v in o.values():
                clean(v)
        elif isinstance(o, list):
            for v in o:
                clean(v)
    clean(schema)
    return schema


def main():
    try:
        from jsonschema import Draft202012Validator
    except ImportError:
        sys.exit("pip install jsonschema")

    validator = Draft202012Validator(load_schema())
    failures = 0
    for f in sorted(glob.glob(os.path.join(ROOT, "oscal", "**", "*.json"), recursive=True)):
        rel = os.path.relpath(f, ROOT)
        doc = json.load(open(f, encoding="utf-8"))
        errors = sorted(validator.iter_errors(doc), key=lambda e: list(e.path))
        if errors:
            failures += 1
            print(f"[FAIL] {rel}  ({len(errors)} error(s))")
            for e in errors[:8]:
                loc = "/".join(str(p) for p in e.path) or "<root>"
                print(f"   - {loc}: {e.message[:160]}")
        else:
            print(f"[OK]   {rel}")
    print("\nRESULT:", "PASS" if not failures else f"{failures} file(s) FAILED")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
