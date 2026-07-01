# 6. Troubleshooting Guide — MDM Migration Readiness Assessment & Wave Planning

Use `MDMRDY-Validation.ps1` for inventory data quality, `MDMRDY-Report.ps1` to re-score, and
`MDMRDY-Remediation.ps1` (default `-WhatIf`) to safely fill gaps. All discovery/validation/report
steps are read-only.

## A. Inventory problems
| Symptom | Cause | Remediation |
|---|---|---|
| Inventory count doesn't match the source console | Scope filter too wide/narrow, or stale/retired devices included | Reconcile against the scope boundary; exclude retired devices; re-run `MDMRDY-Discovery.ps1` |
| Blank required fields (`Platform`, `EnrollmentType`, `Owner`) | Source export omitted columns or used different headers | Map source columns to the input schema (Implementation Guide); run `MDMRDY-Remediation.ps1 -WhatIf` then `-Apply` to fill defaults |
| Unknown platform values | Source uses non-standard platform labels | Normalize to `Windows/iOS/iPadOS/macOS/Android`; remediation infers platform from `OSVersion` where possible |
| Devices with very old `LastCheckIn` | Decommissioned or lost devices still in source | Flag stale in validation; exclude from waves or route to a decommission list, not a migration wave |

## B. Microsoft Graph (optional, Intune-adjacent) issues
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails | SDK missing or scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the read scopes in Requirements 2.3 |
| Graph returns no devices | Wrong tenant or insufficient role | Confirm you signed into the correct tenant with a role that can read managed devices |
| You don't use Intune at all | Source is a non-Intune MDM | Skip `-UseGraph`; run CSV-only — the assessment is fully vendor-neutral without Graph |

## C. Scoring looks wrong
| Symptom | Cause | Remediation |
|---|---|---|
| Everything scores low-readiness | Target supported-OS baseline not provided | Supply the target's supported-OS matrix; re-run `MDMRDY-Report.ps1` |
| Critical devices score low-risk | Stakeholder criticality not fed in | Populate the `Criticality` column from stakeholder input; re-run the report |
| Readiness and actual pilot outcome disagree | Scoring weights mis-tuned | Reconcile predicted vs. actual after the pilot; adjust weights and re-score the remaining waves |

## D. Wave / cohort problems
| Symptom | Cause | Remediation |
|---|---|---|
| A device appears in two waves | Overlapping cohort filters | Re-run `MDMRDY-Set-WaveCohortTargeting.ps1`; ensure each device maps to exactly one wave |
| Dependent devices split across waves | Dependency map not applied to sequencing | Use the `Dependency Map – MDM Migration – Assess` to co-locate dependent devices in one wave |
| Entra group creation denied | Missing `Group.ReadWrite.All` | Grant the write scope, or use export-only mode and import the membership CSVs into the target manually |

## E. Pilot validation gate
- If the `Pilot Wave – MDM Migration – Pilot` does not meet its `Entry/Exit Criteria – Per Wave – Pilot`,
  **do not expand.** Resolve the failing criterion, re-run discovery + report over the post-pilot
  estate, and only proceed once the exit criteria pass and the model is confirmed.

## F. Diagnostics quick reference
```powershell
# Re-check inventory completeness
.\MDMRDY-Validation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY
# Preview gap fills without changing the source of truth
.\MDMRDY-Remediation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY   # -WhatIf is the default
# Re-score after fixing inputs
.\MDMRDY-Report.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY
```

## G. When to escalate
If the inventory reconciles to the source, completeness passes, the target baseline and criticality
are supplied, and the readiness/risk scores still do not match what the pilot wave actually
experienced, pause the expansion and review the scoring model and the dependency map with the
migration sponsor before sequencing further waves.
