# 6. Troubleshooting Guide — Microsoft 365 License Optimization & Reharvesting

Use `M365LIC-Discovery.ps1` / `M365LIC-Validation.ps1` for state, `M365LIC-Report.ps1` for usage and
savings, and `M365LIC-Remediation.ps1` (`-WhatIf` first) for safe fixes.

## A. Connection / permission errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scope is denied | Read scopes not consented, or admin consent required | Re-run and accept the prompt; have an admin grant `Organization.Read.All`, `User.Read.All`, `Directory.Read.All`, `Reports.Read.All` once in Entra |
| Reclamation errors on write | Missing `User.ReadWrite.All` | Consent the write scope; confirm the account holds License + Billing Administrator |

## B. Usage report shows anonymized users
- Names appear as concealed IDs → the tenant privacy setting is concealing report identities. Turn it off for the analysis (`Settings → Org settings → Services → Reports`), let reports re-render, run `M365LIC-Report.ps1`, then restore the setting per policy (Requirement 2.4).

## C. Inventory counts don't match the admin center
| Symptom | Cause | Remediation |
|---|---|---|
| Assigned count differs from `Billing → Licenses` | Replication lag, or group-assigned seats counted differently | Re-run `M365LIC-Discovery.ps1` after a short wait; confirm group-assigned (`assignedByGroup`) seats are accounted for |
| A SKU is missing | Trial/standalone SKU not in scope filter | Add the SKU's part number to the discovery scope |

## D. License removal "didn't stick"
- The seat is assigned via group-based licensing, so removing the user license is overridden. Reclaim by removing the user from the licensing group instead (`M365LIC-Set-ScopeTargeting.ps1`) — see Requirement 2.7.

## E. A reclaimed user lost something they needed
- The inactivity window was too short or an exclusion was missing. Re-grant the license immediately, add the account to `Reclaim Exclusions – Shared+Service – AllStages` (if it should be protected), and lengthen the window before the next cycle.

## F. Savings not reflected on the bill
- Reclaimed seats reduce *assigned* counts but the *purchased* quantity (and the invoice) only drops when you lower seats at the next true-up/renewal. Update the entitlement record and adjust the subscription quantity in `Billing → Your products`.

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Organization.Read.All','Reports.Read.All' -NoWelcome
Get-MgSubscribedSku | Select-Object SkuPartNumber, @{n='Purchased';e={$_.PrepaidUnits.Enabled}}, ConsumedUnits
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365ActiveUserDetail(period='D90')?`$format=text/csv"
```

## H. When to escalate
If scopes are consented, the account holds License + Billing Administrator, usage reports show named
users, and a license still cannot be removed or right-sized, capture the Graph error response and the
user's `licenseDetails`, confirm the seat is not group-assigned or blocked by a dependency, and open a
Microsoft support case.
