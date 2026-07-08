# 6. Troubleshooting Guide — Oracle Data Governance (Microsoft Purview)

Symptom → likely root cause → fix. Use **`DGORACLE-Discovery.ps1`** (account/roles/SHIR/sources),
**`DGORACLE-Test-Readiness.ps1`** (consolidated PASS/GAP gate), and **`DGORACLE-Report.ps1`** (assets /
classifications / owners) to confirm before and after each fix. The Oracle connector, supported
versions, driver requirement, and authentication methods **evolve** — where a detail is flagged,
**verify against current Microsoft documentation / your tenant** before changing the estate.

## A. Account, collections & roles

### `DGORACLE-Discovery.ps1` can't reach the Purview account
- **Endpoint / auth wrong.** **Fix:** confirm the account name/endpoint and that `Connect-MgGraph`/the
  data-plane sign-in succeeded with an account that can read the Data Map; re-run Discovery.

### "You don't have permission" when registering or scanning
- **Missing Data source admin.** Registration/scan requires **Data source admin** on the collection.
  **Fix:** `DGORACLE-Discovery.ps1` reports role coverage; assign Data source admin on
  `DGORACLE-Collection-Pilot` at the narrowest scope (Req/Step 2), not account-wide.

## B. Connector availability

### Oracle isn't offered under Data Map → Sources → Register
- **Connector not available for the tenant / region, or version unsupported.** **Fix:** **verify the
  Oracle connector availability and supported Oracle versions for your tenant** in current Microsoft
  docs; confirm your database version is within the supported range before proceeding.

## C. SHIR / network / driver

### The self-hosted integration runtime shows offline or unavailable
- **Service stopped / registration lapsed / no outbound.** **Fix:** confirm the `DGORACLE-SHIR` service
  is running on the host and re-check the portal; ensure the host has the required outbound connectivity
  to the Purview/managed service. Re-run `DGORACLE-Discovery.ps1` to confirm Running/Available.

### Test connection fails with a network/timeout error
- **No line of sight to the listener / firewall.** **Fix:** confirm the SHIR host can reach the Oracle
  **listener port** (default `1521` — verify your instance's port); open the firewall so **only** the
  SHIR host reaches the listener (Step 5).

### Test connection fails with a driver/class-not-found error
- **Oracle JDBC driver missing on the SHIR machine.** **Fix:** install the **Oracle JDBC driver** where
  Microsoft's current docs specify; **verify whether your SHIR version bundles it or requires a manual
  install**. Restart the SHIR after installing and retry Test connection.

## D. Credential path

### Test connection fails with an authentication error
- **Wrong login, insufficient grants, or Key Vault reference broken.** **Fix:** confirm `PURVIEW_SCAN`
  has **`CREATE SESSION`** + **`SELECT`** on the in-scope objects and the data-dictionary views (Step 3;
  verify the exact grant list in current docs — **no DBA/SYS**); confirm the credential
  `DGORACLE-Cred-Oracle-KV` references the correct **Key Vault secret by name** and that Purview's
  managed identity can read that secret. **No password belongs in any script or document.**

## E. Scan results

### The scan status is Failed
- **Credential / driver / network (see C, D), or scope invalid.** **Fix:** open the failed run in the
  portal for the error; resolve the connectivity/credential cause; confirm the scoped schemas exist and
  are readable by `PURVIEW_SCAN`; re-scan the bounded pilot scope.

### The scan Succeeded but returned few/no assets
- **Scope too narrow or login can't see the objects.** **Fix:** confirm the scan targeted the intended
  **pilot schemas** (not an empty schema); confirm `PURVIEW_SCAN` has `SELECT` on those objects; review
  with `DGORACLE-Report.ps1` and re-scope.

### The scan over-reached / loaded the database
- **Scanned the whole instance or scheduled too aggressively.** **Fix:** cancel the run in the portal and
  set the scan disabled (a scan does not modify source data — cancel only to stop resource use);
  re-scope to fewer schemas via `DGORACLE-Set-Scope.ps1`; keep scans **one-time** until the scope
  validates, then schedule (Step 12) and watch SHIR/database load.

## F. Classification & ownership

### Expected columns come back unclassified
- **Detector didn't match / custom pattern needed.** **Fix:** confirm the classification is in
  `DGORACLE-ScanRuleSet-Pilot`; for a real internal pattern that was missed, define a **custom
  classification rule** (`DGORACLE-Classification-Custom-<name>`), validate against sample data, add it to
  the rule set, and re-scan (Step 9). The count of accepted-unclassified assets is a **data-owner
  determination**, not a technical one.

### Scanned assets have no owner
- **Ownership not assigned after scan.** **Fix:** assign the **owner/steward** from the scope manifest to
  the scanned database/schemas (Step 10); `DGORACLE-Report.ps1` lists assets missing an owner. No governed
  Oracle asset should be unowned.

---
## Escalation checklist
1. `DGORACLE-Discovery.ps1` — account reachable, `DGORACLE-Collection-Pilot` present, Data source admin
   assigned, a SHIR registered?
2. `DGORACLE-Test-Readiness.ps1 -PurviewAccount <account> -Collection DGORACLE-Collection-Pilot` — which
   gate item is GAP (connector / SHIR / credential / scan / classification / owners)?
3. Portal Test connection — network (C), driver (C), or credential (D)?
4. Portal scan run + `DGORACLE-Report.ps1` — Succeeded, scoped, classified, owned?
5. Still stuck → **verify current Microsoft Oracle-connector guidance** (supported versions, driver,
   grant list, auth methods) for your tenant before a broad change. Classification acceptance and
   ownership are **data-owner determinations** — this guide restores the *technical scan path*.
