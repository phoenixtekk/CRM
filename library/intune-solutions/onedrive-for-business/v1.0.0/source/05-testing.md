# 5. Testing Guide — OneDrive for Business

Run these validations after the pilot device has applied policy (Implementation Step 11) and
again after each production wave. Each test states **what to do** and the **expected result**. Do
not expand the rollout until every test passes for the pilot group.

## Test 1 — Policy applied
**Do:** Intune admin center → **Devices → Configuration →** `OneDrive - Pilot - Silent + KFM` **→ Device/User check-in status**.
**Expected:** Pilot devices/users show **Succeeded**. No **Error** or **Conflict**.

## Test 2 — Silent Sign-In worked
**Do:** On a pilot device, look at the OneDrive cloud icon in the system tray (signed in, no prompt). Or run `ODFB-Validation.ps1`.
**Expected:** OneDrive is signed in with the work account automatically — the user was never prompted. Registry `SilentAccountConfig = 1`.

## Test 3 — Known Folder Move applied
**Do:** Open **File Explorer**. Check the location of **Desktop**, **Documents**, and **Pictures** (right-click → Properties → Location), or run `ODFB-Validation.ps1`.
**Expected:** All three point into the OneDrive folder (path contains **OneDrive - <Org>**). Existing files were moved up and continue to sync.

## Test 4 — Files On-Demand active
**Do:** In File Explorer, view the **Status** column in the OneDrive folder.
**Expected:** Files show cloud / "Available when online" badges (not all forced local). Registry `FilesOnDemandEnabled = 1`.

## Test 5 — Sync works (round-trip)
**Do:** Create a test file on the Desktop. Sign in to `https://<tenant>-my.sharepoint.com` in a browser.
**Expected:** The test file appears in OneDrive online within a minute. Delete it online; it disappears locally.

## Test 6 — Version history / ransomware recovery
**Do:** Edit and save a synced document twice. In OneDrive online, right-click the file → **Version history**.
**Expected:** Multiple versions are listed and can be restored — the basis for ransomware recovery.

## Test 7 — Compliance remains intact
**Do:** Intune → **Devices → Compliance**; review the pilot devices after OneDrive configuration.
**Expected:** Devices remain **Compliant**; no new compliance failures were introduced.

## Test 8 — Tenant usage report
**Do:** Run **`ODFB-TenantReport.ps1`** (Microsoft Graph).
**Expected:** Pilot users appear with OneDrive provisioned and non-zero storage used / files synced.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 (and 7–8) all pass for **100%** of the pilot group |
| **Wave pass** | Tests 1–5, 7 pass for the wave before starting the next |

Record results in your change log. If any test fails, use the **Troubleshooting Guide** (Section 6)
and the **`ODFB-Remediation.ps1`** script before proceeding.
