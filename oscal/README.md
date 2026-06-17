# OSCAL — machine-readable compliance content

This folder is the **single source of truth** for the project's compliance
content, expressed in [OSCAL](https://pages.nist.gov/OSCAL/) (Open Security
Controls Assessment Language) 1.1.2 JSON. It replaces what used to be ~16
Markdown/CSV files (SSP, scope, control catalog, AWS mappings, 11 policies, POA&M).

## Files

| File | OSCAL model | Replaces | Contents |
|------|-------------|----------|----------|
| [catalogs/NIST_SP800-171_rev2_catalog.json](catalogs/NIST_SP800-171_rev2_catalog.json) | **Catalog** | — | Local Rev. 2 catalog (14 families, 110 controls) so ids resolve offline |
| [profile/cmmc-l2-profile.json](profile/cmmc-l2-profile.json) | **Profile** | the control list | Imports the local Rev. 2 catalog and selects all 110 controls (CMMC L2) |
| [component-definitions/aws-components.json](component-definitions/aws-components.json) | **Component Definition** | AWS service→control mapping | 6 AWS service components and the controls each satisfies |
| [component-definitions/policies.json](component-definitions/policies.json) | **Component Definition** | the 11 policy `.md` files | Each org policy as a `policy`-type component mapped to its practices |
| [ssp/cmmc-l2-ssp.json](ssp/cmmc-l2-ssp.json) | **System Security Plan** | `scope.md` + `system-security-plan.md` + control catalog | System characteristics, authorization boundary, and all 110 `implemented-requirements` with status/AWS/evidence props |
| [poam/cmmc-l2-poam.json](poam/cmmc-l2-poam.json) | **POA&M** | `poam.csv` | Open weaknesses tracked to closure |

## How the models reference each other

```
   NIST_SP800-171_rev2_catalog.json  (local, in this repo)
              ▲
              │ import
        cmmc-l2-profile.json  ──────────────┐
              ▲                              │ source
              │ import-profile              ▼
        cmmc-l2-ssp.json  ◄──── aws-components.json / policies.json
              ▲
              │ import-ssp
        cmmc-l2-poam.json
```

## Why a local catalog (Rev. 2 vs Rev. 3)

CMMC Level 2 is assessed against **NIST SP 800-171 Rev. 2** (110 controls).
NIST's official OSCAL content repo, however, publishes **only Rev. 3** — whose
controls are renumbered (`03.01.01`-style) and restructured, so it does **not**
resolve against our Rev. 2 ids (`3.1.1`).

To keep the profile/SSP resolvable and the repo fully **offline-validatable**, we
vendor a local Rev. 2 catalog at
[catalogs/NIST_SP800-171_rev2_catalog.json](catalogs/NIST_SP800-171_rev2_catalog.json).
Its control titles/statements are paraphrased **objective summaries** for
engineering traceability; the **normative** text is NIST SP 800-171 Rev. 2,
cited in the catalog's `back-matter` (DOI 10.6028/NIST.SP.800-171r2). The SSP's
`implemented-requirements` reference controls by Rev. 2 id and carry props for
the CMMC id (`AC.L2-3.1.1`), domain, implementation type, status, and evidence.

## Working with these files

```bash
# Validate every OSCAL doc against the official NIST OSCAL schema (CI gate)
python ../scripts/validate_oscal.py        # -> all 6 docs PASS

# Status roll-up + 110-practice integrity check (CI gate)
python ../scripts/status_report.py
python ../scripts/status_report.py --check
```

> `scripts/validate_oscal.py` validates structure (required fields, types,
> `additionalProperties`, enums) against the official NIST schema, **plus** UUID
> and ISO-8601 datetime formats via targeted regex. (The schema's XSD-style
> `\p{...}` patterns are stripped because Python's `re` can't compile them; the
> added format checks recover the important ones.) It's a pure-Python gate with
> no external tool dependency, so CI is reliable. For an additional authoritative
> pass you can optionally run the Java `oscal-cli` locally if you have it.

> Edit these as JSON, or with an OSCAL-aware tool such as
> [compliance-trestle](https://github.com/oscal-compass/compliance-trestle).
> The repo READMEs and `docs/architecture/` diagrams remain Markdown — those are
> navigation/explanation, not formal compliance artifacts.
