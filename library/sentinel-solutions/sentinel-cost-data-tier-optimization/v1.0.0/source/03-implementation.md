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
