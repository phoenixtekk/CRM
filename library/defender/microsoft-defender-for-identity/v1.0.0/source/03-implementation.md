# 3. Implementation Guide — Microsoft Defender for Identity

Follow these steps **in order**. Most configuration is in the **unified Defender portal** (`https://security.microsoft.com` → **Settings → Identities**); the sensor installs on the domain controllers themselves. This is one continuous playbook across three phases: **Phase A — Deploy** (onboard the pillar), **Phase B — Enable the team** (five labs), **Phase C — Prove the value** (guided PoC), then **Expand**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Prepare the DSA, install the sensor on **one pilot domain controller** first, tag entities and plant honeytokens, **validate that a detection actually fires**, enable the team on the pilot, prove the value with benign signal, and only then expand to the remaining DCs and AD FS/AD CS. Keep **response actions** approval-gated throughout. Never remove an existing AD control to "test."

## Naming (set once, reuse verbatim)
- Directory Service Account (gMSA): `MDI Directory Service Account – Tenant – Prod`
- Pilot sensor host / DC: `MDI Sensor Host – Pilot DC – Pilot`
- Sensitive-entity tag scope: `MDI Sensitive Entities – Tier0 – Prod`
- Honeytoken decoy account(s): `MDI Honeytoken – Decoy Identity – Pilot`
- Detection-validation saved query: `MDI Detection Validation – Tenant – Validate`
- Saved hunting queries (labs): `Recon – Identity – Hunt`, `LateralMovement – Identity – Hunt`, `Honeytoken – Identity – Hunt`, `Investigation – Identity – Hunt`
- ISPM remediation shortlist: `MDI ISPM Shortlist – Tier0 – Prod`
- Investigation findings doc: `MDI Investigation – Identity – Validate`
- PoC benign-signal tag: `MDI-TESTSIGNAL`
- PoC scorecard output: `MDI PoC Scorecard – Pilot DC – Validate`

> Portal navigation paths reflect the current Microsoft Defender portal. Microsoft moves menus periodically — *verify current navigation in your tenant*; the Troubleshooting guide lists moved-menu fallbacks (use global search for a feature name).

---

