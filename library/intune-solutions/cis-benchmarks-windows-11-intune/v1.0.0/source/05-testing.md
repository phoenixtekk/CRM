# 5. Testing Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Run after the pilot policies apply (Implementation Step 8) and again after each benchmark-version
update (Maintenance Part B, Step 5).

## Test 1 — Policies applied to the pilot
**Do:** Intune → **Devices → Manage devices → Configuration →** `CIS Win11 – L1 – Pilot` **→ Device status** (and **Per-setting status**).
**Expected:** Pilot devices show **Succeeded**; per-setting status shows the CIS settings applied without conflicts.

## Test 2 — Settings present on the device
**Do:** On a pilot device run `CIS11-Validation.ps1`.
**Expected:** The script reports the device's CIS-relevant settings match the expected baseline values; no drift flagged.

## Test 3 — Compliance policy evaluates the device
**Do:** Intune → **Devices → Compliance →** `CIS Win11 – Compliance` **→ Device status**; or on the device check **Settings → Accounts → Access work or school**.
**Expected:** Pilot devices evaluate **Compliant** against the CIS-relevant compliance rules.

## Test 4 — Level 2 controls present (if deployed)
**Do:** On an L2 pilot device, run `CIS11-Validation.ps1` (it includes L2 checks when the L2 policy is assigned).
**Expected:** L2 settings are present in addition to L1; no L1/L2 conflicts.

## Test 5 — Imported ADMX settings applied (if used)
**Do:** Intune → `CIS Win11 – ADMX – Pilot` **→ Device status**; confirm the imported-template settings on the device.
**Expected:** The imported administrative-template settings show **Succeeded** and are present on the device.

## Test 6 — App soak (hardening did not break the business)
**Do:** Pilot users run their real apps for several business days (sign-in, line-of-business apps, printing, removable media, scripting).
**Expected:** No business-app breakage. Any breakage is traced to a control and handled as a break-glass exception or rolled back.

## Test 7 — Fleet posture and drift report
**Do:** Run `CIS11-Report.ps1`.
**Expected:** A clear per-device CIS posture (compliant / drifted) and a drift list; pilot devices appear compliant.

## Test 8 — Benchmark-version diff (maintenance dry-run)
**Do:** Run `CIS11-Compare-BenchmarkVersion.ps1` against the current live baseline using your current benchmark export.
**Expected:** With no new version, the diff is empty (added/removed/changed = 0) — proving the script and your baseline agree before a real version update.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass; no unresolved business-app breakage on the pilot |
| **Production pass** | Tests 1–3 and 7 pass for `CIS Win11 – Production Devices` after each rollout wave |
| **Version-update pass** | After a benchmark update: Tests 1–6 re-pass on the pilot before promoting to production |
