# Microsoft Sentinel Cost & Data-Tier Optimization

> **Version 1.0.0** · Category: Sentinel Solutions · Solution code: SENTCOST

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Sentinel Cost & Data-Tier Optimization

**Sentinel Solutions**

Microsoft Sentinel bills primarily on the data you ingest and retain — and unmanaged ingestion is where security budgets quietly disappear. A handful of chatty, low-value tables often account for the majority of the bill, high-volume verbose logs land in the premium Analytics tier when they belong in a cheaper one, and noisy events get paid for at the source instead of being filtered out before they arrive. This solution gives you a disciplined way to cut the bill **without losing coverage**: audit what you ingest, right-tier every table (Analytics vs Basic/Auxiliary), filter noise at the data collection rule, set retention and archive deliberately, and size a commitment tier — then forecast the monthly spend so you can defend it.

This is a complete, do-it-today package for optimizing Microsoft Sentinel and Log Analytics cost, written for an administrator with no prior FinOps or KQL-cost experience.

## What you get

- A plain-language Solution Overview of the cost model — what Sentinel/Log Analytics actually charge for, the data tiers (Analytics, Basic, Auxiliary), retention vs archive, and commitment tiers.
- A Requirements Guide with verify / implement-if-missing for every prerequisite specific to cost analysis.
- An Implementation Guide of precise, ordered steps — run the ingestion audit, decide each table's tier, add DCR filtering, set retention/archive, and size a commitment tier — all pilot-first so you never move a table blind.
- Five PowerShell/KQL scripts for an ingestion-cost audit, a tiering-recommendation analysis, a DCR/retention validation, a monthly cost forecast, and a safe retention/tier-change helper (default `-WhatIf`).
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers

A leaner Sentinel bill with the same (or better) detection coverage — the top cost-driving tables identified, low-value high-volume tables moved to Basic/Auxiliary, noise filtered at the DCR before it is ingested, retention and archive right-sized per table, a commitment tier chosen to match steady volume, and a monthly forecast you can put in front of a budget owner — validated on a pilot table before you touch the rest.

## The standard deployment model

`Assess -> Configure -> Pilot -> Validate -> Expand`, with a pilot gate that proves a single table's tier/DCR/retention change saved money **and** kept the detections you rely on, before applying the pattern workspace-wide.

## Outcome

A defensible, forecast-backed Sentinel bill — every table on the right tier, noise filtered before it is paid for, retention matched to need, and a commitment tier sized to your steady volume — achieved without dropping the coverage your SOC depends on.


---


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


---


# 2. Requirements Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first. The requirements below are specific to cost and data-tier optimization.

## 2.1 At least ~31 days of ingestion history in the workspace

- **Description:** The workspace should have roughly a month (or more) of representative ingestion so the audit reflects real, steady volume rather than a partial or atypical window.
- **Why:** Tiering, DCR, and commitment-tier decisions are only as good as the volume data behind them; a short or unusual window produces misleading recommendations.
- **Verify:** `Microsoft Sentinel`/`Log Analytics` → `Logs` → run `Usage | summarize sum(Quantity) by bin(TimeGenerated, 1d) | order by TimeGenerated asc` and confirm ~30 days of data. Run `SENTCOST-Audit.ps1`.
- **Implement-if-missing:** Wait until enough history accrues, or scope the audit to the window available and note it as an estimate to be revisited.

## 2.2 Read access to workspace usage and billing data

- **Description:** A role that can query the `Usage` table and read the workspace's pricing/retention configuration (Log Analytics Reader is enough for the read-only audit/report/forecast).
- **Why:** The audit, tiering analysis, and forecast all read the `Usage` table and the table/workspace configuration; without read access nothing can be measured.
- **Verify:** On the workspace, `Access control (IAM)` → confirm Log Analytics Reader (or higher). In `Logs`, `Usage | take 5` returns rows. Run `SENTCOST-Audit.ps1`.
- **Implement-if-missing:** Assign Log Analytics Reader (read-only work) or Contributor (to also apply changes) on the workspace, scoped per least privilege.

