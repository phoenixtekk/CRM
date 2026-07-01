# 3. Implementation — M365 & Azure Incident Response & Escalation Runbook

This is the operational build-out **and** the live runbook. Part A stands up the named artifacts once (the matrix, templates, playbooks, escalation sheet, RCA, and responder access). Part B is the per-incident runbook you execute every time, phase by phase, with full Microsoft console navigation paths.

Steps are imperative and ordered. Every created object uses the naming standard `<Purpose> – <Scope> – <Stage>` verbatim. **Never assume a prerequisite exists** — each step that depends on access points back to a Requirement (R1–R12) to verify and implement-if-missing.

---

# Part A — Stand up the runbook (one-time)

## A1. Build the Severity & Impact Matrix – Incident – Triage

1. Create the artifact **Severity & Impact Matrix – Incident – Triage** in your PSA/knowledge base (R9). It is a table mapping **severity (P1–P4)** against **business impact**, **urgency**, **response-time target**, and **update cadence**.
2. Populate it from your client SLAs (R11). Where no SLA specifies, adopt these defaults:

| Severity | Definition (impact) | Examples | Response target | Update cadence |
|---|---|---|---|---|
| **P1 — Critical** | Total or near-total outage of a critical service for many/all users; no workaround. | Mail flow stopped tenant-wide; all users can't sign in; suspected active account compromise. | Immediate (≤15 min) | Every 30 min |
| **P2 — High** | Major degradation or outage for a department/site, or a critical service degraded with a partial workaround. | One site can't access SharePoint; Teams calls failing for a region; recurring sign-in failures for a group. | ≤30 min | Every 60 min |
| **P3 — Moderate** | Single user or small group impacted; workaround exists; not business-critical. | One mailbox delayed; one device won't enroll. | ≤4 business hours | Daily |
| **P4 — Low** | Minor issue, question, or cosmetic; no business impact. | Single non-urgent config query. | ≤1 business day | On change |

3. **Verify:** confirm the matrix carries response and cadence targets and that they match or exceed every client SLA (R11). Store one canonical copy; reference it from the Incident Record Template.

> **Note (severity ≠ Microsoft severity):** these P1–P4 levels are *your* internal/client severities. Microsoft support uses its own severity scheme (Azure Sev A/B/C; M365 Critical/Severe/etc.), and which you may set is plan-dependent — see A5 and Part B Phase 6.

## A2. Build the Incident Record Template – Incident – Lifecycle

1. In your PSA (R9), create the incident ticket type **Incident Record Template – Incident – Lifecycle** with these fields:
   - Incident ID, Title, Client/Tenant, **Severity** (from A1).
   - **Timestamps:** Detected, Acknowledged (drives MTTA), Mitigated, Resolved (drives MTTR), Closed.
   - **Roles:** Incident Lead, Communications Lead, Scribe (from A3).
   - **Timeline / running log** (every action and decision, timestamped — the Scribe owns this).
   - **Affected workload(s)** and the Diagnostic Playbook used.
   - **Microsoft case number** (if escalated) and Microsoft severity.
   - **Root cause** (link to RCA), **Corrective actions**, **Problem Record** link.
2. **Verify:** create a test incident and confirm all fields capture and timestamp correctly.

## A3. Build the Roles & On-Call Sheet – Incident – Response

1. Create **Roles & On-Call Sheet – Incident – Response** documenting the three per-incident roles and the on-call rota (R2):
   - **Incident Lead** — owns the response, makes decisions, sets severity, decides escalation. The single throat to choke.
   - **Communications Lead** — owns all client and stakeholder comms (A4); shields the Lead and engineers from status requests.
   - **Scribe** — maintains the timeline in the Incident Record; captures who-did-what-when for the RCA.
2. For a small team, one person may hold multiple roles — but the **Incident Lead role is always named** before diagnosis begins.
3. Link the on-call rota (R2) so "current Incident Lead" is always resolvable.
4. **Verify:** confirm the current on-call engineer is named and reachable through the paging tool.

## A4. Build the Client Comms Templates – Incident – Communicate

