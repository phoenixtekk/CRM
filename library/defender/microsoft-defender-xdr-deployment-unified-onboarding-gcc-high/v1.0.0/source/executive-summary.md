# Executive Summary — Microsoft Defender XDR Deployment & Unified Onboarding — Government (GCC High)

**White-label · Defender · Government (GCC High) edition**

**For US public-sector and Defense-Industrial-Base tenants.** This is the sovereign-cloud edition of the
unified Defender XDR onboarding method — the identical commercial approach, adapted for Microsoft's US
Government national cloud (`security.microsoft.us`, Azure Government `portal.azure.us`, `graph.microsoft.us`
/ DoD `dod-graph.microsoft.us`, `login.microsoftonline.us`, Intune `intune.microsoft.us`). Because GCC High
and DoD can lag commercial in **pillar, feature, connector, and preview availability**, every such point is
flagged **verify against current Microsoft Government documentation**, and the edition ships a dedicated
`gcc-high-parity-notes.md` covering endpoints, parity gaps, and FedRAMP High / DoD IL4-5 / CMMC / ITAR
data-residency context.

Most tenants already own Microsoft Defender XDR but run it as four disconnected point products — Defender for Endpoint in one console, Defender for Identity in another, Defender for Office 365 in the Exchange/email world, and Defender for Cloud Apps somewhere else. A modern attack that moves **identity → endpoint → email → cloud** is seen only in fragments, and each console only tells part of the story. This solution onboards all four pillars into the **unified Defender portal at `security.microsoft.us`**, turns on **cross-pillar incident correlation**, sets a **unified RBAC** role model, and establishes a **Secure Score baseline** — so one portal sees the whole attack.

This is a complete, **deploy-it-today** package written for an administrator with no prior Defender XDR experience. It onboards a **pilot ring first**, keeps automated response in an **approval/simulate** posture until trusted, and never disables an existing control to "test."

## What you get
- A plain-language **Solution Overview** of the four pillars, the unified portal, cross-domain correlation, unified RBAC, and Secure Score.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered portal steps — onboard Endpoint, deploy Identity sensors, activate Office 365 and Cloud Apps, wire unified RBAC, and baseline Secure Score, pilot-first.
- Five **PowerShell scripts** (Microsoft Graph Security + Az) plus **KQL advanced-hunting** queries for readiness discovery, per-pillar validation, coverage/Secure-Score reporting, a `-WhatIf`-gated pilot-ring onboarding helper, and a cross-pillar correlation hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Four Defender pillars — **Endpoint (MDE)**, **Identity (MDI)**, **Office 365 (MDO)**, and **Cloud Apps (MDCA)** — onboarded into the single portal at `security.microsoft.us`, **unified incident correlation** stitching alerts from all pillars into one incident, a **unified role-based access** model so analysts get one consistent permission set, and a **Secure Score baseline** you can trend — all proven on a pilot ring before tenant-wide expansion.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — onboard a pilot ring, keep automated response approval-gated, validate correlation, then expand.

## Boundary
This solution **onboards the Defender XDR suite itself** into the unified portal. It is distinct from a SIEM-integration engagement that streams XDR into Microsoft Sentinel — that is a separate, adjacent solution. Incident-response decisions, automated-response guardrails, and licensing determinations remain the customer's security, operations, and licensing functions; this guide provides the technical configuration. **Government-edition boundary:** GCC High/DoD **pillar, feature, and connector availability** must be confirmed against current Microsoft Government documentation, and the **accreditation boundary / impact-level** determination is the customer's ISSO/compliance decision — this guide supplies the technical method, not the authorization.

## Effort
A competent administrator can complete the pilot-ring onboarding and validation in a focused engagement, then expand on a controlled cadence. Sensor deployment on domain controllers and endpoint onboarding scale with device/DC count.
