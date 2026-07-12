# 2. Requirements Guide — Microsoft Defender for Identity

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to verify · How to implement if missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics workspace, response governance) are covered once in **`global-requirements-defender.md`** — read that first; the items below are **specific to deploying, operating, and proving Defender for Identity**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Identity activated in the portal
**Description:** MDI initialized for the tenant under `security.microsoft.com` → **Settings → Identities**.
**Why required:** The workspace, sensor download, and access key only appear after first-time activation; ITDR sensors, detections, honeytokens, and the identity timeline are the capabilities being deployed and proven.
**How to verify:** Sign in as a Security Administrator and confirm **Settings → Identities** loads with a workspace name. Admin center → **Billing → Licenses** shows Defender for Identity. Run `MDIFULL-Discovery.ps1`. *Verify current plan availability in your tenant.*
**How to implement if missing:** Assign the Defender for Identity plan (often bundled in M365 E5 / E5 Security) and complete the one-time MDI activation (Global Administrator required for first-service activation only).

## 2.2 Domain controllers reachable and supported for the sensor
**Description:** Domain controllers (and AD FS / AD CS servers where present) that meet the current MDI sensor OS/resource requirements and can reach the MDI service.
**Why required:** The sensor runs *on* each DC — there is no agentless AD option; unsupported OS or blocked reach means no coverage.
**How to verify:** `MDIFULL-Discovery.ps1` lists every DC (`Get-ADDomainController`), its OS, and reachability hints. Confirm outbound HTTPS to the MDI service URLs. *Verify current sensor OS support and endpoint list in your tenant.*
**How to implement if missing:** Bring the DC OS to a supported level, confirm resources (CPU/RAM/disk), and schedule a change window per DC.

## 2.3 Directory Service Account (DSA) — read-only, gMSA recommended
**Description:** A read-only **Directory Service Account** the sensors use to query AD for extra context. Current guidance recommends a **group Managed Service Account (gMSA)**, named `MDI Directory Service Account – Tenant – Prod`.
**Why required:** Without the DSA, several detections and enrichment are limited; a gMSA avoids a static password.
**How to verify:** Confirm the gMSA is created and installable on the sensor hosts. `MDIFULL-Discovery.ps1` reports DSA readiness. *Verify current MDI DSA requirements.*
**How to implement if missing:** Create the gMSA `MDI Directory Service Account – Tenant – Prod`, grant the sensor hosts permission to retrieve its password, and register it under **Settings → Identities → Directory Service accounts**.

## 2.4 A pilot domain controller chosen
**Description:** One domain controller selected as `MDI Sensor Host – Pilot DC – Pilot` to carry the first sensor and to host the enablement labs and the PoC.
**Why required:** Deployment is validated on one DC before the rest (per `global-requirements-defender.md`); a bad rollout on every DC at once is avoidable, and a single pilot DC keeps the PoC scope reversible.
**How to verify:** The pilot DC is named and change-approved; `MDIFULL-Discovery.ps1` flags it.
**How to implement if missing:** Pick a healthy, representative (or non-critical / lab) DC and reserve a change window before installing the pilot sensor.

## 2.5 Sensitive entities identified for tagging
**Description:** The high-value accounts, groups, and servers (Tier-0 — Domain Admins, Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, break-glass) to be **tagged sensitive** as `MDI Sensitive Entities – Tier0 – Prod`.
**Why required:** MDI weights alerts on tagged sensitive entities more strongly; untagged Tier-0 dilutes signal.
**How to verify:** A Tier-0 inventory exists; `MDIFULL-Validate.ps1 -Check Sensitive` reports which entities are already tagged.
**How to implement if missing:** Build the Tier-0 list and tag under **Settings → Identities → Entity tags → Sensitive** (or preview with `MDIFULL-Deploy.ps1 -Mode SensitiveTag`).

## 2.6 Honeytoken accounts planned
**Description:** Dormant, unused decoy accounts — `MDI Honeytoken – Decoy Identity – Pilot` — that no legitimate process ever authenticates or queries.
**Why required:** Honeytokens are the highest-confidence, lowest-noise MDI detection: any touch is suspicious by definition, which also makes them the crisp trigger for the PoC.
**How to verify:** The decoy accounts exist in AD and are unused (no recent sign-ins); `MDIFULL-Discovery.ps1` lists candidate no-activity accounts (read-only) and `MDIFULL-Validate.ps1 -Check Honeytoken` confirms tagging.
**How to implement if missing:** Create idle decoy accounts with believable names (e.g. `svc-legacy-backup` in `contoso.com`), ensure nothing uses them, then tag them under **Settings → Identities → Entity tags → Honeytoken**. *Do not tag a real, in-use account.*