1. Create **Client Comms Templates – Incident – Communicate** with four templates and a defined client status method (R10):

   **Initial notification (sent at first triage):**
   > *Subject: [P{n}] Service incident affecting {service} — investigating*
   > We are aware of an issue affecting {service} that began at approximately {time}. Impact: {who/what}. Our team is investigating and treating this as Priority {n}. Next update by {time + cadence}.

   **Update (sent every cadence interval):**
   > *Subject: [P{n}] {service} incident — update {hh:mm}*
   > Status: {investigating / mitigated / monitoring}. What we know: {brief}. What we're doing: {brief}. Workaround (if any): {…}. Next update by {time}.

   **Resolution:**
   > *Subject: [P{n}] {service} incident — RESOLVED*
   > Service was restored at {time}. Cause (preliminary): {brief}. We are completing a full root-cause analysis and will share findings by {date}. Thank you for your patience.

   **Post-incident summary (sent after RCA):**
   > *Subject: Post-incident report — {service} incident {date}*
   > Summary, timeline, root cause, corrective actions, and the permanent fix we are implementing. (Body = the client-facing extract of the RCA Template.)

2. Record each client's **status method** (status page / email DL / call path) and after-hours contact (R10) in the template front matter.
3. **Verify:** send a test Initial+Update to an internal address; confirm the cadence reminder fires.

## A5. Build the Microsoft Escalation Sheet – Incident – Escalate

1. Create **Microsoft Escalation Sheet – Incident – Escalate** recording, for **each tenant/subscription**:
   - The Microsoft **support entitlement** (included support / **Microsoft Unified** / legacy Premier / **Azure support plan**) — confirm at **Microsoft 365 admin center → Support → Help & support**, the **Microsoft Unified** portal (`https://services.microsoft.com`) for Unified customers, and **Azure portal → Help + support** (R8).
   - The **case severities your plan permits** and their response commitments. *Be explicit that this is plan-dependent:* Azure **Sev A** (critical, fastest response) typically requires a **paid Azure support plan**; M365 case severity options likewise vary by entitlement. Do not promise a severity your plan can't set.
   - **How to open a case:**
     - **M365:** `https://admin.microsoft.com` → **Support → Help & support → Contact support** (or "New service request"); attach the message trace / sign-in log / correlation IDs you gathered in Diagnose.
     - **Azure:** `https://portal.azure.com` → **Help + support → Create a support request**; pick the resource, **Issue type**, and the **severity** your plan allows.
     - **Unified:** `https://services.microsoft.com` → submit/manage requests against the Unified contract.
   - The **internal escalation chain** (when the Incident Lead escalates to a senior engineer / management) and the trigger conditions.
2. **Verify:** confirm each tenant's entitlement and the severity list shown when you begin (do not submit) a case; record screenshots/notes.

## A6. Build the Diagnostic Playbooks – Incident – Diagnose

Author the seven named per-workload playbooks below — each is a short, ordered procedure with the **exact Microsoft console path**. These are referenced verbatim in Part B Phase 4.

### A6.1 Microsoft Service Health Playbook – Diagnose – Platform *(run this FIRST)*
1. **M365:** `https://admin.microsoft.com` → **Health → Service health**. Review active issues/advisories for the affected workload; note the **issue ID** and status.
2. **Azure:** `https://portal.azure.com` → **Service Health** → **Service issues** (and **Health advisories**, **Security advisories**, **Planned maintenance**). Filter to your subscriptions/regions.
3. If an active Microsoft issue matches the symptom, this is a **Microsoft-side incident** — switch to "track + communicate + escalate" (Part B Phases 3 & 6), not deep local diagnosis.

### A6.2 Exchange Online Mail Flow Playbook – Diagnose – Exchange
1. `https://admin.exchange.microsoft.com` → **Mail flow → Message trace**. Run a trace for the affected sender/recipient and time window; read the delivery status / failure reason.
2. **Mail flow → Rules** — check for a transport rule blocking/redirecting the message.
3. **Mail flow → Connectors** — check inbound/outbound connector health (relevant to hybrid/third-party gateways).
4. **Defender:** `https://security.microsoft.com` → **Email & collaboration → Threat Explorer / Quarantine** — confirm the message wasn't quarantined or ZAP'd.
5. For deeper data: `Connect-ExchangeOnline` (R5) then `Get-MessageTrace` / `Get-MessageTraceDetail`.

