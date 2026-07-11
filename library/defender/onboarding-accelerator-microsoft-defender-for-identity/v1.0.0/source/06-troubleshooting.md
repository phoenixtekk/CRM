# 6. Troubleshooting Guide — Onboarding Accelerator: Microsoft Defender for Identity

Common field issues, in **symptom → cause → fix** form. Run `MDIONB-Discovery.ps1` and `MDIONB-Validate.ps1` first — most causes surface there.

## DSA not working
**Symptom:** Test 1 fails — `MDI Directory Service Account – Tenant – Prod` is missing, or the sensor cannot use it and enrichment detections are limited.
**Cause:** The gMSA is not registered under **Directory Service accounts**, the sensor host computer accounts lack permission to retrieve the gMSA password, or a standard account's password is wrong.
**Fix:** Confirm the DSA is registered under **Settings → Identities → Directory Service accounts**; grant the sensor hosts permission to retrieve the gMSA password; re-enter credentials for a standard account. *Verify current MDI DSA requirements.* Re-run `MDIONB-Validate.ps1 -Check DSA`.

## Sensor unhealthy
**Symptom:** `MDI Sensor Host – Pilot DC – Pilot` shows **Unhealthy / Not configured / Stopped** in **Settings → Identities → Sensors**.
**Cause:** Blocked outbound reach to the MDI service, insufficient DC resources, an unsupported sensor OS, a wrong/expired access key, or a proxy in the way.
**Fix:** Confirm the DC can reach the MDI service URLs (per `global-requirements-defender.md` G5); confirm DC resources and a supported OS version (*verify current sensor OS support*); reinstall with a fresh access key from **Add sensor** if needed; configure the sensor proxy if one is required. Re-run `MDIONB-Validate.ps1 -Check Sensor`.

## No identity signal
**Symptom:** Test 5 fails — one or more of `IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents` return no rows.
**Cause:** The sensor is unhealthy or too newly installed, or not enough traffic has passed the DC yet for tables to populate.
**Fix:** Confirm the pilot sensor is healthy first (Test 2). Allow warm-up time — identity tables populate over hours. Generate benign authentication traffic through the DC and re-run `MDIONB-Hunt.ps1`.

## Detection does not fire
**Symptom:** Test 6 fails — the controlled honeytoken touch or safe simulation produces no alert.
**Cause:** The honeytoken is not actually tagged, the sensor is unhealthy, the test did not reach a sensored DC, or not enough time has passed for the alert.
**Fix:** Confirm the honeytoken is tagged (Test 4) and the sensor healthy (Test 2); ensure the authentication/query targets a DC that has a sensor; allow time for the alert to surface in **Incidents & alerts**. Re-test with `MDIONB-Hunt.ps1` to confirm the query event is recorded.

## No ISPM recommendations
**Symptom:** Test 7 fails — no MDI Identity recommendations appear in **Secure Score → Recommended actions**.
**Cause:** Sensors are too newly onboarded for ISPM to compute, sensor coverage is too thin, or ISPM is not yet available in the tenant.
**Fix:** Confirm sensor health (Test 2) and allow warm-up; expand sensor coverage so more DCs report; *verify current ISPM availability in your tenant.* Re-run `MDIONB-Report.ps1 -SaveBaseline`.

## Honeytoken generating noise
**Symptom:** The honeytoken account fires alerts from legitimate activity.
**Cause:** A real process (logon script, service, scheduled task, or a person) is using the decoy account, so it is no longer idle.
**Fix:** Identify and remove the legitimate use (`MDIONB-Hunt.ps1` shows what touched it), or retire the account and create a genuinely idle replacement named `MDI Honeytoken – Decoy Identity – Pilot`. Re-tag and re-validate (Test 4).

## Response action acted without approval
**Symptom:** A user was disabled or a password reset forced automatically during the pilot.
**Cause:** A response action was configured for automatic execution rather than approval-gated.
**Fix:** Reset the action to approval-gated (Implementation Step 7), confirm with the SOC, and record the configuration with `MDIONB-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDIONB-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, the account lacks Security Reader, or the AD read helpers are run off a machine without the AD module.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security Reader (or higher); run the AD-inventory portion from a domain-joined host with `RSAT-AD-PowerShell`. Re-run the script.
