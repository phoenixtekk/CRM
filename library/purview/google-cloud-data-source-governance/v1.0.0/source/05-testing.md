# 5. Testing Guide — Google Cloud Data-Source Governance: Microsoft Purview

Run these tests after the pilot scan (Implementation Steps 6–9) and again after each expansion scope.
Each test confirms one part of the Google Cloud governance workflow works end to end. All read-only
checks are safe to repeat.

## Test 1 — Account and roles are ready
Do: Run `DGGCP-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DGGCP-Collection-Pilot` exists, and
least-privilege roles (Collection admin, Data source admin, Data curator, Data reader) are reported as
assigned; **Data source admin** (needed to register/scan) is present. No required role is missing.

## Test 2 — The Google BigQuery connector is available
Do: In the Purview portal, open **Data Map → Sources → Register**.
Expected: **Google BigQuery** appears as a registerable source type for your tenant.

## Test 3 — The service-account credential path works (Key Vault + Test connection)
Do: On the registered BigQuery source, run **Test connection**; confirm the credential references the
Key Vault secret **by name** and the BigQuery API is enabled in the project.
Expected: Purview authenticates to BigQuery as the **service account** using the **named Key Vault
credential** and **Test connection passes**. No key material is stored anywhere.

## Test 4 — The SHIR and network path work
Do: Confirm the **self-hosted integration runtime (SHIR)** shows **Running/Available** and that the
Java/driver prerequisites are installed on the SHIR host.
Expected: The SHIR is Running with line of sight to BigQuery; **Test connection** on the source
succeeds through it.

## Test 5 — The scan succeeds and returns assets
Do: Review the pilot scan run in the portal and run `DGGCP-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope (the pilot
datasets, not the whole project), and assets (BigQuery datasets/tables) were returned into the Data
Map.

## Test 6 — Google Cloud assets are classified
Do: Run `DGGCP-Report.ps1` and review the classification coverage for the pilot Google Cloud assets.
Expected: System (and any custom) classifications are applied to the assets that contain matching
data; the count of unexpectedly **unclassified** assets is understood and accepted by the data owner.

## Test 7 — Scanned Google Cloud assets have owners
Do: Open the pilot datasets/tables in the catalog and run `DGGCP-Report.ps1`.
Expected: Every scanned pilot asset has a named **owner/steward** assigned (from the scope manifest);
no governed Google Cloud asset is unowned.

## Test 8 — Consolidated readiness gate
Do: Run `DGGCP-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGGCP-Collection-Pilot`.
Expected: A single PASS/GAP summary confirming account reachable, roles present, the BigQuery source
registered and Test-connection-ready, at least one scan Succeeded, classification coverage > 0, and
owners assigned — the pilot gate in one view.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass: connector available, service-account Key Vault credential Test connection passes over a Running SHIR, scan Succeeded with classified assets, and every scanned asset has an owner (Test 8 shows all PASS) |
| Expand pass | Tests 1–7 pass for each new Google Cloud scope, and scheduled scans are enabled only after the scope validates (with expected BigQuery query/egress cost accepted) |
