# 7. Best Practices — Netskope Client Troubleshooting & Diagnostics Toolkit

- **Diagnose before you touch.** Always collect the `Diagnostic Bundle – Endpoint – Collect`
  (`NSDIAG-Discovery.ps1` → `NSDIAG-Validation.ps1` → `NSDIAG-Report.ps1`) before any remediation —
  the single most important habit. Evidence first, action second.
- **Classify, then follow the named runbook.** Match the symptom to one of the four classes
  (steering, authentication, performance, certificate) and run that runbook — don't improvise.
- **Make re-enroll a last resort.** Restart and repair fix most steering faults; reserve re-enroll
  for confirmed enrollment/auth faults. Reflexive reinstalls hide root causes and churn users.
- **Always preview with `-WhatIf`.** Run `NSDIAG-Remediation.ps1` and `NSDIAG-Set-ScopeTargeting.ps1`
  in `-WhatIf` first so the action is understood before it touches live steering.
- **Reuse the naming convention verbatim.** `<Purpose> – <Scope> – <Stage>` on every runbook, bundle,
  and group makes a ticket unambiguous and an escalation self-describing.
- **Respect the vendor boundary.** Diagnose to the edge of the operating system; for client-internal
  logs and console policy, hand off to Netskope's documentation rather than guessing paths/menus.
- **Escalate with a full bundle.** Never escalate symptoms — attach the diagnostic bundle plus the
  vendor-deferred client logs so the next tier starts from facts.
- **Check the clock on auth failures.** Time/clock skew is a common, cheap-to-fix cause of
  authentication loops — verify it before re-enrolling.
- **Re-baseline after upgrades.** After a Netskope client or console change, re-confirm vendor paths
  and re-run the Testing Guide so the runbooks stay accurate.
- **Pilot with the help desk first.** Validate the toolkit on real tickets with the help desk before
  expanding to the wider support org — the pilot gate keeps bad runbooks off the floor.