## 2.3 Contributor rights to change table plan, retention, and DCRs

- **Description:** Contributor (or a role that can edit table plans, table/workspace retention, and Data Collection Rules) — needed only for the *apply* steps, not the read-only audit.
- **Why:** Moving a table to Basic/Auxiliary, changing retention/archive, and editing a DCR transformation all require write access to those resources.
- **Verify:** On the workspace and the relevant DCRs, `Access control (IAM)` → confirm Contributor. Opening a table's `Manage table` blade shows editable plan/retention.
- **Implement-if-missing:** Assign the minimum write role at the workspace/DCR scope; prefer PIM-eligible activation over standing access.

## 2.4 An inventory of what your detections and hunting depend on

- **Description:** A list of which tables your active analytics rules, workbooks, and saved hunting queries actually query — so you never retier or filter data a detection needs.
- **Why:** Moving a table to Basic/Auxiliary or filtering it at the DCR can break a scheduled analytics rule or a hunt. Knowing the dependency is what makes the optimization safe.
- **Why tier limits matter:** Basic/Auxiliary tables cannot run scheduled analytics rules the same way Analytics tables can — a rule pointed at a retiered table may silently stop. *Verify current tier query limitations in your tenant.*
- **Verify:** `Microsoft Sentinel` → `Analytics` → review each active rule's query for the tables it uses; check workbooks and hunting queries. Run `SENTCOST-Tiering.ps1`, which cross-references high-volume tables against a supplied rule-table list.
- **Implement-if-missing:** Export the active analytics rules and note the tables each references; mark those tables as "keep on Analytics" in the tier decisions.

## 2.5 A retention and archive policy decision (owned by the customer)

- **Description:** A written decision on how long each class of data must remain queryable (interactive) and how long it must be retained at all (archive/long-term), with the compliance/records owner identified.
- **Why:** Retention drives a large share of cost, but how long data must be kept is a compliance/legal/records determination — the guide provides the levers and the cost of each, not the policy.
- **Verify:** A written retention policy exists per table class, with an owner. Run `SENTCOST-Validate.ps1` to compare configured retention against the policy.
- **Implement-if-missing:** Have the compliance/records owner set required interactive and total retention per data class; record it before changing any table's retention.

## 2.6 A budget owner and a target

- **Description:** The person who owns the Sentinel/Log Analytics budget and an agreed savings target or spend ceiling to optimize toward.
- **Why:** The forecast and commitment-tier decision need a target to be measured against; "cheaper" is not actionable without a number.
- **Verify:** The budget owner and target are documented. Run `SENTCOST-Forecast.ps1` to produce the current-vs-optimized monthly projection.
- **Implement-if-missing:** Identify the budget owner; agree a target or ceiling; record it with the forecast (`Cost Forecast - Workspace - Pilot`).

## 2.7 A pilot table chosen

- **Description:** A single high-volume, low-value table selected as the pilot for the first tier/DCR/retention change, with success criteria (cost drops and no dependent detection breaks).
- **Why:** The standard model proves the pattern on one table before touching the rest, so a mistake affects one table, not the whole workspace.
- **Verify:** The pilot table and its pass criteria are written down; the audit confirms it is high-volume and the dependency check confirms it is low-value to detections. Run `SENTCOST-Audit.ps1` and `SENTCOST-Tiering.ps1`.
- **Implement-if-missing:** From the ranked audit, pick the largest table that no active analytics rule queries as the pilot; record the gate before changing it.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements
- [ ] ~31 days of representative ingestion history — `SENTCOST-Audit.ps1`
- [ ] Read access to `Usage`/billing data — `SENTCOST-Audit.ps1`
- [ ] Contributor rights for the apply steps (table plan, retention, DCR)
- [ ] Inventory of tables your detections/hunting depend on — `SENTCOST-Tiering.ps1`
- [ ] Retention/archive policy decided by the compliance/records owner — `SENTCOST-Validate.ps1`
- [ ] Budget owner and savings target agreed — `SENTCOST-Forecast.ps1`
- [ ] Pilot table chosen with pass criteria — `SENTCOST-Audit.ps1` / `SENTCOST-Tiering.ps1`


