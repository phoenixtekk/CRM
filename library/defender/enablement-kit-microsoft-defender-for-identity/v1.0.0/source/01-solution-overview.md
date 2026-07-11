# 1. Solution Overview — Enablement Kit: Microsoft Defender for Identity

## What this enablement kit is
This is an **enablement / training** deliverable, not a deployment project. It teaches your admins and SOC analysts to **operate Microsoft Defender for Identity (MDI)** confidently — through concept sessions, **five guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**. The output is a skilled team and a reusable runbook, not a new tenant configuration. The labs are designed to be run in a **pilot or lab environment** and are **read-only or preview-first**, so learning never disrupts production.

## What Microsoft Defender for Identity is (the concept)
Microsoft Defender for Identity is the **identity-threat detection and response** pillar of Microsoft Defender XDR. Lightweight **sensors** installed on **domain controllers**, **AD CS**, and **AD FS / Entra Connect** servers watch authentication and directory traffic and behavior, and send signal to the cloud service. MDI then:

- **Detects identity attacks** across the kill chain — **reconnaissance** (account/SPN/network enumeration), **compromised-credential** attempts (brute force, password spray), **lateral movement** (Pass-the-Hash, Pass-the-Ticket, overpass-the-hash), and **domain-dominance** techniques (DCSync, DCShadow, Golden Ticket, skeleton key).
- **Surfaces identity posture** through **Identity Security Posture Management (ISPM)** assessments — misconfigurations and risky practices (unconstrained delegation, legacy protocols, exposed credentials, dormant privileged accounts) with prioritized recommendations.
- **Lets you plant honeytokens** — deliberately un-used decoy accounts that should *never* authenticate; any activity on them is high-fidelity evidence of an intruder.
- **Feeds Defender XDR** — MDI alerts and identity signals correlate into unified **incidents**, enrich the **user/device entity pages**, and are queryable in **advanced hunting** (the `Identity*` tables).

The operator's job is to **read** those detections and posture recommendations, **investigate** them using the entity timelines, and **respond** through the approved workflow. That operating skill is what this enablement kit builds.

## How the operator uses it (the console and workflows)
1. **The unified portal** — `https://security.microsoft.com`. MDI alerts appear inside **Incidents & alerts**; identity settings live under **Settings → Identities**; posture lives under **Secure Score / Exposure management → ISPM recommendations**.
2. **Entity pages** — a **user** or **device** page shows the timeline, related alerts, lateral-movement paths, and investigation priority. This is the analyst's primary investigation surface.
3. **Advanced hunting** — the `IdentityLogonEvents`, `IdentityQueryEvents`, `IdentityDirectoryEvents`, and `IdentityInfo` tables let analysts hunt across identity telemetry with KQL.
4. **Honeytokens** — configured under **Settings → Identities → Entity tags → Honeytoken**; monitored via a dedicated detection and a saved hunting query.
5. **Response** — from an alert/entity, an analyst can **disable a user**, **force password reset**, or **suspend** (subject to the organization's approval gate); MDI also feeds automatic attack-disruption in XDR.

## The standard deployment model (how the enablement kit is run)
This enablement kit follows the same repeatable model as every catalog solution:

- **Assess** — confirm the lab/pilot scope, sensor health, licensing, and that ISPM data has populated (Lab 0 readiness check).
- **Configure** — set up the enablement kit objects: the honeytoken account, the saved hunting queries, and the facilitator/attendee roles.
- **Pilot** — run the five labs against the pilot scope; every attendee performs the steps.
- **Validate** — each lab has a **pass/fail gate** and the enablement kit ends with a **knowledge-check**.
- **Expand** — the team applies the runbook and practices to the full environment and onboards new analysts with it.

## The five labs (scope of the hands-on)
- **Lab 1 — Identity attack paths & the entity page.** Read a user/device entity page; interpret investigation priority and lateral-movement paths.
- **Lab 2 — Recon & lateral-movement detections.** Recognize the detection families; map them to MITRE ATT&CK; triage a simulated recon/lateral-movement alert.
- **Lab 3 — Honeytokens.** Choose, tag, and verify a honeytoken account; understand and monitor the honeytoken detection.
- **Lab 4 — ISPM posture.** Read the ISPM recommendations, prioritize them, and produce a remediation shortlist (no enforcement).
- **Lab 5 — Investigation end-to-end.** Run a full identity investigation using the entity timeline and advanced hunting; document findings; rehearse the **approval-gated** response.

## What is in scope
- Concept enablement, five guided labs, the take-home runbook, and the knowledge-check for **operating** MDI.
- Read-only discovery/validation/reporting helpers and a KQL hunting pack for the labs.

## What is out of scope (and where it lives)
- **Onboarding MDI sensors** and standing up Defender XDR — see the catalog's **Defender XDR Deployment / Unified Onboarding** solution.
- **Broad multi-pillar threat hunting** and SOC process design — see the **Threat Hunting** and **SOC / XDR operations** solutions.
- **Incident-response, regulatory, and records decisions** — these are the customer's SOC/security/compliance functions' determinations; the enablement kit teaches the technical workflow only.
- **Endpoint, email, and cloud-app detections** — covered by the sibling Defender enablement kits (Endpoint, Office 365, Cloud Apps).

## Connections and authentication used
- The **Microsoft Defender portal** (`https://security.microsoft.com`) for alerts, incidents, entity pages, Identity settings, ISPM, and advanced hunting.
- **Microsoft Graph Security / Graph** (via the lab PowerShell helpers, delegated **read** scopes such as `SecurityEvents.Read.All`, `SecurityAlert.Read.All`, `IdentityRiskEvent.Read.All`) for read-only discovery, validation, and reporting. *Confirm exact scopes and availability in your tenant.*
- No lab writes to production; response actions are **simulated / approval-gated**.
