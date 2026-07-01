# 6. Troubleshooting Guide — Workspace ONE to Intune Coexistence & Cutover Runbook

Use `WS1COEX-Discovery.ps1` and `WS1COEX-Validation.ps1` for state, `WS1COEX-Report.ps1` for the
live management/compliance picture, and `WS1COEX-Remediation.ps1` (default `-WhatIf`) for the safe
rollback helper. Workspace ONE-side actions are flagged `[WS1 — see VMware docs]`.

## A. Conditional Access lockouts during coexistence
| Symptom | Cause | Remediation |
|---|---|---|
| Users locked out of email/apps after a cutover | A compliance/enrollment Conditional Access policy is scoped to All users, or to a cohort whose devices are not yet Intune-compliant | Re-scope the policy to the **cohort group only**; confirm devices are compliant in Intune first (`WS1COEX-Report.ps1`); if needed, execute `Rollback Plan – Cohort – Validate` to remove the cohort from the policy |
| Cohort blocked even though enrolled | Devices enrolled but not yet reporting compliant | Wait for compliance to evaluate; re-run `WS1COEX-Report.ps1`; tighten Conditional Access only once compliant |

## B. Double management / conflicting policy
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows in both platforms after cutover | Source assignment/enrollment not removed | Remove the Workspace ONE assignment and retire the device from the source `[WS1 — see VMware docs]`; confirm Intune-only with `WS1COEX-Report.ps1` |
| Conflicting/duplicated profiles or settings | The same payload delivered by both platforms | Enforce the no-double-targeting rule from the `Coexistence Guardrails – Tenant – Configure`; remove one platform's assignment for that cohort |

## C. App and certificate conflicts
- The same app installed twice, or a certificate revoked unexpectedly, usually means both platforms
  targeted the cohort. Keep the source delivering until cutover, then remove the source assignment;
  re-issue the certificate from the surviving authority only `[WS1 — see VMware docs]`.

## D. Cutover gate fails
- If `WS1COEX-Validation.ps1` fails a pre-cutover gate, do **not** proceed. Hold the cohort, fix the
  flagged item (enrollment channel, Conditional Access scope, double-targeting), and re-run the gate.
- If a post-cutover gate fails, execute the `Rollback Plan – Cohort – Validate`
  (`WS1COEX-Remediation.ps1 -WhatIf` to preview, then run for real).

## E. Rollback did not fully revert
- Confirm the cohort group was removed from both the cohort-scoped Conditional Access policy **and**
  the Intune assignments; re-run `WS1COEX-Remediation.ps1 -WhatIf` to see remaining actions, then
  re-enroll/keep the device in Workspace ONE per the source console `[WS1 — see VMware docs]`. Verify
  with `WS1COEX-Report.ps1`.

## F. Discovery shows unexpected dual-managed devices
- Devices appearing as dual-managed before any cutover indicate a prior overlap; quarantine them out
  of the current cohort, resolve the source enrollment `[WS1 — see VMware docs]`, then re-add to a
  later cohort.

## G. When to escalate
If gates pass, Conditional Access is correctly cohort-scoped, devices report compliant in Intune, and
users are still blocked or devices still show dual-managed after a clean rollback, collect the
`WS1COEX-Report.ps1` output and the Entra **Sign-in logs** for the affected user and open a Microsoft
support case (and a VMware case for source-side enrollment issues).
