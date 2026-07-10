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
