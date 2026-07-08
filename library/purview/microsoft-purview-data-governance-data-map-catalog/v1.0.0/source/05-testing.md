# 5. Testing Guide — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

Run these tests after the pilot scan and catalog curation (Implementation Steps 5–9) and again after
each expansion scope. Each test confirms one part of the governed estate works end to end. All
read-only checks are safe to repeat.

## Test 1 — Account and roles are ready
Do: Run `PURVGOV-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DG-Collection-Pilot` exists, and least-privilege
roles (Collection admin, Data source admin, Data curator, Data reader) are reported as assigned; no
required role is missing.

## Test 2 — Pilot sources are registered and reachable
Do: Open `DG-Collection-Pilot` and run **Test connection** on each registered source; confirm with
`PURVGOV-Report.ps1`.
Expected: Each pilot source is registered and **Test connection** passes (managed IR or SHIR shows
Running/Available). No source is unreachable.

## Test 3 — The scan succeeds and returns assets
Do: Review the pilot scan run in the portal and run `PURVGOV-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope, and assets
(databases/tables/files) were returned into the Data Map.

## Test 4 — Assets are classified
Do: Run `PURVGOV-Report.ps1` and review the classification coverage for the pilot assets.
Expected: System (and any custom) classifications are applied to the assets that contain matching
data; the count of unexpectedly **unclassified** assets is understood and accepted by the data owner.

## Test 5 — The business glossary exists
Do: Open the Unified Catalog glossary and confirm `DG-Glossary-Pilot`.
Expected: The agreed 5–10 terms / critical data elements are present and, where intended, linked to
assets.

## Test 6 — The data product is published with an owner
Do: Open `DG-Domain-Pilot` and the data product `DG-DataProduct-Pilot`.
Expected: The data product contains the intended assets, has a named **owner**, a **use purpose**, and
**terms of use**; every published asset has an owner/steward.

## Test 7 — Lineage resolves
Do: Open a pilot asset in the catalog and view its lineage.
Expected: The asset traces **upstream** to its source and **downstream** to at least one consumer for a
supported system; gaps (unsupported systems) are recorded, not silently missing.

## Test 8 — Data quality baseline (if available)
Do: If data quality is available in your tenant (verify), run the `DG-DQ-Ruleset-Pilot` assessment.
Expected: A baseline **quality score** is produced for the pilot data product's critical data
elements. If the feature is unavailable, this test is recorded as deferred, not failed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass: sources registered and reachable, scan Succeeded with classified assets, glossary and data product published with owners, and lineage resolves for at least one asset (Test 8 passes or is recorded as deferred where data quality is unavailable) |
| Expand pass | Tests 1–7 pass for each new scope, and scheduled scans are enabled only after the scope validates |
