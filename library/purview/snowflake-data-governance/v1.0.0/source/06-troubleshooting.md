# 6. Troubleshooting — Snowflake Data Governance (Microsoft Purview)

Symptoms, likely causes, and fixes for onboarding Snowflake to the Purview Data Map. Stay on the **pilot
scope** (one database/schema) while diagnosing — prove the fix there before scanning the account. **Never**
put a Snowflake secret in a script to "test" a connection; the secret lives only in Key Vault.

## The scan fails to authenticate to Snowflake
- **Credential not linked / wrong reference.** The scan references the Purview **credential by name**,
  which must point at the **Key Vault secret**. Confirm the Key Vault is linked to the Purview account
  (Management → Credentials) and the credential resolves the secret. Rotating/fixing the secret is a Key
  Vault action — no script change.
- **Snowflake login/role insufficient.** The scanning login needs read access to the in-scope databases'
  metadata. Verify the Snowflake user/role and that it isn't locked/expired.
- **Wrong server endpoint.** Confirm the Snowflake server (`<account>.snowflakecomputing.com`) and any
  required warehouse/role parameters match the connector's expectations.

## The scan fails to connect (network)
- **No path from the runtime.** If Snowflake isn't reachable from the managed runtime, a **self-hosted
  integration runtime (SHIR)** on a host with connectivity is required. `DGSNOW-Discover.ps1` lists
  registered runtimes; confirm one can reach the Snowflake host/port.
- **Firewall / Snowflake network policy.** Snowflake network policies or corporate firewalls may block the
  runtime's IP. Open the path under change control and confirm with the Snowflake admin.

## `DGSNOW-Register-Source.ps1 -Commit` returns a REST error
- **Token/permissions.** Ensure `Connect-AzAccount` succeeded and a Purview token was acquired
  (`DGSNOW-Check-Prereqs.ps1`), and that the identity has **Data source admin** on the collection.
- **API version / schema drift.** The Data Map REST schema, connector `kind`, and API version **evolve**.
  If the body is rejected, verify the current Snowflake connector request shape and `-ApiVersion` against
  Microsoft's documentation for your account, and adjust.
- **Collection name.** The `-Collection` reference must be the collection's **name** (not its friendly
  name). Confirm with `DGSNOW-Discover.ps1`.

## The scan runs but finds no assets
- **Scope too narrow / wrong database.** Confirm `-PilotDatabase` matches an existing database the login
  can read. Widen within the pilot if the target schema is empty.
- **Still running.** Large scans take time. Check the run status (`DGSNOW-Validate.ps1` / portal) before
  concluding it found nothing.
- **Permissions on objects.** The login may see the database but not specific schemas/tables. Grant the
  least-privilege read it needs on the in-scope objects.

## Classifications aren't applied to columns I expected
- **Scan rule set.** Classifications come from the scan rule set. Confirm `Snowflake – Scan Rule Set`
  includes the classifications/SITs you expect, and that the column data actually matches them.
- **Sampling / thresholds.** Classification uses sampling and confidence thresholds; a column may not
  classify if the sample didn't meet them. Verify the behavior against current Microsoft guidance before
  concluding it's wrong; re-scan if the rule set changed.
- **Custom classifications not defined.** If you expected a custom classification, confirm it's created in
  Purview and included in the rule set.

## Scans are consuming more capacity/cost than expected
- **Full-account scan too early.** Keep to the **pilot scope** until validated, then expand deliberately and
  **schedule** rather than repeatedly full-scanning. Data Governance scans consume capacity — confirm the
  consumption model with the owner and right-size the schedule.

## `DGSNOW-Validate.ps1` shows the run status as failed or empty
- **Read the run detail in the portal.** The REST status is a summary; open the scan run in the Purview
  portal for the detailed error (auth, network, permissions) and fix per the sections above. Re-run on the
  pilot scope after the fix.

---
### When to stop and escalate
- A connector/runtime/consumption constraint blocks progress on your account — record it **deferred**,
  route the licensing/consumption decision to the owner, and confirm the current connector support with
  Microsoft; do not design around an unavailable capability.
- **The classification scheme, data ownership, and glossary** are data-governance determinations, not
  technical fixes — capture them in `Snowflake Governance – Map` and defer the determinations.
- If a scan can't be made to complete on the pilot, gather `DGSNOW-Validate.ps1` output and the portal run
  detail as evidence and raise with Microsoft support before expanding scope — never widen a scan that
  fails on one database.
