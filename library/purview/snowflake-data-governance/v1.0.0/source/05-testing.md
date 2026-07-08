# 5. Testing Guide — Snowflake Data Governance (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to run a scan on the pilot scope. Validate on `Snowflake – Pilot Scope – Stage1` (one
database/schema) before scanning the account.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DGSNOW-Check-Prereqs.ps1`.
**Expected:** Az.Accounts present and connected; a Purview endpoint token can be acquired; the Purview
account and Data-Map read signals reported; reminders to confirm the Key Vault linkage, SHIR, and roles.
Every gap (e.g. SHIR not registered → network path) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DGSNOW-Discover.ps1 -PurviewAccount "<acct>"`.
**Expected:** The Data Map collections, existing registered sources and scans, and registered integration
runtimes are listed — matching what the Purview portal shows.

## Test 3 — Register-source dry-run makes no changes
**Do:** Run `DGSNOW-Register-Source.ps1 -Action RegisterSource -PurviewAccount "<acct>" -Collection "Snowflake - Collection" -SnowflakeServer "<account>.snowflakecomputing.com" -WhatIf`.
**Expected:** It states the source it *would* register (name, collection, server) plus the reverse action
and changes nothing; a follow-up `DGSNOW-Discover.ps1` shows no new source until `-Commit`.

## Test 4 — Source registered under the collection
**Do:** After `-Commit`, run `DGSNOW-Discover.ps1` and check the Purview portal Data Map.
**Expected:** `Snowflake – Source` appears in the Data Map under `Snowflake – Collection` with the correct
Snowflake server.

## Test 5 — Credential is Key Vault-backed, no secret in code
**Do:** Inspect the scan configuration and the scripts.
**Expected:** The scan references `Snowflake – Scan Credential` **by name**; the secret lives in Azure Key
Vault linked to Purview; **no password appears in any script, parameter, or document**. A secret in code is
a fail.

## Test 6 — Scan created on the pilot scope
**Do:** Run `DGSNOW-Register-Source.ps1 -Action CreateScan ... -PilotDatabase "PILOT_DB" -WhatIf` then
`-Commit`.
**Expected:** `-WhatIf` shows the scan it *would* create (credential-by-name, rule set, pilot database)
and changes nothing; `-Commit` creates `Snowflake – Scan` scoped to the pilot database only.

## Test 7 — Scan runs and completes on the pilot
**Do:** Trigger the scan on the pilot scope (portal or `-Action RunScan`) and watch its status.
**Expected:** The scan connects to Snowflake (via the runtime), runs on the pilot database/schema, and
completes with a **Succeeded** status — no authentication or network errors.

## Test 8 — Assets appear in the catalog
**Do:** In the Purview catalog, search for the pilot database's tables.
**Expected:** The scanned tables/columns are discoverable as assets under `Snowflake – Source`, with their
technical metadata (schema, columns, data types).

## Test 9 — Classifications applied where expected
**Do:** Open a table you know contains sensitive data (e.g. a column of emails or IDs) and review its
classifications.
**Expected:** The expected classifications / sensitive information types are applied to the sensitive
columns per the scan rule set. (Verify the classification behavior against current Microsoft guidance.)

## Test 10 — Validation gate passes on the pilot
**Do:** Run `DGSNOW-Validate.ps1 -PurviewAccount "<acct>"`.
**Expected:** PASS for each gate — source registered under the collection, scan exists, last scan
**completed**, and assets/classifications present for the pilot scope. Any FAIL names the specific issue.

## Test 11 — Reporting evidence is produced
**Do:** Run `DGSNOW-Report.ps1 -PurviewAccount "<acct>" -CsvPath .\SnowflakeReport.csv`.
**Expected:** `Snowflake – Coverage Report` lists the source, its scans, last-run status, and a
classification summary — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `Snowflake – Pilot Scope – Stage1` — source registered, scan completed on the pilot
database, assets catalogued and sensitive columns classified, credential Key Vault-backed with no secret in
code, and the coverage report produced — before expanding scope, scheduling, and curating. Any deferred
(connector/runtime/licensing) constraint is recorded explicitly, not silently skipped.