---


# Global Requirements — Sentinel Solutions

These requirements are common to **every** Sentinel Solutions solution in the standard program model. They are the baseline Azure Monitor / Microsoft Sentinel platform prerequisites that any telemetry, detection, or SIEM engagement assumes. Each is structured **Description / Why / Verify / Implement-if-missing**. Solution-specific requirements (see `02-requirements.md`) are layered on top of these.

> Naming convention: every created object is named `<Purpose> - <Scope> - <Stage>` and reused verbatim throughout the engagement (for example `Audit Telemetry - Tenant - Pilot`).

---

## G1. An Azure subscription

- **Description:** An active Azure subscription in the tenant in scope, with billing enabled.
- **Why:** A Log Analytics workspace and Microsoft Sentinel are Azure resources billed against a subscription; nothing can be provisioned without one.
- **Verify:** Sign in to `https://portal.azure.com`, open `Subscriptions`, and confirm an active subscription resolves and shows status `Active`.
- **Implement-if-missing:** Create or associate an Azure subscription (Enterprise Agreement, CSP, or pay-as-you-go) and confirm billing is in place.

## G2. A Log Analytics workspace

- **Description:** A Log Analytics workspace to receive and store ingested telemetry, sized to the data volume and retention in scope.
- **Why:** Microsoft Sentinel runs on top of a Log Analytics workspace; all log data lands here and all queries/analytics run against it.
- **Why region matters:** the workspace region determines data residency and affects egress; pick one deliberately before ingestion starts (it cannot be moved later).
- **Verify:** `portal.azure.com` → `Log Analytics workspaces` → confirm the target workspace exists, note its region and resource group.
- **Implement-if-missing:** Create a workspace named `Security Telemetry - Tenant - Workspace`; choose the region for residency; select the pricing tier that fits expected daily ingestion.

## G3. Microsoft Sentinel enabled on the workspace

- **Description:** Microsoft Sentinel added to (enabled on) the Log Analytics workspace in scope.
- **Why:** Connectors, analytics rules, hunting, and incidents are Sentinel features layered on the workspace; without Sentinel enabled you have logs but no SIEM.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → confirm the workspace is listed.
- **Implement-if-missing:** `Microsoft Sentinel` → `Create` → select the workspace → `Add`.

## G4. Administrative roles (least privilege)

- **Description:** Appropriately scoped roles for the work — Microsoft Sentinel Contributor (or Log Analytics Contributor) on the workspace for configuration, plus the tenant roles needed to set diagnostic settings on the sources (for example a role that can edit Entra ID diagnostic settings).
- **Why:** Each configuration action requires sufficient privilege; least-privilege scoping limits blast radius and satisfies audit requirements.
- **Verify:** On the workspace/resource group, `Access control (IAM)` → confirm the operating accounts hold the required roles. In Entra → `Roles & admins`, confirm the role that can edit diagnostic settings.
- **Implement-if-missing:** Assign the minimum roles needed at the resource-group or workspace scope; prefer eligible (PIM) activation over standing access where available.

## G5. Ingestion and retention cost plan

- **Description:** A documented estimate of daily ingestion (GB/day) and a retention decision (interactive retention vs long-term/archive), with a budget owner.
- **Why:** Sentinel and Log Analytics are billed primarily on data ingested and data retained; identity and device audit logs can be high-volume, so cost must be planned before connectors are switched on.
- **Verify:** Confirm a written estimate exists (sources × expected GB/day) and that retention periods are agreed per table or workspace.
- **Implement-if-missing:** Estimate volume from the source log categories in scope; choose pay-as-you-go or a commitment tier; set workspace/table retention; record the budget and owner.

