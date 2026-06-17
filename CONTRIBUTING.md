# Contributing

This project treats compliance as code, so contributions follow an
engineering workflow with the same gates an auditor would expect.

## Workflow

1. Branch from `main`.
2. Make your change. If it touches a control's intent, status, or evidence,
   **update the OSCAL** in `oscal/` — that is the source of truth, not Markdown.
3. Run the local gates:
   ```bash
   make validate     # terraform fmt+validate, OSCAL schema, SSP completeness
   make scan         # checkov IaC scan (triage new findings in .checkov.yaml)
   ```
4. Open a PR using the template (it includes a CMMC impact analysis — CM.L2-3.4.4).
5. CI must be green; CODEOWNERS review is required (CM.L2-3.4.5).

## Conventions

- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `deps:`).
- **Terraform:** `terraform fmt`; keep paid services behind feature flags
  (default off) so the repo stays Free-Tier safe.
- **OSCAL:** must pass `python scripts/validate_oscal.py` (official NIST schema)
  and keep all 110 practices / 14 domains intact (`status_report.py --check`).
- **Evidence:** never commit real evidence, account IDs, or ARNs.

## Local setup

```bash
python -m pip install -r requirements-dev.txt
pre-commit install   # optional: run the gates automatically on commit
```
