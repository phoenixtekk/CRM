# 1. Solution Overview — Oracle C2M Hypercare & Production Support Runbook

## What hypercare is
The riskiest weeks of any Oracle Utilities Customer to Meter (C2M) program are the ones around
**go-live**: the days spent proving the environment is ready, the **cutover** itself, and the
**hypercare** period that follows — the elevated-support window where the team runs live production
for the first time, watches it closely, and stabilizes it before handing it to steady-state
operations. Hypercare is not a mood ("everyone pay attention"); it is an **operating model**: a
readiness gate that says go/no-go, an on-call and escalation structure so every issue has an owner
and a path, a disciplined way to handle incidents and known issues, a way to keep building in the
lower environments while production runs, and a **daily health routine** so the state of the system
is a measured fact each morning, not a rumor. This solution is that operating model as a
**runbook** — named checklists and rotas you define once and reuse from cutover through
stabilization.

> **Version boundary.** Command names, script names, monitoring interfaces, and object terminology
> below are from the Oracle Utilities Application Framework (OUAF) Server Administration Guide and the
> C2M product documentation. Version-specific details (C2M 25.4 / minimum v2.9, WebLogic 14c, the JMX
> batch connector, `threadpoolworker`/`starttpw`) are **cited or flagged "verify for your version"** —
> never invented. Go-live checklists, patch bundles, and known-issue notes are frequently gated on
> My Oracle Support (MOS); those are **pointed to, not reproduced**. See `global-requirements-oracle.md`.

## Why this matters
Go-live without a runbook is where good programs stumble. Without a **readiness gate**, cutover
begins on hope — an unpatched node, an unconfigured batch daemon, or a missing integration endpoint
surfaces at the worst possible time. Without a **defined on-call and escalation model**, the first
production incident is triaged by whoever happens to be watching, and the bridge call spends its
first hour deciding who owns what. Without disciplined **incident and known-issue handling**, the
same problem is diagnosed three times by three people and the fixes are not written down. Without
**day-2 build support in the lower environments**, the team either freezes all further work (and
falls behind) or builds in production (and destabilizes it). And without a **daily health routine**,
the first sign of trouble is a business user's phone call. A real hypercare model fixes the cause:
it gates readiness, structures on-call, handles incidents once and records them, keeps day-2 work
safely in lower environments, and makes health a measured morning fact — so the team runs production
confidently from cutover.

## The hypercare operating model
Four phases, each with an explicit gate before the next begins:

1. **Readiness** — before cutover, prove the environment, the data, the integrations, the batch
   estate, the monitoring, and the support structure are all go. The **Go-Live Readiness Checklist**
   (`C2M Runbook - Readiness - Go-Live Checklist`) is the gate: no red items, or a signed-off
   exception, before cutover starts.
2. **Cutover** — execute the cutover plan (final data load/sync, config promotion, integration
   enablement, batch daemon start) against a timeboxed plan with a **go/no-go** decision point and a
   documented **rollback**. Cutover ends when the smoke checks pass and production is accepting work.
3. **Hypercare** — the elevated-support window. The **on-call rota** (`C2M Runbook - OnCall - Rota`)
   is staffed, the **escalation matrix** (`C2M Runbook - Escalation - Matrix`) is live, incidents run
   through the **incident procedure**, the **known-issue register** (`C2M Runbook - KnownIssue -
   Register`) is kept current, day-2 builds continue in lower environments, and the **daily health
   routine** (`C2M Runbook - Health - Daily Routine`) runs every morning.
4. **Steady-state** — when the exit gate is met (health stable for the agreed number of consecutive
   days, incident rate below threshold, no open Sev-1/Sev-2, day-2 backlog controlled), hypercare
   **exits** to normal operations and the runbook becomes the standing operations runbook.

## The production-support structure
Hypercare runs on named, reusable structures rather than ad-hoc heroics:

- **On-call rota** — `C2M Runbook - OnCall - Rota`: the primary/secondary schedule for each support
  window, by layer (application, middleware/WebLogic, database, integration, infrastructure), with a
  handover step between shifts.
- **Escalation matrix** — `C2M Runbook - Escalation - Matrix`: for each severity, who is engaged,
  in what order, within what time, up to the incident commander and — for product defects — the
  Oracle Service Request path on MOS.
- **Severity model** — `C2M Runbook - Severity - Model`: the definitions (Sev-1 … Sev-4) that decide
  response time, who is paged, and communications cadence, so severity is a rule, not an argument.
- **Incident procedure** — `C2M Runbook - Incident - Procedure`: detect → triage → assign owner →
  diagnose → mitigate/resolve → communicate → record, with the bridge/comms pattern for a major
  incident.
- **Known-issue register** — `C2M Runbook - KnownIssue - Register`: the living list of known defects
  and their workarounds (many tracked to a MOS note or patch), so a recurring symptom is recognized
  and worked around in minutes, not re-diagnosed.
- **Day-2 build lane** — `C2M Runbook - Day2 - Build Lane`: how further configuration/development
  continues safely in the lower environments (Dev/Test/UAT) during hypercare and promotes to
  production through change control, never bypassing it.
- **Daily health routine** — `C2M Runbook - Health - Daily Routine`: the fixed morning set of
  read-only checks (WebLogic servers, batch completion and backlog, integration queues, database and
  disk, error-log deltas) that produces a green/amber/red health snapshot every day.

## Named objects this solution defines
So the runbook is repeatable, this solution names its artifacts once and reuses them:

- `C2M Runbook - Readiness - Go-Live Checklist` — the go/no-go readiness gate.
- `C2M Runbook - Cutover - Plan` — the timeboxed cutover sequence with its go/no-go and rollback.
- `C2M Runbook - OnCall - Rota` — the primary/secondary on-call schedule by layer.
- `C2M Runbook - Escalation - Matrix` — who is engaged, in what order, by severity.
- `C2M Runbook - Severity - Model` — the Sev-1…Sev-4 definitions and response targets.
- `C2M Runbook - Incident - Procedure` — the standard incident lifecycle.
- `C2M Runbook - KnownIssue - Register` — known defects and their workarounds.
- `C2M Runbook - Day2 - Build Lane` — day-2 build support in lower environments.
- `C2M Runbook - Health - Daily Routine` — the daily read-only health snapshot.

## What this is not
This solution provides the **operating model and runbook** for C2M go-live and hypercare; it does not
replace the environment build, the batch scheduling design, the monitoring platform, or the
integration configuration — those are their own disciplines and are referenced, not restated. Where
the included scripts touch live systems they **read**: the discovery, validation, and report scripts
are read-only; remediation runs **dry-run by default** and only prints or applies safe operational
alignments (never business logic) under change control. Every production change during cutover and
day-2 goes through change control and is proven on a lower environment first.

## The deployment model
> Assess readiness against the checklist, configure the support structure (rotas, escalation,
> severity, incident procedure, known-issue register, day-2 lane, health routine), pilot the whole
> model on a non-production dress rehearsal, validate the readiness and health gates, then expand
> into the live cutover and hypercare. The repeatable way: Assess, then Configure, then Pilot, then
> Validate, then Expand — with a documented rollback for every production change.
