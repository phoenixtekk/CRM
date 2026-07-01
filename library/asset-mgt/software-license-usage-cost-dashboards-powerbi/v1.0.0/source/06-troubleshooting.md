# 6. Troubleshooting Guide — Software License Usage Reporting & Cost Dashboards (Power BI)

Use `LICRPT-Discovery.ps1` to confirm sources are reachable, `LICRPT-Validation.ps1` to find where the
numbers disagree with the source, and `LICRPT-Report.ps1` to produce KPI numbers independently of
Power BI for comparison.

## A. Scheduled refresh fails
| Symptom | Cause | Remediation |
|---|---|---|
| Refresh error on a cloud source | Expired/incorrect data source credentials | Dataset > Settings > Data source credentials: sign in again |
| Refresh error on an on-prem source | No gateway, or gateway offline | Install/register the on-premises data gateway and bind the source (requirement 2.8) |
| Refresh times out | Query too heavy / full reload each time | Reduce columns in Power Query; filter to the reporting scope; consider incremental refresh |

## B. Numbers do not reconcile (gate fails)
| Symptom | Cause | Remediation |
|---|---|---|
| Dashboard count differs from source | Product key mismatch between entitlement and usage queries | Align product key casing/spelling in Power Query (Implementation Step 4) |
| Deployed greater than entitled looks wrong | Stale entitlement export or double-counted assignments | Re-export entitlements; de-duplicate usage; run `LICRPT-Validation.ps1` for the per-product variance |
| Usage looks too low | Active window too short, or a usage source missing | Confirm the active-usage window in the KPI set; verify the usage source via `LICRPT-Discovery.ps1` |

## C. KPI values look wrong
| Symptom | Cause | Remediation |
|---|---|---|
| Rates show blank or error | DIVIDE denominator is zero/blank | Use DIVIDE (handles zero) and confirm both source columns load |
| Cost-per-seat inconsistent | Mixed cost bases (annual vs. monthly vs. list) | Normalize to annual unit cost in Power Query; document the basis (Best Practices) |
| Savings overstated | Idle definition too aggressive | Revisit the active-usage window in `License KPI Set – Software Assets – v1` |

## D. Expirations timeline empty or wrong
- Confirm renewal dates loaded as a Date type (not text) in Power Query, and that
  `Days To Expiration` uses TODAY(); re-sort the page ascending by days-to-expiration.

## E. Distribution / access issues
- A leadership member cannot open the report: confirm they are in
  `License Reporting – Leadership & Procurement – Audience` and the workspace/app grants that group access; rebuild the group with `LICRPT-Set-ScopeTargeting.ps1`.

## F. Script connection problems
- `Connect-MgGraph` fails or returns no data: confirm the read scopes
  (`Organization.Read.All`, `Reports.Read.All`, `User.Read.All`) are consented (requirement 2.7) and that the Microsoft Graph SDK is installed (requirement 2.6).
- Usage report returns concealed names: tenant privacy setting masks user names in reports; have an admin disable concealment or report at the product/aggregate level.

## G. Diagnostics quick reference
```powershell
Get-MgContext                                   # confirm connected account and scopes
Get-MgSubscribedSku | Select SkuPartNumber, ConsumedUnits, PrepaidUnits   # entitlement vs. consumed
.\LICRPT-Discovery.ps1                          # list reachable license/usage sources
.\LICRPT-Validation.ps1                         # per-product reconciliation variance
```

## H. When to escalate
If sources are reachable, scopes are consented, the product key is aligned, and
`LICRPT-Validation.ps1` still reports a variance outside tolerance, capture the
`LICRPT-Report.ps1` output alongside the entitlement system export and review the source data with the
entitlement and procurement owners (global G6) before distributing.
