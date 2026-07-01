# 5. Testing Guide — WSUS to Windows Update for Business Migration

Run after the pilot ring applies and the WSUS/GPO policy is removed (Implementation Steps 7–9), and
again before decommissioning WSUS (Step 11). The central question every test answers: **is the
device now scanning Microsoft instead of WSUS, and patching on the Intune ring?**

## Test 1 — WSUS pointer removed
**Do:** On a pilot device run `WSUSM-Validation.ps1` (or `WSUSM-Discovery.ps1`).
**Expected:** No `WUServer`/`WUStatusServer`, `UseWUServer = 0` or absent, and
`DoNotConnectToWindowsUpdateInternetLocations` not enabled.

## Test 2 — Ring policy applied
**Do:** Intune → **Devices → Manage updates → Windows updates → Update rings →**
`WUfB – Update Ring – Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 3 — Device scans Microsoft
**Do:** On a pilot device, run `WSUSM-Validation.ps1`; it triggers a scan and confirms the source.
**Expected:** The device checks Windows Update online (Microsoft), not the WSUS server; quality/
feature deferral and deadline values match the ring.

## Test 4 — Updates install on schedule from Microsoft
**Do:** Let the current quality update flow to the pilot; observe install + scheduled restart within
the deadline.
**Expected:** The update downloads from Microsoft/Delivery Optimization and the device restarts per
the deadline/active-hours policy.

## Test 5 — Feature version pinned
**Do:** Run `WSUSM-Report.ps1` (or check `winver`).
**Expected:** Pilot devices are on (or moving to) the **targeted** feature version — not drifting.

## Test 6 — Delivery Optimization active
**Do:** On a pilot device: `Get-DeliveryOptimizationStatus` after an update downloads.
**Expected:** Peer/LAN bytes are used where available — confirming DO replaces the WSUS local cache.

## Test 7 — Fleet report
**Do:** Run `WSUSM-Report.ps1`.
**Expected:** A clear per-device update status + OS-build inventory with ring assignments; no device
still reporting a WSUS source.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (cutover gate)** | Tests 1–5 pass; the cycle's quality update installs cleanly from Microsoft on the pilot |
| **Broad pass** | Tests 1–4, 7 pass for the broad ring |
| **Decommission gate** | No device reports a WSUS source (Test 7); broad pass achieved — only then retire WSUS |
