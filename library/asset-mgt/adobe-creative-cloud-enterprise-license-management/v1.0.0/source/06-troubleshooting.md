# 6. Troubleshooting Guide — Adobe Creative Cloud for Enterprise License Management

Use `ADOBELIC-Discovery.ps1` and `ADOBELIC-Validation.ps1` for current state, `ADOBELIC-Report.ps1`
for the seat-and-cost picture, and `ADOBELIC-Remediation.ps1` (default -WhatIf) to flag reclaim and
downsize candidates safely. Adobe Admin Console internals and the exact API authentication flow are
deferred to Adobe's official documentation.

## A. Discovery returns no data
| Symptom | Cause | Remediation |
|---|---|---|
| API call returns nothing or an auth error | Missing or wrong Adobe User Management API credentials | Confirm the credentials and scope per Adobe's developer documentation; verify a test call; ensure the secret is loaded from the environment, not blank |
| API not available to your org | No integration registered | Run the script in CSV mode against an Admin Console export instead |
| CSV mode reads zero rows | Wrong export or missing columns | Re-export users and product assignments from the Admin Console; confirm the expected columns are present |

## B. Seat counts do not reconcile
| Symptom | Cause | Remediation |
|---|---|---|
| Inventory count is over the quota | Stale assignments or duplicate identities | Re-run `ADOBELIC-Discovery.ps1`; check for duplicate users from a prior identity migration; reconcile against the Admin Console quota |
| Inventory count is under the purchased count | Purchased seats unassigned | Treat the gap as available seats; reassign from the waiting list before any new purchase |
| Cannot match a user to a person | Identity type ambiguity | Confirm the identity foundation (requirement 2.2) before reclaiming that user |

## C. Activity or last-active signal is missing
- Some organizations do not have a direct last-active field exposed by Adobe. Substitute the best
  available Admin Console activity report and record the limitation in `Right-Sizing Register – Pilot Scope – Validate`.
- When no activity signal exists at all, fall back to assignment age plus a confirmation-owner check
  rather than reclaiming on assumption.

## D. A reclaimed user lost access they needed
- Reclamation should never run without a recorded confirmation-owner approval. If access was removed in
  error, re-add the user to the product profile in the Admin Console; the seat is consumed again.
- Tighten the process: confirm the approval column in the register is populated before any removal.

## E. Right-sizing flags the wrong product
- An all-apps user who genuinely uses multiple apps is not over-provisioned. Confirm the usage evidence
  before downsizing; record the keep decision so the next cycle does not re-flag them.

## F. Recurring review drifts
- If the estate creeps back out of alignment, confirm the scheduled runs of the discovery, validation,
  and report scripts are actually executing and that `Review Cadence – Adobe Estate – Expand` has a
  named owner and a written idle threshold.

## G. When to escalate
If discovery and reconciliation are clean, credentials are valid, and an assignment still cannot be
read or changed as expected, capture the script output and the Admin Console state and open a support
case with Adobe — console behavior and API specifics are Adobe-owned.
