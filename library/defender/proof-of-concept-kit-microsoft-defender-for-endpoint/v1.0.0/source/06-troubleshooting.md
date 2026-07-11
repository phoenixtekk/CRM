# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Endpoint

Common field issues, in **symptom → cause → fix** form. Run `POCMDE-Enable.ps1 -WhatIf` and `POCMDE-Validate.ps1` first — most causes surface there. All test signal is benign (EICAR / built-in simulation).

## Pilot device not onboarding
**Symptom:** A device in `MDE PoC – Pilot Ring – Pilot` stays "Can be onboarded" in **Assets → Devices**.
**Cause:** The Intune EDR policy `MDE PoC EDR Onboarding – Pilot Ring – Pilot` is not assigned, the MDE-Intune connector is off, or the device cannot reach the Defender service endpoints.
**Fix:** Confirm the device is in the pilot group; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**; verify outbound HTTPS to the Defender endpoint URLs (per `global-requirements-defender.md` G5). Force an Intune sync and re-run `POCMDE-Enable.ps1 -WhatIf`.

## EICAR not detected
**Symptom:** The EICAR test file is written but Microsoft Defender Antivirus does not detect/quarantine it.
**Cause:** Real-time protection is off, third-party AV is primary, tamper/exclusions suppress it, or the file was altered.
**Fix:** Confirm Microsoft Defender Antivirus real-time and cloud-delivered protection are on for the pilot device; remove any test-path exclusion; ensure the EICAR string is exact and unmodified. Re-run `POCMDE-TestSignal.ps1`.

## No alert from test signal
**Symptom:** Test 3 fails — no alert appears in **Incidents & alerts** for the pilot device.
**Cause:** The device is not fully onboarded, signal has not propagated yet, or the simulation targeted the wrong device.
**Fix:** Confirm Test 1 passed; allow propagation time (minutes); confirm the simulation/EICAR ran on an onboarded pilot device. Re-run `POCMDE-Validate.ps1`.

## Timeline empty
**Symptom:** The device **Timeline** shows no test activity.
**Cause:** Onboarding is too recent, or the device stopped reporting.
**Fix:** Allow warm-up time; confirm the device is **Onboarded** and healthy in **Assets → Devices**; generate the benign signal again and re-check.

## Hunting tables empty
**Symptom:** `POCMDE-Validate.ps1` returns no rows from `DeviceEvents` / `AlertInfo` / `AlertEvidence`.
**Cause:** Advanced-hunting tables populate over time, or the account lacks hunting read scope.
**Fix:** Allow warm-up (tables populate over minutes to hours); confirm `ThreatHunting.Read.All` consent and **Security Reader**; re-run the validate script.

## AIR did not start
**Symptom:** Test 6 fails — no automated investigation for the test incident.
**Cause:** Automated Investigation is off, the device is not in an automation-enabled group, or the alert type did not trigger AIR.
**Fix:** Confirm **Settings → Endpoints → Advanced features → Automated Investigation** is on and the pilot group's level is **Semi — require approval**; some benign simulations trigger AIR, some do not — use a built-in EDR simulation known to raise an EDR alert. Re-run `POCMDE-Validate.ps1`.

## Automated response acted unattended
**Symptom:** A pilot device was isolated or a file quarantined automatically during the PoC.
**Cause:** The pilot group's AIR **automation level** is higher than **Semi — require approval**.
**Fix:** Reset to **Semi — require approval** (Implementation Step 2), confirm with the SOC. *The automation-guardrail decision is the security team's.*

## Script cannot authenticate
**Symptom:** `POCMDE-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, read scopes were not consented, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** (or Security Administrator for enable/teardown). Re-run.

## Teardown left residue
**Symptom:** After `POCMDE-Teardown.ps1`, a device still shows onboarded or the Intune policy remains.
**Cause:** Offboarding is asynchronous, or the teardown ran in `-WhatIf` only.
**Fix:** Run teardown **without** `-WhatIf` to apply; offboarding can take time to reflect in **Assets → Devices** — allow it, then confirm with `POCMDE-Validate.ps1`. Remove the Intune policy and pilot group manually if any remain.
