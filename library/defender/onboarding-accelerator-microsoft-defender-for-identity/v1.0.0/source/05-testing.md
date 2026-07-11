# 5. Testing Guide — Onboarding Accelerator: Microsoft Defender for Identity

Run these checks after the pilot onboarding (Steps 2–8) and again after each expansion wave. Each test has a **pass/fail gate**; do not expand to the remaining domain controllers until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — DSA configured
**Procedure:** Run `MDIONB-Validate.ps1 -Check DSA`. In `security.microsoft.com` → **Settings → Identities → Directory Service accounts**, confirm `MDI Directory Service Account – Tenant – Prod` is present.
**Pass:** The DSA (gMSA) is registered and the sensor can retrieve its password.
**Fail:** DSA missing or password-retrieval fails — see Troubleshooting *DSA not working*.

## Test 2 — Pilot sensor healthy
**Procedure:** Run `MDIONB-Validate.ps1 -Check Sensor`. In **Settings → Identities → Sensors**, confirm `MDI Sensor Host – Pilot DC – Pilot` is **Running / Healthy**.
**Pass:** The pilot sensor is healthy and reporting; no health alerts against it.
**Fail:** Sensor "Unhealthy / Not configured / Stopped" — see Troubleshooting *Sensor unhealthy*.

## Test 3 — Sensitive entities tagged
**Procedure:** Run `MDIONB-Validate.ps1 -Check Sensitive`. In **Settings → Identities → Entity tags → Sensitive**, confirm the `MDI Sensitive Entities – Tier0 – Prod` accounts/groups/servers are tagged.
**Pass:** All planned Tier-0 entities are tagged sensitive.
**Fail:** Tier-0 entities missing — re-apply per Implementation Step 4.

## Test 4 — Honeytokens tagged
**Procedure:** Run `MDIONB-Validate.ps1 -Check Honeytoken`. In **Settings → Identities → Entity tags → Honeytoken**, confirm `MDI Honeytoken – Decoy Identity – Pilot` is tagged.
**Pass:** The decoy account(s) are tagged as honeytokens and remain unused.
**Fail:** Not tagged, or the account shows real usage — re-apply per Implementation Step 5 and confirm nothing legitimate uses the account.

## Test 5 — Identity signal streaming
**Procedure:** Run `MDIONB-Hunt.ps1` to execute `MDI Detection Validation – Tenant – Validate`. Confirm `IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, and `IdentityQueryEvents` return recent rows.
**Pass:** All four identity tables stream from the pilot sensor.
**Fail:** A table is empty — see Troubleshooting *No identity signal*.

## Test 6 — A detection actually fires
**Procedure:** Trigger a benign, controlled detection — authenticate against or query the honeytoken `MDI Honeytoken – Decoy Identity – Pilot`, or run a Microsoft-documented safe simulation. In `security.microsoft.com` → **Incidents & alerts**, confirm the resulting alert appears.
**Pass:** The controlled test produces a visible MDI alert within the expected window.
**Fail:** No alert — see Troubleshooting *Detection does not fire*.

## Test 7 — ISPM recommendations present
**Procedure:** Run `MDIONB-Report.ps1 -SaveBaseline`. In **Secure Score → Recommended actions** (Identity), confirm MDI ISPM recommendations are listed.
**Pass:** ISPM recommendations appear and a posture baseline is recorded.
**Fail:** No recommendations — allow sensor warm-up time, confirm sensor health (Test 2), then re-run; see Troubleshooting *No ISPM recommendations*.

## Test 8 — Response actions approval-gated
**Procedure:** Run `MDIONB-Report.ps1` and confirm response actions are approval-gated (not automatic) per Implementation Step 7.
**Pass:** No response action auto-executes during the pilot; actions require approval.
**Fail:** Automation is higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

---
### Exit gate
All eight tests pass on the pilot DC **before** expanding to the remaining domain controllers (Implementation Step 9). Re-run Tests 2, 5, 6, and 7 after each sensor-expansion wave and compare against the saved posture baseline.
