# 5. Testing Guide — Oracle Data Governance: Microsoft Purview

Run these tests after the pilot scan (Implementation Steps 7–10) and again after each expansion scope.
Each test confirms one part of the Oracle-governance workflow works end to end. All read-only checks
are safe to repeat.

## Test 1 — Account and roles are ready
Do: Run `DGORACLE-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DGORACLE-Collection-Pilot` exists, and
least-privilege roles (Collection admin, Data source admin, Data curator, Data reader) are reported as
assigned; **Data source admin** (needed to register/scan) is present. No required role is missing.

## Test 2 — The Oracle connector is available
Do: In the Purview portal, open **Data Map → Sources → Register**.
Expected: **Oracle** appears as a registerable source type for your tenant, and your Oracle database
version is within the connector's currently supported range.

## Test 3 — A SHIR is registered and running
Do: Run `DGORACLE-Discovery.ps1` and check the integration-runtime section; confirm in the portal.
Expected: The self-hosted integration runtime `DGORACLE-SHIR` is registered and shows
**Running/Available**, on a host with network line of sight to the Oracle listener, with the Oracle
JDBC driver present.

## Test 4 — The credential path works (Key Vault + Test connection)
Do: On the registered Oracle source, run **Test connection**; confirm the credential
`DGORACLE-Cred-Oracle-KV` references the Key Vault secret by name.
Expected: Purview authenticates to Oracle with the **named Key Vault credential** (Basic auth) over the
SHIR network path and **Test connection passes**. No password is stored in any script or document.

## Test 5 — The scan succeeds and returns assets
Do: Review the pilot scan run in the portal and run `DGORACLE-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope (the pilot
schemas, not the whole instance), and assets (schemas/tables/columns) were returned into the Data Map.

## Test 6 — Oracle assets are classified
Do: Run `DGORACLE-Report.ps1` and review the classification coverage for the pilot Oracle assets.
Expected: System (and any custom) classifications are applied to the columns/tables that contain
matching data; the count of unexpectedly **unclassified** assets is understood and accepted by the data
owner.

## Test 7 — Scanned Oracle assets have owners
Do: Open the pilot database/schemas in the catalog and run `DGORACLE-Report.ps1`.
Expected: Every scanned pilot asset has a named **owner/steward** assigned (from the scope manifest); no
governed Oracle asset is unowned.

## Test 8 — Consolidated readiness gate
Do: Run `DGORACLE-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGORACLE-Collection-Pilot`.
Expected: A single PASS/GAP summary confirming account reachable, roles present, a SHIR registered, the
Oracle source registered and Test-connection-ready, at least one scan Succeeded, classification
coverage > 0, and owners assigned — the pilot gate in one view.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass: connector available, SHIR running with driver, Key Vault credential Test connection passes, scan Succeeded with classified assets, and every scanned asset has an owner (Test 8 shows all PASS) |
| Expand pass | Tests 1–7 pass for each new Oracle scope, and scheduled scans are enabled only after the scope validates (with expected SHIR/database load accepted) |
