# Executive Summary — Enablement Kit: Microsoft Defender for Identity

**White-label · Defender · Enablement / Training deliverable**

A licensed tool only pays off when the team can drive it. Many organizations turn on **Microsoft Defender for Identity (MDI)**, then leave it half-used because no one on the team is confident with the console, the detections, or the investigation workflow. This is a **structured enablement enablement kit** that takes your admins and SOC analysts from "we have it" to "we operate it" — through concepts, **guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**.

This is a training deliverable, not a deployment project. It assumes MDI sensors are (or are being) onboarded — the *how-to-onboard* work lives in the catalog's Defender XDR onboarding solution — and focuses on the **operating skills**: reading identity attack paths, recognizing lateral-movement and reconnaissance detections, deploying and monitoring **honeytokens**, working the **Identity Security Posture Management (ISPM)** recommendations, and running a clean investigation. Every lab is **read-only or preview-first**, so a team can learn safely in a pilot without disrupting the tenant.

## What you get
- A plain-language **Solution Overview** of Defender for Identity — what it is, how the sensors and the identity threat detections work, and the console/workflows an operator uses daily.
- A **Requirements Guide** covering the enablement-kit-specific prerequisites (a lab environment, sensor health, ISPM data) with verify / implement-if-missing for each.
- An **Implementation Guide** that is the **facilitator + student runbook** — five guided labs, each with named objects, exact portal navigation, and explicit pass/fail checks.
- Five **lab-helper assets**: read-only PowerShell discovery/validation/report scripts (Microsoft Graph Security) plus a **KQL query pack** for advanced hunting across the identity tables.
- A **Testing / knowledge-check** guide and a **Troubleshooting** guide so the enablement kit runs smoothly and the team can self-assess.
- A **Best-Practices + where-to-go-next** guide that points to the adjacent catalog areas (XDR onboarding, threat hunting, SOC operations).

## What this delivers
A team that can **confidently operate Microsoft Defender for Identity**: they understand identity attack paths and the recon/lateral-movement detection families, they have deployed and verified a honeytoken, they can read and act on ISPM recommendations, and they can run an identity investigation end to end — with a **runbook they keep** and reuse. The measurable outcome is competence: every attendee completes the labs and passes the knowledge-check.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — the enablement kit is delivered against a **pilot** scope (a lab or a small pilot ring), attendees validate each skill with a pass/fail gate, and the team then expands the practices to the full environment.

## Boundary
This enablement kit delivers the **technical enablement and the operating runbook**. It does **not** make incident-response, regulatory, or records determinations — those belong to the customer's SOC, security, and compliance functions. Response actions (disable a user, force password reset) are taught in an **approval-gated, simulate-first** posture. Some MDI capabilities are **license-** or **preview-gated**; those facts are flagged **verify current availability in your tenant**.

## Effort
A competent facilitator can run the full enablement kit in a focused one- to two-day engagement against a pilot; the labs and runbook are then reusable to onboard new analysts. No production change is required to complete the enablement kit — the labs are read-only or preview-first.