# Phase A — Deploy (onboard the pillar)

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDIFULL-Discovery.ps1` to capture current state: MDI activation/workspace, licensed-plan hints, admin roles, every domain controller and its OS, DSA readiness, existing sensor status, and candidate no-activity honeytoken accounts. Changes nothing.
3. Choose the pilot DC and record it as `MDI Sensor Host – Pilot DC – Pilot`. Reserve a change window.

## Step 2 — Activate MDI and prepare the Directory Service Account
1. `security.microsoft.com` → **Settings → Identities**. If MDI is not initialized, complete the one-time activation (Global Administrator, first time only) and note the **workspace** name.
2. Create the read-only gMSA `MDI Directory Service Account – Tenant – Prod` in AD, and grant the sensor host computer accounts permission to retrieve its password.
3. **Settings → Identities → Directory Service accounts → Add credentials** — register the gMSA. *Verify current MDI DSA requirements.*
4. Run `MDIFULL-Validate.ps1 -Check DSA` to confirm the DSA is registered.

## Step 3 — Install the pilot sensor (pilot DC)
1. **Settings → Identities → Sensors → Add sensor** — download the sensor package and copy the **access key**.
2. During the approved change window, copy the package to `MDI Sensor Host – Pilot DC – Pilot`, run the installer, and supply the **access key** when prompted.
3. Confirm outbound HTTPS from the DC to the MDI service URLs (per `global-requirements-defender.md`). *Verify current endpoint list.*
4. **Settings → Identities → Sensors** — confirm `MDI Sensor Host – Pilot DC – Pilot` shows **Running / Healthy**.
5. Run `MDIFULL-Validate.ps1 -Check Sensor` to confirm the pilot sensor is healthy and identity signal is flowing.

## Step 4 — Tag sensitive entities (Tier-0)
1. `security.microsoft.com` → **Settings → Identities → Entity tags → Sensitive**.
2. Add the Tier-0 accounts, groups, and servers as `MDI Sensitive Entities – Tier0 – Prod` (Domain/Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, break-glass).
3. Preview the change first with `MDIFULL-Deploy.ps1 -Mode SensitiveTag -InputCsv .\tier0.csv` (safe preview by default); apply only with `-Apply`.
4. Run `MDIFULL-Validate.ps1 -Check Sensitive` to confirm the entities are tagged.

## Step 5 — Plant and tag honeytokens
1. In AD, create the idle decoy account(s) `MDI Honeytoken – Decoy Identity – Pilot` with believable names; confirm **nothing legitimate uses them** (no logon scripts, services, or scheduled tasks).
2. `security.microsoft.com` → **Settings → Identities → Entity tags → Honeytoken** — add the decoy account(s).
3. Preview with `MDIFULL-Deploy.ps1 -Mode Honeytoken -InputCsv .\honeytokens.csv` (safe preview); apply with `-Apply`.
4. Run `MDIFULL-Validate.ps1 -Check Honeytoken` to confirm the accounts are tagged as honeytokens.

## Step 6 — Enable and triage identity posture (ISPM)
1. After the pilot sensor is healthy, `security.microsoft.com` → **Secure Score → Recommended actions** (or **Exposure management → Recommendations**), filter to **Identity** — MDI ISPM recommendations appear (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates). *Verify current ISPM availability; allow warm-up.*
2. Record the starting posture with `MDIFULL-Report.ps1 -SaveBaseline` and build the `MDI ISPM Shortlist – Tier0 – Prod` (top 3–5 by impact and effort); assign owners.
3. *Which posture items are "must-fix" and the remediation change-approval are the security/AD team's decisions — this guide surfaces the recommendations and the technical fix path, it does not enforce a change.*

## Step 7 — Validate detections on the pilot
1. Run `MDIFULL-Validate.ps1 -Check Signal` to execute `MDI Detection Validation – Tenant – Validate` — it confirms the identity tables (`IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents`) are streaming from the pilot sensor.
2. Trigger a **benign, controlled** detection: authenticate against or query the honeytoken `MDI Honeytoken – Decoy Identity – Pilot`, or run a Microsoft-documented safe simulation. Confirm an alert appears in `security.microsoft.com` → **Incidents & alerts**.
3. Confirm response actions remain **approval-gated** (nothing auto-acted). Complete the Phase-A tests in the Testing Guide before enabling the team.

---

# Phase B — Enable the team (five hands-on labs)

Run the labs in order against the **pilot** scope. All steps are **read-only or preview-first**; the one configuration action (already done in Step 5 — the honeytoken tag) and the response rehearsal are **facilitator-driven and approval-gated**. Every attendee performs the steps.

## Lab 0 — Readiness check
1. Facilitator signs in as **Security Administrator**; confirm the pilot sensor is **Healthy** (Step 3).
2. Run `MDIFULL-Discovery.ps1` and `MDIFULL-Validate.ps1` — confirm a healthy sensor, ISPM data present, hunting access, and read-scope consent. **Pass gate:** both green.

## Lab 1 — Identity attack paths & the entity page
1. Open **Assets → Identities** (or search a username). Open a **user** entity page for a pilot account and walk the panels: **Overview** (investigation-priority score, tags, risk), **Timeline** (authentications, alerts, directory changes), **Lateral movement paths** (how this identity could reach higher-privilege accounts).
2. Open a **device** (domain controller) entity page; note logons observed and related identities.
3. **Pass gate:** each attendee, on a second entity page, correctly points to the timeline, the lateral-movement path panel, and the investigation-priority score and explains each.

## Lab 2 — Recon & lateral-movement detections
1. Open **Incidents & alerts → Alerts**; filter **Service source = Defender for Identity**. Review the four detection families (recon, compromised credentials, lateral movement, domain dominance) and map each to its MITRE tactic.
2. Open **Hunting → Advanced hunting**. Paste the **Recon** and **Lateral movement** sections of `MDIFULL-LabQueries.kql`, run them, and **Save as** `Recon – Identity – Hunt` and `LateralMovement – Identity – Hunt`.
3. Take one alert (or query hit) through triage: what identity, what technique, is it expected, what would escalate it.
4. **Pass gate:** each attendee maps a chosen detection to its MITRE tactic and states the first two triage questions.

## Lab 3 — Honeytokens
1. Confirm the decoy `MDI Honeytoken – Decoy Identity – Pilot` is tagged (from Step 5) and has **no legitimate sign-ins**.
2. Explain the model: a honeytoken should *never* authenticate, so **any** logon/query is high-fidelity; MDI raises **"Honeytoken activity"** when it is touched.
3. In **Advanced hunting**, paste the **Honeytoken** section of `MDIFULL-LabQueries.kql`, run it, and **Save as** `Honeytoken – Identity – Hunt`.
4. *(Optional, lab environment only)* From a test workstation, attempt a benign authentication as the honeytoken to generate the detection, then observe the alert. **Do not do this in production.**
5. **Pass gate:** the saved query returns the account and attendees can explain why any activity is a real signal.

## Lab 4 — ISPM posture (read and prioritize, no enforcement)
1. Open **Secure Score** (or **Exposure management → Recommendations**) and filter to **Identity** / **Defender for Identity**. Walk the common recommendations (remove unconstrained delegation, disable legacy/weak protocols, address exposed credentials, review dormant privileged accounts, SAM-R / spooler hardening) and note impact and affected entities.
2. Run `MDIFULL-Report.ps1` to export a read-only posture summary; refine the `MDI ISPM Shortlist – Tier0 – Prod` (top 3–5) with owner candidates.
3. **Boundary:** the labs **do not enforce** any change — remediation and change approval belong to the customer's security/ops functions.
4. **Pass gate:** a written shortlist exists and each attendee can explain why the top item ranks first.

## Lab 5 — Investigation end-to-end + response rehearsal
1. Pick a lead: a real alert from Lab 2, the honeytoken hit from Lab 3, or an entity from Lab 1.
2. Build the story on the **user entity page**: timeline → related alerts → lateral-movement path → involved devices. Cross-check in **Advanced hunting** with the saved queries (or the **Investigation** section of `MDIFULL-LabQueries.kql`, saved as `Investigation – Identity – Hunt`).
3. Capture findings in `MDI Investigation – Identity – Validate`: what happened, which identities/devices, which technique, confidence, recommended action.
4. **Response rehearsal (approval-gated):** from the entity page, review **Disable user / Force password reset / Suspend** and discuss when each applies and who must approve. **Describe/queue the action for approval; do not execute against a production identity.** Discuss how XDR **automatic attack disruption** changes the playbook.
5. **Pass gate:** a completed investigation doc plus each attendee correctly stating which response action fits and who approves it. Run the knowledge-check in the Testing Guide.

---

# Phase C — Prove the value (guided PoC)

Run the PoC on the same pilot DC with **benign, simulated** signal only. All test signal is harmless read-only enumeration and a honeytoken touch — **never a real attack, exploit, or credential theft**.

## Step 8 — Generate benign test signal
1. From the **test workstation**, signed in as the **test account**, run `MDIFULL-TestSignal.ps1 -HoneytokenSam "<sam>"` (preview first with `-WhatIf`). It performs only **benign, read-only** actions tagged `MDI-TESTSIGNAL`:
   - **Reconnaissance signal:** harmless enumeration — `net group "Domain Admins" /domain`, `net user /domain`, `nltest /domain_trusts`, and a read-only LDAP query. MDI flags the *pattern* as reconnaissance.
   - **Honeytoken signal:** a benign lookup touching `MDI Honeytoken – Decoy Identity – Pilot`.
2. **Do not** run attack tooling, credential-dumping utilities, exploitation frameworks, or anything that changes AD.
3. Note the time of each signal for the scorecard latency comparison.

## Step 9 — Validate, demonstrate, and score
1. Run `MDIFULL-Validate.ps1 -Check Signal` — confirm (read-only) the **reconnaissance** and **honeytoken** alerts reached the portal (`AlertInfo`), the activity appears in the identity tables, and the identity timeline populated.
2. In the portal, walk the demo for stakeholders: incident → **alert story** → **identity page → Timeline** → **UEBA / investigation-priority** view.
3. Run `MDIFULL-Report.ps1 -Scorecard -CriteriaPath .\criteria.json -OutFile "MDI PoC Scorecard – Pilot DC – Validate.json"` — it maps each observation to your pass/fail criteria and writes the scorecard. Review it with stakeholders as the decision artefact.

## Step 10 — Tear down the PoC-only scope
1. Run `MDIFULL-Deploy.ps1 -Rollback -WhatIf` first to preview, then for real.
2. Untag any **PoC-only** decoy created just for the demo, **resolve** the `MDI-TESTSIGNAL` test alerts in **Incidents & alerts** as "Not a threat / test," and confirm no PoC-only DSA/sensor residue remains with `MDIFULL-Validate.ps1`.
3. **Keep** the production sensor, the retained honeytoken(s), the tags, the saved queries, the ISPM shortlist, and the scorecard. Only the *demo-only* artefacts are removed.

---

# Expand (across the fleet)

## Step 11 — Expand to remaining DCs and AD FS/AD CS
1. **Sensors:** install the sensor on each remaining domain controller in change windows until all show **Running / Healthy**; then AD FS / AD CS servers.
2. **Tags/honeytokens:** extend sensitive tagging and add honeytokens across additional forests/domains as needed.
3. **ISPM:** re-run `MDIFULL-Report.ps1 -SaveBaseline` after full sensor coverage — recommendations get more complete as more DCs report.
4. **Team:** use the saved queries, runbook, and investigation doc to onboard new analysts.
5. **Response:** only after coverage and detections are trusted, review response-action automation with the SOC (still their decision).
6. Track sensor-health and posture drift each cycle with `MDIFULL-Report.ps1`.

---
### Order of operations
`Assess → activate MDI + DSA → install pilot-DC sensor → tag sensitive entities → plant honeytokens → enable/triage ISPM → validate detections → run the five enablement labs → generate benign PoC signal → validate + demonstrate + score → tear down PoC-only scope → expand to all DCs + AD FS/AD CS (response approval-gated throughout)`
