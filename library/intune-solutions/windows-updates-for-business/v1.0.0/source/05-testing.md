# 5. Testing Guide — Windows Updates for Business

Run after the pilot ring applies (Implementation Step 7) and after each update cycle / feature move.

## Test 1 — Ring policy applied
**Do:** Intune → **Devices → Windows → Update rings →** `Update Ring - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Settings present on device
**Do:** On a pilot device run `WUFB-Validation.ps1`, or open **Settings → Windows Update** ("Some settings are managed by your organization").
**Expected:** Quality/feature deferral and deadline values match the ring; active hours set.

## Test 3 — Updates install on schedule
**Do:** Let the current quality update flow to the pilot; observe install + scheduled restart within the deadline.
**Expected:** The update installs and the device restarts per the deadline/active-hours policy.

## Test 4 — Feature version pinned
**Do:** Run `WUFB-ComplianceReport.ps1` (or check `winver`).
**Expected:** Pilot devices are on (or moving to) the **targeted** feature version — not drifting ahead.

## Test 5 — Expedite works (when needed)
**Do:** Create an expedite profile for a test/recent quality update; assign to a pilot device.
**Expected:** The device installs that update promptly, bypassing the deferral.

## Test 6 — Delivery Optimization active
**Do:** On a pilot device: `Get-DeliveryOptimizationStatus` after an update downloads.
**Expected:** Peer/LAN bytes are used where available (download mode reflects the policy).

## Test 7 — Fleet report
**Do:** Run `WUFB-ComplianceReport.ps1` and `WUFB-RingReport.ps1`.
**Expected:** A clear per-device update status + OS build inventory and the ring assignments.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; the cycle's quality update installs cleanly on the pilot |
| **Broad pass** | Tests 1–3, 7 pass for the broad ring before the next feature move |
