# Solution Overview — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel — Government (GCC High)

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and Defense-Industrial-Base (DIB) tenants. It mirrors the commercial threat-hunting method exactly,
> adapted for the **sovereign cloud**: the Defender portal is `security.microsoft.us`, Azure/Sentinel
> live in **Azure Government** (`portal.azure.us`), Microsoft Graph is `graph.microsoft.us` (DoD:
> `dod-graph.microsoft.us`), and sign-in is `login.microsoftonline.us`. Advanced-hunting schema,
> retention, query limits, and the availability of specific Defender pillars/tables **can lag or differ
> in GCC High and DoD** — every such point below is flagged **verify against current Microsoft
> Government documentation**. See `gcc-high-parity-notes.md` for the endpoint table, feature-parity
> gaps, and compliance/data-residency context.

## What this is

A complete, self-guided method for standing up a **proactive threat-hunting program** across
**Microsoft Defender XDR advanced hunting** and **Microsoft Sentinel**, driven by **KQL**. It gives
you a **MITRE ATT&CK-aligned, reusable hunt library**, a **hypothesis-driven method and cadence**, a
way to **document findings** (bookmarks + a hunt register), and a path to **promote successful hunts
into permanent detections**.

It is the **proactive** layer of a security operations program. It assumes telemetry is already flowing
(Defender XDR onboarded, a connected Sentinel workspace) and builds hunting on top of it. It is the
counterpart to two adjacent solutions: the *Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection
Coverage* solution (which tunes the **reactive** scheduled detections), and the *M365 & Azure Incident
Response & Escalation Runbook* (which **responds** once something is confirmed). This solution sits
before both: it **finds** what the rules miss and turns durable findings into new detections and new
incidents.

## How the technology works (the mental model)

- **Advanced hunting (Microsoft Defender XDR).** A query-based investigation tool in the Defender
  portal (`security.microsoft.us` in GCC High) that runs **KQL** over a **unified schema** of Defender tables —
  device events (`DeviceProcessEvents`, `DeviceNetworkEvents`, `DeviceFileEvents`, …), identity
  (`IdentityLogonEvents`, `IdentityInfo`), email/collaboration (`EmailEvents`, `CloudAppEvents`), and
  alerts (`AlertEvidence`, `AlertInfo`). Data is typically retained for **~30 days** and queries have
  **row/time limits** — and in **GCC High/DoD the advanced-hunting schema, table availability,
  retention, and limits can lag or differ from commercial** — *verify against current Microsoft
  Government documentation and your tenant.*
- **Microsoft Sentinel hunting.** Sentinel adds a **Hunting** experience over the Log Analytics
  workspace: saved **hunt queries** (MITRE-tagged), ad-hoc KQL in **Logs**, **bookmarks** to preserve
  interesting rows, **Livestream** to watch a query in near-real-time, and (where available) a
  **Hunts** feature to organize a hunt as an investigation with hypotheses and linked bookmarks.
  Sentinel queries the workspace tables (`SigninLogs`, `AuditLogs`, `OfficeActivity`, `Device*` if the
  Defender connector streams them, `CommonSecurityLog`, …), often over **longer retention** than
  advanced hunting.
- **KQL as the shared language.** Both surfaces speak **KQL**, so a hunt is fundamentally a KQL
  hypothesis — "if technique *X* were happening, this query would surface it." The **same idea** often
  runs on both platforms with different table names; the delivered library notes which surface each
  hunt targets.
- **MITRE ATT&CK alignment.** ATT&CK is a matrix of adversary **tactics** (the "why" — e.g. *Execution*,
  *Collection*, *Command and Control*) and **techniques** (the "how" — e.g. *T1059 Command and Scripting
  Interpreter*). Tagging each hunt to a technique turns the library into a **coverage map**: you can see
  which tactics you actively hunt and where you have never looked.
- **Hypothesis-driven hunting.** A good hunt is not "run a query and see." It is: **state a hypothesis**
  → **scope it** (time, assets, identities) → **run the KQL** → **triage the results** (benign / suspicious
  / confirmed) → **document the outcome** → **decide the follow-up** (promote to a detection, hand off as
  an incident, or record "not found this window").
- **Bookmarks & the hunt register.** A **bookmark** preserves a specific result row (with its entities)
  so it is not lost when the query window rolls off — the raw evidence of a finding. The **hunt
  register** is the human record: hypothesis, scope, query, outcome, and decision, per hunt.
- **Promotion: hunt → detection.** A hunt that reliably finds real, actionable activity is **promoted**
  into a permanent, automatic detection — a **scheduled analytics rule** in Sentinel, or a **custom
  detection rule** in Defender XDR (built directly from an advanced-hunting query). The one-off hunt
  becomes standing coverage.
