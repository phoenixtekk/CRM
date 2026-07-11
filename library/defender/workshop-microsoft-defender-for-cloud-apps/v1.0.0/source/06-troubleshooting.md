# 6. Troubleshooting — Workshop: Microsoft Defender for Cloud Apps

Symptom → cause → fix for the common issues when running the workshop and its lab helpers. For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## Cloud apps section missing or blades won't open
- **Symptom:** The **Cloud apps** area is absent in the Defender portal, or its blades error.
- **Cause:** MDA is not licensed/active, or the account lacks the role.
- **Fix:** Confirm the MDA plan (Admin center → Billing → Licenses; often bundled in E5 Security — *verify current availability*) and that the account holds an MDA admin / Security Reader role (R1, R7).

## Cloud Discovery shows no apps (Lab 1)
- **Symptom:** The Cloud Discovery dashboard is empty; no discovered apps to rank.
- **Cause:** No discovery data source — the Defender for Endpoint integration is off and no traffic log was uploaded.
- **Fix:** Turn on the **Defender for Endpoint → MDA** integration (fastest continuous feed) or upload a sample traffic log to create a **snapshot report** for the lab (R2). *Verify current integration steps.*

## No connected apps / connector shows no activity (Lab 2)
- **Symptom:** **Connected apps** is empty, or the connector shows no recent activity.
- **Cause:** No API connector added, or the connector just added (data lag).
- **Fix:** Connect the **Microsoft 365** connector at minimum (native, quick) and allow time for activity to populate (R3). Additional SaaS connectors are covered by the Cloud App DLP solution.

## App governance unavailable (Labs 2/3)
- **Symptom:** **App governance** is greyed out or shows no data.
- **Cause:** App governance not enabled, or the plan does not include it.
- **Fix:** Enable app governance in MDA settings (*plan/availability — verify current in your tenant*). If it cannot be enabled, run Lab 3 from the **OAuth apps** inventory (Enterprise applications / MDA OAuth apps) read-only instead (R4).

## `CloudAppEvents` returns nothing (Labs 2/5)
- **Symptom:** `CloudAppEvents | take 5` returns no rows.
- **Cause:** No connected apps feeding the table, warm-up lag, or missing hunting permission.
- **Fix:** Confirm a connector exists and has activity (R3); allow warm-up; confirm the attendee role includes advanced-hunting read (R5).

## `Connect-MgGraph` fails or scopes not granted
- **Symptom:** Lab scripts error on connect, or `WSMCA-Validate.ps1` shows fewer scopes than requested.
- **Cause:** Read scopes not consented, or the account cannot consent.
- **Fix:** Have a Global Administrator consent the read scopes once (`SecurityAlert.Read.All`, `Application.Read.All`, `Directory.Read.All`), or register a read-only workshop app. Never grant write/consent-management scopes for the labs (R6).

## `WSMCA-OAuthApp-Lab.ps1` lists apps but no permission grants
- **Symptom:** RiskHint is based only on publisher verification; `HighPrivScopes` is blank.
- **Cause:** `Get-MgServicePrincipalOauth2PermissionGrant` needs `Directory.Read.All` and returns delegated grants only; some app-role (application) permissions are not shown by this call.
- **Fix:** Confirm `Directory.Read.All` consent. Cross-check high-privilege **application** permissions in **Entra → Enterprise applications → Permissions**. Treat the RiskHint as a starting sort, not a verdict.

## Session policy has no effect / can't be created (Lab 4)
- **Symptom:** The session policy option is missing, or a created policy does nothing.
- **Cause:** Conditional Access App Control is not set up — session control requires the Entra Conditional Access integration and the app routed through it.
- **Fix:** Confirm the CA App Control integration and that the pilot app is routed through it (*verify current setup*). Keep the policy **Monitor only** for the workshop; enforcement is staged later. See the Conditional Access solution.

## Anomaly-detection alerts absent (Lab 5)
- **Symptom:** No Defender-for-Cloud-Apps anomaly alerts to triage.
- **Cause:** A quiet tenant, insufficient baseline (anomaly detection learns normal behavior over time), or alerts outside the window.
- **Fix:** A quiet tenant is fine for teaching — use the runbook descriptions and the `CloudAppEvents` queries to build the investigation skill. Allow the anomaly engine a learning window. Widen the time range.

## Portal menu paths don't match
- **Symptom:** A navigation path in the runbook doesn't exist.
- **Cause:** MDA settings are consolidating from the classic portal into `security.microsoft.com`; menus move.
- **Fix:** Use global search for the feature name (e.g. "Cloud Discovery", "OAuth apps", "App governance"). *Verify current navigation in your tenant* and update your copy of the runbook.
