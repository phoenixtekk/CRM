# 6. Troubleshooting Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Common field issues, in **symptom → cause → fix** form. Run `MDEONB-Discovery.ps1` and `MDEONB-Validate.ps1` first — most causes surface there.

## Device not onboarding
**Symptom:** Test 1 fails — a pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal.
**Cause:** The onboarding profile is not assigned, the Intune MDE connector is off, the device cannot reach the Defender service endpoints, or the platform channel (macOS profile / Linux package) did not complete.
**Fix:** Confirm the device is in `MDE Device Group – Pilot Ring – Pilot` and `MDE Onboarding – Pilot Ring – Pilot` is assigned; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**; verify outbound HTTPS to the Defender endpoints (per `global-requirements-defender.md` G5); for macOS/Linux confirm the MDM profile/package installed. Force a sync and re-run `MDEONB-Validate.ps1 -Check Onboarding`.

## EDR/AV not applied
**Symptom:** Test 2 fails — **EDR in block mode** is off or `MDE Next-Gen AV – Pilot Ring – Prod` is not applied.
**Cause:** Block mode not enabled in Advanced features, the AV policy is not assigned to the ring, or a third-party AV is conflicting.
**Fix:** Enable **Settings → Endpoints → Advanced features → EDR in block mode**; confirm the AV policy is assigned to `MDE Device Group – Pilot Ring – Pilot`; confirm the AV posture (Defender primary or passive behind third-party). Re-run `MDEONB-Validate.ps1 -Check EDR`.

## ASR breaking a business app
**Symptom:** After moving to block, a line-of-business app fails.
**Cause:** An ASR rule in `MDE ASR Rules – Pilot Ring – Block` blocks a legitimate behavior with no exclusion.
**Fix:** Identify the rule from the block event (`MDEONB-Report.ps1 -Section ASR` / `DeviceEvents`), revert that rule to **audit**, add a scoped exclusion, validate in audit, then re-promote. This is exactly why ASR goes **audit → block** first (Implementation Step 4).

## No device telemetry
**Symptom:** Test 6 fails — `DeviceInfo`, `DeviceEvents`, or `DeviceTvmSoftwareVulnerabilities` return no rows.
**Cause:** Devices newly onboarded and still warming up, or a device is unhealthy/not reporting.
**Fix:** Confirm devices are onboarded and healthy (Test 1); allow warm-up (tables populate over hours); check device health in **Assets → Devices**. Re-run `MDEONB-Hunt.ps1`.

## Detection does not fire
**Symptom:** Test 7 fails — the safe EDR detection test produces no alert.
**Cause:** The device is not fully onboarded, block mode/AV is off, or not enough time has passed for the alert.
**Fix:** Confirm onboarding (Test 1) and AV/block mode (Test 2); run the Microsoft-documented EDR test exactly; allow the alert to surface in **Incidents & alerts**. Re-check with `MDEONB-Hunt.ps1`.

## Web content filtering not enforcing
**Symptom:** Test 4 fails — categories in `MDE Web Content Filtering – Tenant – Prod` are not blocked.
**Cause:** Web content filtering requires **P2** and network protection in block mode; the plan or dependency is missing.
**Fix:** *Verify P2 availability in your tenant*; confirm network protection is enabled (web content filtering depends on it); allow policy propagation. Re-run `MDEONB-Validate.ps1 -Check Config`.

## RBAC / device group not effective
**Symptom:** Test 5 fails — analysts have inconsistent access or the automation level is wrong.
**Cause:** Roles not assigned, device group scope wrong, or RBAC not yet propagated.
**Fix:** Confirm `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` assignments and the `MDE Device Group – Pilot Ring – Pilot` scope/automation level under **Settings → Endpoints → Permissions**; allow propagation and re-test. Re-run `MDEONB-Validate.ps1 -Check RBAC`.

## Automated response acted without approval
**Symptom:** A pilot device was isolated or a file remediated automatically.
**Cause:** The device group's AIR **automation level** is higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval** (Implementation Step 7), confirm with the SOC, and record it with `MDEONB-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDEONB-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, or the account lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security Reader (or higher). Re-run the script.
