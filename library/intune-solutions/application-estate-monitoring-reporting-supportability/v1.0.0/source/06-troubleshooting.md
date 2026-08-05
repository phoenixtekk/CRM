# Troubleshooting

This covers the failure modes of the **reporting pipeline and dashboard themselves** — not
per-install app failures, which the dashboard exists to surface and hand to a troubleshooter. Each
entry is **Symptom → Cause → Fix**, and references the exact objects from Implementation.

---

## T1. The extractor returns no rows / empty CSV

**Symptom:** `APPRPT-Export-AppInstallStatus.ps1` completes but writes an empty file, or prints "No
app device-status data found."

**Cause & fix:**
- **No assignments / no installs yet** — an app with no assignment has no `deviceStatuses`. Confirm
  the pilot apps are assigned to devices in `PILOT – App Estate Reporting`.
- **`-AppNameLike` filter too narrow** — it silently excludes everything. Run once without the filter.
- **Wrong scopes** — if `Connect-MgGraph` succeeded but data is empty, confirm
  `DeviceManagementApps.Read.All` was consented (R3), not just requested.
- **Wrong cloud** — a Commercial `-Environment Global` run against a GCC High tenant authenticates to
  the wrong endpoint and returns nothing. Set `-Environment USGov` / `USGovDoD` (R11).

---

## T2. Export counts don't match the Intune console (Testing Gate 2 fails)

**Symptom:** The console shows, say, 480 installed for an app; the CSV shows 455.

**Cause & fix:**
- **"Applicable" counted differently** — the console's Overview may exclude `notApplicable` devices
  from a percentage while your count includes them. Compare **raw state counts**, not percentages, and
  make sure both sides define "applicable" as `total − notApplicable`.
- **Snapshot timing** — devices check in continuously; a console read and an export minutes apart
  legitimately differ by a few devices. Re-read both within the same minute for the gate.
- **Beta endpoint shape changed** — the scripts use the Graph **beta** `deviceStatuses`; Microsoft
  occasionally changes fields. If a state value looks unmapped, inspect one raw record with
  `Invoke-MgGraphRequest -Method GET -Uri ".../deviceStatuses"` and adjust the state filter.

---

## T3. Power BI refresh fails with a credentials or gateway error

**Symptom:** Scheduled refresh on `App Estate Reporting – Dataset – v1` fails; the service reports a
credential or data-source error.

**Cause & fix:**
- **Azure Blob source** — set the data-source credentials on the dataset (**Settings → Data source
  credentials**) to an identity with **Storage Blob Data Reader** on `app-estate-exports` (R6).
- **On-prem folder source** — a folder like `C:\AppEstateReporting\Exports` needs an **on-premises
  data gateway** installed and bound to the dataset; a cloud-only refresh cannot reach a local path.
- **File moved/renamed** — if the dataset points at a specific file rather than a folder/container,
  each new dated export breaks it. Point the query at the **folder/container** and combine files, not
  at one filename.

---

## T4. The nightly task prompts for sign-in or produces nothing (Testing Gate 8 fails)

**Symptom:** `App Estate Reporting – Nightly Export` runs but a sign-in window appears, or it produces
no file when run under the service account.

**Cause & fix:**
- **Still using delegated auth** — the interactive extractor path prompts. The unattended run must use
  the app registration `App Estate Reporting – Graph Export` with **certificate + application scopes**
  (R2/R4). Confirm the task's script invocation uses app-only auth, not interactive `Connect-MgGraph`.
- **Consent missing** — application scopes show as *requested* but not *granted*. Grant admin consent
  (App registration → API permissions → **Grant admin consent**), then re-run.
- **Certificate not found / expired** — the cert must be in the store the task account can read, and
  in date. Re-run `APPRPT-Bootstrap-ScheduledExport.ps1` (it sets a 1-year cert) or renew it.
- **Wrong user context** — the task must run as an account that has the certificate and write access
  to the storage location. Check **Task Scheduler → the task → General → "Run as."**

---

## T5. Version-drift numbers look wrong or the app isn't found

**Symptom:** `APPRPT-Report-VersionDrift.ps1` reports "App not found," or a version you know is
deployed is missing from the histogram.

