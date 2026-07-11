# 3. Implementation — Workshop Runbook: Microsoft Defender for Identity

This is the **facilitator + student runbook**. Run the labs in order against the **pilot/lab** scope from R2. Every object you create uses a consistent naming convention **`<Purpose> – <Scope> – <Stage>`** and is reused by name in later labs, testing, and the scripts. All steps are **read-only or preview-first**; the one configuration action (tagging a honeytoken) and the response rehearsal are **facilitator-driven and approval-gated**.

**Naming convention used throughout**
- Honeytoken account: **`svc-legacy-backup`** (in `contoso.com`) — tagged **`Honeytoken – Identity Lab – Pilot`**.
- Saved hunting queries: **`Recon – Identity Lab – Pilot`**, **`LateralMovement – Identity Lab – Pilot`**, **`Honeytoken – Identity Lab – Pilot`**.
- Investigation notebook / findings doc: **`Investigation – Identity Lab – Pilot`**.
- Remediation shortlist output: **`ISPM-Shortlist – Identity Lab – Pilot`**.

> Portal navigation paths reflect the current Microsoft Defender portal (`https://security.microsoft.com`). Microsoft moves menus periodically — *verify current navigation in your tenant*; the troubleshooting guide lists the moved-menu fallbacks.

---

## Lab 0 — Readiness check (Assess)
**Goal:** confirm the environment is ready before teaching.

1. Sign in to `https://security.microsoft.com` as the **facilitator** (Security Administrator).
2. Go to **Settings → Identities → Sensors**. Confirm at least one sensor shows **Healthy** (R1).
3. From the facilitator workstation, run the read-only discovery helper:
   `powershell -ExecutionPolicy Bypass -File .\WSMDI-Discovery.ps1`
   Confirm it reports a healthy sensor, recent identity alerts (if any), and lists **candidate honeytoken accounts**.
4. Run `powershell -ExecutionPolicy Bypass -File .\WSMDI-Validate.ps1` and confirm the readiness checks (sensor health, ISPM data present, hunting access) pass.
5. **Pass gate:** discovery + validate both green; ISPM recommendations visible in **Secure Score**. If not, resolve using Requirements R1–R6 before continuing.

---

## Lab 1 — Identity attack paths & the entity page (Configure/learn)
**Goal:** read an entity page and interpret investigation priority and lateral-movement paths.

1. In the portal, open **Assets → Identities** (or search a username in the global search).
2. Open a **user** entity page for a pilot account. Walk the panels together:
   - **Overview** — investigation priority score, tags, and account risk.
   - **Timeline** — authentications, alerts, and directory changes over time.
   - **Observed in organization / Lateral movement paths** — how this identity could be used to reach higher-privilege accounts.
3. Open a **device** (domain controller) entity page; note logons observed and related identities.
4. Discuss: an **attack path** chains an exposed/compromised identity to a privileged one. Higher investigation priority = investigate first.
5. **Pass gate:** each attendee can, on a second entity page, correctly point to the timeline, the lateral-movement path panel, and the investigation-priority score, and explain what each means.

---

## Lab 2 — Recon & lateral-movement detections (Pilot)
**Goal:** recognize the detection families, map them to MITRE ATT&CK, and triage an alert.

1. Open **Incidents & alerts → Alerts**. Filter **Service source = Defender for Identity**.
2. Review the detection families with the group (use real alerts if present, otherwise the descriptions in the runbook):
   - **Reconnaissance** — account/SAMR enumeration, SPN reconnaissance (Kerberoasting recon), network mapping (Discovery, TA0007).
   - **Compromised credentials** — brute force, password spray (Credential Access, TA0006).
   - **Lateral movement** — Pass-the-Hash, Pass-the-Ticket, overpass-the-hash, remote code execution (Lateral Movement, TA0008).
   - **Domain dominance** — DCSync, DCShadow, Golden Ticket, skeleton key (Credential Access / Persistence).
