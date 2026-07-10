# 1. Solution Overview — Microsoft Sentinel Cost & Data-Tier Optimization

## What this is

A structured cost-optimization method for Microsoft Sentinel and its underlying Log Analytics workspace. It finds where the money goes (ingestion audit), puts every table on the cheapest tier that still meets its use case (table tiering), stops paying for noise (DCR filtering), matches retention and archive to actual need, and sizes a commitment tier — then produces a monthly forecast. The discipline: **never trade away detection coverage for savings** — every change is validated on a pilot table before it is applied broadly.

## How the technology works — what you actually pay for

Sentinel/Log Analytics cost is driven by three things:

- **Ingestion** — you pay per GB of data ingested. This is usually the largest line item, and it is dominated by a few high-volume tables.
- **Retention** — data is kept in **interactive retention** (queryable, included up to a point then billed per GB/month) and can then move to **long-term/archive** (much cheaper per GB/month, but restore/search costs apply when you need it).
- **The tier the data lands in.** Log Analytics offers different **table plans**:
  - **Analytics** — full-featured: real-time analytics rules, full KQL, workbooks, UEBA. The most expensive per GB. Use it for data your detections and hunting actually query.
  - **Basic logs** — much cheaper ingestion, but limited: a reduced query surface, shorter interactive retention, and per-query search cost. Good for high-volume, verbose logs you rarely query and do not run scheduled analytics on.
  - **Auxiliary logs** — the cheapest ingestion tier, aimed at high-volume, low-fidelity data kept mainly for occasional investigation/compliance, with search-based access. *Tier names, eligibility per table, and pricing change over time and by region — verify current availability in your tenant.*

Two more levers reduce the bill before and after ingestion:

- **DCR (Data Collection Rule) filtering** — a transformation on the DCR can **drop or trim** rows/columns before they are ingested, so noise never becomes a billed GB. This is the highest-leverage change because it cuts cost at the source.
- **Commitment (capacity) tiers** — instead of pay-as-you-go, you commit to a daily GB tier at a discount. If your steady daily volume comfortably exceeds a tier threshold, committing saves money; if it is spiky or low, pay-as-you-go is safer. The forecast tells you which.

## The standard deployment model

This solution follows the same five-stage model as every solution in this program:

`Assess -> Configure -> Pilot -> Validate -> Expand`

- **Assess** — run the ingestion audit; rank tables by volume and cost; identify the biggest, lowest-value contributors and which tables your analytics rules and hunting actually query.
- **Configure** — decide, per table, the target tier and retention; design any DCR filter; model a commitment tier. Change nothing yet beyond the plan.
- **Pilot** — apply the change to **one** high-volume, low-value table (a tier move and/or a DCR filter and a retention change). Keep everything else untouched.
- **Validate** — confirm the pilot table's cost dropped **and** that no analytics rule, workbook, or hunting query that depends on it broke. This is the coverage gate.
- **Expand** — apply the same pattern to the next tables in the ranked list, re-forecast, and — if steady volume warrants — move to a commitment tier.

## Naming convention

Every object/decision created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the guide, testing, and scripts:

- DCR filter transformation: `Noise Filter - <TableName> - Pilot`
- Retention/tier decision record: `Tier Decision - <TableName> - Pilot`
- Commitment-tier decision record: `Commitment Sizing - Workspace - Pilot`
- Cost forecast: `Cost Forecast - Workspace - Pilot`

## Scope

- An ingestion audit ranking tables by volume and cost with keep/cut/retier recommendations.
- Table tiering — moving low-value high-volume tables from Analytics to Basic/Auxiliary where the use case allows.
- DCR filtering to drop noise before ingestion.
- Retention and archive strategy (interactive vs long-term) set per table.
- Commitment-tier sizing and a monthly cost forecast.

## What is out of scope

- The **decision** of which data must be retained for how long for regulatory, records, or legal reasons — that is a compliance/legal/records determination for the customer to own; this guide gives you the technical levers and the cost of each option, not the retention policy.
- Building the detections themselves (see *Sentinel Analytics Rules & MITRE ATT&CK Coverage*) — though this solution tells you which tables those detections depend on so you do not retier data they need.
- Standing up ingestion/connectors (see *Deploy Microsoft Sentinel — Workspace & Connectors*).

## Authentication and connections used

- **Az PowerShell** and the Log Analytics query API against the workspace (read-only for the audit/report/forecast scripts). Requires Log Analytics Reader to query, and Contributor on the workspace to apply tier/retention/DCR changes.
- No external services; all analysis runs against your own workspace's `Usage` and billing data.

## Benefits

- A materially lower bill for the same coverage — most of the saving comes from a small number of tables.
- A forecast you can defend to a budget owner, updated each cycle.
- Cost control that is safe by design — nothing is retiered or filtered until a pilot proves coverage is intact.

## Limitations and honest constraints

- **Basic/Auxiliary tiers reduce capability**, not just cost: limited KQL, no/limited scheduled analytics, per-query search charges. Only move tables your detections do not query. *Verify which tables are eligible for Basic/Auxiliary in your tenant — eligibility and tier names change.*
- **DCR filtering drops data permanently** — filtered rows are never ingested and cannot be recovered. Filter only genuine noise, and pilot the filter first.
- **Commitment tiers are a financial commitment** — if volume drops below the tier you may overpay. Size from a real forecast, not a guess.
- Pricing, tier availability, and archive/search costs vary by region and change over time — *verify current pricing in the Azure Pricing Calculator for your region before committing.*
