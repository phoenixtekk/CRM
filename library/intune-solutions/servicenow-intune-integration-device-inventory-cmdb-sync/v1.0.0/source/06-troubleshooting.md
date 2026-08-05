# 6. Troubleshooting — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

Work from the symptom. Each entry: **Symptom → Likely cause → Fix.** Most feed failures are
authentication (expired secret / missing consent) or reconciliation (identifier) problems.

## Authentication & authorization

### The connection test fails / the feed stopped pulling data
- **Likely cause:** the app registration's **client secret expired**, or the wrong Tenant/Client ID or
  endpoint is configured.
- **Fix:** run **`SNOWINT-Remediation.ps1 -AppId <client-id>`** to check secret expiry; if expired,
  re-run with **`-Apply`** to mint a new secret, paste it into the ServiceNow connection, and **Test**.
  Confirm Tenant ID / Client ID and that the Graph/token endpoint matches the cloud (Commercial vs
  `.us`). Remove the old secret after ServiceNow is updated.

### 403 Forbidden / "Application is not authorized"
- **Likely cause:** the required Graph **Application** permission is missing or **admin consent** was
  not granted (or a scope was granted as Delegated).
- **Fix:** Entra → app → **API permissions**; confirm the four Application scopes show **"Granted for
  <tenant>"**. Click **Grant admin consent**. Re-run **`SNOWINT-Preflight.ps1`** to confirm, then
  re-test the ServiceNow connection.

### Auth works but 0 devices import
- **Likely cause:** no devices enrolled in this tenant, the import scope excludes them, or (Gov) the
  connection points at the wrong sovereign endpoint.
- **Fix:** confirm `SNOWINT-Preflight.ps1` returns a device sample; widen the connector's import scope;
  for Gov, confirm `graph.microsoft.us` / `login.microsoftonline.us`.

## Throttling & performance

### Import is slow, times out, or logs HTTP 429 / "TooManyRequests"
- **Likely cause:** Microsoft Graph **throttling** (large fleet + detected-apps stream is heavy), or
  paging not honored.
- **Fix:** run the import on an **off-peak schedule**; enable only the streams you consume (defer the
  detected-apps stream if not needed); ensure the connector/import honors `@odata.nextLink` paging and
  respects `Retry-After`. Reduce frequency — daily is usually sufficient for inventory.

### MID Server errors (if used for egress)
- **Likely cause:** MID Server down or blocked from reaching Graph.
- **Fix:** confirm the MID Server is **Up** in ServiceNow and can reach `graph.microsoft.com` /
  `graph.microsoft.us` on 443 through the proxy/firewall.

## Reconciliation & CMDB data quality

### Duplicate CIs — two records for one physical device
- **Likely cause:** the **serial-number IRE identifier** is not shared across discovery sources (Intune
  vs Workspace ONE vs SCCM), so each source creates its own CI. This is the most common CMDB symptom.
- **Fix:** **Configuration → CI Class Manager → (hardware class) → Identification/Reconciliation**;
  ensure a **serial-number** identifier rule is active and used by **all** sources; register **Intune**
  and **Workspace ONE** as discovery sources against the same identifier. Run
  **`SNOWINT-Validate-Sync.ps1`** — duplicates should drop to 0. De-dupe existing duplicates per your
  CMDB remediation process.

### Devices with no serial number don't reconcile
- **Likely cause:** some devices (certain VMs / mobile hardware) report an empty or non-unique serial.
- **Fix:** run **`SNOWINT-Report-Coverage.ps1`** to count no-serial devices; add a secondary identifier
  (e.g. Intune device ID / Entra device ID) for those classes, or handle them out-of-band. Don't weaken
  the serial identifier for the whole fleet.

### Wrong or blank owner / compliance on the CI
- **Likely cause:** field mapping incomplete, or `Directory.Read.All` not consented (owner lookup
  fails).
- **Fix:** confirm the connector's field map populates assigned/primary user and compliance; confirm
  `Directory.Read.All` is consented (`SNOWINT-Preflight.ps1`). Decide field authority so another source
  isn't overwriting Intune's compliance/last-check-in.

### Stale records — CIs stop updating
- **Likely cause:** the data-stream **schedule is paused/erroring**, the secret expired, or consent was
  revoked.
- **Fix:** confirm the schedule is enabled and its last run succeeded; check the import log; run
  `SNOWINT-Remediation.ps1` for secret/scope health. Treat a stalled last-updated as an incident.

### Devices in Intune are missing from the CMDB
- **Likely cause:** import scope too narrow, first scheduled run hasn't occurred, or transform errors.
- **Fix:** run **`SNOWINT-Validate-Sync.ps1`** to list missing serials; widen scope / trigger a manual
  run; check the transform log for row-level errors.

## Workspace ONE transition

### After enabling Intune, device counts double
- **Likely cause:** the Intune feed created new CIs instead of reconciling onto the Workspace ONE CIs.
- **Fix:** as above — shared serial-number identifier across both sources. Do **not** retire the
  Workspace ONE feed until `SNOWINT-Validate-Sync.ps1` shows 0 duplicates and matching coverage.

### Retired the WS1 feed and lost devices from the CMDB
- **Likely cause:** those devices had not yet re-enrolled in Intune (still WS1-only) when the feed was
  cut, so nothing refreshed them.
- **Fix:** confirm full Intune enrollment coverage (**`SNOWINT-Report-Coverage.ps1`**) **before**
  retiring the WS1 feed; the device migration itself is the WS1PROG program.

## Government / sovereign cloud

### Gov tenant: connection or scripts fail against `graph.microsoft.com`
- **Likely cause:** Commercial endpoints used for a GCC High / DoD tenant.
- **Fix:** point the ServiceNow connection at `https://graph.microsoft.us` (or `dod-graph.microsoft.us`)
  and `https://login.microsoftonline.us`; run scripts with `-Cloud USGov` / `USGovDoD`. **Verify for
  GCC High** that your connector release exposes a configurable sovereign endpoint; if not, use the
  custom Integration Hub import path with the `.us` endpoints.

---
### Escalation
If a symptom persists after these steps, capture: the ServiceNow import/data-stream log, the connection
test result, `SNOWINT-Preflight.ps1` output, and `SNOWINT-Validate-Sync.ps1` output — and consult the
current **ServiceNow Service Graph Connector for Microsoft Intune** documentation for your release
(names/behavior are release-specific) alongside Microsoft Graph device-management docs.
