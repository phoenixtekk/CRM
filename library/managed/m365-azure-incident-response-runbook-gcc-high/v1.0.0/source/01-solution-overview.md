# 1. Solution Overview — M365 & Azure Incident Response & Escalation Runbook (Government / GCC High edition)

## What this solution is

This is a complete **operational runbook** for leading high-priority and escalated incidents across **Microsoft 365 and Azure — on a US sovereign-cloud (GCC High) tenant**. It is an **incident & problem management package** for a managed-services team operating in Microsoft 365 GCC High and Azure Government: it gives a responder everything needed to take a P1/P2 incident from first alert to a verified, permanent fix — the severity/impact matrix, the named roles, the triage method, the per-workload diagnostic playbooks, the client communication cadence and templates, the path to escalate to Microsoft support, the root-cause analysis (RCA) format, and the post-incident loop that converts a one-off fix into a permanent control.

It is a **playbook, not a wizard.** It pairs a phased incident lifecycle with named artifacts and per-workload diagnostic procedures so an on-call engineer, an incident lead, and a client-facing communicator can run a controlled, auditable response — every time, regardless of which engineer picks up the page.

**Why a separate GCC High edition exists.** GCC High is **not** the Commercial portal behind a different sign-in. The sovereign-cloud admin URLs are different (`*.us`, not `*.com`), PowerShell must be pointed at US Gov endpoints (`-Environment USGov`), and **some security-operations capabilities lag, are limited, or are absent** versus Commercial. A responder who runs the Commercial runbook on a GCC High tenant will hit the wrong portals, or wait for an automated action that never fires — during a live P1. This edition ships the correct portals, endpoints, and an explicit parity map so the runbook is *accurate for the environment it runs in*.

## Commercial vs GCC High — what's different

This is the single most important section for a responder moving from a Commercial tenant. **Confirm each of these before your first incident — never assume a Commercial habit carries over.**

### Admin portals (use the `*.us` sovereign URLs)

| Console | Commercial URL | **GCC High URL (use this)** |
|---|---|---|
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Exchange admin center | `admin.exchange.microsoft.com` | **`admin.exchange.office365.us`** |
| Microsoft Teams admin center | `admin.teams.microsoft.com` | **`admin.gov.teams.microsoft.us`** |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Microsoft Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |

*Sources: Microsoft Learn — [Microsoft Defender XDR for US Government](https://learn.microsoft.com/en-us/defender-xdr/usgov); [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments); [MSPortals.io — Government Portals](https://msportals.io/usgovt.html); [Microsoft Teams — GCC High deployments](https://learn.microsoft.com/en-us/microsoftteams/plan-for-government-gcc-high).*

### PowerShell / API endpoints

- **Microsoft Graph:** service root is **`https://graph.microsoft.us`** (US Gov L4 / GCC High); connect with **`Connect-MgGraph -Environment USGov`**. Without `-Environment USGov`, the module authenticates against the Commercial endpoint (`login.microsoftonline.com`) and your GCC High sign-in fails. (Source: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).)
- **Azure PowerShell (Az):** connect with **`Connect-AzAccount -Environment AzureUSGovernment`**; the Azure portal endpoint is `portal.azure.us`. (Source: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).)
- **Defender XDR API:** GCC High uses **`https://api-gov.security.microsoft.us`** (login via `login.microsoftonline.us`). (Source: [Microsoft Defender XDR for US Government](https://learn.microsoft.com/en-us/defender-xdr/usgov).)
- **Defender for Endpoint API:** GCC High uses **`https://api-gov.securitycenter.microsoft.us`**. (Source: [Defender for Endpoint for US Government](https://learn.microsoft.com/en-us/defender-endpoint/gov).)

### Feature parity gaps that change the runbook

GCC High "uses the same underlying technologies as Microsoft Defender in Azure Commercial" but "doesn't have complete parity with the commercial offering" (Microsoft, [Defender XDR for US Government](https://learn.microsoft.com/en-us/defender-xdr/usgov)). The gaps that materially affect an incident responder:

- **Microsoft Threat Experts — NOT available in GCC High** ("on engineering backlog"). Do not build an escalation step that calls Threat Experts / "Ask a defender expert"; that lifeline does not exist here. (Source: [Defender XDR for US Government](https://learn.microsoft.com/en-us/defender-xdr/usgov), [Defender for Endpoint for US Government](https://learn.microsoft.com/en-us/defender-endpoint/gov).)
- **Automated investigation & response (AIR):** historically available in **Commercial and GCC only** and lagging in GCC High. Do not assume an alert will self-investigate/auto-remediate; the runbook uses **manual** diagnostic playbooks so it is correct whether or not AIR has fired. **Verify AIR status in your own GCC High tenant** before relying on it. (Flag: *verify for GCC High* — availability shifts as Microsoft closes gaps.)
- **Microsoft Defender for IoT (enterprise IoT security) — NOT available** in GCC High. Exclude IoT-device incidents from the Defender-driven workflow. (Source: [Defender XDR for US Government](https://learn.microsoft.com/en-us/defender-xdr/usgov).)
- **Microsoft Secure Score** is available in GCC High, but **some security recommendations are not**; and some **Defender Vulnerability Management** functions (report inaccuracy, request CVE support) are absent. This affects the Permanent-Fix phase where you'd normally track a Secure Score / MDVM recommendation. (Source: [Defender for Endpoint for US Government](https://learn.microsoft.com/en-us/defender-endpoint/gov).)
- **Advanced hunting:** in the **Defender portal**, features in general availability are available in GCC High. Note the documented **GCC (Moderate)** limitation — cross-table queries spanning Microsoft Sentinel *and* Defender XDR aren't supported there — which does **not** apply to GCC High but is a common point of confusion; **verify** your tenant. (Source: [Support for Microsoft Defender XDR connector data types in Microsoft Sentinel for GCC environments](https://learn.microsoft.com/en-us/azure/sentinel/microsoft-365-defender-cloud-support).)
- **Microsoft Sentinel** runs in **Azure Government** for GCC High SOCs; onboard/hunt from the Defender portal `security.microsoft.us` and the Azure Government portal `portal.azure.us`. Some connectors and preview features differ by cloud — **verify connector availability for GCC High** before depending on a data source in an incident. (Source: [Microsoft Sentinel feature availability](https://learn.microsoft.com/en-us/azure/sentinel/feature-availability).)

> **Golden rule for this edition:** where the runbook names a console, it names the **`*.us`** one. Where a Commercial feature might be absent (Threat Experts, AIR, some Secure Score / MDVM items, IoT), the runbook flags it and gives a **manual** path so a live incident is never blocked waiting on a capability that isn't in GCC High. When Microsoft's parity docs change, re-verify — the gaps close over time.

## The phase model

Every incident this runbook governs moves through seven phases, used verbatim throughout the package:

**Detect → Triage → Communicate → Diagnose → Resolve → RCA → Permanent Fix**

- **Detect** — the incident surfaces (monitoring alert, client report, Microsoft Service Health advisory, security signal in `security.microsoft.us`).
- **Triage** — classify severity using the matrix, assign roles, and prioritize using impact × risk × effort.
- **Communicate** — open the client communication cadence with the right template at the right interval.
- **Diagnose** — run the named per-workload diagnostic playbook (in the `*.us` consoles) to reach a root cause (not just a symptom).
- **Resolve** — apply the fix (mitigation first, then full resolution), verify service is restored.
- **RCA** — produce the root-cause analysis record while the timeline is fresh.
- **Permanent Fix** — convert the RCA's corrective actions into a permanent control (a problem record), so the same incident does not recur.

This maps to the standard managed-services lifecycle of **Assess → Stabilize → Diagnose → Remediate → Verify → Review → Expand**: Triage is the Assess gate, Communicate+Resolve stabilize and remediate, RCA is the Review, and Permanent Fix is the Expand step that hardens the estate.

## The named artifacts

The package stands up a small set of reusable artifacts, each named once and reused verbatim across the runbook, scripts, and client comms:

| Artifact | Purpose |
|---|---|
| **Severity & Impact Matrix – Incident – Triage** | The single classification table mapping P1–P4 to impact, urgency, and response/cadence targets. |
| **Incident Record Template – Incident – Lifecycle** | The master record for one incident: timeline, severity, roles, actions, decisions, MTTA/MTTR. |
| **Roles & On-Call Sheet – Incident – Response** | Names the Incident Lead, Communications Lead, and Scribe per incident and the on-call rota. |
| **Client Comms Templates – Incident – Communicate** | Initial / Update / Resolution / Post-Incident message templates for clients and a status method. |
| **Microsoft Escalation Sheet – Incident – Escalate** | How and when to open and severity-set a Microsoft support case in the **GCC High** support surface (plan-dependent). |
| **RCA Template – Incident – Review** | The structured root-cause analysis (timeline, root cause, contributing factors, corrective actions). |
| **Problem Record – Incident – Permanent Fix** | Tracks the permanent control derived from the RCA through to closure. |
| **GCC High Parity Notes – Incident – Sovereign** | The cited reference of Commercial-vs-GCC-High portal/endpoint/feature differences (see `gcc-high-parity-notes.md`). |
| **Diagnostic Playbooks – Incident – Diagnose** | The per-workload procedures (Exchange Online, Entra ID, Teams, SharePoint/OneDrive, Intune, Azure) using the `*.us` consoles. |

## The per-workload diagnostic playbooks

The Diagnose phase is driven by named, per-workload playbooks, each with the **real GCC High console paths** an engineer follows:

1. **Exchange Online Mail Flow Playbook – Diagnose – Exchange** — message trace, transport rules, connectors, queues (`admin.exchange.office365.us`).
2. **Entra Sign-in & Auth Playbook – Diagnose – Identity** — sign-in logs, Conditional Access, MFA, risk (`entra.microsoft.us`).
3. **Teams Service Playbook – Diagnose – Teams** — call quality, meeting/chat health, Teams admin diagnostics (`admin.gov.teams.microsoft.us`).
4. **SharePoint & OneDrive Playbook – Diagnose – Collaboration** — site/sync health, sharing, storage.
5. **Intune Device & App Playbook – Diagnose – Endpoint** — enrollment, policy/app delivery, compliance (`intune.microsoft.us`).
6. **Azure Resource Health Playbook – Diagnose – Azure** — Resource Health, Service Health, Azure Monitor (`portal.azure.us`).
7. **Microsoft Service Health Playbook – Diagnose – Platform** — distinguish a Microsoft outage from a tenant issue (`portal.office365.us` + `portal.azure.us`).

## How it works (the flow)

1. **Detect** the incident and open an **Incident Record Template – Incident – Lifecycle**.
2. **Triage**: score with the **Severity & Impact Matrix – Incident – Triage**; assign roles from the **Roles & On-Call Sheet – Incident – Response**.
3. **Check Microsoft Service Health first** — confirm whether this is a Microsoft-side outage before deep diagnosis (in the `*.us` consoles).
4. **Communicate** to the client using the matching **Client Comms Templates – Incident – Communicate** at the cadence the severity demands.
5. **Diagnose** with the right **Diagnostic Playbook – Incident – Diagnose** until a root cause is identified — checking the **GCC High Parity Notes** if a Commercial capability appears missing.
6. **Escalate to Microsoft** via the **Microsoft Escalation Sheet – Incident – Escalate** if root cause is Microsoft-side or beyond local control.
7. **Resolve**: mitigate, then fully restore; verify; send the Resolution comms.
8. **RCA**: complete the **RCA Template – Incident – Review** within the agreed window.
9. **Permanent Fix**: open a **Problem Record – Incident – Permanent Fix** and drive the corrective control to closure.

## Benefits

- **Faster, more consistent response** — every engineer runs the same triage, comms, and diagnostics *in the correct sovereign consoles*, so MTTA/MTTR drop and don't depend on who is on call.
- **No sovereign-cloud surprises** — the parity map means no engineer wastes a live P1 waiting on a Commercial feature (Threat Experts, AIR) that GCC High doesn't have.
- **Clear client communication** — the templates and cadence remove the "what do we tell the client?" hesitation under pressure.
- **Root cause, not just symptom** — the playbooks push past restarting a thing toward *why* it broke.
- **No repeat incidents** — the RCA → Permanent Fix loop converts each incident into a hardening change.
- **Auditable** — every incident has a named record, a severity, a timeline, and an RCA — usable as managed-service evidence and for the compliance posture (FedRAMP High / DoD IL4 / DFARS) a GCC High tenant is chosen for.

## Honest limitations

- **This is process and tooling, not a fix for every outage.** When the root cause is a Microsoft-side outage, the runbook's job is correct triage, accurate client comms, and escalation — not making Microsoft's service come back faster.
- **Parity is a moving target.** The gaps documented here are cited to Microsoft as of authoring; Microsoft closes gaps over time. **Re-verify the parity notes** for your tenant rather than trusting a static list.
- **Microsoft support severity and response are plan-dependent** and confirmed in the **GCC High** support surface — not the Commercial one. The runbook tells you how to check yours.
- **Diagnostics require the right access.** Reaching root cause depends on having the reader/admin roles and log access in Requirements R1–R12 *in the GCC High tenant*; the runbook will stall at Diagnose without them.

## The standard runbook model

This solution follows the **standard incident-management lifecycle** — a phased model with named artifacts, explicit gates, and a feedback loop:

**Detect → Triage → Communicate → Diagnose → Resolve → RCA → Permanent Fix.**

Each phase has an entry trigger, an exit criterion, and named deliverables. Triage gates whether the response escalates; RCA gates closure; and Permanent Fix gates whether the incident is allowed to recur. No incident is "closed" until its RCA is produced and any required Problem Record is opened.
