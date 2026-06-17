# Evidence samples (sanitized)

Drop **sanitized** screenshots/artifacts here to embed in the README, e.g.:

```markdown
![AWS Config conformance pack mapped to CMMC](docs/evidence-samples/config-conformance.png)
```

Captured from a live AWS deployment (account IDs/ARNs redacted):

- `shot-1-drift-free.jpg` — `terraform plan` shows no drift
- `shot-2-evidence-collection.jpg` — automated evidence collector
- `shot-3-config-conformance-pack.png` — Config conformance pack `CMMC`
- `shot-4-config-rules-compliant.png` — Config rules evaluating Compliant
- `shot-5-guardduty.png` — GuardDuty active
- `shot-6-evidence-artifact.jpg` — evidence JSON artifact
- `shot-7-validation-gates.jpg` — OSCAL schema validation PASS
- `shot-8-ci-green.png` — green compliance-ci run
- `shot-9-status-rollup.png` — status roll-up by domain

> 🔒 Redact account IDs, ARNs, and emails first. Unlike `evidence/collected/`
> (gitignored), this folder **is** committed — so only put deliberately
> sanitized images here.
