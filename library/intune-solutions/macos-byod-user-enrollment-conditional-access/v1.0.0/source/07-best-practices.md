# 7. Best Practices — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Field-proven guidance to keep the deployment reliable, private, and low-footprint — the two things that
make macOS BYOD succeed or fail are **respecting the user's device** and **being honest about what
protection macOS actually provides**.

## Choose the least footprint that still protects data
- **Default to account-driven user enrollment (Model A).** It manages only the corporate scope, leaves
  personal data alone, and still yields a compliance signal for Conditional Access. Use the heavier
  **device enrollment (Model B)** only when user enrollment genuinely doesn't fit.
- **Don't over-manage a personal Mac.** Keep the BYOD compliance policy **minimal** — the OS floor and a
  few sensible health checks. Every additional control on someone's own Mac erodes trust and adoption.
- **Never use retire/wipe-the-device actions on BYOD.** For account-driven user enrollment, off-boarding
  removes only the **managed** data by design — lean on that, not a full wipe.

## Be honest about macOS app protection (the #1 misconception)
- **Do not promise iOS-style App Protection Policies (MAM) on macOS — they don't exist for arbitrary Mac
  apps.** Corporate-data protection on a Mac comes from **enrollment + compliance + Conditional Access**,
  not per-app containers or selective in-app wipe.
- **Message this to stakeholders up front.** If a security requirement assumes macOS MAM, correct it
  before you build — otherwise you'll ship a control that can't do what someone expects.
- **Gate with Conditional Access instead.** The reliable macOS control is "only a compliant, enrolled Mac
  reaches the data." That *is* the protection boundary.

## Privacy: earn and keep user trust
- **Publish a one-page BYOD explainer** (Requirements R8): what's managed (corporate scope only), what
  IT can and **cannot** see or do (no personal data, no personal Apple ID, no whole-device wipe), and how
  the user removes the work account.
- **Make removal easy and honest.** Tell users exactly how to remove the work account and what happens
  (only managed data goes). Ease of exit increases willingness to enrol.
- **Keep the managed Apple Account path clean.** The corporate scope uses a **managed Apple Account**;
  never ask users to hand over their personal Apple ID.

## Conditional Access discipline (don't lock people out)
- **Always start in report-only.** Deploy `CA - Require Compliant Mac - Pilot` in **report-only**, read
  the sign-in logs, and only enforce once the predicted allow/block matches intent.
- **Exclude two break-glass accounts from every CA policy — always.** Verify the exclusion before you
  enable any policy; a misconfigured require-compliance policy can lock out the whole tenant.
- **Scope by platform.** Set the **macOS** device-platform condition so this policy affects Macs only and
  doesn't collide with your Windows/iOS gates.
- **Expand in waves.** Move from `BYOD-Mac-Pilot` to a production group deliberately; re-validate each
  wave with the scripts before widening.

## Operating system & compliance
- **Confirm and pin your OS floor.** Account-driven user enrollment needs a modern macOS; set a
  minimum-OS compliance setting so Macs below the floor are flagged rather than silently failing to
  enrol. If you're unsure of the exact minimum, **flag it and confirm** — don't guess.
- **Keep compliance BYOD-appropriate.** Require what protects data (OS floor, SIP, encryption where it
  makes sense) — not a full corporate lockdown of a personal machine.

## Operations & documentation
- **Keep a runbook** of the named objects (`BYOD-Mac-Pilot`, `macOS BYOD Compliance - Pilot`,
  `CA - Require Compliant Mac - Pilot`), the managed Apple Account owner, the OS floor, and the
  break-glass account locations.
- **Report monthly** with `MACBYOD-Report.ps1`: enrolled BYOD Macs vs unmanaged, compliant vs not, and
  which Macs the CA policy gates. A rising "unmanaged but accessing" count is a signal to act.
- **Use `-WhatIf` first on every change.** `MACBYOD-Remediation.ps1` and `MACBYOD-Set-ScopeTargeting.ps1`
  default to preview mode; review the intended change, then re-run with `-Apply`.

## Security posture
- **Combine BYOD with identity hardening** (MFA, sign-in risk policies) so the CA gate is one layer of
  several, not the only one.
- **Treat unmanaged Macs honestly.** If you allow Model C (unmanaged + CA), remember those Macs **cannot
  be compliant** — a require-compliance policy will block them. Decide that intentionally.
