# 1. Solution Overview — Workspace ONE to Intune Coexistence & Cutover Runbook

## What this runbook is
This is an operational runbook for the riskiest phase of a Workspace ONE to Microsoft Intune
migration: the window where **both MDMs are live at the same time**. It is not a feature guide — it
is the order of operations, the guardrails, the go/no-go gates, the per-cohort cutover sequence, and
the tested rollback that keep that window controlled instead of chaotic. The destination side
(Intune and Microsoft Entra) is given with exact navigation; Workspace ONE internals are deferred to
VMware's own documentation, because the source console changes independently of this runbook.

## Why coexistence is the dangerous part
During a migration you cannot flip an entire fleet at once, so for a period each device is in transit
between two management authorities. Three things break in that period:

- **Double management** — a device that is still enrolled in Workspace ONE while also enrolled in
  Intune can receive conflicting policy (two compliance engines, two sets of profiles, two app
  catalogs), get pushed contradictory settings, or silently drop one authority's payloads.
- **Conditional Access lockouts** — if Microsoft Entra Conditional Access starts requiring a
  compliant or enrolled device before the device is actually managed by Intune and reporting
  compliant, users get locked out of email and apps mid-migration.
- **App and certificate conflicts** — the same app, Wi-Fi/VPN profile, or certificate delivered by
  both platforms can collide, duplicate, or revoke each other.

The *why* lives only in this Overview. Everything after this file is procedure.

## How the runbook works
1. Establish the `Coexistence Guardrails – Tenant – Configure` so the two platforms cannot fight:
   one compliance authority, scoped Conditional Access, and a no-double-targeting rule for apps and
   profiles.
2. Define cohorts and their order with the `Cohort Cutover Order – Fleet – Pilot` plan — small,
   low-risk groups first; high-impact groups last.
3. For each cohort, run the `Cutover Sequence – Cohort – Validate` steps behind the
   `Go/No-Go Checklist – Cohort – Validate`. A cohort only proceeds if every gate passes.
4. If a gate fails, execute the `Rollback Plan – Cohort – Validate` to return the cohort to
   Workspace ONE management with no user lockout.
5. Repeat per cohort, expanding only after each prior cohort is validated and stable.

## What you control with this runbook
- Which platform owns **device compliance** during coexistence (the single compliance authority).
- The **Conditional Access scope** so policies tighten only as devices actually become Intune-managed.
- The **cutover order** — cohort sequencing from pilot to fleet.
- The **go/no-go gates** that must pass before each cohort proceeds.
- The **rollback** path that reverses a cohort cleanly if a gate fails.

## What is in scope vs deferred
- **In scope, exact:** Intune (`https://intune.microsoft.com`) and Microsoft Entra
  (`https://entra.microsoft.com`) configuration — managed devices, Conditional Access, security
  groups, enrollment readiness, compliance.
- **Deferred to VMware documentation:** Workspace ONE UEM console navigation, unenrollment/retirement
  steps, smart-group and profile internals, and the Workspace ONE Intelligent Hub behavior. Where the
  runbook needs a Workspace ONE action it is flagged as `[WS1 — see VMware docs]` rather than
  invented.

## Limitations (be honest with buyers)
- This runbook governs the **coexistence and cutover** phase. Building the target estate (apps,
  configuration profiles, compliance policies, enrollment connectors) is the prerequisite work and is
  assumed complete or in progress per the category global requirements.
- It does **not** automate Workspace ONE-side unenrollment; that action is performed in the source
  console per VMware's documentation and is represented here as a flagged step.
- Conditional Access changes affect live sign-ins; every CA change in this runbook is **scoped to a
  cohort group**, never the whole tenant, until the final expand stage.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand**, with a **per-cohort go/no-go gate and a tested
> rollback** at the Validate step. No cohort expands until the prior cohort passes its gate. This is
> the repeatable way: assign the guardrails once, then repeat the cohort sequence everywhere.
