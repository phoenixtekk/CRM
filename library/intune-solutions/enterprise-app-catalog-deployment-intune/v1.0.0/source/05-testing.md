# 5. Testing Guide — Enterprise App Catalog Deployment in Microsoft Intune

Run after the app applies to the pilot ring (Implementation Step 8) and again after expanding to the
broad ring. The worked example is `Catalog App – Sample App – Prod`, assigned to
`Catalog Apps – Pilot Devices – Ring 1`.

## Test 1 — App added from the catalog
**Do:** Intune → **Apps → All apps** → confirm `Catalog App – Sample App – Prod` exists and its type
is the **Enterprise App Catalog** app type.
**Expected (PASS):** The catalog app is present with Microsoft's prebuilt package attached.
**FAIL:** The app is missing or was created as a hand-packaged Win32 app instead — re-add via the
Enterprise App Catalog app type (Implementation Step 2).

## Test 2 — App reports applicable to the pilot ring
**Do:** Open `Catalog App – Sample App – Prod` → **Device install status**.
**Expected (PASS):** Pilot devices are targeted and **not** **Not applicable**.
**FAIL:** Devices show **Not applicable** — confirm the device is in `Catalog Apps – Pilot Devices –
Ring 1` and meets any requirement (see Troubleshooting §B).

## Test 3 — Install succeeds on the device
**Do:** On a pilot device, sync, then run `ENTAPPCAT-Test-Install.ps1`.
**Expected (PASS):** The IME service is healthy and the app is present / detected on the device.
**FAIL:** IME missing or app absent — sync and re-check (Troubleshooting §C / §F).

## Test 4 — Built-in detection agrees with Intune (reporting is true)
**Do:** Compare Intune → the app → **Device install status** with `ENTAPPCAT-Validate.ps1` on-device.
**Expected (PASS):** Intune reports **Installed** and the on-device state agrees — no "installed but
failed" mismatch and no reinstall loop.
**FAIL:** Mismatch — this is unusual for a catalog app (Microsoft supplies the detection rule);
capture the IME log and see Troubleshooting §A before escalating.

## Test 5 — Update management is enabled
**Do:** Open `Catalog App – Sample App – Prod` → the **update management** setting; or run
`ENTAPPCAT-Validate.ps1` (it reports update management on/off).
**Expected (PASS):** Update management is **enabled** (or the intended version pin is set).
**FAIL:** Update management is off unexpectedly — re-enable (Implementation Step 6).

## Test 6 — An update applies via update management
**Do:** When Microsoft publishes a newer version of the catalog app (or on the next update cycle),
run `ENTAPPCAT-Report.ps1` and confirm the deployed version advances on pilot devices.
**Expected (PASS):** Pilot devices move to the newer version without you re-wrapping or re-uploading a
package.
**FAIL:** Version does not advance after a cycle — confirm update management is enabled and allow a
full policy/update cycle; *update cadence is Microsoft-defined (verify current behavior)* before
concluding it is broken (Troubleshooting §D).

## Test 7 — Fleet report
**Do:** Run `ENTAPPCAT-Report.ps1 -CsvPath C:\Temp\entappcat.csv`.
**Expected (PASS):** A clear per-device Installed / Failed / Not applicable breakdown (and version
where available) across the assigned rings, exported to CSV.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass on `Catalog Apps – Pilot Devices – Ring 1`; install + detection agree; update management enabled |
| **Update pass** | Test 6 passes — an update applies via update management on a pilot device |
| **Broad pass** | Tests 3, 4, 7 pass for `Catalog Apps – Broad Devices – Ring 2` after expansion |

Do **not** assign the broad ring until the pilot gate passes.