### A6.3 Entra Sign-in & Auth Playbook – Diagnose – Identity
1. `https://entra.microsoft.com` → **Monitoring → Sign-in logs**. Filter to the affected user/time; open a failed sign-in and read **Failure reason**, **Conditional Access** result, and **MFA** detail.
2. **Protection → Conditional Access → Policies** — check whether a CA policy is blocking; use **What If** to simulate.
3. **Protection → Identity Protection → Risky sign-ins / Risk detections** (requires **Entra ID P2**, R4) — check for risk-driven blocks or compromise.
4. **Monitoring → Audit logs** — see recent changes (policy, user, app) that could have caused the regression.

### A6.4 Teams Service Playbook – Diagnose – Teams
1. `https://admin.teams.microsoft.com` → **Users** → select the user → **Meetings/Call history**; for quality, open a specific call.
2. **Analytics & reports → Call quality dashboard (CQD)** — assess call/meeting quality trends.
3. Confirm underlying dependencies: Teams relies on Exchange (calendar) and SharePoint (files) — cross-check A6.2 and A6.5 if those are implicated.
4. Check **Service health** (A6.1) — Teams incidents are frequently platform-side.

### A6.5 SharePoint & OneDrive Playbook – Diagnose – Collaboration
1. `https://admin.microsoft.com` → **(SharePoint admin center)** `https://<tenant>-admin.sharepoint.com` → **Sites → Active sites** — check the affected site's status and storage.
2. For sync issues: on the device, OneDrive sync health and the **Sync admin reports** in the SharePoint admin center.
3. **Sharing:** site/tenant external-sharing settings if access-denied is the symptom.
4. Check **Service health** (A6.1) for SharePoint/OneDrive advisories.

### A6.6 Intune Device & App Playbook – Diagnose – Endpoint
1. `https://intune.microsoft.com` → **Devices → All devices** → select the device → **Device compliance** and **Managed Apps**; review last check-in.
2. **Devices → Monitor → Enrollment failures** for enrollment incidents.
3. **Apps → Monitor → App install status** for delivery failures.
4. **Reports → Endpoint analytics** for fleet-wide signals.

### A6.7 Azure Resource Health Playbook – Diagnose – Azure
1. `https://portal.azure.com` → the affected resource → **Resource health** — read current/historical health and Microsoft's stated cause (platform vs. customer-initiated).
2. **Monitor → Metrics** — chart the resource's key metrics around the incident time; **Monitor → Logs** (Log Analytics) for diagnostic logs (R7).
3. **Service Health** (A6.1) — confirm whether a regional Azure issue is in play.
4. For activity/changes: the resource's **Activity log** — see who changed what.

**Verify (A6):** walk each playbook against a known-good resource and confirm every console path resolves with the responder's access (R3–R7).

## A7. Build the RCA Template – Incident – Review and the Problem Record – Incident – Permanent Fix

1. Create **RCA Template – Incident – Review** with sections: **Summary**, **Impact** (who/what/duration), **Timeline** (from the Incident Record), **Root cause** (the *why*, via 5-Whys), **Contributing factors**, **What went well / what didn't**, **Corrective actions** (each with owner + due date), and **Detection/Prevention improvements**.
2. Create **Problem Record – Incident – Permanent Fix** to track each corrective action that is a *permanent control* (not a one-off fix) through to closure, linked back to the RCA and the originating incident.
3. **Verify:** confirm both templates link bidirectionally to the Incident Record (A2).

## A8. Provision responder access (R1, R2)

1. Run `scripts\INCIDENT-Set-ResponderRoles.ps1 -WhatIf` to preview creation of `Responder Access Group – Identity – Response` and the reader/scoped-admin role assignments.
2. Review the preview; then re-run with `-Apply` to create the group and assign roles. Prefer **PIM-eligible** for admin roles.
3. Run `scripts\INCIDENT-Validation.ps1` to confirm responder readiness: roles present, log access, support plan — expect **PASS** on all checks (R1–R8).
4. **Verify:** sign in as a responder and confirm each console path in A6 loads.

---

# Part B — The per-incident runbook (every incident)

## Phase 1 — Detect

