#!/usr/bin/env python3
"""
Generate a CMMC L2 implementation status roll-up from the OSCAL SSP.

Reads oscal/ssp/cmmc-l2-ssp.json and prints implementation-status counts by
domain and overall. Use --check in CI to assert the SSP still covers all 110
practices across the 14 domains (change control on the control set itself).

Usage:
    python scripts/status_report.py            # print the report
    python scripts/status_report.py --check     # exit non-zero if != 110 reqs
"""
import argparse
import collections
import json
import os
import sys

SSP_PATH = os.path.join(
    os.path.dirname(__file__), "..", "oscal", "ssp", "cmmc-l2-ssp.json"
)
EXPECTED_PRACTICES = 110

EXPECTED_BY_DOMAIN = {
    "AC": 22, "AT": 3, "AU": 9, "CM": 9, "IA": 11, "IR": 3, "MA": 6,
    "MP": 9, "PS": 2, "PE": 6, "RA": 3, "CA": 4, "SC": 16, "SI": 7,
}

FAMILY_DOMAIN = {
    "3.1": "AC", "3.2": "AT", "3.3": "AU", "3.4": "CM", "3.5": "IA",
    "3.6": "IR", "3.7": "MA", "3.8": "MP", "3.9": "PS", "3.10": "PE",
    "3.11": "RA", "3.12": "CA", "3.13": "SC", "3.14": "SI",
}


def domain_of(control_id):
    parts = control_id.split(".")
    return FAMILY_DOMAIN[f"{parts[0]}.{parts[1]}"]


def prop(req, name, default=""):
    for p in req.get("props", []):
        if p.get("name") == name:
            return p.get("value", default)
    return default


def load_requirements():
    with open(SSP_PATH, encoding="utf-8") as f:
        ssp = json.load(f)
    return ssp["system-security-plan"]["control-implementation"]["implemented-requirements"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="CI mode: assert SSP integrity, exit non-zero on failure")
    args = parser.parse_args()

    reqs = load_requirements()
    total = len(reqs)
    by_status = collections.Counter(prop(r, "implementation-status", "unknown") for r in reqs)
    by_domain = collections.Counter(domain_of(r["control-id"]) for r in reqs)

    print(f"CMMC Level 2 — OSCAL SSP status ({total} practices)\n")
    print("By implementation-status:")
    for status, n in sorted(by_status.items()):
        print(f"  {status:<16} {n}")

    print("\nBy domain:")
    problems = []
    for domain, expected in EXPECTED_BY_DOMAIN.items():
        actual = by_domain.get(domain, 0)
        flag = "" if actual == expected else f"  <-- expected {expected}"
        print(f"  {domain:<4} {actual}{flag}")
        if actual != expected:
            problems.append((domain, expected, actual))

    if args.check:
        ok = True
        if total != EXPECTED_PRACTICES:
            print(f"\nFAIL: expected {EXPECTED_PRACTICES} implemented-requirements, found {total}")
            ok = False
        if problems:
            print(f"\nFAIL: {len(problems)} domain(s) have wrong practice counts")
            ok = False
        if not ok:
            sys.exit(1)
        print("\nOK: SSP integrity verified (110 practices, all 14 domains correct)")


if __name__ == "__main__":
    main()
