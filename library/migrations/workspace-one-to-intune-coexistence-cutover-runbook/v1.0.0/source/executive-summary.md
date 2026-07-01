# Executive Summary — Workspace ONE to Intune Coexistence & Cutover Runbook

During a Workspace ONE to Microsoft Intune migration you inevitably run **both MDMs at once**, and
that overlap is where migrations break: devices end up double-managed, Conditional Access locks users
out mid-transition, and apps and certificates collide. Without a runbook, the coexistence window is
improvised — and improvisation on live production devices is how a migration turns into an outage.

This is the operational runbook for that window. It is not a feature guide; it is the order of
operations, the guardrails, the go/no-go gates, the per-cohort cutover sequence, and the tested
rollback that keep both platforms running safely in parallel until every device has cleanly cut over.

## What you get
- A **Solution Overview** of the coexistence model and the three risks it controls — double
  management, Conditional Access lockouts, and app/certificate conflicts — and *why* each matters.
- A **Requirements Guide** with verify / implement-if-missing for every coexistence prerequisite.
- An **Implementation Guide** of precise, ordered steps: establish guardrails, define cohorts and
  order, run the per-cohort cutover sequence behind a go/no-go gate, roll back on failure, then expand.
- Five **PowerShell scripts** for dual-management discovery, per-device cutover-readiness validation,
  a coexistence/cutover status report, a safe rollback helper, and a cohort group builder.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates.

## What this delivers
A controlled coexistence-and-cutover process: a single compliance authority, Conditional Access
scoped to one cohort at a time, a no-double-targeting rule for apps and profiles, a risk-ordered
cohort sequence, a go/no-go gate before and after each cutover, and a rollback proven on the pilot
before any production wave. Workspace ONE internals are deferred to VMware's documentation; the
Intune and Microsoft Entra side is given with exact navigation.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a per-cohort go/no-go gate and a tested
rollback at the Validate step. This is the repeatable way: assign the guardrails once, then repeat the
cohort sequence everywhere.

## Outcome
A calm migration window instead of a chaotic one — guardrails against double management, gated
cutovers, a per-cohort sequence, and a tested rollback — proven on a pilot cohort before you scale.
