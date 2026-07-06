# 7. Best Practices — macOS Compliance & Conditional Access for Zero-Trust Access

## Grace & rollout safety
- **Use a compliance grace period.** Set **Actions for noncompliance → Mark device noncompliant** to
  fire after a **grace window** (e.g. a few days) rather than immediately, so a Mac that briefly fails
  a signal gets a warning before access is cut. Start tighter in pilot, more generous during fleet
  expansion, then tighten once stable.
- **Send the noncompliance email.** Add **Send email to end user** so people know *why* they're about
  to be blocked and how to fix it — this dramatically reduces help-desk load at cutover.
- **Always pilot the CA policy in Report-only.** Never enable `CA - macOS - Require Compliant Device`
  straight to On — review the would-be impact in sign-in logs first.
- **Prove the block before you enforce.** Deliberately make one test Mac non-compliant and confirm the
  Report-only "would block" *before* flipping enforcement On.

## Zero-Trust rollout
- **Start narrow, expand in waves.** Pilot group → wave 1 → wave 2 → all Macs. Validate each wave with
  `MACCA-Report.ps1` before widening.
- **Start with Office 365, then broaden resources.** Scope the CA policy to **Office 365** first;
  expand to **All cloud apps** only after the compliant-device gate is proven stable.
- **Keep the policy macOS-scoped.** Leave **Conditions → Device platforms = macOS** so this policy
  never surprises Windows or mobile sign-ins — pair it with the general Conditional Access solution
  for those.
- **Layer signals, don't rush them.** If Defender on macOS isn't ready, ship the encryption + OS +
  firewall gate now and add the **machine-risk** rule when the connector is on. Tighten the risk
  threshold (Medium → Low) only after the fleet is clean.
- **Set a reachable OS floor.** Base **Minimum OS version** on what `MACCA-Discovery.ps1` shows your
  fleet can actually run; raise it as you patch, not before.

## Safety & hygiene
- **Break-glass first, excluded always.** Keep emergency-access accounts (from the Conditional Access
  Integration solution) excluded from this policy; re-verify the exclusion before every enforcement
  change with `MACCA-Validation.ps1`.
- **Name objects clearly.** `macOS - Zero-Trust Compliance`, `CA - macOS - Require Compliant Device`,
  `macOS-ZeroTrust-Pilot` — consistent names make audits and handovers trivial.
- **Ensure a remediation path exists.** Before requiring a signal, make sure users *can* satisfy it —
  a FileVault disk-encryption policy, an OS-update policy, firewall configuration — so "non-compliant"
  is always fixable, never a dead end.
- **Monitor continuously.** Review sign-in logs and `MACCA-Report.ps1` after every change; watch for
  unexpected denies for legitimate Macs.
- **Use `-WhatIf` first.** Run `MACCA-Remediation.ps1` and `MACCA-Set-ScopeTargeting.ps1` in their
  default `-WhatIf` mode and read the preview before committing any change.
