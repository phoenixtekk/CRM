# 6. Troubleshooting Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Use `CPLTREADY-Discovery.ps1` for readiness, `CPLTREADY-OversharingScan.ps1` for data hygiene, `CPLTREADY-Validate.ps1` for pre-enablement checks, `CPLTREADY-AssignLicenses.ps1` (default `-WhatIf`) for license assignment, and `CPLTREADY-Report.ps1` for adoption/value.

## A. Copilot doesn't appear for a licensed user

| Symptom | Cause | Remediation |
|---|---|---|
| No Copilot in the apps despite a license | Unsupported Microsoft 365 Apps channel/build, or client not updated | Move the user to a supported channel/build (Requirement 2.6); *verify current client requirements*; restart the apps |
| License shows assigned but experience missing | Base-plan service disabled, or licensing not yet propagated | Confirm the qualifying base-plan services are enabled on the license; allow propagation; re-run `CPLTREADY-Validate.ps1` |
| Blocked by Conditional Access | A CA policy blocks the Copilot/Graph experience | Review CA for the cohort; adjust in report-only first, then enforce |

## B. Copilot surfaces content it shouldn't

| Symptom | Cause | Remediation |
|---|---|---|
| An answer cites broadly-shared sensitive content | Oversharing not remediated for the scope before enablement | This is the core risk — run `CPLTREADY-OversharingScan.ps1`, remediate the broad-access site/link, and re-verify (Implementation Step 2) |
| Sensitive content not excluded | No sensitivity-label baseline / content unlabeled | Publish and apply labels (Requirement 2.5); *deep exclusion may need SharePoint Advanced Management — verify availability* |

## C. License assignment fails

| Symptom | Cause | Remediation |
|---|---|---|
| `CPLTREADY-AssignLicenses.ps1` errors on assign | No free Copilot seats, or missing base-plan prerequisite | Confirm free seats (`admin.microsoft.com` → `Billing` → `Licenses`); ensure the user holds a qualifying base plan *(verify current prerequisite)* |
| Group-based licensing shows an error state | Conflicting/duplicate service plan, or usage-location unset | Set the user's usage location; resolve the service-plan conflict in the group licensing assignment |

## D. Readiness scan gaps

| Symptom | Cause | Remediation |
|---|---|---|
| Oversharing scan returns little/nothing | Insufficient Graph permissions, or SAM features unavailable | Grant the read scopes the script requests; *Restricted Content Discovery / SAM availability varies — verify in your tenant* and supplement with SharePoint sharing reports |
| Discovery can't read licensing/MFA | Missing admin role or Graph scope | Assign the least-privilege admin role (global requirement G6) and consent to the read scopes |

## E. Adoption/value not showing

| Symptom | Cause | Remediation |
|---|---|---|
| Copilot Dashboard empty | Viva Insights prerequisite/availability, or too little usage yet | *Verify Copilot Dashboard availability/prerequisite in your tenant*; allow usage to accumulate; use `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot` as well |
| Usage report lags | Reporting latency | Allow the reporting window; re-run `CPLTREADY-Report.ps1` |

## F. Permission / role errors

- Cannot manage licenses/groups → assign the required admin role (global requirement G6); reserve Global Administrator for tenant-wide changes.
- Scripts fail to connect Graph → run `Connect-MgGraph` with the scopes each script's header lists and consent as an admin.

## G. When to escalate

If licensing is confirmed, the client is supported, blockers are remediated, and Copilot still fails to appear or surfaces content that should have been remediated, capture `CPLTREADY-Validate.ps1` and `CPLTREADY-OversharingScan.ps1` output and open a Microsoft support case (Copilot enablement / SharePoint sharing) — and *re-verify any licensing/preview fact with Microsoft* before assuming it is a defect.
