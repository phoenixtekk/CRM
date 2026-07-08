# 6. Troubleshooting Guide — Microsoft Purview Managed Service

Common issues when running the managed-service operating model, and how to resolve them. The service is
largely **read-and-coordinate**, so most problems are **read-access**, **signal-availability**, or
**routing/scoring** issues — not a change that broke something. The **portal is authoritative**; artifacts
(`Managed Service – *`) and scripts are named verbatim from the Implementation Guide.

## The monitoring baseline looks empty for a surface
- **Symptom:** `OPSMANAGED-Discovery.ps1` shows no DLP/labels/retention/roles where the portal has them.
- **Likely cause:** The operator lacks the **read** role for that surface (Requirement 2.2) — an empty
  read is not an empty estate.
- **Resolve:** Record it as a **read-access** finding; assign the least-privilege read role under change
  control; re-baseline. Don't over-grant write access.

## The monitoring sweep returns no activity
- **Symptom:** `OPSMANAGED-Monitor.ps1` finds no DLP events / activity.
- **Likely cause:** **Audit logging off** (Requirement 2.5), not connected to Exchange Online, or the
  window is genuinely quiet / audit not yet populated.
- **Resolve:** Confirm the unified audit log is on (the script reports it); `Connect-ExchangeOnline`;
  widen `-Days`; allow audit to populate. A persistently-off audit log is a **High-severity** triage item
  routed to the Audit owner.

## A cmdlet is unavailable (e.g. insider risk)
- **Symptom:** `Get-InsiderRiskPolicy` or another cmdlet is missing after a good connection.
- **Likely cause:** The capability is **portal-managed** or **plan-gated** (E5 / E5 Compliance; some
  preview), or the module is old.
- **Resolve:** Update the module; confirm the surface in the **portal** (insider risk is largely
  portal-managed — report **presence + privacy posture only**) and **verify your licensing/tenant.** An
  unlicensed capability is out of scope, not a service gap.

## Triage is too noisy or too slow (SLOs missed)
- **Symptom:** The triage queue floods, or High-severity items miss the response window.
- **Likely cause:** The severity model is mis-tuned, the cadence is too infrequent, or capacity is short.
- **Resolve:** Re-tune the severity model (what counts as High), adjust the `Managed Service – Cadence
  Calendar` frequency, and re-pilot. Missing an SLO is itself a finding — record it and adjust.

## A finding has no owner / isn't routed
- **Symptom:** A triage item can't be routed to an owning capability.
- **Likely cause:** The `Managed Service – Capability Map` is incomplete (Requirement 2.4).
- **Resolve:** Complete the capability-to-owner map so every operated capability has an owning solution
  and a named owner; unowned findings rot.

## Someone tried to enforce a high-impact change from the managed service
- **Symptom:** A DLP enforce / label / retention / insider-risk change was attempted directly here.
- **Likely cause:** Confusing "operate" with "re-implement."
- **Resolve:** **Stop.** High-impact changes belong to the **owning capability solution**, piloted in
  simulation/test there. Propose the change, pilot it, validate, record it in `Managed Service – Tuning
  Log`, then enforce under change control. `OPSMANAGED-Remediation.ps1` only enables a disabled label/
  retention policy and never enforces DLP.

## A tuning change disrupted work
- **Symptom:** A change coordinated by the service caused blocked/disrupted work.
- **Likely cause:** It wasn't piloted in simulation/test first, or an exception was missed.
- **Resolve:** **Roll back per the owning solution's rollback** (DLP back to test, auto-labeling to
  simulation, disable a policy). Re-pilot with the exception fixed. The tuning log should show the change
  and its rollback.

## Insider-risk / communication-compliance detail is showing up
- **Symptom:** More than presence/posture appears for these surfaces.
- **Likely cause:** The review crossed the **HR/privacy boundary** (Requirement 2.2).
- **Resolve:** **Stop.** Report **presence + privacy posture only** — never case contents or a person's
  identity. The scripts do not read case contents; keep the portal review posture-only too.

## The service report diverges from the portal
- **Symptom:** `OPSMANAGED-Report.ps1` rollup doesn't match the portal.
- **Likely cause:** A read gap, a stale triage CSV, or a mis-scored row.
- **Resolve:** The **portal is authoritative** — reconcile the report to it, fix any read-access finding,
  ensure every open item has an owner, and re-issue to the named audience.

## SLO adherence can't be computed
- **Symptom:** `OPSMANAGED-Report.ps1` reports it can't compute adherence.
- **Likely cause:** The triage CSV lacks **Opened/Closed** timestamps (or **Owner**) columns.
- **Resolve:** Add `Opened`, `Closed`, and `Owner` columns to the triage queue so the report can measure
  response times and ownership.

## A determination item was actioned before governance signed off
- **Symptom:** A records/retention/legal-hold/regulatory/insider-risk item was changed by the service.
- **Likely cause:** A determination was treated as a technical fix.
- **Resolve:** **Halt**; route it to compliance/records/privacy/legal. The service surfaces technical state
  and evidence, not the determination.

---
### Key reminders
| Rule | Why |
|---|---|
| Operate, don't re-implement | High-impact changes belong to the owning capability, piloted first |
| Empty read ≠ empty estate | An unreadable surface is a read-access finding, not drift |
| The portal is authoritative | Reconcile the report to it before issuing |
| Posture only on IRM/CC | HR/privacy-sensitive — presence + guardrails, never content |
| Read-only + safe writes only | Monitoring/reporting read-only; only safe, logged, reversible fixes here |
| Determinations to governance | Records/retention/legal/regulatory/insider-risk decisions aren't the service's |
