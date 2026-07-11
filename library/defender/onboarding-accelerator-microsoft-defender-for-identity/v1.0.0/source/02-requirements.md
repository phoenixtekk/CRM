# 2. Requirements Guide — Onboarding Accelerator: Microsoft Defender for Identity

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding Defender for Identity**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Identity activated in the portal
**Description:** MDI initialized for the tenant under `security.microsoft.com` → **Settings → Identities**.
**Why:** The workspace, sensor download, and access key only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Settings → Identities** loads with a workspace name. Run `MDIONB-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDI activation (Global Administrator required for first-service activation only).

## 2.2 Domain controllers reachable and supported for the sensor
**Description:** Domain controllers (and AD FS / AD CS servers where present) that meet the current MDI sensor OS/resource requirements and can reach the MDI service.
**Why:** The sensor runs *on* each DC — there is no agentless AD option; unsupported OS or blocked reach means no coverage.
**Verify:** `MDIONB-Discovery.ps1` lists every DC (`Get-ADDomainController`), its OS, and reachability hints. Confirm outbound HTTPS to the MDI service URLs. *Verify current sensor OS support and endpoint list in your tenant.*
**Implement-if-missing:** Bring the DC OS to a supported level, confirm resources (CPU/RAM/disk), and schedule a change window per DC.

## 2.3 Directory Service Account (DSA) — read-only, gMSA recommended
**Description:** A read-only **Directory Service Account** the sensors use to query AD for extra context. Current guidance recommends a **group Managed Service Account (gMSA)**.
**Why:** Without the DSA, several detections and enrichment are limited; a gMSA avoids a static password.
**Verify:** Confirm the gMSA `MDI Directory Service Account – Tenant – Prod` (or a standard read-only account) is created and installable on the sensor hosts. `MDIONB-Discovery.ps1` reports DSA readiness. *Verify current MDI DSA requirements.*
**Implement-if-missing:** Create the gMSA `MDI Directory Service Account – Tenant – Prod`, grant the sensor hosts permission to retrieve its password, and register it under **Settings → Identities → Directory Service accounts**.

## 2.4 A pilot domain controller chosen
**Description:** One domain controller selected as `MDI Sensor Host – Pilot DC – Pilot` to carry the first sensor.
**Why:** MDI onboarding is validated on one DC before the rest (per `global-requirements-defender.md` G6); a bad rollout on every DC at once is avoidable.
**Verify:** The pilot DC is named and change-approved; `MDIONB-Discovery.ps1` flags it. 
**Implement-if-missing:** Pick a healthy, representative DC and reserve a change window before installing the pilot sensor.

## 2.5 Sensitive entities identified for tagging
**Description:** The high-value accounts, groups, and servers (Tier-0 — Domain Admins, Enterprise Admins, DCs, ADFS/ADCS, PKI, backup, break-glass) to be **tagged sensitive** in MDI.
**Why:** MDI weights alerts on tagged sensitive entities more strongly; untagged Tier-0 dilutes signal.
**Verify:** A Tier-0 inventory exists; `MDIONB-Validate.ps1` reports which entities are already tagged. 
**Implement-if-missing:** Build the Tier-0 list and tag under **Settings → Identities → Entity tags → Sensitive** (or use `MDIONB-Honeytoken.ps1 -Mode SensitiveTag` in preview).

## 2.6 Honeytoken accounts planned
**Description:** Decoy user/computer accounts — `MDI Honeytoken – Decoy Identity – Pilot` — that no legitimate process ever authenticates or queries.
**Why:** Honeytokens are the highest-confidence, lowest-noise MDI detection: any touch is suspicious by definition.
**Verify:** The decoy accounts exist in AD and are unused; `MDIONB-Validate.ps1` confirms they are tagged as honeytokens. 
**Implement-if-missing:** Create idle decoy accounts with believable names, ensure nothing uses them, then tag them under **Settings → Identities → Entity tags → Honeytoken**.

## 2.7 Identity posture (ISPM) scope agreed
**Description:** Agreement to enable and triage **identity security posture management (ISPM)** recommendations surfaced by MDI into Microsoft Secure Score.
**Why:** ISPM finds exploitable AD/identity misconfigurations (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates); ignoring them leaves attack surface open.
**Verify:** `security.microsoft.com` → **Secure Score → Recommended actions** (Identity) shows MDI recommendations after sensors are healthy. `MDIONB-Report.ps1` lists them. *Verify current ISPM availability.*
**Implement-if-missing:** Confirm sensors are healthy (ISPM depends on sensor data), then review the Identity recommendations and assign owners.

## 2.8 Connected response workloads and governance
**Description:** For MDI response actions (disable user, force password reset), the on-prem/hybrid identity workloads must be connected, and a response-governance position agreed.
**Why:** Response actions are disruptive; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; actions are approval-gated. `MDIONB-Validate.ps1` reports the current action configuration. 
**Implement-if-missing:** Keep response actions approval-gated at first; *incident-response and automation guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] MDI activated in the portal — `MDIONB-Discovery.ps1`
- [ ] Domain controllers supported/reachable for the sensor
- [ ] DSA (gMSA) `MDI Directory Service Account – Tenant – Prod` prepared
- [ ] Pilot DC `MDI Sensor Host – Pilot DC – Pilot` chosen + change window
- [ ] Sensitive entities (Tier-0) identified for tagging
- [ ] Honeytoken accounts `MDI Honeytoken – Decoy Identity – Pilot` planned
- [ ] ISPM scope agreed — `MDIONB-Report.ps1`
- [ ] Response governance (approval-gated) documented
