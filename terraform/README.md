# Terraform — CMMC L2 technical control baseline

Infrastructure-as-code that deploys the **automatable** CMMC Level 2 controls.

## Layout

```
terraform/
├── environments/
│   └── dev/              ← root module you run (init/plan/apply)
└── modules/
    ├── iam/              ← AC, IA  (password policy, MFA, Access Analyzer, boundaries)
    ├── storage/         ← SC, MP  (KMS CMK, encrypted CUI bucket, TLS-only, block public)
    ├── logging/         ← AU      (CloudTrail, immutable log archive, logging-failure alarm)
    ├── security/        ← SI, CA, RA (SNS alerts, budget, optional GuardDuty/SecHub/Config)
    └── networking/      ← SC      (VPC boundary, deny-by-default SG, flow logs, S3 endpoint)
```

## Usage

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars   # then edit alert_email
terraform init
terraform plan
terraform apply
```

## Staying in the Free Tier

The paid services (`enable_config`, `enable_guardduty`, `enable_security_hub`)
default to **false**. The billing budget/alarm defaults to **true**. There is
**no NAT Gateway** (the usual budget killer) — the private subnet reaches S3 via
a free Gateway VPC endpoint. See
[../docs/architecture/free-tier-cost-notes.md](../docs/architecture/free-tier-cost-notes.md).

## Practice coverage

Each module file header lists the exact CMMC practices it implements. The
authoritative status across all 110 practices is in the OSCAL SSP,
[../oscal/ssp/cmmc-l2-ssp.json](../oscal/ssp/cmmc-l2-ssp.json) (run
`python ../scripts/status_report.py` for a readable roll-up).

## Validate before applying

```bash
terraform fmt -recursive -check
terraform validate
tflint --recursive          # optional
checkov -d .                # optional policy-as-code scan
```
