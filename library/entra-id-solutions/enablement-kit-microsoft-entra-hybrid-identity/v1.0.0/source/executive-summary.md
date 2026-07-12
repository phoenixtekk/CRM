# Executive Summary — Enablement Kit: Microsoft Entra Hybrid Identity

Entra ID Solutions · Enablement Kit (self-guided training)

Hybrid identity — the bridge between on-premises Active Directory and Microsoft Entra ID — breaks in
subtle, expensive ways: the wrong sync scope, a mismatched source anchor, a poorly chosen
authentication method, or a hybrid join that never completes. Most of those failures trace back to a
team that never internalized how the pieces fit. This Enablement Kit teaches hybrid identity on
Microsoft Entra as a self-guided training deliverable — concepts, guided hands-on labs, a health-check
lab, a take-home runbook, and a knowledge-check — so a competent admin team can run hybrid identity
confidently and diagnose it when it drifts.

## How this differs from the implementation product (important)
There is a separate, deeper **implementation** solution — *Hybrid Identity with Active Directory &
Microsoft Entra Connect* (HYBID) — that installs and configures production hybrid identity end to end.
**This kit is the team-enablement / labs companion to it, not a replacement.** It teaches the *why*
and rehearses the moving parts (sync engine choice, source anchor, UPN hygiene, PHS/PTA/federation
trade-offs, hybrid join, hybrid Conditional Access, health checks) in a safe, read-only / preview-first
way. When the team is ready to build for real, hand off to HYBID. The two are cross-referenced
throughout.

## What you get
- A plain-language **Solution Overview** of hybrid identity: Entra Connect vs Cloud Sync, sync scope,
  source anchor, UPN hygiene, and the three authentication methods, mapped to the standard deployment
  model (Assess → Configure → Pilot → Validate → Expand).
- A **Requirements** guide of the enablement-specific prerequisites (a read-only lab vantage point, the
  right modules) — the category-level prerequisites live in the separate global requirements file.
- A guided **Implementation** guide: ordered, hands-on labs on engine selection, sync scope / source
  anchor / UPN inspection, authentication-method trade-offs and staged-rollout patterns, hybrid join,
  hybrid Conditional Access, and a **health-check lab**.
- **Testing** (a knowledge-check and lab-validation procedures) and **Troubleshooting** guides.
- Five lab helpers: read-only hybrid discovery, prerequisite validation, a hybrid-health scorecard
  report, a read-only hybrid health-check, and a KQL signal pack for hybrid sign-in analysis.
- A take-home **hybrid-identity runbook** distilled from the labs.

## The outcome
A team fluent in hybrid identity on Entra — sync, source anchor, authentication method, hybrid join,
and hybrid Zero Trust understood and rehearsed — holding a runbook and a health-check routine, with a
clear path into the HYBID implementation solution for production work.

## Effort
Self-paced. Plan roughly two to three focused days for a small admin team to work through the concepts
and all guided labs. The labs are read-only / inspection-first and do not require changing a
production sync configuration.
