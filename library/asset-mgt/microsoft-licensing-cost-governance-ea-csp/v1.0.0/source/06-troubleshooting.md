# 6. Troubleshooting Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Use `MSLICGOV-Discovery.ps1` and `MSLICGOV-Validation.ps1` for tenant reads, `MSLICGOV-Report.ps1`
for the position/cost report, and `MSLICGOV-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Script counts do not match the admin center
| Symptom | Cause | Remediation |
|---|---|---|
| Assigned count differs from Billing then Licenses | Stale read, or group-based licensing still processing | Re-run `MSLICGOV-Discovery.ps1`; allow group-based assignments to finish; reconcile per-user vs group counts |
| `Get-MgSubscribedSku` returns nothing | Not connected, or missing scope | Run `Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'` and retry |
| Friendly product names missing | SKU part numbers not mapped | Map `skuPartNumber` to product names in the register; the script reports the raw part number |

## B. Position looks wrong
| Symptom | Cause | Remediation |
|---|---|---|
| Position negative but no shortfall expected | Owned quantity missing/under-recorded | Confirm the owned count from the agreement (Requirement 2.3); update the register |
| Position hugely positive | Counting CSP and EA owned twice, or shelfware | Verify channel per product; flag surplus as reharvest/right-size in the decision log |
| Numbers drift between cycles | No cadence; assignments creep | Run the `Cost Governance Cadence – Tenant-Wide – Ongoing` on schedule |

## C. True-up exposure questions
- True-up reports a large delta: confirm the committed baseline you supplied matches the agreement;
  the delta is assigned minus baseline, not assigned minus zero.
- Expecting to reduce at true-up: you cannot true down mid-term; record the reduction in the
  `Renewal Decision Log – EA+CSP – Per-Cycle` for the next renewal.
- CSP product appears in true-up output: CSP has no true-up — exclude CSP SKUs from the EA worksheet;
  confirm the channel column is correct.
- Unsure of the true-up window or process: defer to the agreement and your licensing partner; do not
  report against an assumed window.

## D. Remediation concerns
- Remediation made no change: that is correct in `-WhatIf` mode (the default). Review the planned
  output, then re-run with `-Confirm` on the pilot scope first.
- Removed a license a user actually needed: restore by re-assigning in `https://admin.microsoft.com`
  then Billing then Licenses; always confirm a utilization signal (Requirement 2.5) before removal.

## E. Scope groups / targeting
- Group not appearing: allow Entra replication; re-run `MSLICGOV-Set-ScopeTargeting.ps1`; confirm the
  account has Groups Administrator or equivalent.
- Wrong membership: review the seeding filter; membership for the named groups
  (`License Governance – Pilot Scope – Stage1`, `License Governance – Estate Scope – Stage2`) should
  match the pilot vs estate split.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'
Get-MgSubscribedSku | Select-Object SkuPartNumber, @{n='Owned';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits
Get-MgUser -All -Property AssignedLicenses,UserPrincipalName | Select-Object UserPrincipalName, AssignedLicenses
```

## G. When to escalate
If tenant reads match the admin center, the register's owned counts are confirmed from the
agreement, and a position or true-up figure still cannot be reconciled, take the
`License Position Register – EA+CSP – Steady-State` and the `True-Up Worksheet – Enterprise Agreement
– Annual` to procurement and your licensing partner — the remaining gap is a commercial/agreement
question, not a tenant data question.
