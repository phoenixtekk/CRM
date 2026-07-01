# 7. Best Practices — AppLocker to WDAC (App Control for Business) Migration

- Audit first, always. Never enforce a WDAC policy before its audit log is clean of legitimate
  would-blocks. The audit gate is the single most important practice — it is how you migrate with no
  user lockouts.
- Translate, do not guess. Author the WDAC policy from the exported AppLocker policy, not from memory.
  Pay special attention to AppLocker path rules for unsigned apps — those are the highest lockout
  risk under WDAC.
- Coexist on purpose. Keep AppLocker in force while WDAC runs in audit and through early enforcement,
  so application control is never absent. Retire AppLocker per ring, only after WDAC enforcement is
  validated on that ring.
- Prefer the managed installer. Re-trust line-of-business apps by deploying them through Intune under
  the managed installer rather than re-creating brittle path rules — it survives app updates and
  replaces AppLocker's weakest construct.
- Use ISG for reputable apps. Enable Intelligent Security Graph trust for well-known,
  good-reputation apps that are not deployed through Intune, to shrink the supplemental rule set.
- Ring everything. Pilot to broad to fleet. A too-strict policy caught on `App Control Migration –
  Pilot – Ring 1` never reaches the fleet.
- Name artifacts consistently. Use the `<Purpose> – <Scope> – <Stage>` names verbatim across audit
  profile, enforce profile, base policy, and ring groups so audits and handoffs are unambiguous.
- Keep a rollback ready. Pre-plan the unassign-enforce / re-assign-audit path and keep
  `WDACMIG-Remediation.ps1` (default -WhatIf) on hand. If AppLocker is already retired on a ring,
  know how to re-deploy it temporarily.
- Re-audit after change. Any new or updated app can introduce a would-block; re-run
  `WDACMIG-Report.ps1` after notable app changes, not just at migration time.
- Document the cutover. Record per-ring dates, the audit-gate sign-off, enforcement, and
  AppLocker-retirement for audits and repeatability.
