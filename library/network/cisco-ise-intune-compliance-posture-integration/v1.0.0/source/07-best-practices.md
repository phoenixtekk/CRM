# Best Practices

Operate the posture gate so it enforces security without generating false lockouts. These
practices cover grace periods, remediation, secret hygiene, and steady-state operation.

## Grace periods — enforce, but don't ambush

- Set a **grace period** on each compliance policy's *Actions for noncompliance* rather than
  marking devices non-compliant instantly. A user whose patch level slips at 9am should get a
  remediation window, not an immediate VPN lockout. A grace of **24–72 hours** is a common
  starting point; tune per platform and risk.
- During grace, Intune reports the device as **in grace period** (still treated as compliant
  by the gate). ISE therefore still grants access, but the user is being warned.
- Pair grace with a **"Send email to end user"** noncompliance action so the user knows what to
  fix and by when.
- Shorten or remove grace for the highest-risk signals (jailbreak/root, encryption off) — those
  warrant faster denial than a lagging OS patch.

## Remediation — give users a path back

- Make the **non-compliant / quarantine** ISE authorization result a **remediation VLAN** with
  reachability to the enrollment portal, patch/update services, and support — not a dead end.
  A user who is denied should be able to self-heal.
- Publish clear end-user guidance (Help Center) for each common failure: how to turn encryption
  back on, update the OS, or re-enroll. Denial without a fix path generates support tickets.
- Use `ISEPOST-Remediation.ps1` (default `-WhatIf`) to identify non-compliant devices and nudge
  them toward compliance (for example triggering a sync / notification) before enforcement bites.

## Naming and reuse

- Keep every object on the fixed convention — `ISE-Intune-Compliance-Connector`,
  `Compliance – <platform> – Baseline`, `PILOT – ISE Posture Devices`,
  `PROD – ISE Posture Devices` — so the connector, policies, and scripts stay coherent and
  auditable. Do not create ad-hoc duplicates.

## Secret hygiene

- The app registration's **client secret** is a live credential. Store it in a secrets manager,
  never in a repo or ticket. Record its **expiry** and renew **before** it lapses — an expired
  secret silently breaks the connector and every device starts reading as unmanaged.
- Prefer the **shortest practical secret lifetime** your operations can renew reliably. Set a
  calendar reminder ahead of expiry.
- Grant only the **read** Graph permissions the connector needs; do not over-scope the app.

## Pilot-first, always

- Never widen the compliance policy assignment or the ISE authorization scope straight to the
  fleet. Expand `PILOT → PROD` in **waves**, validating each wave with `ISEPOST-Report.ps1`.
- Keep the **rollback** (loosen the ISE rule to permit / unassign the policy) documented and
  reachable throughout every wave.

## Steady-state operations

- Run `ISEPOST-Discovery.ps1` on a schedule to catch a **secret nearing expiry** or a permission
  that lost consent before it causes an outage.
- Run `ISEPOST-Report.ps1` regularly to watch compliance coverage and the granted/denied split
  trend; a sudden spike in denials usually means a policy change or an expired secret, not a
  fleet-wide device failure.
- Review compliance policy rules periodically against your security baseline (OS floors move,
  new signals appear) and re-validate the pass/fail gates after any change.
- Keep the ISE side aligned with **Cisco's current documentation** across ISE upgrades — the
  MDM integration and its dictionary attributes can change between releases.
