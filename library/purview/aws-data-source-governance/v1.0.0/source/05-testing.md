# 5. Testing Guide — AWS Data-Source Governance (S3/RDS): Microsoft Purview

Run these tests after the pilot scan (Implementation Steps 6–9) and again after each expansion scope.
Each test confirms one part of the AWS-governance workflow works end to end. All read-only checks are
safe to repeat.

## Test 1 — Account and roles are ready
Do: Run `DGAWS-Discovery.ps1`.
Expected: The Purview account endpoint is reachable, `DGAWS-Collection-Pilot` exists, and
least-privilege roles (Collection admin, Data source admin, Data curator, Data reader) are reported as
assigned; **Data source admin** (needed to register/scan) is present. No required role is missing.

## Test 2 — Amazon S3 / RDS connectors are available
Do: In the Purview portal, open **Data Map → Sources → Register**.
Expected: **Amazon S3** and **Amazon RDS** appear as registerable source types for your tenant, and the
supported RDS engine list matches what the pilot database uses.

## Test 3 — The S3 trust path works (role assume + Test connection)
Do: On the registered S3 source, run **Test connection**; confirm the credential references the role
ARN by name.
Expected: Purview successfully **assumes the cross-account IAM role** (trust + external ID correct) and
**Test connection passes**; encrypted buckets resolve (KMS decrypt granted). No AWS secret is stored
anywhere.

## Test 4 — The RDS credential path works (Key Vault + network + Test connection)
Do: On the registered RDS source, run **Test connection**; confirm the credential references the Key
Vault secret by name and the integration runtime shows Running/Available.
Expected: Purview authenticates to the RDS database using the **named Key Vault credential** over a
working network path (managed IR or SHIR) and **Test connection passes**.

## Test 5 — The scan succeeds and returns assets
Do: Review the pilot scan run in the portal and run `DGAWS-Report.ps1`.
Expected: The scan status is **Succeeded**, the run scanned the intended bounded scope (the pilot
buckets/database, not the whole account/instance), and assets (S3 paths/objects, RDS tables) were
returned into the Data Map.

## Test 6 — AWS assets are classified
Do: Run `DGAWS-Report.ps1` and review the classification coverage for the pilot AWS assets.
Expected: System (and any custom) classifications are applied to the assets that contain matching data;
the count of unexpectedly **unclassified** assets is understood and accepted by the data owner.

## Test 7 — Scanned AWS assets have owners
Do: Open the pilot buckets/databases in the catalog and run `DGAWS-Report.ps1`.
Expected: Every scanned pilot asset has a named **owner/steward** assigned (from the scope manifest); no
governed AWS asset is unowned.

## Test 8 — Consolidated readiness gate
Do: Run `DGAWS-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGAWS-Collection-Pilot`.
Expected: A single PASS/GAP summary confirming account reachable, roles present, AWS sources registered
and Test-connection-ready, at least one scan Succeeded, classification coverage > 0, and owners
assigned — the pilot gate in one view.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass: connectors available, S3 role-assume and RDS Key Vault credential Test connections pass, scan Succeeded with classified assets, and every scanned asset has an owner (Test 8 shows all PASS) |
| Expand pass | Tests 1–7 pass for each new AWS scope, and scheduled scans are enabled only after the scope validates (with expected AWS request/egress cost accepted) |
