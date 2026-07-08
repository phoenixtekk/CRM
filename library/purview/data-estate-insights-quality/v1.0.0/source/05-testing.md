# 5. Testing Guide — Data Estate Insights & Data Quality (Microsoft Purview)

Run these tests after the insights baseline and the pilot data-quality scan (Implementation Steps 4–9)
and again after each expansion scope. Each test confirms one part of the measure-and-report capability
works end to end. All read-only checks are safe to repeat.

## Test 1 — Estate and roles are ready
Do: Run `DGINSIGHT-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, catalogued **assets**, **governance domains**, and
**data products** are reported, the **Data Quality** surface responds (feature available), and
least-privilege roles are reported as assigned; no required role is missing. (If Data Quality does not
respond, its tests below are recorded as deferred — verify licensing/preview — not failed.)

## Test 2 — Data Estate Insights baseline is captured
Do: Open the insights/analytics/Health management experience and run `DGINSIGHT-Report.ps1`.
Expected: An estate-level picture is produced — asset totals, **classification distribution**,
**ownership coverage %**, and per-domain/data-product coverage — and captured as
`DGI-Insights-Baseline`. The portal view and the report agree.

## Test 3 — The data-quality connection is reachable
Do: Run **Test connection** on the pilot data-quality connection and confirm with
`DGINSIGHT-Discovery.ps1`.
Expected: The connection to the pilot data product's source passes with least-privilege read (managed
identity or Key Vault credential); no secret appears in any script or manifest.

## Test 4 — Data-quality rules are authored on the pilot data product
Do: Open `DGI-DataProduct-Pilot` and confirm `DGI-DQ-Ruleset-Pilot`; run `DGINSIGHT-Report.ps1`.
Expected: The agreed `DGI-DQ-Rule-<Dimension>-<CDE>` rules exist against the pilot CDEs with the owner's
thresholds; the rule set is scoped to the pilot data product only.

## Test 5 — The data-quality scan succeeds and returns scores
Do: Review the pilot data-quality scan run in the portal and run `DGINSIGHT-Report.ps1`.
Expected: The scan status is **Succeeded**, it scored the intended bounded scope, and a **quality
score** is returned per rule, per data asset, and rolled up for `DGI-DataProduct-Pilot`. No source data
was modified.

## Test 6 — Scores are meaningful and owner-reviewed
Do: Run `DGINSIGHT-Report.ps1` and review the per-rule scores and below-threshold CDEs with the data
owner.
Expected: Each score reflects reality (false low/high rules tuned and re-run); the owner has accepted
the scores or flagged which CDEs need remediation. The count of below-threshold rules is understood and
owned — remediation is the owner's action, not a test failure.

## Test 7 — Estate-health coverage is reported
Do: Run `DGINSIGHT-Scope-Health.ps1` (and, if available, review `DGI-Health-Controls-Pilot`).
Expected: Coverage gaps are reported for the pilot domain — data products without an owner, CDEs without
a data-quality rule, stale scans. Gaps are listed, not silently missing; where health-controls is
unavailable the script still reports the same coverage.

## Test 8 — Trend tracking works against the baseline
Do: Re-run `DGINSIGHT-Report.ps1` after a change (a new rule, a re-scan, or an expansion scope) and
compare to `DGI-Insights-Baseline`.
Expected: The report shows the delta from baseline (classification/ownership coverage and data-product
quality score moving as expected). If Data Quality is unavailable in the tenant, this test covers the
insights delta only and the DQ portion is recorded as deferred.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass: estate/roles ready, insights baseline captured, DQ connection reachable, rules authored on the pilot data product, the DQ scan **Succeeded** with per-rule and data-product scores, and the owner has reviewed/accepted the scores (Test 7 reported; Test 8 established). Where Data Quality is unavailable for the tenant, Tests 3–6 are recorded as **deferred** with the insights tests (1, 2, 7, 8-insights) passing. |
| Expand pass | Tests 1–7 pass for each new scope, and scheduled data-quality scoring is enabled only after the scope validates and the owner accepts its scores. |
