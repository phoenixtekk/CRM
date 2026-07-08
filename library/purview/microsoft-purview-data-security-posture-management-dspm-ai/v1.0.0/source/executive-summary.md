# Executive Summary — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

You cannot reduce data-security risk you cannot see — and generative AI has made that blind spot
dangerous. Microsoft 365 Copilot can surface any content a user already has access to, so years of
over-shared, unlabeled files that "nobody ever found" are suddenly one prompt away. This solution
implements **Data Security Posture Management (DSPM)** in Microsoft Purview to make the risk visible and
reduce it: the DSPM posture and recommendations, the sensitive-data risk across your estate, and **DSPM
for AI** — visibility into what Copilot and other AI apps can access, which prompts and responses touch
sensitive data, and the controls to reduce oversharing before and during AI adoption.

This is a complete, deploy-it-today package written for a competent Purview / compliance administrator,
using only the Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph — no
third-party tooling. Every high-impact change is piloted in **simulation/test** before it is enforced.

## What you get
- A plain-language Solution Overview of what DSPM and DSPM for AI show, the availability/licensing caveat
  for these evolving features, and the boundary between technical method and legal/records determination.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, DSPM roles,
  auditing, the labels + DLP foundation, Copilot/AI in scope, the sharing signal, and pilot discipline.
- An Implementation Guide of precise, ordered portal and PowerShell steps: read the posture, assess
  sensitive-data and AI/Copilot exposure, act on recommendations, pilot each reduction in
  simulation/test, validate, expand to enforce, and review on a recurring cadence.
- Five PowerShell scripts for scope/health checking, controls discovery, AI/oversharing exposure
  reporting, recommendation tracking, and safe oversharing reduction (read-only or `-WhatIf` by default).
- Testing and Troubleshooting guides, with an explicit enforcement gate, for a confident, safe rollout.

## What this delivers
A measured posture baseline across your data-security controls, a sensitive-data risk assessment, a
DSPM-for-AI exposure report of what Copilot/AI can reach and what it has touched, a prioritized set of
oversharing targets, and a validated reduction workflow — auto-labeling in simulation, DLP for AI in
test, and sharing restriction — that improves posture on re-measure rather than merely adding policies.

## The deployment model
Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).

## Outcome
Data-security risk made visible and reduced — posture measured, recommendations actioned, and Copilot/AI
oversharing surfaced and controlled — so data is safer before and during AI adoption. Feature
availability is flagged to verify in your tenant; regulatory, records, and legal determinations remain
with your governance functions.
