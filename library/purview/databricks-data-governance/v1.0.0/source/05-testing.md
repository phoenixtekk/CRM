# 5. Testing Guide — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

Run these tests after the pilot scan (Implementation Steps 6–9) and again after each expansion scope.
Each test confirms one part of the Databricks-governance workflow works end to end. All read-only checks
are safe to repeat.

## Test 1 — Account, roles, and runtime are ready
Do: Run `DGDBX-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DGDBX-Collection-Pilot` exists, least-privilege
roles (Collection admin, Data source admin, Data curator, Data reader) are reported as assigned —
**Data source admin** (needed to register/scan) is present — and at least one **integration runtime** is
registered. No required role is missing.

## Test 2 — The Azure Databricks connector is available and the connector type is confirmed
Do: In the Purview portal, open **Data Map → Sources → Register**.
Expected: **Azure Databricks** appears as a registerable source type for your tenant, and the connector
that matches your workspace — **Unity Catalog** (this solution's path) or **Hive metastore** — is the one
you register. Confirm the workspace's Unity Catalog / metastore status with the Databricks admins.

## Test 3 — The scan credential resolves (Key Vault, by name)
Do: In Purview **Management → Credentials / Key Vault connections**, confirm `DGDBX-Cred-Databricks-KV`
references the Key Vault secret **by name**; `DGDBX-Discovery.ps1` reports the Key Vault connection present.
Expected: The credential resolves and the Databricks-side scan identity (service principal / PAT) can read
the in-scope catalogs' metadata. **No secret is stored in any script or document.**

## Test 4 — The source registers and Test connection passes
Do: On the registered Databricks source, run **Test connection**; confirm the integration runtime shows
Running/Available and the credential references the Key Vault secret by name.
Expected: Purview authenticates to the workspace using the **named Key Vault credential** over a working
network path (Azure managed IR, or `DGDBX-SHIR` for a private workspace) and **Test connection passes**.

## Test 5 — The scan succeeds and returns lakehouse assets
Do: Review the pilot scan run in the portal and run `DGDBX-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope (the pilot
catalog/schema, not the whole metastore), and assets (catalogs → schemas → tables/views/columns) were
returned into the Data Map.

## Test 6 — Databricks assets are classified
Do: Run `DGDBX-Report.ps1` and review the classification coverage for the pilot assets.
Expected: System (and any custom) classifications are applied to the assets that contain matching data;
the count of unexpectedly **unclassified** assets is understood and accepted by the data owner.

## Test 7 — Lineage is surfacing
Do: Open a scanned table in the catalog and review its lineage; run `DGDBX-Report.ps1` for lineage
coverage.
Expected: Where Unity Catalog tracks it, **table/column lineage** is visible in the Data Map (upstream to
origin, downstream to consumers). **Lineage depth is connector- and tenant-dependent — verify**; absent
lineage is investigated (connector version / Unity Catalog lineage prerequisites), not assumed a defect.

## Test 8 — Scanned assets have owners and are cataloged
Do: Open the pilot catalog/schema in the catalog and run `DGDBX-Report.ps1`.
Expected: Every scanned pilot asset has a named **owner/steward** assigned (from the scope manifest); the
pilot assets are published under the `DGDBX-Domain-Lakehouse` governance domain as a data product. No
governed lakehouse asset is unowned.

## Test 9 — Consolidated readiness gate
Do: Run `DGDBX-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGDBX-Collection-Pilot`.
Expected: A single PASS/GAP summary confirming account reachable, roles present, integration runtime
registered, Databricks source registered and Test-connection-ready, at least one scan Succeeded,
classification coverage > 0, and owners assigned — the pilot gate in one view.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–8 pass: connector available and confirmed, credential resolves, Test connection passes, scan Succeeded with classified assets, lineage reviewed, and every scanned asset has an owner (Test 9 shows all PASS) |
| Expand pass | Tests 1–8 pass for each new catalog/schema scope, and scheduled scans are enabled only after the scope validates (with expected Databricks/Azure cost accepted) |