1. The incident surfaces via a monitoring alert, a client report, a Microsoft Service Health advisory, or a security signal (Defender).
2. **Acknowledge** immediately and open an **Incident Record Template – Incident – Lifecycle** (A2). Record **Detected** and **Acknowledged** timestamps (these drive MTTA).
3. Capture the raw symptom verbatim and the reporter/source.

## Phase 2 — Triage

1. The on-call engineer assumes (or assigns) the **Incident Lead** role and, for P1/P2, names a **Communications Lead** and **Scribe** from the **Roles & On-Call Sheet – Incident – Response** (A3).
2. Classify severity with the **Severity & Impact Matrix – Incident – Triage** (A1) using **impact × urgency**. To prioritize among competing actions, weigh **impact × risk × effort** — do the highest-impact, lowest-risk, lowest-effort mitigation first.
3. **Run the Microsoft Service Health Playbook – Diagnose – Platform (A6.1) now** — answer "is this Microsoft or us?" before committing to deep diagnosis.
4. Record severity and roles in the Incident Record. This is the gate: P1/P2 trigger the full response; P3/P4 follow the lighter cadence.

## Phase 3 — Communicate

1. The **Communications Lead** sends the **Initial notification** from **Client Comms Templates – Incident – Communicate** (A4) via the client's status method, at the severity's response target (R11).
2. Set a recurring reminder at the matrix **update cadence** and send the **Update** template each interval — even "no change yet" is an update.
3. Keep internal coordination in the incident war-room channel (R10); keep client comms calm, factual, and free of internal jargon.

## Phase 4 — Diagnose

1. Select the **Diagnostic Playbook – Incident – Diagnose** matching the affected workload (A6.2–A6.7) and follow its ordered console steps.
2. Drive toward **root cause**, not symptom — capture correlation IDs, message-trace IDs, sign-in error codes, and Resource Health statements; the Scribe logs each finding with a timestamp.
3. If multiple workloads are implicated, run the dependent playbooks (e.g. Teams → Exchange/SharePoint).
4. If the playbook points at a Microsoft-side cause, proceed to Phase 6 (escalate) in parallel with continued communication.
5. (Optional) Run `scripts\INCIDENT-Discovery.ps1` to snapshot current Service Health, recent high-severity sign-ins/risk, and Azure resource health in one pass to seed diagnosis.

## Phase 5 — Resolve

1. **Mitigate first** (restore service / workaround), **then** fix fully — record both in the Incident Record with timestamps (**Mitigated**, then **Resolved**, which drives MTTR).
2. For common, well-understood fixes, use `scripts\INCIDENT-Remediation.ps1` — it defaults to `-WhatIf`; review the preview, then `-Apply` (e.g. revoke a compromised user's sessions; re-enable a disabled mail-flow connector for a *named* object). High-risk fixes follow the emergency-change rule (R12).
3. **Verify the fix** against the original symptom (re-run the relevant playbook step; confirm with the reporter).
4. The Communications Lead sends the **Resolution** template (A4).

## Phase 6 — Escalate to Microsoft (when needed)

1. Escalate when root cause is **Microsoft-side** (confirmed in Service Health) or **beyond local control**, using the **Microsoft Escalation Sheet – Incident – Escalate** (A5).
2. Open the case at the right portal (M365 / Azure / Unified) and set the **severity your plan permits** — *remember severity options and response are plan-dependent* (R8). Attach the diagnostic evidence gathered in Phase 4.
3. Record the **Microsoft case number** and severity in the Incident Record; keep the client updated that an escalation is in progress.

## Phase 7 — RCA → Permanent Fix

1. Within the agreed window (e.g. ≤5 business days for P1), complete the **RCA Template – Incident – Review** (A7) from the Incident Record timeline; use **5-Whys** to reach the true root cause.
2. Send the **Post-incident summary** (A4) — the client-facing extract of the RCA.
3. For every corrective action that is a *permanent control*, open a **Problem Record – Incident – Permanent Fix** (A7) with an owner and due date, and drive it to closure (a config hardening, a new monitor/alert, a policy change, a documentation/runbook update).
4. Run `scripts\INCIDENT-Report.ps1` to compute **MTTA/MTTR** and append this incident to the trend metrics.
5. **Close** the incident only when the RCA exists and any required Problem Record is open. The loop is complete when the permanent fix lands — converting this incident into estate hardening (the Expand step).
