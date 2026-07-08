# 5. Testing Guide — SAP Data Governance: Microsoft Purview

Run these tests after the pilot scan (Implementation Steps 6–9) and again after each expansion source.
Each test confirms one part of the SAP-governance workflow works end to end. All read-only checks are
safe to repeat.

## Test 1 — Account and roles are ready
Do: Run `DGSAP-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DGSAP-Collection-Pilot` exists, and
least-privilege roles (Collection admin, Data source admin, Data curator, Data reader) are reported as
assigned; **Data source admin** (needed to register/scan) is present. No required role is missing.

## Test 2 — The SAP connector is available
Do: In the Purview portal, open **Data Map → Sources → Register**.
Expected: The SAP source type you need (**SAP ECC / S/4HANA / BW / HANA**) appears as a registerable
source type for your tenant, and the supported SAP version list matches what the pilot system runs.

## Test 3 — The SHIR and SAP driver are in place
Do: Run `DGSAP-Discovery.ps1` and check the SHIR machine.
Expected: A **self-hosted integration runtime** is registered and shows **Running/Available**; the
SAP-provided driver (`sapjco3.jar` + `sapjco3.dll` for ECC/S4HANA/BW, or `ngdbc.jar` for HANA) and a
supported **64-bit Java runtime** are present on the SHIR machine in the location Microsoft's docs
specify; the SHIR can reach the SAP host/port.

## Test 4 — The SAP credential path works (Key Vault + Test connection)
Do: On the registered SAP source, run **Test connection**; confirm the credential references the Key
Vault secret **by name** and the SHIR shows Running/Available.
Expected: Purview (via the SHIR) loads the SAP driver, reaches the SAP system, and authenticates using
the **named Key Vault credential** with the **least-privilege SAP read user** — **Test connection
passes**. No SAP secret is stored anywhere.

## Test 5 — The scan succeeds and returns assets
Do: Review the pilot scan run in the portal and run `DGSAP-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope (the pilot
system's intended tables/objects, not the entire SAP dictionary), and assets (SAP tables/objects and,
where scanned, fields/columns) were returned into the Data Map.

## Test 6 — SAP assets are classified
Do: Run `DGSAP-Report.ps1` and review the classification coverage for the pilot SAP assets.
Expected: System (and any custom) classifications are applied to the assets that contain matching data;
the count of unexpectedly **unclassified** assets is understood and accepted by the data owner.

## Test 7 — Scanned SAP assets have owners
Do: Open the pilot SAP source/assets in the catalog and run `DGSAP-Report.ps1`.
Expected: Every scanned pilot asset has a named **owner/steward** assigned (from the scope manifest);
no governed SAP asset is unowned.

## Test 8 — Consolidated readiness gate
Do: Run `DGSAP-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGSAP-Collection-Pilot`.
Expected: A single PASS/GAP summary confirming account reachable, roles present, a SHIR registered, the
SAP source registered and Test-connection-ready, at least one scan Succeeded, classification coverage
> 0, and owners assigned — the pilot gate in one view.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass: connector available, SHIR + driver in place, SAP Key Vault credential Test connection passes, scan Succeeded with classified assets, and every scanned asset has an owner (Test 8 shows all PASS) |
| Expand pass | Tests 1–7 pass for each new SAP source, and scheduled scans are enabled only after the source validates (with scan windows coordinated with SAP Basis) |
