# 5. Testing Guide — Endpoint Health & Digital Experience Monitoring

Run after the pilot has collected its baseline (Implementation Step 4) and after wiring proactive
remediations (Step 6). Repeat each monitoring cycle.

## Test 1 — Endpoint analytics is enabled and reporting
**Do:** `Reports → Endpoint analytics → Overview`.
**Expected:** A score (0–100) and the four sub-scores are shown — not the "get started" prompt.

## Test 2 — Pilot devices are onboarded for analytics
**Do:** On a pilot device run `EHEM-Validation.ps1`; cross-check `Endpoint analytics → Settings`.
**Expected:** The device reports as enrolled for analytics; diagnostic data is at the required level.

## Test 3 — Startup performance data is present
**Do:** `Endpoint analytics → Startup performance`; or run `EHEM-Report.ps1`.
**Expected:** Pilot devices appear with boot/sign-in times; counts grew over the baseline period.

## Test 4 — Application reliability data is present
**Do:** `Endpoint analytics → Application reliability`.
**Expected:** Apps are listed with crash/hang scores for the pilot devices.

## Test 5 — Resource performance data is present
**Do:** `Endpoint analytics → Resource performance`.
**Expected:** Devices show CPU/RAM spike-time scores; outliers are identifiable.

## Test 6 — Proactive remediation runs and fixes
**Do:** `Endpoint analytics → Proactive remediations →` open the pilot package **→ Device status**.
**Expected:** Run history shows detections and successful remediations on pilot devices.

## Test 7 — Fleet report
**Do:** Run `EHEM-Report.ps1`.
**Expected:** A clear summary of the overall/sub-scores and the top startup, reliability, and
resource issues across the monitored devices.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass; the baseline period completed and scores are populated for the pilot |
| **Broad pass** | Tests 1, 3–5, 7 pass for the broad scope, and remediation run history is healthy |
