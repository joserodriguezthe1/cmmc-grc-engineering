# AWS Free Tier Cost Notes

This project is engineered to demonstrate CMMC Level 2 controls while staying at
or near **$0/month**. AWS Free Tier has three flavors: **Always Free**,
**12-months Free** (from account creation), and **Free Trials**. Know which is which.

## Service-by-service posture

| Service | Tier | Notes / cost risk |
|---------|------|-------------------|
| **IAM** | Always Free | No charge. Core of AC/IA controls. |
| **S3** | 12-mo Free (5 GB std) | Log/CUI buckets are tiny. Object Lock is free; you pay only for storage. |
| **CloudTrail** | Always Free (1 trail, mgmt events) | First copy of management events is free. Data events & extra trails cost. |
| **CloudWatch Logs** | Always Free (5 GB ingest) | Keep retention low; set a retention policy to avoid creep. |
| **CloudWatch Alarms** | 10 alarms free | Used for AU.3.3.4 logging-failure alerts. |
| **SNS** | Always Free (1M publishes) | Alert fan-out. Negligible. |
| **Lambda** | Always Free (1M req/mo) | Evidence collection / auto-remediation. |
| **KMS** | 20k req/mo free | **$1/month per customer-managed key.** Use 1–2 CMKs, or AWS-managed keys to stay free. |
| **VPC / Security Groups / NACLs** | Always Free | No charge for the constructs themselves. |
| **VPC Flow Logs** | Pay for log storage | Send to CloudWatch/S3 — counts against those free tiers. |
| **AWS Config** | ⚠️ **No free tier** | ~$0.003 per configuration item recorded + rule evaluations. Can add up. **Feature-flagged off by default** (`enable_config=false`). |
| **GuardDuty** | ⚠️ 30-day free trial | Then priced on events/log volume. **Flagged off by default** (`enable_guardduty=false`). |
| **Security Hub** | ⚠️ 30-day free trial | Then per-check/per-finding. **Flagged off by default.** |
| **Amazon Inspector** | ⚠️ 15-day free trial | Then per-instance/image. Flagged off. |
| **AWS Backup** | Pay per storage | Minimal for demo data. |
| **NAT Gateway** | ⚠️ **NOT free** (~$32/mo + data) | Avoid. Use VPC endpoints or public subnet for the demo. |

## Rules of thumb to stay free

1. **Leave the paid feature flags off** until you specifically want to demo them,
   then turn them on, capture evidence, and turn them back off.
2. **Avoid NAT Gateways** — the silent budget killer. Use Gateway VPC endpoints (free) for S3.
3. **Set a billing alarm** — the first thing this project does. See `terraform/modules/security` (`enable_billing_alarm`, default **true**).
4. **Use AWS Budgets** ($0) with a $1 and $5 threshold.
5. **Set CloudWatch Logs retention** (e.g. 30 days) so ingestion doesn't accumulate storage cost.
6. **Prefer AWS-managed KMS keys** where the control doesn't require a CMK.

## Demonstrating paid controls cheaply

Several CMMC practices (continuous monitoring, threat detection) are best shown
with Config/GuardDuty/Security Hub. The intended pattern:

```bash
# Turn on, let it run briefly, snapshot evidence, turn off
terraform apply -var="enable_config=true" -var="enable_guardduty=true"
python evidence/automation/collect_evidence.py
terraform apply -var="enable_config=false" -var="enable_guardduty=false"
```

This captures auditable evidence that the control *works* without leaving meters running.
