# 5. Testing Guide — Windows Autopilot

Run after a pilot device completes OOBE (Implementation Step 8) and after each production wave.

## Test 1 — Profile assigned
**Do:** Intune → **Devices → Enrollment → Devices** → select the device → **Profile status**.
**Expected:** **Assigned** (not "Assigning"/"Not assigned").

## Test 2 — OOBE provisions end-to-end
**Do:** Power on the registered device, connect to the internet, sign in with a work account.
**Expected:** Autopilot branding shows; the device completes OOBE without manual configuration.

## Test 3 — Entra joined + Intune enrolled
**Do:** On the device run `dsregcmd /status`; in Intune check **Devices → All devices**.
**Expected:** `AzureAdJoined : YES`; the device is listed and **compliant** in Intune.

## Test 4 — Enrollment Status Page completes
**Do:** Watch the ESP during provisioning, or run `Autopilot-Validation.ps1` afterward.
**Expected:** ESP reaches "All done!"; required apps/policies installed.

## Test 5 — Policies and apps applied
**Do:** Intune → device → **Device configuration** / **Managed apps**.
**Expected:** Assigned policies show **Succeeded**; required apps installed.

## Test 6 — Compliance intact
**Do:** Intune → **Devices → Compliance**.
**Expected:** The device is **Compliant**.

## Test 7 — Tenant report
**Do:** Run **`Autopilot-TenantReport.ps1`**.
**Expected:** The device appears with profile **Assigned** and enrollment state OK.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for 100% of pilot devices |
| **Wave pass** | Tests 1–5 pass for the wave before the next |
