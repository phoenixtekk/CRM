# 6. Troubleshooting Guide — Software License Compliance & Audit-Defense (Effective License Position)

Use `LICCOMP-Discovery.ps1` and `LICCOMP-Validation.ps1` for the input data state,
`LICCOMP-Report.ps1` for the ELP and gaps, and `LICCOMP-Remediation.ps1` (default `-WhatIf`) for safe
reclamation of clear over-deployment.

## A. The ELP does not reconcile / numbers look wrong
| Symptom | Cause | Remediation |
|---|---|---|
| Entitled and consumed counts seem incomparable | Different counting metric on each side | Normalize the deployment count to the entitlement metric (per-core, per-device, per-user); re-run `LICCOMP-Report.ps1` |
| Many unmapped deployment rows | Normalization mapping incomplete | Add raw-name to canonical mappings in the ELP workbook; re-run `LICCOMP-Validation.ps1` |
| Shortfall larger than expected | Product use rights not applied | Apply downgrade/second-use/virtualization/BYOL rights per Requirement 2.4 and re-reconcile |

## B. Entitlements cannot be proven
- An entitlement line with no purchase record counts as zero in an audit. Mark it "unproven" in the
  `Entitlement Baseline – <Publisher/Product> – Source`, then recover the proof from procurement, the
  publisher portal, or finance before relying on the line.

## C. Deployment data is incomplete
| Symptom | Cause | Remediation |
|---|---|---|
| Known devices missing from the inventory | Discovery source not covering the population | Confirm the scope group (`LICCOMP-Set-ScopeTargeting.ps1`); widen the discovery export |
| Installs present but no usage | Usage telemetry not enabled (SaaS) | Enable sign-in/usage reporting and export recent activity before counting active users |

## D. Gaps are not closing
- A shortfall stays open when no owner is assigned or no closure is chosen. Ensure every gap in the
  `Gap Register – <Publisher/Product> – Reconciled` has an owner and one of: reharvest, reassign,
  data fix, or true-up — and that owner sign-off (Requirement 2.6) is recorded before spend.

## E. Remediation removed nothing
- `LICCOMP-Remediation.ps1` defaults to `-WhatIf` and only previews. After owner sign-off, re-run
  with `-WhatIf:$false` to act. Confirm the input list (stale/disabled-user assignments) is correct
  first — remediation is for clear over-deployment, not disputed lines.

## F. Quick reference
```powershell
.\LICCOMP-Discovery.ps1 -CsvPath .\deployment.csv     # collect installed-software inventory
.\LICCOMP-Validation.ps1 -EntitlementCsv .\ent.csv -DeploymentCsv .\dep.csv   # confirm inputs reconcilable
.\LICCOMP-Report.ps1 -ElpPath .\elp.csv -CsvPath .\gap-register.csv           # ELP summary + gap list
.\LICCOMP-Remediation.ps1 -InputCsv .\stale.csv       # preview reclamation (WhatIf by default)
```

## G. When to escalate
If both inputs are complete and proven, the normalization maps cleanly, and product use rights are
applied, but the position is still disputed (for example, a publisher contests your metric or rights
interpretation), capture the ELP, the proofs, and the contract clause in the
`Audit Package – <Publisher/Product> – Defense` and escalate to procurement and licensing/legal for a
contract-level decision.