## G6. Diagnostic settings capability on each source

- **Description:** The ability to create diagnostic settings (or enable the relevant data connector) on every source whose telemetry is in scope.
- **Why:** Telemetry only flows to the workspace when a diagnostic setting (or connector) routes the source's log categories to it; this is the switch that turns the pipeline on.
- **Verify:** For each source, confirm a diagnostic setting can be created and that no existing setting already routes the same categories elsewhere (to avoid duplicate ingestion and double billing).
- **Implement-if-missing:** Plan one named diagnostic setting per source that forwards the in-scope categories to the workspace (named per G's convention).

## G7. Change control & rollback posture

- **Description:** An approved change process with a scheduled window, plus a documented rollback (which diagnostic settings/connectors/analytics rules were added) before any change.
- **Why:** Enabling connectors and analytics rules changes ingestion volume (and therefore cost) and can generate incidents; controlled changes and a recorded back-out keep the pipeline safe and auditable.
- **Verify:** Confirm an approved change record and a written list of objects to be created (so they can be removed cleanly).
- **Implement-if-missing:** Stand up a lightweight change/approval process; capture the pre-change configuration; document the rollback (delete the named diagnostic setting / disable the connector / disable the rule).


---


# 3. Implementation Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Follow these steps **in order**. They use the Azure portal (`https://portal.azure.com`) for Log Analytics, Microsoft Sentinel, and Data Collection Rules, plus the `Logs` (KQL) blade for the audit. Audit first, decide per table, then change **one pilot table** and prove coverage is intact before applying the pattern workspace-wide.

> Model: audit ingestion → decide tier/retention/filter per table → apply to one pilot table → validate savings + coverage (the gate) → expand. Every decision/object is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects/decisions this guide creates (name them exactly):

- DCR filter transformation: `Noise Filter - <TableName> - Pilot`
- Per-table tier/retention decision record: `Tier Decision - <TableName> - Pilot`
- Commitment-tier decision record: `Commitment Sizing - Workspace - Pilot`
- Cost forecast: `Cost Forecast - Workspace - Pilot`

## Step 1 — Run the ingestion audit (find the money)

1. `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Logs`.
2. Run the top-tables-by-volume audit query (30-day window):
   ```kql
   Usage
   | where TimeGenerated > ago(31d)
   | where IsBillable == true
   | summarize BillableGB = round(sum(Quantity) / 1000, 2) by DataType
   | order by BillableGB desc
   ```
3. Note the top 10 `DataType` (table) contributors — these drive the bill. Run `SENTCOST-Audit.ps1` for the same ranking plus a per-day trend and an estimated cost (using a rate you supply).
4. Record the ranked list; the top few tables are your optimization targets.

## Step 2 — Map detection dependencies (protect coverage)

1. `Microsoft Sentinel` → `Configuration` → `Analytics` → `Active rules`. For each rule, open it and note the tables its query uses. Do the same for key workbooks and saved hunting queries.
2. Run `SENTCOST-Tiering.ps1 -RuleTables <comma-separated table list>` — it cross-references your top-volume tables against the tables your detections use and flags which are **safe to retier** (high volume, not queried by any rule) vs **keep on Analytics** (a rule depends on them).
3. For each top table, write a `Tier Decision - <TableName> - Pilot` record: target tier (Analytics / Basic / Auxiliary), rationale, and whether any detection depends on it.

## Step 3 — Choose the pilot table

1. From Steps 1-2, pick the **largest table that no active analytics rule queries** as the pilot (Requirement 2.7). A verbose, high-volume informational log is the classic candidate.
2. Write its pass criteria: measurable cost drop **and** no dependent rule/workbook/hunt breaks.

## Step 4 — Design the DCR noise filter for the pilot table

1. Identify the noise within the pilot table — rows or columns you never need (for example, specific verbose event IDs, health/heartbeat chatter, or unused columns). Confirm with a KQL query that these rows are genuinely low-value:
   ```kql
   <PilotTable>
   | where TimeGenerated > ago(7d)
   | summarize count() by <NoiseColumn>
   | order by count_ desc
   ```
2. `portal.azure.com` → `Monitor` → `Data Collection Rules` → open the DCR feeding the pilot table (or the workspace's default ingestion-time transformation).
3. Add/edit the transformation KQL to drop the noise, for example:
   ```kql
   source
   | where not(<NoiseColumn> in ('<verbose-value-1>','<verbose-value-2>'))
   ```
   Name this change `Noise Filter - <TableName> - Pilot` in your change record.
4. **Filter only genuine noise** — dropped rows are never ingested and cannot be recovered. Keep the filter narrow for the pilot.

## Step 5 — Set the pilot table's tier and retention

1. `Log Analytics workspaces` → (workspace) → `Tables` → find the pilot table → `Manage table`.
2. If the table is eligible and your decision says so, change the **table plan** to `Basic` (or `Auxiliary`) — *verify the table is eligible in your tenant; not all tables can be retiered.*
3. Set **interactive retention** and **total (archive) retention** to the values in your retention policy (Requirement 2.5), recorded as `Tier Decision - <TableName> - Pilot`.
4. Save. Note that a tier change affects data ingested from that point forward; existing data keeps its original plan.

## Step 6 — Size the commitment tier and build the forecast

1. Run `SENTCOST-Forecast.ps1 -PerGBRate <your-analytics-rate> -CommitmentTiers <e.g. 100,200,300,400,500>` — it takes your steady daily GB (from the audit), compares pay-as-you-go against each commitment tier at your region's rates, and outputs the cheapest option plus a projected monthly bill (current vs optimized).
2. Record the recommendation as `Commitment Sizing - Workspace - Pilot` and the projection as `Cost Forecast - Workspace - Pilot`.
3. **Do not commit yet** — the commitment tier is applied in Expand, after the pilot proves the tiering/filtering savings are real. *Verify current commitment-tier thresholds and pricing for your region in the Azure Pricing Calculator.*

## Step 7 — Validate the pilot (the gate)

1. Wait for a representative window after the change (at least a few days of ingestion at the new tier/with the filter).
2. Run `SENTCOST-Validate.ps1` → confirms the pilot table's configured tier and retention match the `Tier Decision` record and that the DCR filter is active.
3. Run `SENTCOST-Audit.ps1` again → confirm the pilot table's billable GB dropped versus the baseline.
4. **Coverage check (the critical gate):** confirm no analytics rule, workbook, or hunting query that should still work is now broken or empty. Re-run any hunt that touches the table; confirm active rules still fire. Complete the Testing Guide.
5. **Pilot gate:** do not expand until the pilot table shows a real cost drop **and** coverage is intact.

## Step 8 — Expand

1. Once the gate passes, apply the same pattern (Steps 4-5) to the next tables in the ranked list, one at a time, writing a `Tier Decision - <TableName> - Production` record for each.
2. Re-run `SENTCOST-Forecast.ps1` with the new steady volume; if it now clearly favors a commitment tier, apply the commitment tier on the workspace (`Usage and estimated costs` → `Commitment tier`) — this is the point where you make the financial commitment, backed by the forecast.
3. Re-run `SENTCOST-Audit.ps1` and `SENTCOST-Forecast.ps1` each cycle to track savings against the budget target (Requirement 2.6) and catch any table whose volume grows.

---

### Order of operations

`ingestion audit -> detection-dependency map -> choose pilot table -> DCR noise filter -> tier + retention change -> commitment-tier forecast (no commit yet) -> validate savings + coverage (gate) -> expand table-by-table -> apply commitment tier`


---


# 5. Testing Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Run after the pilot table's change is configured (Implementation Step 7) and after each expansion. The two things every test must prove together: the bill went **down**, and coverage stayed **intact**.

## Test 1 — Baseline captured

**Do:** Before any change, run `SENTCOST-Audit.ps1` and save the output. Or in `Logs`, capture the 31-day billable GB per table.
**Expected:** A saved baseline of billable GB per table, so post-change savings are measurable.

## Test 2 — Pilot table is high-volume and low-value

**Do:** Run `SENTCOST-Tiering.ps1 -RuleTables <rule table list>`.
**Expected:** The pilot table appears among the top-volume tables and is flagged **safe to retier** (no active analytics rule queries it).

## Test 3 — DCR filter is active and dropping only noise

**Do:** `Monitor` → `Data Collection Rules` → confirm `Noise Filter - <TableName> - Pilot` transformation is present. In `Logs`, query the table for the filtered values over a window after the change.
**Expected:** The transformation is live; the noise rows no longer appear post-change, while legitimate rows still arrive.

## Test 4 — Table tier and retention match the decision

**Do:** Run `SENTCOST-Validate.ps1`. Or `Log Analytics workspaces` → `Tables` → `Manage table` for the pilot table.
**Expected:** The table plan (Analytics/Basic/Auxiliary) and interactive/archive retention match `Tier Decision - <TableName> - Pilot`.

## Test 5 — Billable volume dropped

**Do:** After a representative window, re-run `SENTCOST-Audit.ps1` and compare to the Test 1 baseline.
**Expected:** The pilot table's billable GB is measurably lower (from the DCR filter and/or the cheaper tier).

## Test 6 — Coverage is intact (the critical test)

**Do:** Re-run every analytics rule, workbook, and hunting query that touches (or is near) the pilot table. `Microsoft Sentinel` → `Analytics` → confirm rules still fire; run saved hunts.
**Expected:** Nothing that should still work is broken or returning empty because of the change. If anything is, roll back the tier/filter for that table (Troubleshooting).

## Test 7 — Forecast produced and defensible

**Do:** Run `SENTCOST-Forecast.ps1` with your region's rate and candidate commitment tiers.
**Expected:** A current-vs-optimized monthly projection and a recommended pay-as-you-go-or-commitment decision, recorded as `Cost Forecast - Workspace - Pilot`.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass: the pilot table's billable GB dropped, its tier/retention/filter match the decision, and **no dependent detection, workbook, or hunt broke** |
| Expand pass | Tests 5 and 6 pass for each additional table before moving on, and the re-forecast confirms savings against the budget target before any commitment tier is applied |


---


# 6. Troubleshooting Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Common failures, their cause, and the fix. Work top-down; most issues are permissions, tier eligibility, or a filter that was too aggressive.

## The audit query returns nothing (or errors)

- **Symptom:** `SENTCOST-Audit.ps1` or the `Usage` query returns no rows or a 403.
- **Cause:** No read access to the workspace, or the `Usage` table has no billable data in the window.
- **Fix:** Confirm Log Analytics Reader on the workspace (Requirement 2.2). Confirm the workspace actually has ~31 days of ingestion (Requirement 2.1); if newer, shorten `-Days`. Re-run.

## A retiered table broke an analytics rule or hunt

- **Symptom:** After moving a table to Basic/Auxiliary, a scheduled analytics rule stopped firing or a hunt returns empty.
- **Cause:** Basic/Auxiliary tiers limit scheduled analytics and full KQL; the detection depended on the table you retiered.
- **Fix:** This is the exact failure the dependency map (Step 2) exists to prevent. Move the table back to Analytics (`Manage table` → plan), or split the needed data into an Analytics table and keep only the noise on the cheaper tier. Re-run `SENTCOST-Tiering.ps1` and only retier SAFE-TO-RETIER tables.

## The DCR filter dropped data I actually needed

- **Symptom:** Legitimate rows are missing after adding a DCR transformation.
- **Cause:** The filter was too broad — it matched more than the intended noise.
- **Fix:** Edit the DCR transformation (`Monitor` → `Data Collection Rules` → `Noise Filter - <TableName> - Pilot`) to narrow the condition. Note that data dropped while the bad filter was live **cannot be recovered** — this is why the filter is piloted narrowly first. Re-validate with a KQL query that the intended noise (and only that) is gone.

## Table plan change is greyed out / not available

- **Symptom:** `Manage table` does not offer Basic/Auxiliary for a table you want to retier.
- **Cause:** Not every table is eligible for every tier; eligibility varies by table type, region, and over time.
- **Fix:** *Verify current tier eligibility for that specific table in your tenant.* If it is not eligible, rely on DCR filtering and retention tuning for that table instead of a tier move.

## Retention change refused or has no effect

- **Symptom:** `SENTCOST-Set-TableRetention.ps1` errors, or retention does not change.
- **Cause:** Insufficient rights (needs Contributor — Requirement 2.3), total retention set below interactive, or the table type does not support per-table retention.
- **Fix:** Confirm Contributor on the workspace. Ensure total ≥ interactive (the script enforces this). For tables that do not support per-table retention, set it at the workspace default. Re-run in `-WhatIf` first, then `-WhatIf:$false`.

## Savings did not appear after the change

- **Symptom:** Re-running the audit shows little or no drop for the changed table.
- **Cause:** The measurement window is too short (tier/filter changes only affect data ingested *after* the change), or the noise you filtered was a small fraction of the table.
- **Fix:** Wait for a full representative window (several days) of post-change ingestion, then re-run `SENTCOST-Audit.ps1`. If the table is still large, re-examine what is driving its volume (`summarize count() by <column>`) and filter or retier the real driver.

## The commitment tier now costs more than pay-as-you-go

- **Symptom:** After optimizing, the committed tier looks like an overpay.
- **Cause:** Your optimizations lowered daily volume below the committed tier — the commitment no longer fits.
- **Fix:** Re-run `SENTCOST-Forecast.ps1` with the new steady volume and drop to a lower tier (or back to pay-as-you-go). Always re-forecast after each round of tiering/filtering (Best Practices).

## Forecast numbers look wrong

- **Symptom:** `SENTCOST-Forecast.ps1` output does not match your actual bill.
- **Cause:** The per-GB rate, commitment thresholds, or discount passed to the script do not match your region/agreement — the script is a model, not a live billing feed.
- **Fix:** Pull the current per-GB rate, tier thresholds, and effective discount from the Azure Pricing Calculator for your region and re-run. *Always verify pricing before committing money.*

---

If a problem persists, re-run `SENTCOST-Audit.ps1`, `SENTCOST-Tiering.ps1`, and `SENTCOST-Validate.ps1` and compare against your `Tier Decision` records — nearly every issue is a missing role, a table that was not eligible/safe to retier, or a DCR filter that needs narrowing.


---


# 7. Best Practices — Microsoft Sentinel Cost & Data-Tier Optimization

Field-proven guidance for cutting the Sentinel bill without losing coverage.

## Optimize the biggest tables first, one at a time

- Cost is concentrated: a handful of tables usually drive most of the bill. Rank with `SENTCOST-Audit.ps1` and start at the top — the first few tables deliver most of the savings.
- Change **one table at a time** and re-measure. Batching changes makes it impossible to tell which one saved money or which one broke a detection.

## Never trade coverage for cost — check dependencies first

- Before retiering or filtering any table, confirm no active analytics rule, workbook, or hunting query depends on it (`SENTCOST-Tiering.ps1`). A silent gap in detection is far more expensive than the data.
- Remember Basic/Auxiliary tiers limit scheduled analytics and full KQL — keep tables your detections query on **Analytics**. *Verify current tier query limits in your tenant.*

## Filter at the source — the DCR is your highest-leverage lever

- Dropping noise at the DCR means you never pay to ingest it. This beats retiering, because retiered data still costs something.
- Filter only **genuine, well-understood noise** (health/heartbeat chatter, verbose informational events you never query, unused columns). Dropped rows are gone for good — pilot every filter narrowly first.
- Trim unused **columns** as well as rows where the transformation supports it; wide verbose tables often carry fields nobody queries.

## Right-size retention deliberately, and let the customer own the policy

- Interactive retention is expensive; archive is cheap but has restore/search costs. Match interactive retention to how far back you actually query, and push the rest to archive.
- The **length** of retention is a compliance/records/legal decision — the customer owns it. Your job is to set the levers to that policy and show the cost of each option, not to decide the policy.

## Size commitment tiers from a real forecast, not a guess

- Only commit when steady daily volume comfortably exceeds a tier threshold (`SENTCOST-Forecast.ps1`). Spiky or shrinking volume is safer on pay-as-you-go.
- Re-forecast after each round of tiering/filtering — your optimizations lower the volume, which can change the best commitment tier.

## Measure, forecast, and review on a cycle

- Re-run the audit and forecast every billing cycle. Tables grow, new connectors add volume, and a table that was fine last quarter can become the top cost driver.
- Track savings against the agreed budget target so the optimization is visible and defensible to the budget owner.

## Verify pricing and tier availability for your region

- Tier names, table eligibility, thresholds, and per-GB rates change over time and by region and cloud. Always confirm current numbers in the Azure Pricing Calculator before committing money. *Verify current availability in your tenant.*

## Where to go next

- **Sentinel Analytics Rules & MITRE ATT&CK Coverage** — make sure the coverage you are protecting is actually mapped and complete before you optimize around it.
- **Deploy Microsoft Sentinel — Workspace & Connectors** — apply DCR filtering and tier decisions to new sources as you onboard them, so cost discipline starts at ingestion.
- **Sentinel SOAR — Automation Rules & Playbooks** — automate the routine SOC work on top of the lean, well-tiered data you now pay less for.
- **SOC Onboarding — Sentinel & Defender XDR** — a unified queue on cost-optimized data keeps both coverage and spend under control.


---


# 8. Deliverables Summary — Microsoft Sentinel Cost & Data-Tier Optimization

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The cost model — what Sentinel/Log Analytics charge for, the data tiers (Analytics/Basic/Auxiliary), retention vs archive, DCR filtering, commitment tiers, scope, benefits, limitations |
| 2. Requirements Guide | Every cost-optimization prerequisite with Verify / Implement-if-missing |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — ingestion audit, dependency map, DCR filter, tier/retention change, commitment forecast, pilot-first |
| 5. Testing Guide | Validation procedures with pass/fail gates (savings AND coverage) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell / KQL scripts

| Script | What it does |
|---|---|
| `SENTCOST-Audit.ps1` | Ingestion-cost audit — ranks tables by billable GB over 31 days with a per-day trend and estimated cost at a supplied rate (read-only) |
| `SENTCOST-Tiering.ps1` | Tiering-recommendation analysis — cross-references top-volume tables against the tables your detections use and flags safe-to-retier vs keep-on-Analytics (read-only) |
| `SENTCOST-Validate.ps1` | Confirms each table's configured plan (Analytics/Basic/Auxiliary) and retention match the tier decisions, and that expected DCR filters are present (read-only) |
| `SENTCOST-Forecast.ps1` | Monthly cost forecast — compares pay-as-you-go vs commitment tiers at your region's rate and projects current-vs-optimized spend (read-only) |
| `SENTCOST-Set-TableRetention.ps1` | Safe retention/tier-change helper (default `-WhatIf`) — applies a table's interactive/archive retention per the tier decision only when explicitly confirmed |

## What the buyer receives

- This implementation guide as a branded Word document and PDF.
- All five PowerShell/KQL scripts in a single ZIP.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome

A leaner, forecast-backed Sentinel bill — top cost drivers identified, low-value tables retiered, noise filtered at the DCR, retention right-sized, and a commitment tier sized to steady volume — achieved without dropping the detection coverage your SOC depends on, and validated on a pilot table before workspace-wide rollout.
