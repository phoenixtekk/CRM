# 3. Implementation Guide — Microsoft Purview Managed Service

Follow these steps **in order**. This solution stands up an **operating model** — runbooks, cadences,
monitoring, triage, tuning, reporting, and an improvement loop — for Microsoft Purview
(`https://purview.microsoft.com`). It **operates** the capability solutions; it does not re-implement
them. Portal paths and cmdlets are current at authoring; Purview evolves and features are licensing-/
cloud-dependent — **verify your licensing/tenant.**

> **Model:** Baseline the estate, design the operating model (runbooks + cadences + SLOs), configure
> monitoring/triage, **pilot the cadence** on a limited scope, validate the SLOs are met, then run
> continuously. High-impact changes are **piloted in simulation/test in their owning capability** — the
> service coordinates and evidences them. Pattern:
> **Assess → Design → Configure → Pilot (the cadence) → Validate → Expand (run continuously).**

> **Determinations stay with governance.** Regulatory, records, retention-schedule, legal-hold, insider-
> risk, and communication-compliance determinations are compliance/records/privacy/legal's. The service
> surfaces technical state and routes determinations; it does not make them. HR/privacy-sensitive
> surfaces are reported **posture only**.

The named artifacts created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Artifact | Name |
|---|---|
| Monitoring baseline | `Managed Service – Monitoring Baseline` |
| Runbook set | `Managed Service – Run Book` (Alert Triage, DLP Tuning, Health Monitoring, New-Workload Onboarding) |
| Cadence calendar | `Managed Service – Cadence Calendar` (Daily / Weekly / Monthly / Quarterly) |
| SLO definition | `Managed Service – SLO Targets` |
| Triage queue | `Managed Service – Triage Queue` |
| Tuning log | `Managed Service – Tuning Log` |
| Service report | `Managed Service – Service Report` |
| Improvement backlog | `Managed Service – Improvement Backlog` |
| Capability-to-owner map | `Managed Service – Capability Map` |
| Pilot scope | `Managed Service - Pilot Scope` |

## Step 1 — Baseline the estate (Assess)
1. Run `OPSMANAGED-Discovery.ps1` (read-only) to inventory the estate and its operational signals: DLP
   policies and **modes**, sensitivity labels + label policies, retention/lifecycle policies, unified-
   audit-log status, alert-policy presence, insider-risk **presence/posture** only, and role groups.
2. Record the result as `Managed Service – Monitoring Baseline` — the reference the service watches for
   drift.
3. Build `Managed Service – Capability Map` — map each in-scope capability to its **owning solution** and
   a named owner (Requirement 2.4). **Gate:** baseline captured and every capability has an owner.

## Step 2 — Design the operating model (Design)
1. Define `Managed Service – SLO Targets` (Requirement 2.3) — e.g. High-severity DLP alert triaged within
   N business hours; monitoring run daily; tuning reviewed monthly; service review quarterly.
2. Build `Managed Service – Cadence Calendar`:
   - **Daily** — monitoring sweep (`OPSMANAGED-Monitor.ps1`); confirm audit on, no policy unhealthy.
   - **Weekly** — triage the `Managed Service – Triage Queue`; route each item to its owning capability.
   - **Monthly** — tuning review (safe changes, piloted in the owning capability); refresh the report.
   - **Quarterly** — service review with stakeholders; re-baseline; groom the improvement backlog.
3. Write `Managed Service – Run Book` with named runbooks:
   - **Alert Triage** — read alert/activity, assign severity, route to owner, record in the triage queue.
   - **DLP Tuning** — propose a change, pilot it in simulation/test in the owning DLP solution, validate,
     record in `Managed Service – Tuning Log`, enforce under change control.
   - **Health Monitoring** — run the monitoring sweep, compare to the baseline, flag drift.
   - **New-Workload Onboarding** — extend coverage to a new workload via its owning capability, then add
     it to the baseline.

## Step 3 — Configure monitoring and triage (Configure)
1. Confirm the alert/activity/audit signals are readable (Requirement 2.5); run `OPSMANAGED-Monitor.ps1`
   to pull recent DLP/alert/activity into the `Managed Service – Triage Queue` with severity and workload.
2. Set the triage severity model (e.g. High = audit-log off, enforce-mode DLP false positive storm,
   missing coverage on a regulated workload; Medium/Low below that) and the routing to each owning
   capability.
3. Establish `Managed Service – Service Report` and `Managed Service – Improvement Backlog` templates.

## Step 4 — Pilot the cadence (Pilot)
1. Run the **daily monitoring** and **weekly triage** cadences against `Managed Service - Pilot Scope`
   for one full cycle.
2. Exercise the **DLP Tuning** runbook end to end on one low-risk item — proposed, **piloted in
   simulation/test in the owning DLP solution**, validated, recorded in the tuning log, then enforced
   under change control (or rolled back).
3. **Gate:** the cadence runs, findings flow into the queue with severity/owner, and the SLO targets are
   met on the pilot. If the cadence is noisy or slow, tune the severity model/cadence before expanding.

## Step 5 — Validate (Validate)
1. Complete the Testing Guide against the pilot.
2. Run `OPSMANAGED-Validation.ps1` (audit on, no intended policy missing/disabled/stuck, alert signals
   readable, roles separated) and `OPSMANAGED-Report.ps1` (service report + SLO adherence).
3. **Gate:** all pass/fail gates met; the service report reconciles with the portal (authoritative);
   every triage item has an owner and severity.

## Step 6 — Run continuously and improve (Expand)
1. Turn on the full `Managed Service – Cadence Calendar` across the agreed service scope.
2. Each cycle: monitor → triage → route/tune (in the owning capability, piloted) → report → groom the
   `Managed Service – Improvement Backlog`. Record every change in `Managed Service – Tuning Log`.
3. **Trend the health.** Keep each cycle's `Managed Service – Service Report`; a falling count of drift/
   open findings and steady SLO adherence is the evidence the estate is operated and improving.
4. **Route determinations, don't make them.** Records/retention/legal/insider-risk items go to their
   governance owner; the service surfaces state and evidence only.

---
### Order of operations
`Baseline + capability map → SLOs + cadence + runbooks → monitoring/triage configured → pilot the cadence
(tuning piloted in owning capability) → validate SLOs → run continuously + improvement backlog`

### Rollback summary
| Change | Rollback |
|---|---|
| A tuning change disrupted work | It was piloted in the owning capability — revert per that solution's rollback (DLP back to test, auto-labeling to simulation, disable a policy) |
| Cadence too noisy | Adjust the severity model / cadence frequency; re-pilot |
| A determination item was actioned early | Halt; route to compliance/records/privacy/legal |
| Monitoring mis-scored a licensing gap as drift | Re-tag as a licensing decision; re-run `OPSMANAGED-Report.ps1` |
