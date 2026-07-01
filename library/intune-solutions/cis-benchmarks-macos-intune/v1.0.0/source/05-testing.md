# 5. Testing Guide — CIS Benchmarks for macOS (Microsoft Intune)

Run after the pilot objects apply (Implementation Step 10) and again after each benchmark-version
update (Maintenance Part B, Step 5).

## Test 1 — Settings-catalog policy applied to the pilot
**Do:** Intune → **Devices → macOS → Configuration →** `CIS macOS – L1 – Pilot` **→ Device status** (and **Per-setting status**).
**Expected:** Pilot Macs show **Succeeded**; per-setting status shows the CIS settings applied without conflicts.

## Test 2 — Settings present on the device
**Do:** On a pilot Mac run `CISMAC-Validation.ps1`.
**Expected:** The script reports the Mac's CIS-relevant settings match the expected baseline values; no drift flagged.

## Test 3 — Compliance policy evaluates the device
**Do:** Intune → **Devices → macOS → Compliance →** `CIS macOS – Compliance` **→ Device status**; or on the Mac check **Company Portal**.
**Expected:** Pilot Macs evaluate **Compliant** against the CIS-relevant compliance rules (for example FileVault on, firewall on, minimum OS version).

## Test 4 — Custom `.mobileconfig` profile applied (if used)
**Do:** Intune → `CIS macOS – Custom – Pilot` **→ Device status**; on the Mac confirm via **System Settings → Privacy & Security → Profiles**.
**Expected:** The custom profile shows **Succeeded** and the payload is present on the Mac.

## Test 5 — Shell-script control applied (if used)
**Do:** Intune → **Devices → macOS → Shell scripts →** `CIS macOS – Shell – Pilot` **→ Device status**; confirm the resulting setting on the Mac.
**Expected:** The script shows it ran successfully and the targeted control value is set.

## Test 6 — Level 2 controls present (if deployed)
**Do:** On an L2 pilot Mac, run `CISMAC-Validation.ps1` (it includes L2 checks when the L2 policy is assigned).
**Expected:** L2 settings are present in addition to L1; no L1/L2 conflicts.

## Test 7 — App and login soak (hardening did not break the business)
**Do:** Pilot users run their real apps for several business days (sign-in / login window, app launch under Gatekeeper, firewall-blocked apps, printing, removable media, automation).
**Expected:** No business-app or login breakage. Any breakage is traced to a control and handled as a break-glass exception or rolled back.

## Test 8 — Fleet posture and drift report
**Do:** Run `CISMAC-Report.ps1`.
**Expected:** A clear per-device CIS posture (compliant / drifted) and a drift list; pilot Macs appear compliant.

## Test 9 — Benchmark-version diff (maintenance dry-run)
**Do:** Run `CISMAC-Compare-BenchmarkVersion.ps1` against the current live baseline using your current benchmark export.
**Expected:** With no new version, the diff is empty (added/removed/changed = 0) — proving the script and your baseline agree before a real version update.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass; no unresolved business-app or login breakage on the pilot |
| **Production pass** | Tests 1–3 and 8 pass for `CIS macOS – Production Devices` after each rollout wave |
| **Version-update pass** | After a benchmark update: Tests 1–7 re-pass on the pilot before promoting to production |
