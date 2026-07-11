# Executive Summary — Onboarding Accelerator: Microsoft Defender for Identity

**White-label · Defender**

Most tenants that own Microsoft Defender for Identity (MDI) never finish onboarding it. A sensor is installed on one domain controller, the directory service account is half-configured, honeytokens and sensitive-entity tagging are skipped, and the identity posture (ISPM) recommendations sit un-triaged. The result is an **identity threat detection & response (ITDR)** capability that looks "on" in the portal but sees only a fraction of Active Directory — and nobody has ever confirmed a detection actually fires. This accelerator onboards Defender for Identity **end to end**: it deploys sensors on every domain controller (and AD FS / AD CS where present), configures the read-only **Directory Service Account (DSA)**, plants and tags **honeytokens**, tags **sensitive entities**, turns on and triages **identity posture (ISPM)**, and **validates detections** — piloted first on one domain controller, validated, then expanded to the rest.

This is a complete, **deploy-it-today** package written for an administrator with no prior MDI experience. It onboards a **pilot domain controller first**, keeps any response action **approval-gated**, and never removes an existing control to "test."

## What you get
- A plain-language **Solution Overview** of MDI sensors, the DSA, honeytokens, sensitive tags, ISPM posture, and detections.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered steps — prepare the DSA, install the pilot sensor, tag entities, plant honeytokens, enable ISPM, validate — pilot-first.
- Five **PowerShell scripts** (Microsoft Graph Security + AD read helpers) plus **KQL advanced-hunting** queries for readiness discovery, sensor/DSA/tagging validation, posture & coverage reporting, a `-WhatIf`-gated honeytoken/sensitive-entity helper, and an identity-detection validation hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A validated, monitored Defender for Identity deployment delivering **ITDR** — sensors healthy on every domain controller, the DSA configured, honeytokens planted and tagged, sensitive entities marked, ISPM recommendations triaged, and detections proven to fire — onboarded in a ring and expanded with confidence, not a half-configured console.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — prepare the DSA and pick a pilot DC, install and health-check one sensor, tag entities and plant honeytokens, validate a detection fires, then expand sensor-by-sensor.

## Boundary
This solution **onboards the Defender for Identity pillar itself**. It is distinct from the unified Defender XDR onboarding accelerator (which brings all four pillars into `security.microsoft.com`) and from the SOC/Sentinel integration solutions — cross-reference those, do not duplicate them. Incident-response decisions, automated-response guardrails, and licensing determinations remain the customer's security, operations, and licensing functions; this guide provides the technical configuration.

## Effort
A competent administrator can complete the pilot-DC sensor install and detection validation in a focused engagement, then expand across the remaining domain controllers on a controlled change cadence. Sensor rollout scales with domain-controller count and change-window availability.
