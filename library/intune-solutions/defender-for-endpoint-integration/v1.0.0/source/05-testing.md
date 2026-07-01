# 5. Testing Guide — Microsoft Defender for Endpoint Integration

Run after the pilot onboarding policy applies (Implementation Step 8) and after each production wave.

## Test 1 — Connector active
**Do:** Intune → **Endpoint security → Microsoft Defender for Endpoint**; or run `MDE-ConnectorCheck.ps1`.
**Expected:** Connection status **Active / Available**.

## Test 2 — Onboarding policy applied
**Do:** Intune → **Endpoint security → Endpoint detection and response →** policy → **Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 3 — Device onboarded (local)
**Do:** On a pilot device run `MDE-Validation.ps1` (checks the Sense service + onboarding state).
**Expected:** Sense service **Running**; `OnboardingState = 1`.

## Test 4 — Device appears in the Defender portal
**Do:** `https://security.microsoft.com` → **Assets → Devices**.
**Expected:** The pilot device is listed with health **Active** and a risk level.

## Test 5 — Risk score feeds compliance
**Do:** Intune → device → **Compliance**; review the Defender risk requirement.
**Expected:** A device under the threshold is **Compliant**; a higher-risk device would be **Not compliant**.

## Test 6 — EDR detection (optional, safe simulation)
**Do:** Run Microsoft's official EDR detection test (from the Defender portal device page) on a test device.
**Expected:** An alert appears in the Defender portal, confirming EDR telemetry.

## Test 7 — Tenant report
**Do:** Run **`MDE-TenantReport.ps1`**.
**Expected:** Onboarded devices with health + risk score listed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass for the pilot group |
| **Wave pass** | Tests 2–3, 5, 7 pass before the next wave |