3. Open **Hunting → Advanced hunting**. Paste the **Recon** and **Lateral movement** sections of `WSMDI-LabQueries.kql`. Run them; review results.
4. Save the two queries as **`Recon – Identity Lab – Pilot`** and **`LateralMovement – Identity Lab – Pilot`** (**Save → Save as**).
5. Take one alert (or one query hit) through triage: what identity, what technique, is it expected, what would escalate it.
6. **Pass gate:** each attendee maps a chosen detection to its MITRE tactic and states the first two triage questions.

---

## Lab 3 — Honeytokens (Pilot, one facilitator config action)
**Goal:** deploy and verify a honeytoken; understand its detection.

1. **Facilitator only:** choose the decoy account **`svc-legacy-backup`** (from R4 / the discovery output). Confirm it has **no legitimate sign-ins**.
2. Tag it: **Settings → Identities → Entity tags → Honeytoken → Add**; add **`svc-legacy-backup`**. (This is the single configuration change in the workshop.) Record it as **`Honeytoken – Identity Lab – Pilot`**.
3. Explain the model: a honeytoken should *never* authenticate, so **any** logon/query against it is high-fidelity. MDI raises **"Honeytoken activity"** when it is touched.
4. In **Advanced hunting**, paste the **Honeytoken** section of `WSMDI-LabQueries.kql` (filters identity events to the tagged account), run it, and **Save as `Honeytoken – Identity Lab – Pilot`**.
5. *(Optional, lab environment only)* From a test workstation, attempt a benign authentication as the honeytoken to generate the detection, then observe the alert. **Do not do this in production.**
6. **Pass gate:** the honeytoken is tagged and visible under Entity tags; the saved query returns the account; attendees can explain why any activity is a real signal.

---

## Lab 4 — ISPM posture (Validate posture, no enforcement)
**Goal:** read and prioritize identity posture recommendations — produce a shortlist, not a change.

1. Open **Secure Score** (or **Exposure management → Recommendations**) and filter to **Identity** / **Defender for Identity** recommendations.
2. Walk the common recommendations: remove **unconstrained delegation**, disable **legacy/weak protocols**, address **exposed credentials**, review **dormant privileged accounts**, and **SAM-R / printer-spooler** hardening. Note each recommendation's impact and affected entities.
3. Run `powershell -ExecutionPolicy Bypass -File .\WSMDI-Report.ps1` to export a read-only posture summary.
4. As a group, build the **`ISPM-Shortlist – Identity Lab – Pilot`** — the top 3–5 recommendations ranked by impact and effort. Record owner candidates.
5. **Important boundary:** the workshop **does not enforce** any change. Actual remediation and change approval belong to the customer's security/ops functions and follow their change process.
6. **Pass gate:** a written shortlist exists and each attendee can explain why the top item ranks first.

---

## Lab 5 — Investigation end-to-end + response rehearsal (Validate/Expand)
**Goal:** run a full identity investigation and rehearse response in a **simulate/approval-gated** posture.

1. Pick a lead: a real alert from Lab 2, the honeytoken hit from Lab 3, or a chosen entity from Lab 1.
2. Build the story on the **user entity page**: timeline → related alerts → lateral-movement path → involved devices. Cross-check in **Advanced hunting** with the saved queries.
3. Capture findings in the **`Investigation – Identity Lab – Pilot`** doc: what happened, which identities/devices, which technique, confidence, and recommended action.
4. **Response rehearsal (approval-gated):** from the entity page, review the available response actions — **Disable user**, **Force password reset**, **Suspend** — and discuss **when** each applies. In production, these require the organization's approval gate. **In the workshop, describe/queue the action for approval; do not execute against a production identity.** MDI also feeds XDR **automatic attack disruption** — discuss how that changes the playbook.
5. Discuss the hand-off to the SOC: the incident, the evidence, and who decides. **Incident-response and containment decisions are the SOC/security team's, not the workshop's.**
6. **Pass gate:** a completed investigation doc plus each attendee correctly stating which response action fits the scenario and who must approve it.

---

## Wrap-up (Expand)
1. Confirm the take-home artifacts exist: the three saved hunting queries, the honeytoken tag, the ISPM shortlist, and the investigation doc.
2. Run the **knowledge-check** in `05-testing.md`.
3. Agree the **expand** plan: apply the runbook to full production scope through the customer's change process, and use this runbook to onboard new analysts.
