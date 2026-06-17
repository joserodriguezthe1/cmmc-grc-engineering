<!--
Change control (CM.L2-3.4.3/3.4.4/3.4.5): every change to the compliance
baseline is tracked, security-impact-analyzed, and reviewed before merge.
-->

## What changed

<!-- Summary of the change. -->

## CMMC impact analysis (CM.L2-3.4.4)

- **Practices affected:** <!-- e.g. AU.L2-3.3.1, SC.L2-3.13.16 -->
- **Risk introduced / reduced:**
- **OSCAL updated?** <!-- SSP / profile / component-def / POA&M — yes/no + where -->

## Checklist

- [ ] `make validate` passes locally (terraform + OSCAL schema + SSP completeness)
- [ ] `make scan` reviewed; any new findings triaged in `.checkov.yaml`
- [ ] OSCAL changes reflected in `oscal/` (not stale Markdown)
- [ ] POA&M updated if this opens or closes a gap
- [ ] No secrets, account IDs, or real evidence committed
