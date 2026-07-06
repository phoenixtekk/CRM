# Executive Summary — Oracle C2M Hypercare & Production Support Runbook

The riskiest weeks of any Oracle Utilities Customer to Meter (C2M) program are **go-live and
hypercare** — the readiness checks before cutover, the cutover itself, and the elevated-support
window that follows while the team runs live production for the first time. Done without a runbook,
these weeks are where good programs stumble: cutover begins on hope, the first incident is triaged by
whoever is watching, the same problem is diagnosed three times, day-2 work either freezes or
destabilizes production, and the first sign of trouble is a business user's phone call. This solution
is the **hypercare and production-support runbook** that removes that risk: a go-live readiness gate,
the on-call and escalation model, incident and known-issue handling, day-2 build support in the lower
environments, and the daily health/monitoring routine — so the team runs production confidently from
cutover through stabilization.

This is a complete, do-it-today package for an experienced C2M production-support lead. Every
structure is named once — the readiness checklist, the cutover plan, the on-call rota, the escalation
matrix, the severity model, the incident procedure, the known-issue register, the day-2 build lane,
the daily health routine — and reused from cutover to steady-state, so you configure it once and run
it every day of hypercare.

## What you get
- A plain-language Solution Overview of the hypercare operating model (readiness → cutover →
  hypercare → steady-state) and the production-support structure, with an explicit gate at each phase.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a reachable
  environment, the readiness checklist with owners, monitoring/health-check access (WLST, the JMX
  batch connector, the schema, the logs), the on-call rota, the escalation matrix and severity model,
  the incident procedure and known-issue register, lower-environment access for day-2, and the
  cutover plan with backups and rollback.
- The Runbook itself: the go-live readiness checklist, the on-call/escalation model, incident and
  known-issue handling, day-2 build support in the lower environments, and the daily health/monitoring
  routine — each with a pass/fail gate, pilot-first on a non-production dress rehearsal.
- Five automation scripts (shell, WLST/Jython, and SQL — not PowerShell) for readiness/health
  discovery, go-live readiness validation, a health and incident report, safe remediation (dry-run by
  default), and a scope/target helper (rota and day-2 lane) — authentic to C2M and WebLogic
  administration.
- Testing and Troubleshooting guides with explicit pass/fail gates (readiness gated, incidents
  handled, health stable), plus Best Practices for a smooth stabilization.

## What this delivers
A C2M go-live and hypercare the team can actually run — readiness proven, on-call structured,
incidents handled, health stable — from cutover through stabilization.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — rehearsed on a non-production dress
rehearsal before the live cutover, with a documented rollback for every production change.

## Outcome
Reliable C2M stabilization: a shaky, ad-hoc go-live — no readiness gate, ad-hoc on-call, unhandled
incidents, chaos at cutover — replaced by a runbook-driven cutover and hypercare with a proven
readiness gate, a structured on-call and escalation model, handled and recorded incidents, controlled
day-2 builds, and a green daily health snapshot, exiting to steady-state on evidence rather than the
calendar.
