# 6. Troubleshooting Guide — Microsoft 365 Copilot Secure Adoption & Governance

Use `COPILOT-Discovery.ps1` / `COPILOT-Validation.ps1` for the current state, `COPILOT-Report.ps1`
for the data-exposure picture, and `COPILOT-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Copilot surfaces content it shouldn't
| Symptom | Cause | Remediation |
|---|---|---|
| Copilot returns confidential/HR/stale files to a user | Oversharing — the user actually has access via a broad or org-wide link | Run `COPILOT-Discovery.ps1` to find the broad grants; run `COPILOT-Remediation.ps1 -Apply` to remove anonymous/org-wide links; tighten site permissions |
| Sensitive site still surfaced during pilot | Remediation not yet complete on that site | Add the site to the **Restricted SharePoint Search** allowed-list containment until it's remediated; then lift |
| Guest surfaced internal content via Copilot | Stale external/guest access | Run an Entra access review for guests; remove stale guest grants; tighten tenant external-sharing policy |

## B. Sensitivity labels not honored
| Symptom | Cause | Remediation |
|---|---|---|
| Copilot uses content that should be blocked by a label | The label carries no encryption/usage rights, or the content is unlabeled | Confirm the protected label applies encryption; run/verify auto-labeling; label-based access only constrains Copilot where content is actually labeled and protected |
| Copilot output lost its source label | Output-inheritance not evaluated as expected | Confirm labels are published to the user and the source item is protected; re-test per Testing Test 5 |

## C. DLP-for-Copilot not excluding content
- Confirm the policy targets the **Microsoft 365 Copilot** location and is **on** (not still in
  test/simulation). Confirm the excluded label matches the content's label exactly. Give policy
  changes time to propagate before re-testing.

## D. Legitimate work is now blocked (over-remediation)
- If tightening sharing or restricted search blocked people who need access: re-grant via specific
  people/groups (not broad links), add the site to the restricted-search allowed list, or unpublish an
  over-aggressive label policy from the affected scope. Use the change-control rollback (global G8).

## E. Copilot not working for a pilot user
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot user has no Copilot | License not assigned or user not in the pilot group | Confirm membership of `Copilot Adoption – Pilot Users – Pilot`; assign the Copilot license (group-based licensing preferred) |
| Copilot answers with no tenant grounding | Base-plan/prerequisite or indexing not ready | Confirm the qualifying base plan and that content has been indexed; allow time after enablement |

## F. Diagnostics quick reference
```powershell
# Read-only signals and exposure baseline
.\COPILOT-Discovery.ps1
.\COPILOT-Report.ps1

# Confirm remediation held (broad links removed, labels published, licensing pilot-only)
.\COPILOT-Validation.ps1

# Preview safe remediation before applying
.\COPILOT-Remediation.ps1 -WhatIf
```
Portal checks: SharePoint admin center → **Sites → Active sites** (sort by external sharing);
Microsoft Purview → **Information Protection** (labels) and **Data Loss Prevention** (policies);
Microsoft 365 admin center → **Billing → Licenses** (Copilot assignment) and the **Copilot** admin
experience.

## G. When to escalate
If oversharing is remediated, labels are published and honored, DLP is on for the Copilot location,
licensing is pilot-only, and Copilot still surfaces content it should not — capture the exact prompt,
the citing item, and the user's effective permissions on that item, and open a Microsoft support case.
Volatile Copilot-portal and DLP-for-Copilot specifics are deferred to Microsoft's documentation.
