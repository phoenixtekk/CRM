# 1. Solution Overview — Proof-of-Concept Kit: Microsoft Defender for Identity

## What Microsoft Defender for Identity is
Microsoft Defender for Identity (MDI) is Microsoft's **identity threat detection & response (ITDR)** platform for on-premises Active Directory (and AD FS / AD CS / Entra Connect where present). Lightweight **sensors** installed directly on domain controllers watch AD traffic and behaviour and stream detections to the unified Defender portal at `security.microsoft.com`. Its headline capabilities are:

- **Reconnaissance detection** — enumeration of users, groups, and machines (LDAP/SAMR/DNS recon), the classic first step of an intrusion.
- **Lateral-movement & credential-attack detection** — Pass-the-Hash/Ticket, overpass-the-hash, DCSync, and suspicious authentication patterns.
- **Identity timeline & investigation** — a per-identity activity timeline stitched into Defender XDR incidents.
- **User & entity behavioural analytics (UEBA)** and **investigation-priority scoring**.
- **Honeytoken accounts** — decoy identities that should never be used, so *any* activity against them is a high-fidelity signal.

## What a Proof-of-Concept Kit is
A PoC Kit is a **customer-runnable evaluation**, not a production deployment and not a sales demo. Its job is to answer one question — *does MDI actually detect identity attacks against our AD?* — with evidence, safely, in your own tenant. It does that by:

1. **Enabling** MDI with a single **sensor on a pilot domain controller**.
2. **Generating benign test signal** — harmless, **read-only directory enumeration** (the same `net group` / `nltest` / LDAP queries an admin runs every day) to trigger reconnaissance detections, plus a Microsoft **honeytoken** decoy account whose use is a clean, high-fidelity trigger. **No real attack, exploit, credential theft, or malware is ever used.**
3. **Demonstrating** that the signal produces a real detection — an alert in the incident queue, an entry on the identity timeline, rows in advanced hunting, and UEBA scoring.
4. **Scoring** what you observed against your evaluation criteria.
5. **Tearing down** — uninstalling the pilot sensor and removing everything the PoC created.

## Why this matters
Identity is the modern battleground, and most breaches move *through* Active Directory. A vendor deck can't show you how MDI behaves against *your* DCs, *your* directory, and *your* admin patterns. A scoped PoC replaces "trust the deck" with "watch it catch the recon." Because it uses **one pilot sensor and benign signal**, the rest of AD is untouched and you get proof without a fleet-wide deployment before you've seen the value.

## How it works
1. **Assess** readiness with `POCMDI-Enable.ps1 -WhatIf` — MDI plan, admin roles, a Directory Service Account (DSA), a candidate pilot DC, and network reach.
2. **Configure & enable** — activate MDI, register the DSA `MDI PoC – DSA – Pilot`, and install the sensor `MDI PoC Sensor – Pilot DC – Pilot` on one domain controller in a change window. Tag a **honeytoken** decoy account `MDI PoC Honeytoken – Pilot`.
3. **Generate benign signal** with `POCMDI-TestSignal.ps1` — run harmless read-only enumeration from a test workstation and touch the honeytoken account.
4. **Validate & demonstrate** with `POCMDI-Validate.ps1` — confirm the reconnaissance and honeytoken alerts reached the portal, the identity timeline, and hunting (`IdentityQueryEvents`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `AlertInfo`).
5. **Score** with `POCMDI-Scorecard.ps1` against your criteria.
6. **Tear down** with `POCMDI-Teardown.ps1 -WhatIf` first, then for real — untag the honeytoken, uninstall the sensor, remove the DSA, resolve test alerts.

## What you can control
- **Pilot sensor** — one domain controller only; the rest of the fleet is untouched.
- **Which capabilities to prove** — recon detection, honeytoken, identity timeline, UEBA, XDR correlation.
- **Response posture** — any response kept in an **approval/simulate** posture throughout the PoC.
- **Scorecard criteria** — the pass/fail bar you evaluate against.
- **Teardown** — full, reversible removal.

## Limitations (be honest with buyers)
- MDI is **license-gated** (Defender for Identity, often bundled in E5 / E5 Security). *Verify current plan availability in your tenant.*
- The **sensor runs on a domain controller** and requires resources, network reach, and a change window — it is not a portal-only toggle, and it cannot be installed agentlessly.
- Test signal is **benign and simulated only** — read-only enumeration and a decoy account. This proves the detection pipeline, not resilience to a real adversary (that is a red-team engagement, out of scope).
- Advanced-hunting tables and UEBA scoring **populate over time** — allow warm-up after sensor install before judging.
- This is a **PoC**, not a production rollout — it stays on one DC and is designed to be removed. Fleet-wide deployment is a separate solution.
- MDI improves detection; it does not replace AD hardening, tiered admin, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) for MDI activation, sensor management, honeytoken configuration, incidents, and the identity timeline.
- **Microsoft Graph Security** and the advanced-hunting API (`IdentityQueryEvents`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `AlertInfo`) for read-only validation and scoring.
- **Directory enumeration** (LDAP / `net` / `nltest`) from a test workstation for the benign recon signal.
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, **Domain Admin** (change window) for the one-time sensor install, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness → configure/activate MDI and install one pilot sensor → generate benign recon + honeytoken signal → validate the detections and score → expand or tear down.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, run here as a safe, reversible PoC with response kept approval-gated.
