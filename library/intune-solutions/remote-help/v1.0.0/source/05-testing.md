# 5. Testing Guide — Remote Help

Run after the pilot setup (Implementation Step 7) and after each production wave.

## Test 1 — Remote Help enabled
**Do:** Intune → **Tenant administration → Remote Help**; or run `RHELP-SettingsCheck.ps1`.
**Expected:** Remote Help is **Enabled** with your chosen options (remote control, unenrolled policy).

## Test 2 — App deployed
**Do:** On pilot helper and sharer devices run `RHELP-Validation.ps1` (checks the app is installed).
**Expected:** The Remote Help app is present (and the assignment shows Succeeded in Intune → Apps).

## Test 3 — RBAC gates access
**Do:** Have a non-help-desk account attempt to give help.
**Expected:** Only members of the help-desk role can initiate a "Give help" session.

## Test 4 — Session connects with consent
**Do:** Run a session: sharer requests help, helper joins, sharer consents.
**Expected:** The session connects; the helper sees the device, and control works if enabled.

## Test 5 — Compliance is surfaced
**Do:** During the session, observe the device compliance indicator shown to the helper.
**Expected:** The helper sees whether the device is compliant before assisting.

## Test 6 — Session is audited
**Do:** Run `RHELP-SessionReport.ps1` (or review Intune audit/Remote Help usage).
**Expected:** The session appears with helper, sharer, and timestamp.

## Test 7 — Unenrolled-device policy honored
**Do:** If "allow unenrolled" is **No**, attempt to help an unenrolled device.
**Expected:** The session is not permitted, per policy.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for the pilot helpers/sharers |
| **Wave pass** | Tests 2, 4, 6 pass before the next wave |
