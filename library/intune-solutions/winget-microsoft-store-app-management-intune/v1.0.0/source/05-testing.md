# 5. Testing Guide — Winget & Microsoft Store App Management with Microsoft Intune

Run after the apps apply to the pilot ring (Implementation Step 7) and again after expanding to the
broad ring. The worked example apps are `Adobe Acrobat Reader – Store – Required` (Required) and
`VLC media player – Winget – Available` (self-service).

## Test 1 — Required Store app installs automatically
**Do:** On a pilot device (user in `Store & Winget Apps – Pilot – Ring 1`), sync policy, wait a cycle,
then run `WINGETSTORE-Validate.ps1`.
**Expected:** `Adobe Acrobat Reader – Store – Required` installs **without user action** and is present
on the device.
**PASS/FAIL:** PASS if the app is installed and detected; FAIL if it never installs or reports Failed.

## Test 2 — A winget long-tail app installs
**Do:** Confirm the winget-backed app deploys on the device — either the Available app after a
self-service install (Test 3) or a winget-wrapped Win32 app if you used Step 5. Check with
`WINGETSTORE-Test-Install.ps1`.
**Expected:** The winget-sourced app (e.g. VLC media player) is installed and detected on the device.
**PASS/FAIL:** PASS if installed and detected; FAIL if absent or reporting Failed.

## Test 3 — An Available app self-installs via Company Portal
**Do:** On the pilot device, open **Company Portal**, locate `VLC media player – Winget – Available`,
and click **Install**.
**Expected:** The app appears in Company Portal for the pilot user, installs on demand, and Company
Portal shows it as **Installed**.
**PASS/FAIL:** PASS if the app is visible in Company Portal and self-installs; FAIL if it never appears
(check the Available assignment and Company Portal presence) or the install fails.

## Test 4 — An update applies
**Do:** For a Store/winget app with a newer version available, allow the service-managed update path a
cycle, then re-check the installed version with `WINGETSTORE-Test-Install.ps1` (or
`WINGETSTORE-Report.ps1` for the fleet). **The expected update timing is verify-with-Microsoft** —
confirm the current cadence for your tenant before treating a lag as a failure.
**Expected:** The installed app moves to the newer version without re-adding the app in Intune.
**PASS/FAIL:** PASS if the version advances within the documented cadence; FAIL if it stays behind after
the expected window (then see Troubleshooting E).

## Test 5 — Assignment and self-service are configured correctly
**Do:** Run `WINGETSTORE-Validate.ps1`, which checks that the pilot Store app is assigned **Required**
and the pilot winget app is assigned **Available** (self-service) to `Store & Winget Apps – Pilot –
Ring 1`.
**Expected:** Required app → Required assignment present; Available app → Available assignment present;
both scoped to the pilot group.
**PASS/FAIL:** PASS if both assignments match; FAIL if either is missing or mis-scoped.

## Test 6 — Fleet report
**Do:** Run `WINGETSTORE-Report.ps1 -CsvPath C:\Temp\wingetstore.csv`.
**Expected:** A clear per-app, per-device Installed / Failed / Not applicable / Pending breakdown across
the assigned rings, exported to CSV.
**PASS/FAIL:** PASS if the report generates and pilot devices show Installed; FAIL on widespread Failed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 PASS for the pilot ring `Store & Winget Apps – Pilot – Ring 1` |
| **Broad pass** | Tests 1, 3, 6 PASS for `Store & Winget Apps – Broad – Ring 2` after expansion |

Do **not** assign the broad ring until the pilot gate passes.
