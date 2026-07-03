# 2. Requirements — M365 & Azure Incident Response & Escalation Runbook (Government / GCC High edition)

Each requirement is structured as **Description / Why / Verify / Implement-if-missing**. **Never assume a prerequisite exists** — verify each one before you rely on the runbook in a live incident. Requirements are numbered R1–R12. These layer on top of the shared `global-requirements-managed.md`.

> **Sovereign-cloud note:** every *Verify* step below uses the **GCC High (`*.us`)** consoles and **US Gov** PowerShell endpoints (`Connect-MgGraph -Environment USGov`, `Connect-AzAccount -Environment AzureUSGovernment`). If a step sends you to a `*.com` Commercial URL by habit, you are in the wrong cloud. See `gcc-high-parity-notes.md` for the full cited portal map.

> Naming convention used throughout the runbook (reused verbatim in implementation): every created object is named `<Purpose> – <Scope> – <Stage>`, e.g. `Responder Access Group – Identity – Response`.

---

## R1. Responder identities with the right M365 / Azure roles (least privilege) — in the GCC High tenant

- **Description:** Each responder has a working account **in the GCC High tenant** with the roles needed to **diagnose and act** across the in-scope workloads — at minimum reader-level visibility everywhere, with scoped admin where remediation is expected (Exchange Administrator, Teams Administrator, SharePoint Administrator, Intune Administrator, Azure Reader/Contributor, and a Security Reader).
- **Why:** The Diagnose phase stalls without log and console access; the Resolve phase stalls without scoped admin. Personal Global Admin for everyone is the wrong answer (blast radius, audit). Reader-first with scoped, PIM-eligible admin is the target — and it must exist in the *sovereign* tenant, not a Commercial one.
- **Verify:** In **Entra admin center** (**`https://entra.microsoft.us`**) → **Roles & admins**, confirm each responder holds the expected role(s). In **Azure portal** (**`https://portal.azure.us`**) → **Subscriptions → Access control (IAM)**, confirm at least **Reader** on in-scope subscriptions.
- **Implement-if-missing:** Create the responder access group (R2) and assign the minimum roles; prefer **PIM eligible** activation over standing access. Run `scripts\INCIDENTG-Set-ScopeTargeting.ps1 -WhatIf` first (it uses `-Environment USGov`), then apply.

## R2. A defined responder group + on-call rota

- **Description:** A named Entra group `Responder Access Group – Identity – Response` containing the response team, and a documented on-call rota covering the hours your SLAs require.
- **Why:** Role assignment, alert routing, and "who is the Incident Lead right now?" all key off a known group and rota. An incident at 02:00 must have a named owner.
- **Verify:** In **Entra admin center** (`https://entra.microsoft.us`) → **Groups**, confirm the group exists with current members. Confirm a published on-call schedule (PSA/calendar/paging tool) names the current on-call engineer.
- **Implement-if-missing:** Create the group (`INCIDENTG-Set-ScopeTargeting.ps1`), populate it, and stand up an on-call rota in your paging/PSA tool. Record both in the **Roles & On-Call Sheet – Incident – Response**.

## R3. Access to Microsoft 365 + Azure Service Health (sovereign consoles)

- **Description:** Responders can read **Service health** in the Microsoft 365 admin center and **Service Health** in the Azure portal — the **`*.us`** ones.
- **Why:** The very first diagnostic question — "is this Microsoft or is this us?" — is answered here. Misclassifying a Microsoft outage as a tenant fault wastes the response.
- **Verify:** Open **Microsoft 365 admin center** (**`https://portal.office365.us`**) → **Health → Service health** and confirm it loads (requires Global Reader, Service Support Admin, or higher). Open **Azure portal** (**`https://portal.azure.us`**) → **Service Health** and confirm advisories load.
- **Implement-if-missing:** Assign **Service Support Administrator** or **Global Reader** to responders; confirm the account can see **Health → Service health** and the Azure **Service Health** blade in the sovereign consoles.

## R4. Entra ID sign-in & audit log access — plus risk data caveat for GCC High

