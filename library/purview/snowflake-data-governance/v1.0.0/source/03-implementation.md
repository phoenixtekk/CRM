# 3. Implementation Guide — Snowflake Data Governance (Microsoft Purview)

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (limited scope) → Validate
→ Expand**. Every write is **piloted on `Snowflake – Pilot Scope – Stage1` (one database/schema) first**,
previewed with `-WhatIf`, and reversible. Named objects are introduced once and reused everywhere:

| Object | Name |
|---|---|
| Collection | `Snowflake – Collection` |
| Registered source | `Snowflake – Source` |
| Scan | `Snowflake – Scan` |
| Scan rule set | `Snowflake – Scan Rule Set` |
| Credential (Key Vault-backed) | `Snowflake – Scan Credential` |
| Pilot scope | `Snowflake – Pilot Scope – Stage1` |
| Design map | `Snowflake Governance – Map` |
| Coverage report | `Snowflake – Coverage Report` |

> **No secret ever lives in a script.** The Snowflake credential's secret is stored in **Azure Key Vault**,
> the Key Vault is **linked to the Purview account**, and the Purview **credential** references it by name.
> The scripts pass the *credential name* — never a password. **Verify the current Snowflake connector flow
> and integration-runtime requirements against your Purview account.**

## Step 0 — Connect (all steps)
Open PowerShell 5.1+ or 7+ and connect with a modern-auth/MFA admin:
```powershell
Connect-AzAccount                                  # Azure sign-in (for the Purview/Key Vault context)
# Data Map REST calls use a bearer token: (Get-AzAccessToken -ResourceUrl "https://purview.azure.net").Token
```
Keep credentials out of scripts — sign in interactively; the scripts acquire a token at runtime. **Pass/
fail:** sign-in succeeds and a token for the Purview endpoint can be acquired.

## Step 1 — Assess current state (Assess)
1. Run `DGSNOW-Discover.ps1 -PurviewAccount "<your-purview-account>"`. Read-only, it reports the Data Map
   **collections**, existing **registered sources** and **scans**, and any registered **integration
   runtimes** — so you know what exists before adding Snowflake.
2. Run `DGSNOW-Check-Prereqs.ps1` — modules/connection, the Purview-account and Data-Map read signals, and
   reminders to confirm the Key Vault linkage, SHIR, and roles — PASS/GAP per signal.
3. Record every GAP and remediate before configuring. **Pass/fail:** the inventory and prereq report
   complete; existing collections/runtimes captured in `Snowflake Governance – Map`.

## Step 2 — Design the governance approach (Design)
1. With data-governance, decide the **collection** (`Snowflake – Collection`), the **classifications /
   SITs** the scan rule set applies, the **scope** (which databases/schemas), and the **pilot scope**
   (one database/schema).
2. Decide the **credential** approach: create the least-privilege **Snowflake login**, store its secret in
   **Azure Key Vault**, and plan the Purview **credential** (`Snowflake – Scan Credential`) that references
   it. Confirm whether a **SHIR** is required for network reachability.
3. Record everything (collection, scope, rule set, credential plan, SHIR, stewards) in `Snowflake
   Governance – Map`.
   **Pass/fail:** the map is agreed and signed off; the classification scheme and data owners are owned by
   stakeholders, not IT.

## Step 3 — Prepare credential + register the source (Configure)
Do this **for the pilot first** — one database/schema.

1. **Prepare the Key Vault-backed credential (portal + Azure).** In Azure, store the Snowflake secret in
   Key Vault; in the Purview portal **Management → Credentials** link the Key Vault and create
   `Snowflake – Scan Credential` referencing the secret. **No secret is entered in any script.**
2. **Register the source.** Preview then commit:
   ```powershell
   .\DGSNOW-Register-Source.ps1 -Action RegisterSource -PurviewAccount "<acct>" -Collection "Snowflake - Collection" -SnowflakeServer "<account>.snowflakecomputing.com" -WhatIf
   .\DGSNOW-Register-Source.ps1 -Action RegisterSource -PurviewAccount "<acct>" -Collection "Snowflake - Collection" -SnowflakeServer "<account>.snowflakecomputing.com" -Commit
   ```
   This registers `Snowflake – Source` in the Data Map under the collection.
   **Pass/fail:** `Snowflake – Source` appears in the Data Map under `Snowflake – Collection` (portal /
   `DGSNOW-Discover.ps1`).

## Step 4 — Create and run the scan on the pilot (Pilot)
1. **Create the scan** referencing the credential *by name* and the scan rule set, scoped to the pilot
   database/schema:
   ```powershell
   .\DGSNOW-Register-Source.ps1 -Action CreateScan -PurviewAccount "<acct>" -SnowflakeServer "<account>.snowflakecomputing.com" -CredentialName "Snowflake - Scan Credential" -PilotDatabase "PILOT_DB" -WhatIf
   .\DGSNOW-Register-Source.ps1 -Action CreateScan -PurviewAccount "<acct>" -SnowflakeServer "<account>.snowflakecomputing.com" -CredentialName "Snowflake - Scan Credential" -PilotDatabase "PILOT_DB" -Commit
   ```
2. **Trigger the scan** (portal or `-Action RunScan`) on the **pilot scope only**. Watch it complete; note
   the assets discovered and the classifications applied.
   **Pass/fail:** the scan runs on the pilot database/schema and completes without auth/network errors;
   assets and classifications begin to appear. Discrepancies are recorded for troubleshooting, not worked
   around.

## Step 5 — Validate the pilot (Pilot → Validate)
1. Run `DGSNOW-Validate.ps1 -PurviewAccount "<acct>"`. Read-only, it confirms `Snowflake – Source` is
   registered under the collection, `Snowflake – Scan` exists, the last scan **completed**, and assets/
   classifications are present for the pilot scope — PASS/FAIL per gate.
2. In the catalog, confirm the pilot database's tables/columns are discoverable and that expected
   classifications (e.g. a PII column) applied.
3. Complete the **Testing Guide** on the pilot. **Pass/fail:** all Testing-Guide gates pass on
   `Snowflake – Pilot Scope – Stage1`.

## Step 6 — Expand and schedule (Expand)
1. Broaden `Snowflake – Scan` scope to the intended databases/schemas once the pilot validates, and set a
   **recurring schedule** so the catalog stays current.
2. **Curate** — assign data owners/stewards, glossary terms, and review classifications with the
   governance team (their determination, your enablement).
3. Run `DGSNOW-Report.ps1 -PurviewAccount "<acct>" -CsvPath .\SnowflakeReport.csv` to produce
   `Snowflake – Coverage Report` — the source, scans, last-run status, and a classification summary — as
   the management evidence artifact, and re-run it on a schedule.
   **Pass/fail:** the scan covers the intended databases on a schedule; the report shows assets and
   classifications as designed.

---
### Rollback
- **Disable / delete the scan** (portal or `-Action DeleteScan`) to stop scanning; the already-cataloged
  metadata remains until you remove it.
- **Remove the registered source** to take Snowflake out of the Data Map (removes its assets from the
  catalog). Prefer disabling the scan over deleting the source while tuning.
- **Rotate the credential** in Key Vault if it is ever suspected exposed — the scan references the Key
  Vault secret, so rotating there updates the scan without touching any script. Keep `Snowflake
  Governance – Map` as the record of the intended state.

### Order of operations
`Assess collections + runtimes → design collection/scope/rule set/credential (map) → prepare Key
Vault-backed credential + register source → create + run scan on pilot db/schema → validate assets +
classifications → expand scope + schedule + curate → report coverage`
