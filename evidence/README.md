# Evidence

Automated, repeatable collection of audit evidence — "evidence as code."

## Layout

```
evidence/
├── automation/
│   ├── collect_evidence.py   ← read-only AWS snapshot → JSON artifact
│   └── requirements.txt
└── collected/                ← timestamped evidence packages (gitignored)
```

## Why automate evidence

Assessors want proof that controls are *operating*, not just *designed*. Manual
screenshots rot. This collector produces timestamped, machine-readable snapshots
of the live control state (password policy, MFA coverage, CloudTrail config, S3
encryption/public-access, Config compliance, GuardDuty) on demand or on a schedule.

## Usage

```bash
pip install -r automation/requirements.txt
python automation/collect_evidence.py --region us-east-1
```

Output lands in `collected/evidence-<timestamp>.json`.

## Scheduling (optional)

Run monthly via cron / EventBridge + Lambda to build a continuous evidence trail
(CA.L2-3.12.1). Keep the artifacts in a separate, access-controlled store for the
real environment — **`collected/` is gitignored** because evidence contains
account IDs and ARNs.

## Mapping evidence to controls

The keys in each JSON package map to practices as follows:

| Evidence key | CMMC practice(s) |
|--------------|------------------|
| `iam_password_policy` | IA.L2-3.5.7 / 3.5.8 |
| `iam_mfa` | IA.L2-3.5.3 |
| `cloudtrail` | AU.L2-3.3.1 / 3.3.2 / 3.3.8 |
| `s3_public_access_and_encryption` | AC.L2-3.1.22 / SC.L2-3.13.16 |
| `aws_config_compliance` | CA.L2-3.12.3 |
| `guardduty` | SI.L2-3.14.6 / 3.14.7 |
