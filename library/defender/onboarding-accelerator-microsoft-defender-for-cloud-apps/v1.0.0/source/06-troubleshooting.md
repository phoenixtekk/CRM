# 6. Troubleshooting Guide — Onboarding Accelerator: Microsoft Defender for Cloud Apps

Common field issues, in **symptom → cause → fix** form. Run `MCAONB-Discovery.ps1` and `MCAONB-Validate.ps1` first — most causes surface there.

## Connector not connecting
**Symptom:** Test 1 fails — a connector in `MDCA App Connectors – Priority SaaS – Prod` shows an error or "Disconnected."
**Cause:** The app's admin consent/API credential was not completed or has expired, the connecting account lacks admin rights in that app, or the app's API access is restricted.
**Fix:** Re-run the connector's consent flow with an admin of that app; confirm the API credential/token is valid; check the app's own API access settings. Remove and re-add the connector if needed, then re-run `MCAONB-Validate.ps1 -Check Connectors`.

## No discovery data
**Symptom:** Test 2 fails — **Cloud discovery → Dashboard** is empty.
**Cause:** No discovery source is configured, the Defender for Endpoint integration is off, pilot devices are not MDE-onboarded, or the log collector is not receiving logs.
**Fix:** Confirm a source under **Cloud discovery → Settings**; turn on the **Defender for Endpoint → Cloud Apps** integration and confirm devices are MDE-onboarded (see the MDE onboarding accelerator); verify the log collector is receiving SWG logs. Allow warm-up, then re-run `MCAONB-Validate.ps1 -Check Discovery`.

## App governance not inventorying
**Symptom:** Test 3 fails — **App governance** shows no OAuth app inventory, or the report policy is absent.
**Cause:** App governance is not enabled, the plan does not include it, or it has not finished the initial inventory.
**Fix:** Enable app governance under **Cloud apps → App governance**; *verify the plan includes app governance in your tenant*; allow the initial inventory to complete, then create `MDCA OAuth App Risk – Tenant – Report`. Re-run `MCAONB-Report.ps1 -Section OAuth`.

## App Control not proxying
**Symptom:** Test 5 fails — a pilot user's session is not routed through MDCA (no session banner/suffix).
**Cause:** The Conditional Access policy `MDCA Session Control – Pilot Users – Report` is not enabled/assigned to the pilot users, the app is not supported by App Control, or the session-control session setting is not applied.
**Fix:** Confirm the CA policy is **On** and assigned to `MDCA Pilot Users – Pilot Ring – Pilot`; confirm the app is supported by Conditional Access App Control (*verify current supported apps*); confirm **Session → Use Conditional Access App Control** is set. Have the user sign out/in and re-test.

## No cloud-app signal
**Symptom:** Test 6 fails — `CloudAppEvents` returns no rows.
**Cause:** Connectors are newly added and still warming up, or discovery has no source, so no activity is streaming yet.
**Fix:** Confirm connectors are connected (Test 1) and discovery is flowing (Test 2); allow warm-up (tables populate over hours); re-run `MCAONB-Hunt.ps1`.

## Policy too noisy / false positives
**Symptom:** A monitor policy generates excessive or irrelevant alerts on the pilot.
**Cause:** The policy scope or thresholds are too broad, or a legitimate business workflow matches the pattern.
**Fix:** Tighten the policy scope to `MDCA Pilot Users – Pilot Ring – Pilot`, adjust thresholds/filters, and add exclusions for known-good workflows. Keep it report-only until the noise is acceptable, then enforce.

## Policy enforced or app revoked unexpectedly
**Symptom:** A pilot user was blocked, or an OAuth app was revoked, during the pilot.
**Cause:** A policy was created in enforce mode, or an app-governance policy had auto-revoke enabled, before validation.
**Fix:** Reset the policy to **report-only** (Implementation Step 5) and disable auto-revoke; confirm with the security team; re-validate before enforcing. *Enforcement/revocation decisions are the security team's.*

## Script cannot authenticate
**Symptom:** `MCAONB-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, or the account lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security Reader (or higher). Re-run the script.
