# Executive Summary — Proof-of-Concept Kit: Microsoft Defender for Identity

**White-label · Defender**

Deciding on Microsoft Defender for Identity (MDI) shouldn't rest on a slide deck. This Proof-of-Concept (PoC) Kit stands up a **scoped, safe** proof of concept in your own tenant: it enables MDI on a single **pilot domain controller**, generates **benign, simulated** test signal (harmless read-only directory enumeration and a Microsoft **honeytoken** decoy account — never a real attack, exploit, or credential theft), demonstrates the headline **identity threat detection & response (ITDR)** capabilities on that signal, scores the result against your evaluation criteria, and then **cleanly tears the PoC back down**.

The kit is written for an administrator with no prior Defender experience. Everything is **pilot-scoped and reversible**: you deploy one sensor, prove the value, capture a scorecard, and uninstall — with the rest of Active Directory untouched.

## What you get
- A plain-language **Solution Overview** of MDI, ITDR, and how a PoC proves it on real-but-safe signal.
- A **Requirements Guide** of the PoC-specific prerequisites (the category-wide ones live in `global-requirements-defender.md`).
- An **Implementation Guide** — exact, ordered steps to deploy a pilot sensor, generate benign signal, demonstrate the detections, score, and tear down.
- Five **PowerShell scripts** (Microsoft Graph Security + directory enumeration) with **KQL advanced-hunting** queries: a `-WhatIf`-gated pilot enable/honeytoken helper, a **benign** recon test-signal generator, a demo/validate check, a criteria scorecard, and a `-WhatIf`-gated teardown.
- **Testing**, **Troubleshooting**, and **Best Practices** guides.

## What this delivers
A concrete, **in-tenant proof** that Microsoft Defender for Identity delivers ITDR — a pilot sensor raising a real detection from benign reconnaissance and honeytoken activity, the alert visible in the incident queue and on the **identity timeline**, the compromised-path and **UEBA** views populated, and a **scorecard** mapping each observed capability to your pass/fail criteria — all torn down cleanly at the end.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — here scoped as a PoC: assess readiness, deploy one pilot sensor, generate benign signal, validate and score, then either expand or tear down.

## Boundary
This is an **evaluation kit**, not a production rollout. It proves MDI on one pilot DC and then removes the sensor. Fleet-wide sensor deployment, AD hardening, and long-term operations are separate adjacent solutions (see *Where to go next*). All test signal is **benign and simulated** — read-only enumeration and a decoy account. Response actions are kept **approval-gated**; incident-response decisions remain the SOC/security team's.

## Effort
A competent administrator can complete the full PoC — deploy, signal, validate, score, and teardown — in a short, focused engagement on one domain controller in an approved change window. Sensor install requires a maintenance window on the pilot DC; everything else is reversible.
