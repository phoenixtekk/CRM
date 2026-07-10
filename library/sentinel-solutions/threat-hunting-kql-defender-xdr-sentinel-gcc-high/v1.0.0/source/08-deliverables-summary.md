# Deliverables Summary — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the reactive-only blind spot and the knowledge-that-evaporates problem, the proactive KQL hunt-program solution, and the boundary (finds and promotes; does **not** respond — that is the IR runbook). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (advanced hunting vs Sentinel hunting, KQL, MITRE alignment, hypothesis-driven method, bookmarks/register, hunt→detection promotion, the read-only hand-off), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Defender XDR onboarded, connected Sentinel workspace, read-only hunter RBAC, an agreed hunt backlog, a findings home, a hunt-to-incident hand-off, the toolchain, and advanced-hunting limits) — layered on the shared `global-requirements-sentinel-solutions.md` (G1–G7). |
| **Implementation** (`03-implementation.md`) | Exact, ordered build: assess the surface, stand up read-only RBAC + the KQL library + register + cadence, run pilot hunts read-only and document them, hand off confirmed findings to IR, validate and promote a win, then expand on a cadence — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from surface-has-data and read-only-access through library-runs-clean, findings-documented-and-bookmarked, confirmed-true-positives-handed-off, at-least-one-hunt-promoted, and cadence-established, referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (hunt returns nothing/too much, schema/column errors, retention/limit truncation, Graph `runHuntingQuery` throttling, RBAC too broad or too narrow, bookmark/entity issues, promotion floods, Gov-cloud/endpoint errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-from-a-hypothesis, hunt-against-a-map, stay-read-only, document-so-knowledge-compounds, promote-wins, run-it-as-a-program — plus where to go next in the catalog. |
| **GCC High Parity Notes** (`gcc-high-parity-notes.md`) | The Government-edition addendum: the national-cloud endpoints this solution uses (`security.microsoft.us`, `portal.azure.us`, `graph.microsoft.us` / DoD `dod-graph.microsoft.us`, `login.microsoftonline.us`), the GCC High/DoD **feature-parity gaps** (advanced-hunting schema/limits, Defender pillar & table availability) each flagged *verify against current Microsoft Government documentation*, and the **compliance & data-residency context** (FedRAMP High, DoD IL4/IL5, CMMC 2.0, ITAR/EAR, US-persons). |

## Hunt library & PowerShell tools (5)

All tools are **read-only** (they run KQL and report — no response actions, **no credentials in code**)
and target both platforms: **Microsoft.Graph** (`Microsoft.Graph.Security` —
`Invoke-MgSecurityRunHuntingQuery`) for Defender XDR advanced hunting, and the **Az** modules
(`Az.Accounts`, `Az.OperationalInsights`, `Az.SecurityInsights`) for Sentinel. The scripts default to the
US Gov cloud (`Connect-MgGraph -Environment USGov` / `Connect-AzAccount -Environment AzureUSGovernment`;
DoD: `-Environment USGovDoD`) — *verify the correct national-cloud endpoints and scopes for your cloud
against current Microsoft Government documentation.*

| File | Type | What it does |
| --- | --- | --- |
| **`THREATHUNTG-HuntLibrary.kql`** | KQL library | `Hunt Library - Tenant - Main` — the **MITRE ATT&CK-aligned reusable hunt library**: real, ready-to-run KQL hunts, each with a header block (name, hypothesis, tactic/technique, target surface XDR-vs-Sentinel, and a promotion note), plus a template header to add more. The core deliverable the whole program hunts from. |
| **`THREATHUNTG-Discovery.ps1`** | Read-only | Inventories the hunting surface: which advanced-hunting tables and which Sentinel tables have recent data, and the existing Sentinel hunt queries, bookmarks, and custom detection rules — so hunting starts from reality. Changes nothing. |
| **`THREATHUNTG-RunHuntLibrary.ps1`** | Read-only | Executes every hunt in `THREATHUNTG-HuntLibrary.kql` across the correct platform (Defender via `runHuntingQuery`, Sentinel via the Log Analytics query API) and reports a per-hunt row count. The automation that runs the whole library in one pass. **Runs queries only — it never acts.** |
| **`THREATHUNTG-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as pass/fail lines: surface has data, the hunter RBAC group is **read-only** (flags any write role), the expected hunts are saved/tagged, pilot hunts documented, and at least one successful hunt **promoted** to a `-Prod` detection. |
| **`THREATHUNTG-Report.ps1`** | Read-only | Hunt-program metrics: hunts run over the window, findings/bookmarks, incidents handed off, and promotions to detections, plus a coverage view of which ATT&CK techniques are actively hunted. Exports to CSV — the trend that shows the program maturing. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Read-only hunter RBAC group:** `Threat Hunters - Tenant - Group`
- **Reusable KQL hunt library:** `Hunt Library - Tenant - Main` (`THREATHUNTG-HuntLibrary.kql`)
- **Findings home:** `Hunt Register - Tenant - Main`; bookmarks `Bookmark-<Hunt>-Finding`
- **Cadence:** `Hunt Cadence - Tenant - Monthly`
- **Pilot hunts (worked examples in the library):**
  - `Hunt-LOLBins-Devices-Pilot` — **T1059** Command and Scripting Interpreter (Execution), Defender XDR
  - `Hunt-RareParentChild-Devices-Pilot` — **T1055 / T1036** (Defense Evasion), Defender XDR
  - `Hunt-InboxRules-M365-Pilot` — **T1114 / T1564** (Collection), Defender XDR / Sentinel
  - `Hunt-RareServiceSignin-Entra-Pilot` — **T1078** Valid Accounts, Sentinel
  - `Hunt-BeaconEgress-Network-Pilot` — **T1071** Application Layer Protocol (Command & Control), Defender XDR
- **Promoted detections:** `Rule-<Hunt>-Prod` (Sentinel scheduled rule), `CD-<Hunt>-Prod` (Defender custom detection)

## What this solution deliberately does NOT do

- It does **not** respond — no isolation, account disablement, mailbox purge, eradication, or escalation.
  Those are the companion *M365 & Azure Incident Response & Escalation Runbook*; this solution hands
  confirmed findings **to** it and stops.
- It does **not** connect data sources or size the workspace — that is the *Deploy Microsoft Sentinel:
  Workspace, Data Connectors & Ingestion* solution; a hunt only finds what is ingested.
- It does **not** fully tune the detections it promotes — the *Microsoft Sentinel Analytics Rules & MITRE
  ATT&CK Detection Coverage* solution owns rule tuning; this solution performs the promotion.
- It does **not** decide which techniques matter most or your risk tolerance — those are
  security-leadership determinations that prioritize the hunt backlog.
- It does **not** invent schema, retention, licensing, or limit facts — where availability may differ by
  tenant/cloud/license it says **verify in your tenant**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation
as a formatted Word document and PDF, plus the KQL hunt library and all four PowerShell tools, in a
single ZIP (`THREATHUNTG-Complete-Solution.zip`) — yours to keep and reuse on every tenant and every hunt
cycle.
