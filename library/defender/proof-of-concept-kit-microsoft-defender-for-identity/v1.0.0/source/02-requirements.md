# 2. Requirements Guide — Proof-of-Concept Kit: Microsoft Defender for Identity

Verify **every** requirement before enabling anything. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running a scoped MDI proof of concept**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Identity plan available to activate
**Description:** A licensed **Defender for Identity** plan the tenant can activate for the PoC.
**Why:** ITDR sensors, detections, and the identity timeline are the capabilities being proven; without the plan MDI cannot be activated.
**Verify:** Admin center → **Billing → Licenses** shows Defender for Identity; `security.microsoft.com` → **Settings → Identities** loads. Run `POCMDI-Enable.ps1 -WhatIf`. *Verify current plan availability in your tenant.*
**Implement-if-missing:** Assign the Defender for Identity plan (often bundled in M365 E5 / E5 Security) before enabling.

## 2.2 A pilot domain controller for the sensor
**Description:** One **domain controller** to host the pilot sensor `MDI PoC Sensor – Pilot DC – Pilot`, with a supported OS, adequate resources, and a **change window** to install.
**Why:** MDI detects on-prem identity attacks from a sensor installed directly on a DC; the PoC deliberately uses one DC so it can be uninstalled cleanly.
**Verify:** `POCMDI-Enable.ps1 -WhatIf` lists candidate DCs; confirm OS support, resources, and a maintenance window. *Verify current sensor OS support and sizing.*
**Implement-if-missing:** Choose a non-critical DC (or a lab DC), confirm prerequisites, and schedule the change window.

## 2.3 Directory Service Account (DSA)
**Description:** A read-only **Directory Service Account** for MDI (gMSA recommended), named `MDI PoC – DSA – Pilot`.
**Why:** The sensor uses the DSA to query AD for additional context; without it, some detections are limited.
**Verify:** Confirm a gMSA (or standard read-only account) is created; `POCMDI-Enable.ps1 -WhatIf` notes DSA readiness. *Verify current MDI DSA requirements.*
**Implement-if-missing:** Create the gMSA and register it under **Settings → Identities → Microsoft Defender for Identity → Directory Service accounts**.

## 2.4 Network reach from the pilot DC to the MDI service
**Description:** Outbound HTTPS from the pilot DC to the Microsoft Defender for Identity service URLs.
**Why:** The sensor reports to the cloud service; blocked endpoints break sensor health and detections.
**Verify:** Confirm the documented MDI service URLs are allowed from the pilot DC. *Verify current endpoint list.*
**Implement-if-missing:** Allow the MDI service endpoints through proxy/firewall for the pilot DC.

## 2.5 A test workstation and test account for benign recon
**Description:** A non-privileged **test workstation** and a **test account** from which to run harmless read-only directory enumeration.
**Why:** The benign recon signal (LDAP/`net`/`nltest` enumeration) must originate from a real client so the sensor observes it; using a dedicated test account keeps the signal attributable and the teardown clean.
**Verify:** You can sign in to a domain-joined test workstation with a test account.
**Implement-if-missing:** Provision a test workstation and a low-privilege test account before Step 3.

## 2.6 A honeytoken decoy account
**Description:** A dormant, unused **decoy account** to tag as a honeytoken (`MDI PoC Honeytoken – Pilot`).
**Why:** A honeytoken should never be used legitimately, so any activity against it is a clean, high-fidelity detection — ideal for a PoC.
**Verify:** An unused AD account exists to tag; `POCMDI-Enable.ps1 -WhatIf` reports honeytoken status.
**Implement-if-missing:** Create (or pick) a dormant account and plan to tag it as a honeytoken in MDI settings. *Do not tag a real, in-use account.*

## 2.7 Evaluation criteria agreed up front
**Description:** A short, written list of what "pass" means — e.g. *the reconnaissance alert fires within N minutes, appears on the identity timeline, is queryable in hunting, and the honeytoken activity is flagged.*
**Why:** A PoC is only conclusive if the bar is set **before** you run it; the scorecard maps observations to these criteria.
**Verify:** A criteria list exists; `POCMDI-Scorecard.ps1` accepts it as input.
**Implement-if-missing:** Draft 5–8 criteria with the evaluating stakeholders before Step 1. *What counts as "good enough" is the customer's decision.*

## 2.8 Advanced-hunting read access
**Description:** Permission to run advanced-hunting queries via the portal and the Graph Security API (`ThreatHunting.Read.All`).
**Why:** The validate and scorecard scripts confirm the signal landed in `IdentityQueryEvents`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, and `AlertInfo`.
**Verify:** `security.microsoft.com` → **Hunting → Advanced hunting** runs a query; `POCMDI-Validate.ps1` returns rows.
**Implement-if-missing:** Grant the running account **Security Reader** (or higher) and consent to the read-only hunting scope.

---
## Checklist
- [ ] Defender for Identity plan available to activate — `POCMDI-Enable.ps1 -WhatIf`
- [ ] A pilot domain controller + change window for `MDI PoC Sensor – Pilot DC – Pilot`
- [ ] Directory Service Account `MDI PoC – DSA – Pilot` (gMSA)
- [ ] Network reach from the pilot DC to the MDI service URLs
- [ ] A test workstation and test account for benign recon
- [ ] A dormant honeytoken decoy account `MDI PoC Honeytoken – Pilot`
- [ ] Evaluation criteria agreed and written down — `POCMDI-Scorecard.ps1`
- [ ] Advanced-hunting read access (`ThreatHunting.Read.All`)
