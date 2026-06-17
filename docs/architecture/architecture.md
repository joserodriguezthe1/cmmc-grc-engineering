# Reference Architecture

A minimal, Free-Tier-friendly AWS architecture that demonstrates the technical
CMMC Level 2 controls. The emphasis is on the **security and monitoring plane** —
the controls that earn CMMC practices — rather than a heavy application workload.

## Logical diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│ AWS Organization (SCPs enforce the CUI boundary)                           │
│                                                                            │
│  ┌────────────────────────────┐      ┌──────────────────────────────────┐ │
│  │  CUI / Workload Account     │      │  Log Archive Account             │ │
│  │                             │      │                                  │ │
│  │  VPC                        │      │  S3 (Object Lock, KMS)           │ │
│  │  ├─ public subnet  (ALB)    │      │   ▲  immutable audit logs        │ │
│  │  └─ private subnet (app)    │      │   │  (AU.L2-3.3.8)               │ │
│  │        │                    │      │   │                              │ │
│  │        ▼                    │      │   │                              │ │
│  │  S3 CUI bucket (KMS)        │      │   │                              │ │
│  │                             │      │   │                              │ │
│  │  Security plane:            │──────┼───┘                              │ │
│  │   • CloudTrail (org trail)  │      │                                  │ │
│  │   • AWS Config + rules      │      │                                  │ │
│  │   • GuardDuty (optional)    │      └──────────────────────────────────┘ │
│  │   • Security Hub (optional) │                                           │
│  │   • IAM + Access Analyzer   │      ┌──────────────────────────────────┐ │
│  │   • KMS CMKs                │─────►│  SNS  ──►  Email / ticketing      │ │
│  │   • VPC Flow Logs           │      │  (alerts: IR / SI / AU.3.3.4)    │ │
│  └────────────────────────────┘      └──────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

## Control-to-component mapping

| Component | CMMC practices served |
|-----------|----------------------|
| IAM password policy + MFA | IA.L2-3.5.3, 3.5.7, 3.5.8 |
| IAM least privilege + Access Analyzer | AC.L2-3.1.1, 3.1.2, 3.1.5 |
| CloudTrail (org trail) | AU.L2-3.3.1, 3.3.2 |
| CloudWatch Logs + Alarms + SNS | AU.L2-3.3.4, SI.L2-3.14.3 |
| S3 log archive w/ Object Lock | AU.L2-3.3.8 |
| AWS Config + conformance pack | CM.L2-3.4.1, 3.4.2, CA.L2-3.12.3 |
| KMS | SC.L2-3.13.10, 3.13.16, MP.L2-3.8.1 |
| S3 Block Public Access | AC.L2-3.1.22 |
| VPC subnets + Security Groups | SC.L2-3.13.1, 3.13.5, 3.13.6 |
| VPC Flow Logs | SI.L2-3.14.6 |
| GuardDuty (optional) | SI.L2-3.14.6, 3.14.7 |
| Security Hub (optional) | CA.L2-3.12.1, SI.L2-3.14.3 |

## Design principles

1. **Least privilege by default** — IAM permission boundaries; deny-by-default SGs.
2. **Immutable audit trail** — logs flow to a separate account/bucket with Object Lock.
3. **Everything encrypted** — KMS at rest, TLS in transit, no exceptions for CUI.
4. **Detect, don't just prevent** — Config + GuardDuty close the loop on drift.
5. **Cost-aware** — paid services are feature-flagged and off by default.

See [free-tier-cost-notes.md](free-tier-cost-notes.md) for the cost posture.
