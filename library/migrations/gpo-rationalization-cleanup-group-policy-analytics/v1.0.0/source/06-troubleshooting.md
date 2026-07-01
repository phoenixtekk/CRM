# 6. Troubleshooting Guide — GPO Rationalization & Cleanup with Group Policy Analytics

Use `GPORAT-Discovery.ps1` / `GPORAT-Validation.ps1` for inventory and coverage state,
`GPORAT-Report.ps1` for redundancy/conflict/readiness, and `GPORAT-Remediation.ps1` for safe link
cleanup.

## A. GPO export / inventory problems
| Symptom | Cause | Remediation |
|---|---|---|
| `GPORAT-Discovery.ps1` finds no GPOs | GroupPolicy module missing or no AD read access | Install RSAT Group Policy Management Tools; confirm a Group Policy read/backup role |
| Some GPO exports fail | Permissions on individual GPOs, or special characters in names | Re-run elevated; the script sanitizes names and reports each failed export to retry |
| Inventory count differs from GPMC | Filtered/blocked-inheritance links not counted, or stale RSAT | Refresh GPMC; re-run discovery; reconcile against the GPMC list |

## B. Group Policy analytics import problems
| Symptom | Cause | Remediation |
|---|---|---|
| Import shows no readiness % | Wrong export format uploaded | Upload the GPMC backup/export (the same XML `GPORAT-Discovery.ps1` produces), not a settings report |
| A GPO is missing from analytics | It was not included in the import set | Re-import that GPO into `GPO Analytics Import – All GPOs – Assess` |
| Readiness is 0% / very low | The GPO is mostly preferences/scripts with no MDM equivalent | Expected — classify it **Replace** and tag its re-implementation surface in the register |

## C. Classification / coverage gaps
- `GPORAT-Validation.ps1` reports unclassified GPOs → open the register and assign every listed GPO a
  keep / retire / consolidate / replace disposition; coverage must reach 100% before the pilot gate.
- Unsure whether a GPO is dead → check its links and last-modified date in the inventory; an unlinked,
  long-unmodified GPO for a decommissioned system is a retire candidate (route through the owner).

## D. Redundant audit / conflicting policies
| Symptom | Cause | Remediation |
|---|---|---|
| Same audit area set in several GPOs | Audit policy duplicated over the years | Pick one authoritative GPO per area; clear the duplicates; log each in `Conflict Resolution Log – Audit & Overlaps – Configure` |
| A setting has different values across GPOs | Link-order accident, never reconciled | Decide the intended value, set it on the surviving GPO, remove it from the others, and record the resolution |

## E. Remediation (unlink/remove) problems
- `GPORAT-Remediation.ps1` made no changes → it runs in -WhatIf by default; re-run with `-Apply`
  inside the approved change window.
- Removed too much / need to roll back → retired GPOs are left present-but-unlinked, not deleted;
  re-link from GPMC, or restore from the retained `GPORAT-Discovery.ps1` export folder.

## F. Graph / scope-group problems
- `Connect-MgGraph` fails or returns no reports → confirm `Microsoft.Graph` is installed and consent
  exists for `Group.ReadWrite.All` and `DeviceManagementConfiguration.Read.All`; sign in as an admin.
- Scope group already exists → `GPORAT-Set-MigrationBacklogTargeting.ps1` reuses an existing group of
  the same name (it is idempotent), it does not duplicate.

## G. When to escalate
If exports succeed, analytics imports cleanly, coverage is 100%, and the report still shows conflicts
you cannot reconcile, capture `GPORAT-Report.ps1` output and the register, and review with the
rationalization owner before committing any link removal.
