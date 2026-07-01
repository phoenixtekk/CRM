# 5. Testing Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Run after the pilot policies apply (Implementation Step 9) and again after each STIG-release update
(Maintenance Part B, Step 5).

## Test 1 — Policies applied to the pilot
Do: Intune → Devices → Manage devices → Configuration → `STIG Win10/11 – CAT I – Pilot` → Device status (and Per-setting status). Repeat for CAT II/III.
Expected: Pilot devices show Succeeded; per-setting status shows the STIG settings applied without conflicts.

## Test 2 — Settings present on the device
Do: On a pilot device run `STIG-Validation.ps1`.
Expected: The script reports the device's STIG-relevant settings match the expected baseline values; no drift flagged.

## Test 3 — Compliance policy evaluates the device
Do: Intune → Devices → Compliance → `STIG Win10/11 – Compliance` → Device status; or on the device check Settings → Accounts → Access work or school.
Expected: Pilot devices evaluate Compliant against the STIG-relevant compliance rules.

## Test 4 — Reconcile with a STIG Viewer / SCAP scan
Do: Run a SCAP scan (or import results into the DISA STIG Viewer) against a pilot device and compare the findings to your Intune-applied baseline.
Expected: Applied CAT I/II rules show as Not a Finding (or Open only where a POA&M exists). Any Open finding without a POA&M is investigated.

## Test 5 — Imported ADMX settings applied (if used)
Do: Intune → `STIG Win10/11 – ADMX – Pilot` → Device status; confirm the imported-template settings on the device.
Expected: The imported administrative-template settings show Succeeded and are present on the device.

## Test 6 — App soak (hardening did not break the mission)
Do: Pilot users run their real mission apps for several business days (sign-in, line-of-business apps, printing, removable media, scripting).
Expected: No mission-app breakage. Any breakage is traced to a rule and handled as a POA&M exception or rolled back.

## Test 7 — Fleet posture and drift report
Do: Run `STIG-Report.ps1`.
Expected: A clear per-device STIG posture (compliant / drifted) and a drift list; pilot devices appear compliant.

## Test 8 — STIG-release diff (maintenance dry-run)
Do: Run `STIG-Compare-StigVersion.ps1` against the current live baseline using your current STIG export.
Expected: With no new release, the diff is empty (added/removed/changed = 0) — proving the script and your baseline agree before a real release update.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass; no unresolved mission-app breakage; open CAT I/II findings fixed or carried as approved POA&Ms |
| Production pass | Tests 1–3 and 7 pass for `STIG Win10/11 – Production Devices` after each rollout wave |
| Release-update pass | After a STIG release: Tests 1–6 re-pass on the pilot before promoting to production |
