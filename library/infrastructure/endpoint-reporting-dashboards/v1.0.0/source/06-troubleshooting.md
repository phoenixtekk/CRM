# 6. Troubleshooting Guide — Endpoint Reporting & Dashboards

Use `EPRPT-Discovery.ps1` to confirm data-source access, `EPRPT-Validation.ps1` to reconcile counts,
and `EPRPT-Report.ps1` for the consolidated KPI view.

## A. Cannot sign in / read a data source
| Symptom | Cause | Remediation |
|---|---|---|
| Discovery fails to connect | Graph SDK missing or no consent | Install the Microsoft Graph SDK; sign in with an Intune-read admin; grant the read scopes |
| One source reads, another does not | Missing a specific read scope | Add the missing scope (`DeviceManagementApps.Read.All`, etc.) and re-consent |
| Unattended export 401/403 | App registration not consented or wrong secret | Confirm admin consent on `Endpoint Reporting Export – Tenant – Prod`; refresh the client secret/certificate |

## B. Numbers don't reconcile (KPI mismatch)
| Symptom | Cause | Remediation |
|---|---|---|
| Report % differs from portal | Different scope or filter | Confirm the report runs against the same group (`Endpoint Reporting Scope – …`) and the same OS/state filter as the portal view |
| Counts lower than expected | Stale devices not checked in | Devices report last-known state; let them sync, or document the "last seen" window in the KPI definition |
| Encryption % off | Encryption report still calculating | The encryption report can lag after enrollment; re-run after the device reports encryption status |
| App success % off | In-progress installs counted | Reconcile only completed install states; exclude pending/in-progress per the KPI definition |

## C. Export job problems
| Symptom | Cause | Remediation |
|---|---|---|
| Export never completes | `exportJobs` still processing | The job is async; let `EPRPT-Export-Scheduled.ps1` poll to completion before downloading |
| Empty/partial export | Wrong report name or filter | Confirm the requested report name and filter; large tenants page — let the script follow `@odata.nextLink` |
| Files don't land | Output path not writable | Point `-OutputPath` at a writable reporting destination; check share/library permissions |

## D. Configuration Manager reports
- Reports won't render in **Monitoring → Reporting** → the **Reporting Services point** (SSRS) is
  down or mis-URL'd; confirm the SSRS reporting point role and that the report URL resolves.
- Configuration Manager devices missing from the consolidated view → confirm those collections report
  and that you are reading the SSRS software-update/compliance reports, not only Intune.

## E. Scope-group issues
- Pilot and fleet numbers blur together → confirm `EPRPT-Set-ReportingScopeTargeting.ps1` populated
  the correct, separate groups and that the report `-Group` parameter targets the intended scope.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome   # confirm read access
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/managedDevices?$top=1'   # smoke test
Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/reports/exportJobs'      # list export jobs
```

## G. When to escalate
If discovery confirms read access, scopes are consented, devices are synced, and a KPI still will not
reconcile after matching scope and filter to the portal, capture the script output and the portal
view side by side and open a Microsoft support case for the affected report.
