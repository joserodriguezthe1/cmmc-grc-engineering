# Security Policy

This is a **reference / portfolio** project. It does not host production CUI and
is not a certified system. Still, security hygiene applies.

## Reporting a vulnerability

If you find a security issue in this repository (e.g. a Terraform misconfiguration
that would weaken a control, or an exposed secret), please open a **private**
report via GitHub Security Advisories, or email the maintainer. Please do not
open a public issue for anything exploitable.

## Scope & expectations

- **No secrets in git.** Credentials, account IDs, and real evidence are
  `.gitignore`d. If you find any committed, report it.
- **IaC findings** are triaged in [.checkov.yaml](.checkov.yaml) with written
  justifications. New findings should be triaged the same way, not silenced.
- **Least privilege.** Examples use scoped IAM; tighten before any real use.

## Not in scope

- This project does not constitute, imply, or guarantee CMMC certification.
  Certification requires assessment by a C3PAO.
