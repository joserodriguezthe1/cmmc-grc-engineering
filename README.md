# CMMC GRC Engineering Project

<!-- After pushing to GitHub, replace OWNER/REPO so these badges render live. -->
[![compliance-ci](https://github.com/OWNER/REPO/actions/workflows/compliance-ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/compliance-ci.yml)
![CMMC](https://img.shields.io/badge/CMMC-Level%202-blue)
![NIST 800-171](https://img.shields.io/badge/NIST%20SP%20800--171-Rev.%202-blue)
![OSCAL](https://img.shields.io/badge/OSCAL-1.1.2%20schema--valid-success)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC)
![AWS Free Tier](https://img.shields.io/badge/AWS-Free%20Tier-orange)
![License](https://img.shields.io/badge/license-MIT-green)

A **GRC-as-code** project that implements, enforces, and continuously monitors
**CMMC Level 2** (110 practices, aligned to NIST SP 800-171 Rev. 2) on **AWS**,
designed to stay within the **AWS Free Tier** wherever technically possible.

> **What this demonstrates (for reviewers):** the full GRC-engineering loop —
> control intent as **schema-valid OSCAL** → enforcement as **Terraform** →
> detection as **AWS Config** → **automated evidence** → gaps tracked in a
> **POA&M** → every change **gated in CI**. All 110 practices are version-
> controlled data, not prose. See [oscal/](oscal/).

This is not a documentation-only compliance binder. It treats compliance as an
engineering discipline:

- **Controls as data** — all compliance content lives as machine-readable **OSCAL** (NIST's standard) under `oscal/`.
- **Infrastructure as code** — security controls are deployed with Terraform.
- **Policy as code** — drift and misconfiguration are detected with AWS Config Conformance Packs.
- **Evidence as code** — audit artifacts are collected automatically by scripts/Lambda.
- **Validated in CI** — every change is linted, scanned, and policy-checked before merge.

---

## What is CMMC?

The **Cybersecurity Maturity Model Certification (CMMC) 2.0** is the U.S. Department
of Defense framework that contractors must meet to handle Federal Contract
Information (FCI) and Controlled Unclassified Information (CUI).

| Level | Data | Practices | Basis |
|-------|------|-----------|-------|
| Level 1 | FCI | 17 | FAR 52.204-21 |
| **Level 2** (this project) | CUI | **110** | NIST SP 800-171 Rev. 2 |
| Level 3 | CUI (advanced) | 110 + subset of 800-172 | NIST SP 800-172 |

This project targets **Level 2**.

---

## Repository layout

```
CMMC Project/
├── README.md                  ← you are here
├── oscal/                     ← compliance content as OSCAL JSON (source of truth)
│   ├── catalogs/              ← local NIST 800-171 Rev. 2 catalog (offline-resolvable)
│   ├── profile/               ← CMMC L2 profile (imports the local catalog)
│   ├── component-definitions/ ← AWS service components + policy components
│   ├── ssp/                   ← System Security Plan (all 110 implemented-requirements)
│   └── poam/                  ← Plan of Action & Milestones
├── docs/
│   └── architecture/          ← reference architecture, diagrams, cost notes (Markdown)
├── terraform/                 ← Infrastructure as code (technical controls)
│   ├── modules/
│   └── environments/
├── policy-as-code/            ← AWS Config Conformance Packs / OPA
├── evidence/                  ← automated evidence collection
│   ├── automation/
│   └── collected/
├── pipelines/                 ← CI/CD (GitHub Actions)
└── scripts/                   ← helper scripts (bootstrap, status report, etc.)
```

---

## How the layers map to CMMC

| Layer | Folder | CMMC domains primarily served |
|-------|--------|-------------------------------|
| Compliance content (OSCAL: SSP, profile, policies, POA&M) | `oscal/` | all 14 domains |
| Identity & access (Terraform) | `terraform/modules/iam` | AC, IA |
| Logging & audit (Terraform) | `terraform/modules/logging` | AU |
| Detection (Terraform) | `terraform/modules/security` | SI, CA |
| Data protection (Terraform) | `terraform/modules/storage` | SC, MP |
| Continuous monitoring | `policy-as-code/` | CA, CM |
| Evidence | `evidence/` | CA, AU |

---

## Quick start

> **Prerequisites:** an AWS account, AWS CLI v2 configured, Terraform >= 1.6, and
> (optionally) `git`, `python3`, and `tflint`/`checkov` for the CI checks.

```bash
# 1. Review and bootstrap the Terraform state backend (one-time)
bash scripts/bootstrap-backend.sh

# 2. Initialize and review the plan
cd terraform/environments/dev
terraform init
terraform plan

# 3. Apply the baseline security controls
terraform apply

# 4. Deploy the continuous-monitoring conformance pack
bash policy-as-code/deploy-conformance-pack.sh

# 5. Collect a round of evidence
python evidence/automation/collect_evidence.py
```

---

## AWS Free Tier posture

This project is deliberately built to demonstrate CMMC controls **without a large
bill**. See [docs/architecture/free-tier-cost-notes.md](docs/architecture/free-tier-cost-notes.md)
for the per-service breakdown. In short:

- **Always free / negligible:** IAM, S3 (5 GB), CloudWatch Logs (5 GB), CloudTrail (1 trail), SNS, Lambda (1M req).
- **Free trial then paid — deploy with eyes open:** GuardDuty (30 days), Security Hub (30 days), AWS Config (charges per config item recorded).
- Cost-sensitive resources are **feature-flagged** in Terraform (`enable_guardduty`, `enable_config`, etc.) and default to a Free-Tier-safe setting.

> ⚠️ This is a learning/reference project. Nothing here makes you "CMMC certified."
> Certification requires a C3PAO assessment. This gives you the engineering
> backbone and evidence to get there.

---

## Status

The live implementation status of all 110 practices lives in the OSCAL SSP,
[oscal/ssp/cmmc-l2-ssp.json](oscal/ssp/cmmc-l2-ssp.json). For a human-readable
roll-up by domain and status:

```bash
python scripts/status_report.py
```

See [oscal/README.md](oscal/README.md) for how the OSCAL models fit together.