## 2.7 Identity posture (ISPM) scope agreed
**Description:** Agreement to enable and triage **Identity Security Posture Management (ISPM)** recommendations surfaced by MDI into Microsoft Secure Score / Exposure management.
**Why required:** ISPM finds exploitable AD/identity misconfigurations (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates); ignoring them leaves attack surface open. Lab 4 works these recommendations.
**How to verify:** `security.microsoft.com` → **Secure Score → Recommended actions** (Identity) shows MDI recommendations after sensors are healthy. `MDIFULL-Report.ps1` lists them. *Verify current ISPM availability; assessments populate over hours to a few days after sensors report.*
**How to implement if missing:** Confirm sensors are healthy (ISPM depends on sensor data), allow warm-up, then review the Identity recommendations and assign owners.

## 2.8 Advanced-hunting read access (identity tables)
**Description:** Operators can open **Advanced hunting** in the Defender portal and via the Graph Security API (`ThreatHunting.Read.All`) query the `Identity*` tables.
**Why required:** Detection validation, the enablement labs, and the PoC scorecard confirm the signal landed in `IdentityInfo`, `IdentityLogonEvents`, `IdentityQueryEvents`, `IdentityDirectoryEvents`, and `AlertInfo`.
**How to verify:** **Hunting → Advanced hunting** → run `IdentityInfo | take 5`; confirm rows. `MDIFULL-Validate.ps1` returns rows.
**How to implement if missing:** Grant the running account **Security Reader** (or higher) plus hunting permission, and consent to the read-only hunting scope.

## 2.9 A test workstation and test account for benign PoC signal
**Description:** A non-privileged, domain-joined **test workstation** and a **test account** from which to run harmless read-only directory enumeration for the PoC.
**Why required:** The benign recon signal (LDAP/`net`/`nltest`) must originate from a real client so the sensor observes it; a dedicated test account keeps the signal attributable and the teardown clean.
**How to verify:** You can sign in to a domain-joined test workstation with a test account and run `net group` / `nltest` queries.
**How to implement if missing:** Provision a test workstation and a low-privilege test account before the PoC phase.

## 2.10 Evaluation criteria agreed for the PoC
**Description:** A short, written list of what "pass" means — e.g. *the reconnaissance alert fires within N minutes, appears on the identity timeline, is queryable in hunting, and the honeytoken activity is flagged.*
**Why required:** A PoC is only conclusive if the bar is set **before** you run it; the scorecard maps observations to these criteria.
**How to verify:** A criteria list (5–8 items) exists; `MDIFULL-Report.ps1 -Scorecard` accepts it as input.
**How to implement if missing:** Draft the criteria with the evaluating stakeholders before the PoC phase. *What counts as "good enough" is the customer's decision.*

## 2.11 Facilitator and attendee roles for the enablement labs
**Description:** One **facilitator** (Security Administrator) to drive the single configuration action (tagging the honeytoken); **attendees** with **Security Reader** (plus hunting) to follow along read-only.
**Why required:** Least privilege — only the facilitator needs a configuration action; everyone else learns read-only and rehearses response in a **simulate / approval-gated** posture.
**How to verify:** Entra → **Roles and administrators** — confirm the facilitator holds Security Administrator and attendees hold Security Reader.
**How to implement if missing:** Assign the roles before the session; keep write/response roles reserved for the approval-gated response rehearsal only.

## 2.12 Connected response workloads and governance
**Description:** For MDI response actions (disable user, force password reset), the on-prem/hybrid identity workloads must be connected, and a response-governance position agreed.
**Why required:** Response actions are disruptive; the organization decides the guardrails (per `global-requirements-defender.md`).
**How to verify:** A documented response policy exists; actions are approval-gated. `MDIFULL-Validate.ps1` / `MDIFULL-Report.ps1` report the current configuration.
**How to implement if missing:** Keep response actions approval-gated at first; *incident-response and automation-guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] MDI activated in the portal — `MDIFULL-Discovery.ps1`
- [ ] Domain controllers supported/reachable for the sensor
- [ ] DSA (gMSA) `MDI Directory Service Account – Tenant – Prod` prepared
- [ ] Pilot DC `MDI Sensor Host – Pilot DC – Pilot` chosen + change window
- [ ] Sensitive entities `MDI Sensitive Entities – Tier0 – Prod` identified
- [ ] Honeytoken accounts `MDI Honeytoken – Decoy Identity – Pilot` planned
- [ ] ISPM scope agreed — `MDIFULL-Report.ps1`
- [ ] Advanced-hunting read access (`ThreatHunting.Read.All`)
- [ ] Test workstation + test account for benign PoC signal
- [ ] PoC evaluation criteria written — `MDIFULL-Report.ps1 -Scorecard`
- [ ] Facilitator (Sec Admin) + attendees (Sec Reader) for the labs
- [ ] Response governance (approval-gated) documented
