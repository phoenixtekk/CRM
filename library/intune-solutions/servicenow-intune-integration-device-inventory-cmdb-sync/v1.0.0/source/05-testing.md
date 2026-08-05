# 5. Testing & Validation — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

Work top to bottom. Each test has an explicit **PASS / FAIL** gate. Do not expand to production until
the pilot tests pass.

## Test 1 — Microsoft-side preflight (auth + scopes + read)
1. Run **`SNOWINT-Preflight.ps1`** (add `-Cloud USGov` for a Gov tenant).
- **PASS:** connects to Graph; the four expected scopes are present; managed devices are readable
  (sample count > 0).
- **FAIL:** any scope missing / not consented, or the managed-device read errors. Fix the app
  registration / admin consent (§3 Steps 3–4) before touching ServiceNow.

## Test 2 — ServiceNow connection test
1. In the connector's connection, run the built-in **Test** action.
- **PASS:** authentication to Graph succeeds (token acquired). If a MID Server is used, it is **Up**.
- **FAIL:** auth error → recheck Tenant ID / Client ID / Client Secret and the Graph/token endpoint
  (Commercial vs `.us`).

## Test 3 — First import lands devices (pilot)
1. Trigger the import manually (§3 Step 10). Wait for completion; check the import/data-stream log for
   errors.
- **PASS:** the run completes; devices are created/updated in the CMDB with no transform errors.
- **FAIL:** transform/IRE errors in the log → see Troubleshooting (mapping / identifier).

## Test 4 — A known device is correct and NOT duplicated
1. Pick a known pilot device. In ServiceNow, search the CMDB by its **serial number**.
- **PASS:** exactly **one** CI in the correct hardware class; owner, OS, compliance, and last check-in
  are populated and match Intune; **discovery source** includes **Intune**.
- **FAIL:** two CIs for one serial → IRE identifier problem (see Test 6); wrong/blank fields → field
  map problem.

## Test 5 — Reconciliation against the Microsoft source of truth
1. Export the Intune set with **`SNOWINT-Export-ManagedDevices.ps1`**.
2. Export the CMDB device list to CSV (serial column), then run
   **`SNOWINT-Validate-Sync.ps1 -CmdbCsv <cmdb.csv>`**.
- **PASS:** **Matched** ≈ the pilot count; **Missing in CMDB** ≈ 0 (allowing for very recent
  enrollments); **DUPLICATE serials = 0**.
- **FAIL:** significant Missing (import scope/schedule) or any Duplicates (identifier) — resolve before
  expanding.

## Test 6 — No duplicates vs the existing Workspace ONE feed
1. For a device present in **both** the Workspace ONE feed and Intune, confirm in the CMDB there is
   **one** CI whose **discovery sources list both** Workspace ONE and Intune.
- **PASS:** single reconciled CI, both sources listed.
- **FAIL:** two CIs (one per source) → the serial-number IRE identifier is not shared across sources;
  fix the identification rule (§3 Step 8) and re-run.

## Test 7 — Ownership / compliance signal is usable
1. On several CIs, confirm the **assigned/primary user** and **compliance state** populated from
   Intune, and that the fields are visible on an Incident form's affected-CI lookup.
- **PASS:** owner + compliance present and visible to the service desk.
- **FAIL:** blank owner → confirm `Directory.Read.All` is consented and the owner field is mapped.

## Test 8 — App inventory (only if the app stream is enabled)
1. On a known device, confirm its installed/detected applications appear in the CMDB software model.
- **PASS:** the device's apps are listed.
- **FAIL:** confirm `DeviceManagementApps.Read.All` is consented and the detected-apps stream is
  enabled and mapped. *(Software licensing/entitlement is out of scope — SNOWSAM/SWDISC.)*

## Test 9 — Scheduled recurrence
1. Confirm the data stream is scheduled (e.g. daily) and enabled; after the next scheduled run,
   confirm **last check-in / last updated** on a CI advanced.
- **PASS:** the CI updates on schedule without manual triggering.
- **FAIL:** schedule disabled or erroring → re-enable and check the job log.

## Test 10 — Coverage matches expectation before cutover
1. Run **`SNOWINT-Report-Coverage.ps1`**; compare platform/ownership totals to the CMDB count.
- **PASS:** CMDB device count ≈ Intune managed-device count (minus intentionally out-of-scope
  platforms); coverage matches or exceeds the Workspace ONE feed before you retire it.
- **FAIL:** large gap → widen import scope / investigate missing serials before retiring WS1.

---
### Pilot exit criteria (all must be true)
- [ ] Preflight + connection tests PASS
- [ ] Known device correct, single CI, Intune as a discovery source
- [ ] `SNOWINT-Validate-Sync.ps1`: 0 duplicates, ~0 missing
- [ ] Dual-source device reconciles to one CI (no WS1/Intune duplicate)
- [ ] Owner + compliance populated and visible to the service desk
- [ ] Scheduled run updates CIs automatically
- [ ] Coverage report matches expectation
