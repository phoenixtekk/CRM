# 6. Troubleshooting Guide — Technical Blocker Mitigation: Defender for Endpoint

The four blocker classes in **symptom → cause → fix** form, plus escalation. Run `TBMMDE-Discovery.ps1` and `TBMMDE-Connectivity.ps1` first — most causes surface there. This *is* the troubleshooting solution, so this guide is the core reference.

## Device not onboarding
**Symptom:** A device in `MDE Blocker Triage – Affected Ring – Diagnose` stays **"Can be onboarded"** in **Assets → Devices** and never becomes managed.
**Cause:** The onboarding configuration never reached or applied on the device — the EDR onboarding policy is unassigned, the Intune connector is off (so no package is generated), or the GPO/script channel did not run.
**Fix:** Confirm the channel (Requirements 2.2). Intune: set **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**, confirm the EDR policy uses **Auto from connector** and is assigned to the affected subset, then force an Intune sync. GPO/script: re-apply the current onboarding package from **Settings → Endpoints → Onboarding** and confirm the onboarding task/service ran. Re-run `TBMMDE-Validate.ps1`.

## Sensor Inactive / Impaired communication
**Symptom:** A device shows **Onboarded** but sensor health is **Inactive**, **Impaired communication**, or **No sensor data**.
**Cause:** The onboarded sensor cannot reach the Defender service endpoints — a proxy/firewall block is the most common root cause; less often an out-of-date agent or a stopped service.
**Fix:** Run `TBMMDE-Connectivity.ps1` on a sample device; allow any blocked Defender endpoints at the proxy/firewall (per `global-requirements-defender.md` G5 — *verify the current endpoint list*). If connectivity is clean, run the Microsoft Defender **client analyzer** on the device to confirm agent version/health and reconnect. Re-run `TBMMDE-Validate.ps1` and confirm **Active**.

## No telemetry after onboarding
**Symptom:** A device is Onboarded and Active, but no rows appear in `DeviceInfo` / `DeviceEvents` and it is absent from Secure Score.
**Cause:** Warm-up not complete, the device is scoped out by a device group, or advanced hunting is not enabled for the tenant.
**Fix:** Allow warm-up time (tables populate over hours). Confirm the device is not excluded by a device-group scope. Confirm advanced hunting is available. Run `TBMMDE-Validate.ps1`, which executes `MDE Onboarding Blocker Check – Tenant – Diagnose` to count recent rows; re-check after warm-up.

## MDE–Intune connector broken
**Symptom:** Devices will not onboard via Intune; `TBMMDE-Discovery.ps1` reports the connector as **disabled/expired**, or onboarding packages are stale.
**Cause:** The Defender for Endpoint ↔ Intune connection lapsed (token expiry, first-time link never completed, or it was toggled off).
**Fix:** `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint** → re-establish the connection so **Connection status: Enabled**; confirm the app-level connection in `security.microsoft.com` → **Settings → Endpoints → Advanced features → Microsoft Intune connection** is on. Re-assign the EDR policy to the affected subset and force a sync. Re-run `TBMMDE-Discovery.ps1`.

## Licensing / activation blocker
**Symptom:** Onboarding options are missing, or the service is not activated in the portal.
**Cause:** No Defender for Endpoint plan assigned, or first-service activation was never completed.
**Fix:** Assign the plan (Admin center → **Billing → Licenses**), then complete activation in **Settings → Endpoints → Onboarding**. *Verify the exact plan the feature needs — availability changes; confirm in your tenant.* Re-run `TBMMDE-Discovery.ps1`.

## Script cannot authenticate
**Symptom:** `TBMMDE-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the read scopes was not granted, or the account lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** (or higher). Re-run.

## When to escalate to Microsoft support
Escalate — and attach `MDE Support Bundle – <case> – Escalate` — when **all** of the following hold:
- Discovery shows the plan assigned, service activated, connector Enabled, and policy assigned.
- Connectivity to the documented endpoints is clean from the affected device.
- The correct documented fix was applied and warm-up time elapsed, yet the device still will not onboard or stays Inactive.
In that case the root cause is likely a **service-side issue**, not your configuration. Run `TBMMDE-SupportBundle.ps1`, run the on-device **client analyzer**, open the case, and attach both. *Incident-response decisions remain the SOC's; this is a service-support escalation.*
