# 1. Solution Overview — Microsoft Purview Reporting & Power BI Framework

## What this solution is
Microsoft Purview generates a great deal of compliance signal — DLP policy matches, sensitivity- and
retention-label activity, audit events, alerts, and compliance/secure-score posture — but that signal
lives inside the Purview portal's built-in reports, one workload at a time, behind licensing and role
gates. Leadership rarely opens the portal, so the picture never reaches the people who own the risk.
This solution is a repeatable **reporting framework**: it defines a governed set of Purview data
exports (pulled from **Microsoft Graph** and **Security & Compliance PowerShell**), a consistent
dataset shape, and a **Power BI** dashboard model built on top of that data — so the compliance
posture becomes a small number of dashboards a leader actually reads, refreshed on a schedule, with a
documented, defensible data lineage. It uses only Microsoft-native tooling (Purview portal, Graph,
Security & Compliance PowerShell, Power BI) — no third-party product.

> **Boundary.** This solution delivers the **reporting capability** — the pipeline, dataset, and
> dashboards — and the evidence behind each number. It does **not** make the underlying
> **regulatory, records-retention, or legal determinations** (what to retain, what a DLP match
> means legally, whether an insider-risk signal warrants action). Those stay with the organization's
> **compliance, records, privacy, HR, and legal** functions. Purview capabilities are heavily
> **licensing-/plan-dependent** (many reporting sources require **Microsoft 365 E5** or the **E5
> Compliance** add-on; some are in preview) and the portal is evolving — every data source below is
> flagged **"verify your licensing/tenant"** rather than assumed.

## Why this matters
- **Portal reports don't reach leadership.** Each Purview report is scoped to one capability and one
  admin audience; there is no native cross-capability, leadership-ready view. The gap between "the
  data exists" and "the board saw it" is itself a compliance and data-risk exposure.
- **A trend beats a snapshot.** A single portal screenshot is a point in time; a governed, scheduled
  dataset lets you show *direction* — DLP matches falling after a policy tightened, label coverage
  rising, audit activity within expected bounds.
- **Defensibility.** When an auditor or regulator asks "how do you know," a reporting framework with
  a documented source (which Graph endpoint / which cmdlet), a refresh cadence, and a validation gate
  is an answer; an ad-hoc export is not.
- **Privacy discipline.** Insider-risk and communication-compliance data is HR/privacy-sensitive.
  This framework reports **aggregate counts only** for those sources (never case content or named
  subjects) and keeps role separation intact — reporting operators never gain case access.

## How it works
1. **Scope** is defined first: which Purview capabilities are in scope (DLP, sensitivity labels,
   retention/records, audit, alerts, secure/compliance score, and *aggregate-only* insider-risk /
   communication-compliance counts), which workloads (Exchange, SharePoint, OneDrive, Teams,
   endpoints), and the reporting date window.
2. **Data is pulled read-only** from two sources: **Microsoft Graph** (security alerts, secure score,
   audit-log queries) and **Security & Compliance PowerShell** (`Export-ActivityExplorerData` for
   label/DLP activity, `Get-ProtectionAlert`, `Search-UnifiedAuditLog`). Each pull writes to a
   consistent, dated export set — the framework's single source of truth.
3. **The exports are shaped into a stable dataset** (a fixed set of columns per source) so the Power BI
   model does not break when a portal report changes layout. The dataset is the contract between the
   pipeline and the dashboards.
4. **Power BI dashboards** are built on the dataset — one page per capability plus an executive summary
   page — first in a **pilot workspace**, validated against the portal's own numbers, then promoted to
   a production workspace with a scheduled refresh.
5. **The pipeline is health-checked** on each run (connections succeed, exports are fresh, row counts
   are sane) so a silent failure never produces a stale-but-plausible dashboard.

## The reporting sources (each licensing-gated — verify your tenant)
| Source | Pulled via | Typical licensing |
|---|---|---|
| DLP & label activity (Activity Explorer) | `Export-ActivityExplorerData` (S&C PowerShell) | E5 / E5 Compliance — verify |
| Purview alerts (DLP, IP, etc.) | `Get-ProtectionAlert` (S&C PowerShell) / Graph `security/alerts_v2` | E3 baseline, E5 for advanced — verify |
| Audit activity | `Search-UnifiedAuditLog` / Graph `security/auditLog/queries` | Audit Standard (E3) / Premium (E5) — verify |
| Compliance / secure-score posture | Graph `security/secureScores` | Verify per tenant |
| Insider risk / comm. compliance | **aggregate counts only** (portal export) | E5 / E5 Compliance — verify |

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, Purview portal, and Power BI.

| Artifact | Name |
|---|---|
| Reporting scope definition | `Reporting Scope – Purview – Config` |
| Dated export set | `Purview Data Export – AllSources – Report` |
| Export storage location | `Purview Exports – <yyyyMM> – Report` |
| Dashboard dataset | `Purview Compliance Dataset – Report` |
| Pilot Power BI workspace | `Purview Reporting – Pilot – Stage1` |
| Production Power BI workspace | `Purview Reporting – Prod – Stage2` |
| Scheduled refresh | `Purview Refresh – Daily – Recurring` |
| Pipeline health log | `Purview Pipeline Health – Report` |

## The standard deployment model
> Assess the available sources and licensing → design the dataset and dashboard pages → configure the
> exports and build the pilot workspace → **pilot in a test workspace and validate every number
> against the portal** → expand to the production workspace with a scheduled refresh.
> Pattern: **Assess → Design → Configure → Pilot (validate) → Validate → Expand.**

## What you can control
- Which Purview capabilities and workloads are in scope, and the reporting date window.
- The dataset shape (which columns each source contributes) and the dashboard page set.
- The pilot audience that reviews the dashboards before production promotion.
- The refresh cadence (e.g. daily) and who receives the leadership view.
- The privacy posture for HR-sensitive sources (aggregate-only, role-separated).

## Limitations (be honest with buyers)
- **Licensing gates the data, not the framework.** If a source (e.g. Activity Explorer) is not
  licensed in your tenant, that dashboard page has no data until the licensing is in place — the
  framework flags it rather than inventing numbers.
- **Latency.** Audit and Activity Explorer data has ingestion latency (often hours to a day); a
  dashboard reflects data up to the source's own delay, not real time.
- **Portal parity.** Portal reports and PowerShell/Graph exports can differ slightly in how they
  aggregate; the validation gate documents the reconciliation so a small variance is explained, not a
  surprise.
- **Insider-risk / communication-compliance content is out of scope by design** — only aggregate
  counts are reported, to preserve privacy and role separation.