**Cause & fix:**
- **Name mismatch** — `detectedApps` uses the app's *installed* display name, which can differ from
  the Intune app name (e.g. "Google Chrome" vs the packaging name). Widen `-AppDisplayNameLike`.
- **Stale detected-app inventory** — Intune refreshes discovered apps on a schedule; a very recent
  install may not appear yet. Confirm the device's **last sync** is recent.
- **Version string parsing** — some apps report non-numeric version strings. The script sorts
  defensively, but treat the histogram order as approximate for such apps and rely on the counts.

---

## T6. Graph requests throttle at fleet scale (HTTP 429)

**Symptom:** After Step 13 (whole estate), the extractor or KPI snapshot slows dramatically or errors
with 429 / "Too many requests."

**Cause & fix:**
- **Expected at scale** — reading `deviceStatuses` per app across a large estate is many calls. The
  scripts follow `@odata.nextLink` paging; add a short delay between apps, run the nightly export in a
  **quiet window**, and consider the Graph **`exportJobs`** report API (asynchronous, one job instead
  of many calls) for very large tenants — see Overview data source #2.
- **Overlapping runs** — don't run the interactive extractor and the nightly task at the same time.
- **Honor Retry-After** — if you customize the scripts, respect the `Retry-After` header on a 429
  rather than hammering.

---

## T7. Alert never fires, or fires constantly (Testing Gate 9)

**Symptom:** `ALERT – App Failure Rate – High` either never triggers or pages every hour.

**Cause & fix:**
- **Never fires** — the KQL scope/query is wrong or `law-endpoint-ops` isn't receiving app data.
  Confirm the diagnostic setting `Intune → law-endpoint-ops` is sending the needed categories (R9) and
  test by lowering the threshold (Gate 9).
- **Fires constantly** — the threshold is below your normal baseline. Re-tune to **2× the trailing
  7-day baseline** (or a sensible absolute floor) after observing a month of real data, per Best
  Practices.
- **No notification though it fired** — the action group `AG – Endpoint Operations` has no valid
  recipient/webhook, or the ticketing webhook rejected the payload. Re-check the action group.

---

## T8. Government-cloud endpoint errors

**Symptom:** In a GCC High / DoD tenant, `Connect-MgGraph` fails, or Power BI publish targets the
wrong service.

**Cause & fix:**
- **Graph** — pass `-Environment USGov` (Graph `graph.microsoft.us`) or `-Environment USGovDoD`
  (`dod-graph.microsoft.us`). The default `Global` cannot reach a sovereign tenant.
- **Power BI** — sign Power BI Desktop into **`app.powerbigov.us`** before publishing; a report
  authored against the commercial service cannot be published to the Government cloud. Keep a
  **separate** Government dataset/report (Best Practices → Government cloud).
- **Feature parity** — if a Graph report endpoint or Power BI feature you depend on isn't available in
  your Government cloud yet, **verify for GCC High** against Microsoft's US-sovereign-cloud
  documentation; do not assume commercial parity.

---

## T9. Adoption numbers look implausible or can't be sourced

**Symptom:** The adoption KPI is blank, zero, or obviously wrong.

**Cause & fix:**
- **No native source** — Intune does not report per-app *launch* telemetry for Windows desktop apps.
  Wire adoption from whatever signal your estate has (M365 Apps usage, Defender for Endpoint software
  inventory, Endpoint analytics app reliability, or the vendor portal) and **label the KPI's source
  and confidence** (Overview caveat, Best Practices). Do not present an adoption number whose source
  you can't name.
- **Confidence not shown** — if the number is assembled from indirect signals, mark it "indicative" on
  the drill-down page so consumers read it correctly.

---

## T10. Two visuals show different values for the "same" KPI

**Symptom:** The executive card and an operations visual disagree on, say, install success rate.

**Cause & fix:**
- **KPI recomputed from a second query** — the cardinal sin. Every visual must read the **shared DAX
  measure** from `App Estate Reporting – Dataset – v1`, not its own recomputation. Delete the offending
  ad-hoc measure and repoint the visual at the canonical measure.
- **Different filter context** — one visual is filtered (a slicer, a page filter) and the other isn't.
  Confirm both are at the same scope before concluding they disagree.
