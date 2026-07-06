# 6. Troubleshooting Guide — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

Use `GWGMAIL-Discovery.ps1` for the source baseline, `GWGMAIL-Validation.ps1` for per-user readiness
and migration validation, `GWGMAIL-Report.ps1` for coverage/exceptions, and `GWGMAIL-Remediation.ps1`
(runs with `-WhatIf` by default) for safe fixes to batch-readiness data gaps. Migration-**tool**
failures (a specific job erroring inside the data migration service, GWMME, or a third-party tool) are
diagnosed in the tool's own docs; this guide covers the **migration pattern**: data types, coexistence,
cutover, and validation.

## A. A user's mail migrated but calendar or contacts did not
| Symptom | Cause | Remediation |
|---|---|---|
| Mail present in Gmail, calendar empty | Calendar not included in the run, or resource/attendee mapping missing | Confirm calendar is in scope in `GWGMAIL Design - Tooling & Data Types - Mail`, supply the resource/attendee mapping, and re-run calendar for the user ([Google — what's imported from Exchange Online](https://knowledge.workspace.google.com/admin/migrate/whats-migrated-in-an-exchange-online-migration)) |
| Contacts missing | Tool/path chosen does not move contacts (e.g. Admin-console mail/calendar path) | Use the desktop tool (GWMME) for contacts, or migrate contacts separately, per the design ([Google — about GWMME](https://knowledge.workspace.google.com/admin/migrate/about-gwmme)) |
| Events import without rooms/attendees | Resource-calendar / attendee mapping not provided | Provide the mapping and re-run; validate with Testing Guide Test 4 |

## B. Migrated mail appears duplicated
- A re-run duplicated items instead of adding only new mail. Use a **delta migration** for re-runs —
  it brings only mail that arrived since the last pass without duplicating — rather than re-running a
  full migration ([Google — migrate email with the data migration service](https://knowledge.workspace.google.com/admin/migrate/migrate-email-with-the-new-data-migration-service)).
  Re-validate with Testing Guide Test 3.

## C. Mail is lost or double-delivered during coexistence
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated user's mail still lands in Exchange Online | Split-delivery routing not updated after the batch cut over | Update `GWGMAIL Coexistence - Mail Routing - Transition` so the batch's users deliver in Gmail; re-test with Testing Guide Test 6 ([Google — split delivery](https://knowledge.workspace.google.com/admin/gmail/advanced/send-email-to-2-email-systems-with-split-delivery)) |
| A message is delivered to both platforms | Dual delivery left on for users who have cut over | Switch those users to split-delivery routing (single target = Gmail); confirm no forwarding loop remains |
| Not-yet-migrated user's mail bounces | No onward route to Exchange Online | Confirm the onward host/route to Exchange Online exists per the coexistence design |

## D. Cross-platform free/busy fails
- A migrated and a not-yet-migrated user cannot see each other's availability. Confirm the calendar
  interop in `GWGMAIL Coexistence - Mail Routing - Transition` is live for both directions and re-run
  Testing Guide Test 7 before continuing the wave.

## E. The DNS/MX cutover did not take effect (or cannot be reversed quickly)
- Routing changes are slow to apply, or a back-out is stuck. The MX **TTL** was likely not lowered
  before the cutover. Set a low MX TTL (for example 300 seconds) ahead of the cutover so changes and
  back-outs propagate fast; confirm the change was applied under change control with a documented
  back-out (Testing Guide Test 8).

## F. A batch fails validation
| Symptom | Cause | Remediation |
|---|---|---|
| Readiness fails | Target accounts not provisioned/licensed in Google | Provision/license the batch's Gmail accounts; re-run `GWGMAIL-Validation.ps1` |
| Coverage incomplete | A data type did not migrate for some users | Do not cut over; re-run the missing data type, run `GWGMAIL-Report.ps1`, remediate exceptions |
| Membership wrong | Duplicate or missing wave assignment | Rebuild the target group with `GWGMAIL-Set-ScopeTargeting.ps1`; reconcile with `GWGMAIL-Remediation.ps1` |

## G. The same problem recurs every wave
- A defect fixed only for one batch will reappear. Fix the **runbook**, the tooling/data-types design,
  or the coexistence routing — not just the batch — so later waves inherit the fix (Implementation
  Step 7). Recurring issues are almost always an un-fixed design, not bad luck.

## H. A cutover needs to be reversed
- The batch failed validation after the routing/DNS change. Invoke the runbook's rollback: revert the
  coexistence routing/DNS change to the prior platform under change control and re-point the batch.
  Rollback is only used when the gate fails — confirm it was tested (Testing Guide Test 10).

## I. Graph scripts fail to connect
- `GWGMAIL-Discovery.ps1`, `GWGMAIL-Validation.ps1`, `GWGMAIL-Report.ps1`, and
  `GWGMAIL-Set-ScopeTargeting.ps1` use Microsoft Graph against the source M365/Entra tenant. If
  connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the signed-in account
  holds the read scopes the script requests (consent on first run). Re-run after consent.

## J. Diagnostics quick reference
```powershell
.\GWGMAIL-Discovery.ps1                                          # source-mailbox baseline
.\GWGMAIL-Set-ScopeTargeting.ps1 -GroupName "..." -MembersCsv .\batch.csv   # -WhatIf by default
.\GWGMAIL-Validation.ps1 -Wave "Wave 0" -MembersCsv .\batch.csv -TargetProvisioned -CoexistenceLive
.\GWGMAIL-Report.ps1 -CoverageCsv .\gwgmail-coverage.csv         # per-user mail/cal/contacts coverage
.\GWGMAIL-Remediation.ps1 -MembersCsv .\batch.csv               # -WhatIf by default; add -WhatIf:$false to act
```

## K. When to escalate
If a batch's target accounts are provisioned and licensed, coexistence routing is correct, the tool
reports the migration complete, and validation still reports gaps after remediation and a delta pass,
capture the `GWGMAIL-Validation.ps1` and `GWGMAIL-Report.ps1` output and review the batch with the
identity, mail-flow, and migration-tool owners before cutting over DNS/MX.
