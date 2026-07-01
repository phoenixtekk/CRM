# 6. Troubleshooting Guide — Software Asset Management (SAM) Program Standup & Governance

Use `SAMPROG-Discovery.ps1` and `SAMPROG-Validation.ps1` for readiness and coverage state,
`SAMPROG-Report.ps1` for the KPI/ELP view, and `SAMPROG-Remediation.ps1` (runs with `-WhatIf` by
default) for safe fixes to data gaps.

## A. Reconciliation cannot compute an ELP
| Symptom | Cause | Remediation |
|---|---|---|
| ELP blank for a product | Entitlement missing from the register | Add the entitlement to `SAM Register - Entitlements - System of Record`; re-run `SAMPROG-Report.ps1` |
| ELP blank for a product | No deployment/usage data | Run `SAMPROG-Discovery.ps1`; enable Intune/discovery or SaaS usage reporting; re-run validation |
| ELP looks wrong | Stale or duplicate register rows | Run `SAMPROG-Remediation.ps1` to flag duplicates/gaps; clean the register and reconcile again |

## B. Requests bypass the program
- Side-channel requests (email/Teams) are invisible to approval and metrics. Enforce
  `SAM Intake - Software Requests - Request Stage` as the only supported channel and route all others
  back through it; have the Executive Sponsor reinforce the mandate.

## C. A lifecycle stage stalls
| Symptom | Cause | Remediation |
|---|---|---|
| Requests pile up unapproved | No Accountable owner for the stage | Complete `SAM RACI - Program - All Stages`; name an Accountable person per stage |
| Renewals slip | Renewal review opened too late | Open the renewal review 90 days out per the Renewal/Retirement SOP; surface upcoming dates in `SAMPROG-Report.ps1` |

## D. KPI report has gaps
- Missing measures usually mean a missing data source. Run `SAMPROG-Validation.ps1` to see which of
  register / discovery / intake coverage is absent, then implement the missing prerequisite from the
  Requirements Guide and re-run `SAMPROG-Report.ps1`.

## E. Graph scripts fail to connect
- `SAMPROG-Discovery.ps1`, `SAMPROG-Report.ps1`, and `SAMPROG-Set-ScopeTargeting.ps1` use Microsoft
  Graph. If connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the signed-in
  account has the read scopes the script requests (consent on first run). Re-run after consent.

## F. Program drifts back to spreadsheets
- The cause is almost always a missing cadence. Confirm `SAM Governance Cadence - Program -
  Reconciliation & Renewal` is scheduled and chaired by the sponsor; a lifecycle that is never reviewed
  always decays.

## G. Diagnostics quick reference
```powershell
.\SAMPROG-Discovery.ps1                 # readiness: discovery source, tenant coverage, devices/licenses
.\SAMPROG-Validation.ps1 -Scope Pilot   # process/data coverage for a scope
.\SAMPROG-Report.ps1                     # KPI set + ELP snapshot
.\SAMPROG-Remediation.ps1               # -WhatIf by default; add -Apply to act
```

## H. When to escalate
If the register is populated, discovery data is present, the intake is live, and the KPI set still
reports gaps after remediation, capture the `SAMPROG-Validation.ps1` and `SAMPROG-Report.ps1` output
and review the data sources with the IT/Deployment Owner and Procurement Liaison at the governance
cadence.
