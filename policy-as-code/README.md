# Policy as Code

Continuous detection of control drift and misconfiguration using **AWS Config
Conformance Packs**. This is the "monitor" half of the GRC loop: Terraform
*deploys* controls, Config *verifies* they stay in place (CA.L2-3.12.3).

## Contents

| File | Purpose |
|------|---------|
| [conformance-packs/cmmc-l2-conformance-pack.yaml](conformance-packs/cmmc-l2-conformance-pack.yaml) | ~17 managed Config rules mapped to CMMC practices |
| [deploy-conformance-pack.sh](deploy-conformance-pack.sh) | Deploys the pack (requires Config enabled) |
| [rule-to-control-map.csv](rule-to-control-map.csv) | Which Config rule proves which CMMC practice |

## Cost

AWS Config is **not** in the Free Tier — it bills per configuration item and per
rule evaluation. Recommended pattern: enable, let it evaluate once, snapshot
evidence, disable. See
[../docs/architecture/free-tier-cost-notes.md](../docs/architecture/free-tier-cost-notes.md).

```bash
# 1. Enable Config
(cd ../terraform/environments/dev && terraform apply -var=enable_config=true)
# 2. Deploy the pack
bash deploy-conformance-pack.sh
# 3. After it evaluates, collect evidence
python ../evidence/automation/collect_evidence.py
# 4. Disable to stop charges
(cd ../terraform/environments/dev && terraform apply -var=enable_config=false)
```

## Extending

Add more `AWS::Config::ConfigRule` blocks for additional practices, or author
custom (Lambda-backed) rules for checks AWS doesn't cover out of the box. Keep
[rule-to-control-map.csv](rule-to-control-map.csv) in sync so the audit trail
from rule → CMMC practice stays clear.
