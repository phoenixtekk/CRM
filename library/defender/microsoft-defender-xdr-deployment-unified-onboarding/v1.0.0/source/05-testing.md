# 5. Testing Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Run these checks after the pilot onboarding (Steps 2–8) and again after each expansion wave. Each test has a **pass/fail gate**; do not expand tenant-wide until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Endpoint (MDE) onboarding
**Procedure:** Run `DEFXDR-Validate.ps1 -Pillar Endpoint`. In `security.microsoft.com` → **Assets → Devices**, confirm each pilot device (from `MDE Onboarding – Pilot Ring – Pilot`) appears as **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting; the script reports EDR signal within the expected window.
**Fail:** A pilot device is missing or "Can be onboarded" — see Troubleshooting *Device not onboarding*.

## Test 2 — Identity (MDI) sensor health
**Procedure:** Run `DEFXDR-Validate.ps1 -Pillar Identity`. In **Settings → Identities → Sensors**, confirm the pilot DC sensor is **Running / Healthy**.
**Pass:** The sensor is healthy, the DSA is configured, and identity signal is flowing.
**Fail:** Sensor "Not configured / Unhealthy" — see Troubleshooting *MDI sensor unhealthy*.

## Test 3 — Office 365 (MDO) policy active
**Procedure:** Run `DEFXDR-Validate.ps1 -Pillar Office365`. Send a benign EICAR-style test through the standard Microsoft test procedure to a pilot user, or confirm Safe Links rewriting on a test message.
**Pass:** MDO preset policy is applied to `XDR Pilot Users – Pilot Ring – Pilot`; `EmailEvents` appears in advanced hunting.
**Fail:** Policy not applied or no email signal — see Troubleshooting *MDO no email signal*.

## Test 4 — Cloud Apps (MDCA) discovery
**Procedure:** Run `DEFXDR-Validate.ps1 -Pillar CloudApps`. In **Cloud apps → Cloud discovery → Dashboard**, confirm discovery data from pilot devices.
**Pass:** MDCA is active, the MDE integration feeds discovery, and `CloudAppEvents` appears.
**Fail:** No discovery data — see Troubleshooting *MDCA no discovery data*.

## Test 5 — Cross-pillar correlation
**Procedure:** Run `DEFXDR-Hunt.ps1` to execute `XDR Cross-Pillar Correlation Check – Tenant – Validate`. Confirm all four tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) return recent rows. Then, in **Incidents**, confirm alerts from more than one pillar have grouped into a single incident (use a Microsoft attack-simulation or safe test alert per pillar where available).
**Pass:** All four pillar tables stream, and multi-pillar alerts correlate into one incident.
**Fail:** A table is empty or alerts stay separate — see Troubleshooting *No cross-pillar correlation*.

## Test 6 — Unified RBAC
**Procedure:** Run `DEFXDR-Validate.ps1 -Pillar RBAC`. Sign in (or use a test account) with `XDR Security Reader – Tenant – Prod` and confirm read-only access across pillars; confirm `XDR Security Operator – Tenant – Prod` has response permissions.
**Pass:** One unified role model governs all pillars; reader cannot take response actions, operator can.
**Fail:** Access is inconsistent or still per-pillar — see Troubleshooting *Unified RBAC not effective*.

## Test 7 — Automated response is approval-gated
**Procedure:** Run `DEFXDR-Report.ps1` and confirm the pilot device group's **automation level** is **Semi — require approval** (not full automation).
**Pass:** AIR is approval-gated; no action auto-executes on the pilot without approval.
**Fail:** Automation is set higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

## Test 8 — Secure Score baseline captured
**Procedure:** Run `DEFXDR-Report.ps1 -SaveBaseline`. Confirm a Secure Score value and top recommendations are recorded to the baseline file.
**Pass:** A Secure Score baseline exists to trend against.
**Fail:** No score returned — allow time after onboarding, then re-run; see Troubleshooting *Secure Score empty*.

---
### Exit gate
All eight tests pass on the pilot ring **before** any tenant-wide expansion (Implementation Step 9). Re-run Tests 1–5 and 8 after each expansion wave and compare against the saved baseline.