- **Hunt → incident hand-off (read-only boundary).** When a hunt confirms a true positive, it becomes an
  **incident** that flows into the **reactive** process. This solution **stops at the hand-off** — it
  never isolates, disables, or remediates. Those response actions live in the companion *M365 & Azure
  Incident Response & Escalation Runbook*.

## The standard deployment model

Every solution in this program follows the same five stages:

1. **Assess.** Confirm the hunting surface is usable — which advanced-hunting tables and Sentinel tables
   have recent data, who holds hunting access, and which ATT&CK techniques are the priority. Inventory
   any existing hunt queries, bookmarks, and custom detections (run `THREATHUNTG-Discovery.ps1`).
2. **Configure.** Stand up the program's named objects: the **read-only hunter RBAC group**, the
   **reusable KQL hunt library** (`Hunt Library - Tenant - Main`), the **hunt register**, and the
   **monthly cadence** — naming every object.
3. **Pilot.** Run the first batch of hypothesis-driven hunts **read-only** across both platforms,
   triage the results, and **document findings** as bookmarks + register entries. Hand any confirmed
   true positive off to incident response (run `THREATHUNTG-RunHuntLibrary.ps1`, `THREATHUNTG-Report.ps1`).
4. **Validate.** Confirm the hunts return coherent results, findings are documented, and at least one
   successful hunt **promotes cleanly** into a scheduled analytics rule / custom detection
   (run `THREATHUNTG-Validate.ps1`).
5. **Expand.** Promote the hunts worth keeping, grow the library across the rest of the ATT&CK matrix,
   and run the loop on the agreed cadence.

## Scope — what this solution covers

- **The hunting environment** — Defender XDR advanced hunting + Sentinel hunting, scoping, and
  **least-privilege, read-only RBAC** for hunters.
- **A MITRE ATT&CK-aligned reusable KQL hunt library** — real hunt queries, tagged to technique,
  runnable on both surfaces.
- **A hypothesis-driven hunt method and cadence** — hypothesis → scope → run → triage → document →
  decide, on a recurring schedule.
- **Findings documentation** — bookmarks, a hunt register, and the **hunt-to-incident hand-off**.
- **Promotion of successful hunts** into scheduled analytics rules / custom detection rules.

## Out of scope (handled elsewhere)

- **Incident response & escalation** — containment, isolation, account disablement, mailbox purge,
  eradication, and crisis coordination are the **companion *M365 & Azure Incident Response & Escalation
  Runbook***. This solution hands confirmed findings **to** that process and stops.
- **Standing up the workspace, connectors, and ingestion** — a hunt can only find what is ingested;
  connect sources first (the *Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion*
  solution).
- **Full detection tuning & false-positive engineering** for the promoted rules — the *Microsoft
  Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage* solution owns rule tuning; this solution
  performs the **promotion** and points there for the tuning loop.
- **Automated response / SOAR playbooks** — a separate Sentinel automation solution.
- **The determination of which techniques matter most and your risk tolerance** — security-leadership
  decisions that set the hunt backlog priority; this solution provides the method and the library to
  execute against them.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.us` — GCC High) → **Advanced hunting** (KQL) and
  **Custom detection rules** (promotion).
- **Microsoft Sentinel** in **Azure Government** (Azure portal `portal.azure.us`, or the unified Defender
  portal) → **Hunting**, **Logs**, **Bookmarks**, **Livestream**, and **Analytics** (promotion).
- **PowerShell** with **Microsoft.Graph** (`Microsoft.Graph.Security` — `Invoke-MgSecurityRunHuntingQuery`),
  connected to the US Gov cloud with **`Connect-MgGraph -Environment USGov`** (`graph.microsoft.us`; **DoD:
  `dod-graph.microsoft.us` / `-Environment USGovDoD`** — *verify your cloud*), to run advanced-hunting KQL
  against Defender XDR; and the **Az** modules (`Az.Accounts`, `Az.OperationalInsights` for
  `Invoke-AzOperationalInsightsQuery`, `Az.SecurityInsights` for hunts, bookmarks, and rules) connected
  with **`Connect-AzAccount -Environment AzureUSGovernment`** for Sentinel.
- **Sign-in / token host** is **`login.microsoftonline.us`** for the national cloud.
- **KQL** — the delivered `Hunt Library - Tenant - Main` (`THREATHUNTG-HuntLibrary.kql`), run on both
  surfaces.
- All tools authenticate **interactively** with an MFA-capable admin, need only **read/hunting** scopes
  (`ThreatHunting.Read.All` for Graph; Security Reader / Microsoft Sentinel Reader for the portals), and
  hold **no credentials in code**. The delivered scripts default to the US Gov cloud — *verify the correct
  national-cloud endpoints and scopes for your cloud (GCC High vs DoD) against current Microsoft
  Government documentation.*