- **Description:** Responders can read **Sign-in logs** and **Audit logs** in Entra (`entra.microsoft.us`) and, where licensed, **Risky sign-ins / Risk detections** (Identity Protection).
- **Why:** Identity is the most common root cause of "can't log in / can't get mail" incidents. Sign-in logs show failure reasons, Conditional Access results, and MFA outcomes; audit logs show what changed.
- **Verify:** **Entra admin center** (`https://entra.microsoft.us`) → **Monitoring → Sign-in logs** and **Monitoring → Audit logs** both load. For risk data, **Protection → Identity Protection** requires **Entra ID P2** (in GCC High this is delivered via the **G5 Gov** stack / EMS E5 for GCC High). **Verify Identity Protection availability and behavior for GCC High in your tenant** — do not assume Commercial risk-detection parity.
- **Implement-if-missing:** Assign a role that grants log read (**Reports Reader**, **Security Reader**, or **Global Reader**). For risk detections, confirm the P2 entitlement in the GCC High licensing stack; if absent, document that risk-based diagnosis is unavailable and rely on raw sign-in logs.

## R5. Exchange Online message trace + transport access (sovereign EAC)

- **Description:** Responders can run **message trace** and read transport rules, connectors, and queues in the Exchange admin center, plus connect via the Exchange Online PowerShell module **to the US Gov environment**.
- **Why:** Mail-flow incidents (NDRs, delays, blocked senders, connector failures) are diagnosed through message trace and transport configuration — there is no other reliable path.
- **Verify:** **Exchange admin center** (**`https://admin.exchange.office365.us`**) → **Mail flow → Message trace** runs; → **Mail flow → Rules / Connectors** load. **`Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`** succeeds for the responder account.
- **Implement-if-missing:** Assign **Exchange Administrator** (or a custom RBAC role with View-Only Recipients + Message Tracking + Transport read). Install `ExchangeOnlineManagement` on the responder workstation and always connect with the **`O365USGovGCCHigh`** environment name.

## R6. Defender / security signal access (for security-driven incidents) — and the GCC High parity gaps

- **Description:** Responders can read alerts and incidents in the **Microsoft Defender portal** (`security.microsoft.us`) — Defender for Office 365 / Endpoint / Identity, as licensed.
- **Why:** Many P1s start as a security signal (account compromise, mass mail, malware). The runbook needs to read these alerts to triage and to feed the Diagnose phase.
- **Verify:** **Microsoft Defender portal** (**`https://security.microsoft.us`**) → **Incidents & alerts → Incidents** loads for the responder account.
- **Implement-if-missing:** Assign **Security Reader** (read) or **Security Administrator** (act); confirm the relevant Defender workloads are licensed and onboarded. **Known GCC High parity gaps to account for (cited):** **Microsoft Threat Experts is NOT available** in GCC High; **Automated investigation & response (AIR)** historically lags (verify in your tenant); **Defender for IoT enterprise IoT security is NOT available**. Do not design escalation or Resolve steps that depend on these. See `gcc-high-parity-notes.md`.

## R7. Azure Monitor / Resource Health access (Azure Government)

- **Description:** Responders can read **Resource Health** and **Service Health** per resource and query **Azure Monitor** (Metrics, Log Analytics) for in-scope Azure Government workloads.
- **Why:** Azure resource incidents (VM down, App Service 5xx, SQL throttling) are diagnosed through Resource Health and Monitor metrics/logs.
- **Verify:** **Azure portal** (`https://portal.azure.us`) → a resource → **Resource health** loads; **Monitor → Metrics** and any **Log Analytics workspace** are queryable by the responder (**Monitoring Reader** or **Reader**). In PowerShell, `Connect-AzAccount -Environment AzureUSGovernment` succeeds.
- **Implement-if-missing:** Assign **Monitoring Reader** (and **Reader**) on in-scope subscriptions/resources; confirm diagnostic settings send logs to a Log Analytics workspace so history exists at incident time.

## R8. A Microsoft support plan for GCC High (and knowledge of its severity rules)

