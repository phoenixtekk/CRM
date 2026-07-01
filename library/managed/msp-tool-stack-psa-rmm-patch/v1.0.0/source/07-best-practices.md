# 7. Best Practices & Operations — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

This is **Stage Operate** — the day-to-day operating cadence once the stack is stood up, integrated, and validated, plus the standards that keep it healthy as you **expand** to the full client base.

---

## Operating cadence

### Daily

- Work `Service Desk – Reactive – Triage` to zero: every inbound and alert-generated ticket triaged and dispatched to `Service Desk – Reactive – Dispatch`.
- Review `NOC – Alerts – Automated` for tickets that did not auto-close; investigate noisy or stuck alerts.
- Confirm `Automation Policy – Maintenance – Nightly` completed across all sites; investigate failures.

### Weekly

- Review patch compliance per ring; chase devices missing from `Patch Ring – Broad – Stage2`.
- Reconcile the CMDB: confirm RMM-discovered assets match PSA configuration items per client.
- Review alert→ticket noise and tune thresholds on `Monitoring Policy – Workstation – Standard` / `…– Server – Standard`.

### Monthly

- Verify time→billing: all billable technician time is captured against the right agreement.
- Audit MFA and role assignments across all three tools (R5, R8).
- Rotate or re-verify the `Integration – PSA-RMM – Bi-Directional` credentials per the secrets-store policy.

---

## Standards that keep the stack healthy

### Naming discipline

Every new object — board, queue, site, policy, ring, group — uses the `<Purpose> – <Scope> – <Stage>` convention verbatim. Never create ad-hoc one-off objects; if a new pattern is needed, add it to the standard in the documentation home first.

### One site, one company, per client

Each managed client maps to exactly one `Client Site – {ClientName} – Production` RMM site and one PSA company. Never split a client across multiple sites or merge clients into one site — it breaks attribution of alerts, assets, and billing.

### Ring-based patching, never all-at-once

Patches always flow Pilot → Early → Broad → Critical Servers. Never push an update straight to all devices. Watch `Patch Ring – Pilot – Stage0` for regressions before the wave reaches `Patch Ring – Broad – Stage2`.

### Integration as the source of truth for assets

Let the RMM be the discovery source and the PSA be the system of record; the `Integration – PSA-RMM – Bi-Directional` feed keeps them aligned. Do not hand-maintain assets in the PSA — fix discovery at the RMM instead.

### Change control on fleet-wide changes

Any change to a shared policy, ring deferral, or the integration affects every client at once. Route these through change control (GM4): pilot on one client/site, validate, then expand.

### Least privilege and MFA always

Keep the four roles tight; grant the minimum each user needs. MFA stays enforced on all three tools for every human account, with SSO via Entra where supported.

---

## Expanding to the full client base

Onboard each remaining client by re-running `Onboarding Template – Managed Client – Standard` (via `MSPSTACK-Set-ClientOnboarding.ps1`, `-WhatIf` then `-Apply`). Onboard in waves, validating each wave with `MSPSTACK-Validation.ps1` before the next. Keep `MSPSTACK-Report.ps1` output as the running record of stack coverage and onboarding status.

## Continuous improvement

- Track recurring alert types and convert them into RMM automation that self-remediates before a ticket is needed.
- Review SLA performance on `Service Desk – Reactive – Triage` and adjust dispatch/staffing.
- Re-run `MSPSTACK-Discovery.ps1` periodically to catch unmanaged endpoints and integration drift.
- Keep the operating standard, integration details, and onboarding runbook current in the documentation home — the stack is only as repeatable as its documentation.
