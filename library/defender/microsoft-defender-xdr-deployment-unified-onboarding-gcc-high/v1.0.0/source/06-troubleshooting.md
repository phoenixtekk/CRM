# 6. Troubleshooting Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Common field issues, in **symptom → cause → fix** form. Run `DEFXDRG-Discovery.ps1` and `DEFXDRG-Validate.ps1` first — most causes surface there.

## Device not onboarding (MDE)
**Symptom:** A pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal.
**Cause:** The Intune EDR profile `MDE Onboarding – Pilot Ring – Pilot` is not assigned to the device, the MDE-Intune connector is off, or the device cannot reach the Defender service endpoints.
**Fix:** Confirm the device is in `MDE Onboarding – Pilot Ring – Pilot`; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled** in Intune; verify outbound HTTPS to the Defender endpoint URLs (per `global-requirements-defender.md` G5). Force an Intune sync and re-run `DEFXDRG-Validate.ps1 -Pillar Endpoint`.

## MDI sensor unhealthy
**Symptom:** The domain-controller sensor shows **Unhealthy** or **Not configured** in **Settings → Identities → Sensors**.
**Cause:** Missing/mis-scoped Directory Service Account, blocked outbound reach to the MDI service, insufficient DC resources, or an unsupported sensor OS.
**Fix:** Verify the DSA (gMSA) under **Directory Service accounts**; confirm the DC can reach the MDI service URLs; confirm DC resources and a supported OS version (*verify current sensor OS support*). Reinstall the sensor with a fresh access key if needed, then re-run `DEFXDRG-Validate.ps1 -Pillar Identity`.

## MDO no email signal
**Symptom:** Test 3 fails — no `EmailEvents` rows or Safe Links not rewriting for pilot users.
**Cause:** The preset security policy is not scoped to `XDR Pilot Users – Pilot Ring – Pilot`, mail is not routing through Exchange Online, or the MDO plan is not licensed.
**Fix:** Confirm the preset policy scope includes the pilot users; confirm Exchange Online is the mail path; verify the MDO P1/P2 plan (*verify current plan features*). Allow time for signal, then re-run `DEFXDRG-Validate.ps1 -Pillar Office365`.

## MDCA no discovery data
**Symptom:** **Cloud discovery → Dashboard** is empty; `CloudAppEvents` returns nothing.
**Cause:** The Defender for Endpoint → Cloud Apps discovery integration is off, or pilot devices are not yet onboarded to MDE.
**Fix:** Turn on the MDE integration under **Cloud apps → Cloud discovery → Settings**; confirm pilot devices are onboarded (Test 1 must pass first); add app connectors in monitor mode. Re-run `DEFXDRG-Validate.ps1 -Pillar CloudApps`.

## No cross-pillar correlation
**Symptom:** Test 5 fails — a hunting table is empty, or alerts from different pillars stay as separate incidents.
**Cause:** One pillar is not fully onboarded/streaming yet, or not enough time has passed for tables and correlation to populate.
**Fix:** Run `DEFXDRG-Hunt.ps1` to see exactly which table is empty and fix that pillar's onboarding first; allow warm-up time (tables populate over hours). Correlation only groups alerts that share entities — confirm the test alerts share a device/user/mailbox. **In GCC High/DoD, first confirm the pillar and its advanced-hunting table are even available in your cloud** — a persistently empty table can mean the feature/connector lags or is unavailable, not that onboarding failed (*verify against current Microsoft Government documentation*). Re-run once each pillar streams.

## Unified RBAC not effective
**Symptom:** Analysts still see inconsistent access, or the unified role assignments don't take effect.
**Cause:** Unified RBAC is not activated for the tenant, legacy per-pillar permissions still override, or the role assignment scope/data-source is wrong.
**Fix:** Confirm unified RBAC activation under **System → Permissions and roles** (*verify current activation steps*); confirm `XDR Security Reader – Tenant – Prod` / `XDR Security Operator – Tenant – Prod` grant the right data sources; allow propagation time and re-test with a pilot account. Re-run `DEFXDRG-Validate.ps1 -Pillar RBAC`.

## Automated response acted without approval
**Symptom:** A device was isolated or a user disabled automatically during the pilot.
**Cause:** The device group's AIR **automation level** is set higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval** (Implementation Step 7), confirm with the SOC, and record the level with `DEFXDRG-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Secure Score empty
**Symptom:** `DEFXDRG-Report.ps1 -SaveBaseline` returns no Secure Score.
**Cause:** Onboarding is too recent for Secure Score to compute, or the account lacks read permission to the score.
**Fix:** Allow time after onboarding; confirm the running account has at least Security Reader; re-run the report. If still empty, verify pillar activation in the portal.

## Script cannot authenticate
**Symptom:** `DEFXDRG-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph / Az modules are missing, consent to the required read scopes was not granted, the account lacks Security Reader, or the script connected to the **wrong national cloud** (e.g. commercial `graph.microsoft.com` from a GCC High tenant).
**Fix:** Let the script install the modules (it checks on run); sign in to the **US Gov cloud** with `Connect-MgGraph -Environment USGov` (GCC High; **DoD:** `-Environment USGovDoD`) and `Connect-AzAccount -Environment AzureUSGovernment`, and consent to the read-only scopes; confirm Security Reader (or higher). The scripts default to the US Gov cloud. *Verify the correct national-cloud endpoints for your cloud against current Microsoft Government documentation.* Re-run the script.
