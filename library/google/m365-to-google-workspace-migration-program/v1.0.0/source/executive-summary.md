# Executive Summary — Microsoft 365 → Google Workspace Migration Program & Wave Plan

Moving 150k+ users from Microsoft 365 to Google Workspace is a **program, not a project** — and it
fails without a disciplined wave plan, a coexistence design, and cutover governance. Most attempts
stumble the same way: no wave plan, so a big-bang cutover meets 150k-scale problems a pilot would have
caught; coexistence as an afterthought, so mail is lost or double-delivered while the estate is split;
ungoverned cutovers, so waves are declared done before validation completes and fail with no rollback;
and nothing proven first, so every wave re-does the same work. This flagship solution is the
**end-to-end migration program** that removes those failure modes.

This is a complete, run-it-as-a-program package written for a senior migration program lead and
architect. Every stage and artifact is named once and reused across every wave, so the same governed
runbook executes from the pilot through the last business unit — the repeatable way.

## What you get
- A **Solution Overview** of the migration operating model — discovery → design → coexistence → waves
  → cutover → hypercare — with workstream sequencing (identity first, coexistence before the first
  wave, mail/Drive/collaboration per wave, decommission last) and the named program artifacts.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: a source-estate
  baseline, a frozen target & tooling design, identity/provisioning into Google, a proven coexistence
  design, the wave plan, the per-wave runbook and gate, and the program cadence/RACI.
- An **Implementation Guide** of precise, ordered steps: baseline the estate, design the
  target/tooling and coexistence, segment 150k users into sized waves, author the per-wave cutover
  runbook (readiness → mail-flow/DNS → data move → validation → rollback) and the go/no-go gate, prove
  it on a pilot wave, then expand wave by wave with hypercare and decommission.
- **Five PowerShell scripts** — source-estate discovery for wave planning, per-wave readiness
  validation, a migration progress/coverage report, safe remediation, and a wave target-group builder
  — read-only against Microsoft Graph except the two write scripts, which default to `-WhatIf`.
- **Testing and Troubleshooting** guides with explicit per-wave gates, plus Best Practices for
  executing waves without rework — and a **Migration-Program playbook outline** the program runs from.

The program **references, rather than duplicates,** the individual mail, Drive, and chat migration
solutions: it sequences, segments, and governs them, keeping the tooling layer tool-agnostic so a
tooling change touches the per-service solution, not the program.

## What this delivers
A governed, wave-based migration: 150k+ users moved from Microsoft 365 to Google Workspace with
coexistence managed during the transition, every cutover gated by an explicit go/no-go, and the
cutover runbook proven on a pilot wave before any production business unit moves.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — with a per-wave go/no-go gate before
every subsequent wave, and coexistence decommissioned only when the estate is fully migrated.

## Outcome
The business moves off Microsoft 365 without breaking — waves execute the same proven runbook without
architectural rework, coexistence keeps mail and calendars working while the estate is split, and the
transition state is retired only after the final wave clears hypercare.
