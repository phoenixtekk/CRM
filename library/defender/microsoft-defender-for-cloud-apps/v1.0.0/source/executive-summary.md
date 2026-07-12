# Executive Summary — Microsoft Defender for Cloud Apps

**White-label · Defender · Complete lifecycle solution**

Most tenants that own Microsoft Defender for Cloud Apps (MDCA) run it as an empty console. The **app connectors** were never added, so the SaaS apps that hold the organization's data send no signal; **Cloud Discovery** was never wired to a log source, so shadow IT is invisible; **app governance** and **OAuth app** policies are off, so risky third-party app consents go unwatched; **session/access policies** via Conditional Access App Control were never created, so there is no real-time control over risky sessions — and even where it is switched on, the admins and SOC analysts have never been trained to drive it and the value was never proven to the people who paid for it. The result is a **cloud access security broker (CASB)** that is licensed but blind, or partly wired and unloved.

This is the **complete Defender for Cloud Apps solution** — one product that takes MDCA the whole way, in three phases:

1. **Connect & Govern** — onboard MDCA end to end: API app connectors, Cloud Discovery, app governance and OAuth app policies, and session/access policies via Conditional Access App Control — piloted first, monitor-first, then expanded.
2. **Enable the team** — five guided, hands-on labs plus a take-home runbook and knowledge-check that take your admins and SOC analysts from "we have it" to "we operate it."
3. **Prove value** — a guided, scoped proof-of-concept that generates **benign** test signal, demonstrates the headline detections, and produces a decision scorecard — cleanly rolled back at the end.

It is written for an administrator with no prior MDCA experience. Every enforcing policy stays in **monitor / report-only** until validated, every disruptive or destructive action (block, revoke OAuth app, suspend session, teardown) is **`-WhatIf`-gated or approval-gated**, and no production access is ever blocked to "test."

## What you get
- A plain-language **Solution Overview** of app connectors, Cloud Discovery, app governance, OAuth app policies, and session/access control, and how the whole lifecycle fits together.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (the category-wide ones live in `global-requirements-defender.md`).
- An **Implementation Guide** covering all three phases — connect & govern, the five enablement labs, and the guided PoC — with every object named and reused verbatim.
- Six **deliverables**: read-only PowerShell (Microsoft Graph Security) for readiness, validation, and coverage/OAuth-risk reporting; a read-only OAuth-risk enumerator; a `-WhatIf`-gated PoC helper (enable → benign signal → teardown); and a **KQL advanced-hunting** pack.
- **Testing** (deployment validation + the enablement knowledge-check + the PoC gates) and **Troubleshooting** guides.

## What this delivers
A fully connected, team-ready, value-proven Defender for Cloud Apps: connectors streaming from priority SaaS apps, Cloud Discovery surfacing shadow IT, app governance and OAuth policies watching risky consents, session/access policies enforcing real-time control on a pilot scope, a **team that can operate all of it** with a runbook they keep, and a **scorecard** that proves the value — the whole CASB lifecycle in one package.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — connect apps and discovery, scope monitor-first policies to a pilot user group, validate signal and control, enable the team on the same pilot, prove value with a benign PoC, then expand tenant-wide.

## Boundary
This solution delivers the **Defender for Cloud Apps pillar itself** — onboarding, enablement, and a proof-of-concept. It is distinct from the unified **Defender XDR** onboarding accelerator (**DEFXDR**) and from the **Cloud-App DLP (Defender for Cloud Apps) — Microsoft Purview** solution that builds the data-loss-prevention program on top of the connected apps — cross-reference those, do not duplicate them. Data-classification, acceptable-use, app-sanctioning, and incident-response determinations remain the customer's compliance, security, and operations functions; this guide provides the technical configuration and the operating skills, not the decisions.

## Effort
A competent administrator can complete the pilot-scope connect & govern work and the guided PoC in a focused engagement, run the five enablement labs against the same pilot in a one- to two-day session, then expand tenant-wide on a controlled cadence. Connector rollout scales with the number of SaaS apps to govern. MDCA, app governance, and Conditional Access App Control are license-/preview-gated — **verify current availability in your tenant.**
