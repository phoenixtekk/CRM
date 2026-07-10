# 6. Troubleshooting Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Common field issues, in **symptom → cause → fix** form. Run `DEFXDR-Discovery.ps1` and `DEFXDR-Validate.ps1` first — most causes surface there.

## Device not onboarding (MDE)
**Symptom:** A pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal.
**Cause:** The Intune EDR profile `MDE Onboarding – Pilot Ring – Pilot` is not assigned to the device, the MDE-Intune connector is off, or the device cannot reach the Defender service endpoints.
**Fix:** Confirm the device is in `MDE Onboarding – Pilot Ring – Pilot`; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled** in Intune; verify outbound HTTPS to the Defender endpoint URLs (per `global-requirements-defender.md` G5). Force an Intune sync and re-run `DEFXDR-Validate.ps1 -Pillar Endpoint`.

## MDI sensor unhealthy
**Symptom:** The domain-controller sensor shows **Unhealthy** or **Not configured** in **Settings → Identities → Sensors**.
**Cause:** Missing/mis-scoped Directory Service Account, blocked outbound reach to the MDI service, insufficient DC resources, or an unsupported sensor OS.
**Fix:** Verify the DSA (gMSA) under **Directory Service accounts**; confirm the DC can reach the MDI service URLs; confirm DC resources and a supported OS version (*verify current sensor OS support*). Reinstall the sensor with a fresh access key if needed, then re-run `DEFXDR-Validate.ps1 -Pillar Identity`.

## MDO no email signal
**Symptom:** Test 3 fails — no `EmailEvents` rows or Safe Links not rewriting for pilot users.
**Cause:** The preset security policy is not scoped to `XDR Pilot Users – Pilot Ring – Pilot`, mail is not routing through Exchange Online, or the MDO plan is not licensed.
**Fix:** Confirm the preset policy scope includes the pilot users; confirm Exchange Online is the mail path; verify the MDO P1/P2 plan (*verify current plan features*). Allow time for signal, then re-run `DEFXDR-Validate.ps1 -Pillar Office365`.

## MDCA no discovery data
**Symptom:** **Cloud discovery → Dashboard** is empty; `CloudAppEvents` returns nothing.
**Cause:** The Defender for Endpoint → Cloud Apps discovery integration is off, or pilot devices are not yet onboarded to MDE.
**Fix:** Turn on the MDE integration under **Cloud apps → Cloud discovery → Settings**; confirm pilot devices are onboarded (Test 1 must pass first); add app connectors in monitor mode. Re-run `DEFXDR-Validate.ps1 -Pillar CloudApps`.

## No cross-pillar correlation
**Symptom:** Test 5 fails — a hunting table is empty, or alerts from different pillars stay as separate incidents.
**Cause:** One pillar is not fully onboarded/streaming yet, or not enough time has passed for tables and correlation to populate.
**Fix:** Run `DEFXDR-Hunt.ps1` to see exactly which table is empty and fix that pillar's onboarding first; allow warm-up time (tables populate over hours). Correlation only groups alerts that share entities — confirm the test alerts share a device/user/mailbox. Re-run once each pillar streams.

## Unified RBAC not effective
**Symptom:** Analysts still see inconsistent access, or the unified role assignments don't take effect.
**Cause:** Unified RBAC is not activated for the tenant, legacy per-pillar permissions still override, or the role assignment scope/data-source is wrong.
**Fix:** Confirm unified RBAC activation under **System → Permissions and roles** (*verify current activation steps*); confirm `XDR Security Reader – Tenant – Prod` / `XDR Security Operator – Tenant – Prod` grant the right data sources; allow propagation time and re-test with a pilot account. Re-run `DEFXDR-Validate.ps1 -Pillar RBAC`.

## Automated response acted without approval
**Symptom:** A device was isolated or a user disabled automatically during the pilot.
**Cause:** The device group's AIR **automation level** is set higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval** (Implementation Step 7), confirm with the SOC, and record the level with `DEFXDR-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Secure Score empty
**Symptom:** `DEFXDR-Report.ps1 -SaveBaseline` returns no Secure Score.
**Cause:** Onboarding is too recent for Secure Score to compute, or the account lacks read permission to the score.
**Fix:** Allow time after onboarding; confirm the running account has at least Security Reader; re-run the report. If still empty, verify pillar activation in the portal.

## Script cannot authenticate
**Symptom:** `DEFXDR-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph / Az modules are missing, consent to the required read scopes was not granted, or the account lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` / `Connect-AzAccount` and consent to the read-only scopes; confirm Security Reader (or higher). Re-run the script.
