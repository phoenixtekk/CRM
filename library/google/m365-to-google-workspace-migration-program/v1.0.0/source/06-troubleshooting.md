# 6. Troubleshooting Guide — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Use `GWMIGPROG-Discovery.ps1` for the source baseline, `GWMIGPROG-Validation.ps1` for per-wave
readiness, `GWMIGPROG-Report.ps1` for progress/coverage, and `GWMIGPROG-Remediation.ps1` (runs with
`-WhatIf` by default) for safe fixes to wave-readiness data gaps. Per-service data-movement failures
(a specific mailbox, Drive item, or chat) are diagnosed in the individual mail/Drive/chat migration
solutions and the tool's own docs; this guide covers the **program**: waves, coexistence, cutover, and
gates.

## A. Mail is lost or double-delivered during coexistence
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated user's mail still lands in Microsoft 365 | Routing rule not updated after the wave | Update `GWMIGPROG Coexistence - Mail & Calendar - Transition` routing so the wave's users route to Google; re-test with Testing Guide Test 3 |
| A message is delivered to both platforms | Dual delivery left on for users who have cut over | Switch those users to split-delivery routing (single target = Google); confirm no forwarding loop remains |
| Not-yet-migrated user's mail bounces | Routing has no on-ward path to Microsoft 365 | Confirm the secondary host/route to Microsoft 365 exists per the coexistence design ([Google — split delivery](https://support.google.com/a/answer/12971016)) |

## B. Cross-platform free/busy fails
- A migrated and a not-yet-migrated user cannot see each other's availability. Confirm the calendar
  interop in `GWMIGPROG Coexistence - Mail & Calendar - Transition` is live for both directions and
  re-run Testing Guide Test 4 before continuing the wave.

## C. A wave fails its go/no-go gate
| Symptom | Cause | Remediation |
|---|---|---|
| Readiness fails | Users not provisioned/licensed in Google | Fix identity/provisioning (GCDS/SCIM) for the wave; re-run `GWMIGPROG-Validation.ps1` |
| Validation incomplete | Data move not finished for the wave's users | Do not pass the gate; complete the per-service move, then re-run `GWMIGPROG-Report.ps1` |
| Gate ambiguous | Criteria not defined/owned | Complete `GWMIGPROG Gate - Go/No-Go - Per Wave` criteria and name the Accountable owner before deciding |

## D. The same problem recurs every wave
- A defect fixed only for one wave will reappear. Fix the **runbook**, coexistence design, or tooling
  pattern — not just the wave — so later waves inherit the fix (Implementation Step 7). Recurring
  issues are almost always an un-fixed runbook, not bad luck.

## E. A wave overwhelms migration throughput
- A wave runs long or stalls. The wave is likely too large or too data-heavy. Re-balance
  `GWMIGPROG Wave Plan - Segmentation - 150k` to spread data-heavy users across waves and pre-stage
  Drive content ahead of cutover ([Google — plan your phases](https://support.google.com/workspacemigrate/answer/9275515)),
  then rebuild the wave group with `GWMIGPROG-Set-ScopeTargeting.ps1`.

## F. A user appears in two waves or none
- Duplicate or missing wave assignment causes duplicate data or a stranded user. Enforce one-user-one-
  wave in the wave plan; run `GWMIGPROG-Set-ScopeTargeting.ps1` (preview) and
  `GWMIGPROG-Validation.ps1` to reconcile membership before cutover. Never move a confirmed user
  between waves.

## G. A cutover needs to be reversed
- The wave failed validation after the routing/DNS change. Invoke the runbook's rollback: revert the
  coexistence routing/DNS change to the prior platform under change control and re-point the wave.
  Rollback is only used when the gate fails — confirm it was tested (Testing Guide Test 7).

## H. Graph scripts fail to connect
- `GWMIGPROG-Discovery.ps1`, `GWMIGPROG-Validation.ps1`, `GWMIGPROG-Report.ps1`, and
  `GWMIGPROG-Set-ScopeTargeting.ps1` use Microsoft Graph against the source M365/Entra tenant. If
  connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the signed-in account
  holds the read scopes the script requests (consent on first run). Re-run after consent.

## I. Diagnostics quick reference
```powershell
.\GWMIGPROG-Discovery.ps1                              # source-estate baseline for wave planning
.\GWMIGPROG-Set-ScopeTargeting.ps1 -GroupName "..." -MembersCsv .\wave.csv   # -WhatIf by default
.\GWMIGPROG-Validation.ps1 -Wave "Wave 1" -MembersCsv .\wave.csv             # per-wave readiness
.\GWMIGPROG-Report.ps1 -WavePlanCsv .\wave-plan.csv    # progress/coverage
.\GWMIGPROG-Remediation.ps1 -MembersCsv .\wave.csv     # -WhatIf by default; add -WhatIf:$false to act
```

## J. When to escalate
If a wave's users are provisioned and licensed, coexistence routing is correct, the data move
completed, and validation still reports gaps after remediation, capture the `GWMIGPROG-Validation.ps1`
and `GWMIGPROG-Report.ps1` output and review the wave with the identity, mail-flow, and per-service
migration owners at the program cadence before passing the go/no-go gate.
