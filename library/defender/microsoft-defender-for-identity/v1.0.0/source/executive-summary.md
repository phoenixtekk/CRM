# Executive Summary — Microsoft Defender for Identity

**White-label · Defender**

Identity is the top attack surface — almost every intrusion that reaches an enterprise moves *through* Active Directory. Yet Microsoft Defender for Identity (MDI), the **identity threat detection & response (ITDR)** pillar of Microsoft Defender, is routinely left half-finished: a sensor on one domain controller, a partly-configured Directory Service Account, no honeytokens, un-triaged identity posture (ISPM), a team that has never investigated a real identity alert, and value nobody has ever proven to the business. The console looks "on," but it sees a fraction of AD and no one is confident driving it.

This is the **complete Microsoft Defender for Identity solution** — one product that takes MDI end to end across its whole lifecycle:

1. **Deploy it right** — install sensors on every domain controller (and AD FS / AD CS where present), configure the read-only Directory Service Account (DSA), tag sensitive Tier-0 entities, plant and tag honeytokens, turn on and triage identity posture (ISPM), and validate that detections actually fire — piloted on one DC first, then expanded.
2. **Enable the team** — five hands-on labs that take your admins and SOC analysts from "we have it" to "we operate it": reading identity attack paths, recognizing recon and lateral-movement detections, deploying honeytokens, working ISPM, and running a clean, approval-gated investigation — with a runbook and KQL pack they keep.
3. **Prove the value** — a guided, in-tenant proof of concept that generates **benign, simulated** signal (harmless read-only directory enumeration plus a honeytoken touch — never a real attack), demonstrates the headline ITDR capabilities on that signal, scores the result against your criteria, and cleanly tears the PoC scope down.

Written for a competent admin with no prior MDI experience, this is a **deploy-it-today** package. Everything disruptive is **pilot-first** and **approval-gated**; response actions stay approval-gated throughout; and no existing AD control is ever removed to "test."

## What you get
- A plain-language **Solution Overview** of MDI — sensors, the DSA, honeytokens, sensitive tags, ISPM posture, detections, the operator console, and how a safe PoC proves it.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (category-wide ones live in `global-requirements-defender.md`).
- An **Implementation Guide** that is one continuous playbook: deploy the pilot sensor → tag entities and plant honeytokens → enable/triage ISPM → run the five enablement labs → run the guided PoC → expand across the fleet.
- Six **automation assets**: read-only discovery, validation, and posture/scorecard reporting (Microsoft Graph Security), a `-WhatIf`-gated deploy/rollback helper (sensitive-entity and honeytoken tagging), a **benign** PoC test-signal generator, and a **KQL advanced-hunting pack** for the identity tables.
- **Testing**, **Troubleshooting**, and **Best-Practices + where-to-go-next** guides for a confident rollout.

## What this delivers
A **fully sensored, team-ready, value-proven** Defender for Identity delivering ITDR — sensors healthy on every domain controller, the DSA configured, honeytokens planted, Tier-0 tagged, ISPM triaged, detections proven to fire, a team that can investigate unaided, and a scorecard the business can stand behind — the whole lifecycle in one package, not a half-configured console.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — assess readiness (license, roles, DCs, DSA), configure the DSA and portal settings, pilot one DC (sensor, tags, honeytokens), validate that detections fire and the team can operate, then expand sensor-by-sensor with response kept approval-gated until trusted.

## Boundary
This solution deploys, enables, and proves the **Defender for Identity pillar itself**. It is distinct from the unified **Microsoft Defender XDR — Unified Onboarding** solution (which brings all four pillars into `security.microsoft.com`), the **SOC Operations — Sentinel + Defender XDR** solution, and the **Advanced Threat Hunting (KQL)** solution — cross-reference those, do not duplicate them. Incident-response, automated-response guardrail, regulatory, and licensing determinations remain the customer's security, operations, and compliance functions; this guide provides the technical configuration and the operating skill.

## Effort
A competent administrator can complete the pilot-DC deployment and detection validation in a focused engagement, run the five enablement labs in a one- to two-day session, and complete the guided PoC on the same pilot DC — then expand across the remaining domain controllers on a controlled change cadence. Sensor rollout scales with domain-controller count and change-window availability.