- **Description:** A known Microsoft support entitlement for escalation **for the GCC High tenant** — at minimum the support included with the subscription, ideally **Microsoft Unified** (the successor to Premier) — and documented knowledge of which case severities your plan permits and their response commitments.
- **Why:** When root cause is Microsoft-side or beyond local control, you escalate to Microsoft **through the GCC High support surface**. **The severities you can set and the response you receive are plan-dependent** — included support, Microsoft Unified, and legacy Premier differ. You must know yours *before* the incident, not during it.
- **Verify:** **Microsoft 365 admin center** (`https://portal.office365.us`) → **Support → Help & support** shows your entitlement and the severity options available when opening a case. Azure: **Azure portal** (`https://portal.azure.us`) → **Help + support → Create a support request** shows the **severity** levels your plan allows (e.g. Sev A/B/C; Sev A typically requires a paid Azure support plan). **Confirm the support path is the GCC High one**, not a Commercial tenant's.
- **Implement-if-missing:** Confirm or purchase the appropriate support plan (Microsoft Unified for managed-service breadth, or an **Azure support plan** for Sev A response) for the GCC High tenant. Record entitlement details and severity rules in the **Microsoft Escalation Sheet – Incident – Escalate**.

## R9. A ticketing / PSA system as the system of record

- **Description:** A ticketing or PSA platform where every incident is logged, timestamped, and tracked through closure.
- **Why:** The **Incident Record Template – Incident – Lifecycle**, MTTA/MTTR metrics, and the audit trail all need a durable home. Email and chat are not a system of record.
- **Verify:** Confirm a ticket type/queue exists for incidents and that responders can create and update tickets with timestamps.
- **Implement-if-missing:** Configure an incident ticket type in your PSA carrying the fields the Incident Record Template needs (severity, detected/acknowledged/resolved times, roles, RCA link). Map the template to those fields. *(For regulated GCC High engagements, confirm the PSA's own data-residency/compliance posture meets the contract.)*

## R10. Defined on-call communication channels + a client status method

- **Description:** A real-time responder channel (e.g. a dedicated chat/bridge for war-rooming) **and** a defined method to communicate status to clients — a status page, an email distribution, or a documented call/contact path per client.
- **Why:** The Communicate phase requires both an internal coordination channel and an outward client channel. Improvising the client channel mid-incident erodes trust. *(In GCC High, confirm the war-room tool itself is an approved sovereign service where the contract requires it — a Commercial chat tool may be out of scope.)*
- **Verify:** Confirm a standing incident bridge/channel exists and that each managed client has a documented status/comms method and an after-hours contact.
- **Implement-if-missing:** Create the incident war-room channel; for each client, record the comms method and emergency contact in the **Client Comms Templates – Incident – Communicate** front matter.

## R11. Defined response-time / SLA targets

- **Description:** Documented response and update-cadence targets per severity — either your contractual SLAs or the matrix defaults adopted as policy.
- **Why:** Triage and the comms cadence are meaningless without targets; "P1 = update every 30 minutes" must be a stated commitment, not an ad-hoc decision.
- **Verify:** Confirm the **Severity & Impact Matrix – Incident – Triage** carries response and cadence targets and that these match (or exceed) any client SLAs.
- **Implement-if-missing:** Populate the matrix targets from contracts; where no contract specifies, adopt the defaults in §03 as internal policy.

## R12. Change-control & rollback posture for remediations

- **Description:** A lightweight change path for incident remediations, including approval for high-risk fixes and a back-out for each, plus the discipline to record changes in the incident record.
- **Why:** Incident fixes are applied under pressure; an un-recorded or irreversible change can turn one incident into two. Emergency change still needs a record and a back-out — and in a regulated GCC High estate, an auditable change trail is part of the compliance obligation, not a nicety.
- **Verify:** Confirm an **emergency change** path exists and that responders know when a fix needs approval vs. when to act-then-document. Confirm `INCIDENTG-Remediation.ps1` defaults to `-WhatIf`.
- **Implement-if-missing:** Define an emergency-change rule (what may be done without prior approval, what may not), and require every remediation to be logged in the **Incident Record Template – Incident – Lifecycle**. See also `global-requirements-managed.md`.
