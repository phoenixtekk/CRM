# 6. Troubleshooting Guide — Microsoft Defender for Cloud Apps

Common field issues across all three phases, in **symptom → cause → fix** form. Run `MDCAFULL-Discovery.ps1` and `MDCAFULL-Validate.ps1` first — most causes surface there. For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## Cloud apps section missing or blades won't open
**Symptom:** The **Cloud apps** area is absent in the Defender portal, or its blades error.
**Cause:** MDCA is not licensed/active, or the account lacks the role.
**Fix:** Confirm the MDCA plan (Admin center → Billing → Licenses; often bundled in E5 Security — *verify current availability*) and that the account holds an MDCA admin / Security Reader role (Requirements 2.1, 2.9). Complete the one-time activation if needed.

## Connector not connecting
**Symptom:** Test A1 fails — a connector in `MDCA App Connectors – Priority SaaS – Prod` shows an error or "Disconnected."
**Cause:** The app's admin consent/API credential was not completed or has expired, the connecting account lacks admin rights in that app, or the app's API access is restricted.
**Fix:** Re-run the connector's consent flow with an admin of that app; confirm the API credential/token is valid; check the app's own API access settings. Remove and re-add the connector if needed, then re-run `MDCAFULL-Validate.ps1 -Check Connectors`.

## No discovery data
**Symptom:** Test A2 (or Lab 1) fails — **Cloud discovery → Dashboard** is empty.
**Cause:** No discovery source is configured, the Defender for Endpoint integration is off, pilot devices are not MDE-onboarded, or the log collector is not receiving logs.
**Fix:** Confirm a source under **Cloud discovery → Settings**; turn on the **Defender for Endpoint → Cloud Apps** integration and confirm devices are MDE-onboarded (see the MDE onboarding accelerator); verify the log collector is receiving SWG logs; or upload a snapshot log for the labs/PoC. Allow warm-up, then re-run `MDCAFULL-Validate.ps1 -Check Discovery`.

## App governance not inventorying
**Symptom:** Test A3 (or Labs 2/3) fails — **App governance** shows no OAuth app inventory, or the report policy is absent.
**Cause:** App governance is not enabled, the plan does not include it, or it has not finished the initial inventory.
**Fix:** Enable app governance under **Cloud apps → App governance**; *verify the plan includes app governance in your tenant*; allow the initial inventory to complete, then create `MDCA OAuth App Risk – Tenant – Report`. If it cannot be enabled, run Lab 3 from the **OAuth apps** inventory read-only. Re-run `MDCAFULL-OAuthRisk.ps1`.

## App Control not proxying / session policy has no effect
**Symptom:** Test A5 (or Lab 4) fails — a pilot user's session is not routed through MDCA (no session banner/suffix), or a created session policy does nothing.
**Cause:** The Conditional Access policy `MDCA Session Control – Pilot Users – Report` is not enabled/assigned to the pilot users, the app is not supported by App Control, or the session-control setting is not applied.
**Fix:** Confirm the CA policy is **On** and assigned to `MDCA Pilot Users – Pilot Ring – Pilot`; confirm the app is supported by Conditional Access App Control (*verify current supported apps*); confirm **Session → Use Conditional Access App Control** is set. Keep the policy **Monitor only** during enablement. Have the user sign out/in and re-test.

## No cloud-app signal
**Symptom:** Test A6 (or Labs 2/5) fails — `CloudAppEvents` returns no rows.
**Cause:** Connectors are newly added and still warming up, discovery has no source, or the account lacks advanced-hunting read.
**Fix:** Confirm connectors are connected (A1) and discovery is flowing (A2); allow warm-up (tables populate over hours); confirm the attendee role includes advanced-hunting read (Requirement 2.7); re-run `MDCAFULL-Validate.ps1 -Check Signal`.

## `MDCAFULL-OAuthRisk.ps1` lists apps but no permission grants
**Symptom:** RiskHint is based only on publisher verification; `HighPrivScopes` is blank.
**Cause:** `Get-MgServicePrincipalOauth2PermissionGrant` needs `Directory.Read.All` and returns delegated grants only; some app-role (application) permissions are not shown by this call.
**Fix:** Confirm `Directory.Read.All` consent. Cross-check high-privilege **application** permissions in **Entra → Enterprise applications → Permissions**. Treat the RiskHint as a starting sort, not a verdict.

## Anomaly-detection alerts absent (Lab 5)
**Symptom:** No Defender-for-Cloud-Apps anomaly alerts to triage.
**Cause:** A quiet tenant, insufficient baseline (anomaly detection learns normal behavior over time), or alerts outside the window.
**Fix:** A quiet tenant is fine for teaching — use the runbook descriptions and the `CloudAppEvents` queries to build the investigation skill. Allow the anomaly engine a learning window; widen the time range.

## PoC policy scope or action wrong
**Symptom:** Test C1 fails — the audit policy applies to more than the pilot users, or it has a governance action.
**Cause:** The policy filter was not scoped to `MDCA Pilot Users – Pilot Ring – Pilot`, or a governance action was left set.
**Fix:** Edit `MDCA PoC Activity Policy – Pilot Users – Audit` — restrict the filter to the pilot group and set **Governance actions = none**. Re-run `MDCAFULL-PoC.ps1 -Action Enable -WhatIf`.

## PoC signal not generated / discovery report empty
**Symptom:** Test C2/C3 fails — the sample log did not upload, the benign activity did not register, or `MDCA PoC Discovery – Pilot – Report` shows no data.
**Cause:** The upload used the wrong format/source, the test account is not in the pilot group, or the snapshot report is still processing.
**Fix:** Use Microsoft's sample Cloud Discovery log with a matching data source in the snapshot report; confirm the test account is in `MDCA Pilot Users – Pilot Ring – Pilot`; allow processing time; re-run `MDCAFULL-PoC.ps1 -Action Signal`.

## PoC policy did not match / no alert surfaced
**Symptom:** Test C4 fails — the audit policy did not match the benign activity, or matched but no alert appears.
**Cause:** The activity did not meet the policy filter/threshold, the connector is not yet returning activity, signal has not propagated, or alerting is off.
**Fix:** Confirm the benign action matches the policy's trigger (threshold/activity type); confirm the connector is returning activity; confirm the policy raises an alert on match (alerting is independent of governance actions); allow warm-up and re-run `MDCAFULL-Validate.ps1 -Check PoC`.

## PoC teardown left residue
**Symptom:** After `MDCAFULL-PoC.ps1 -Action Teardown`, the policy, report, or connector remains.
**Cause:** Teardown ran in `-WhatIf` only, or an item must be removed in the portal.
**Fix:** Run teardown **without** `-WhatIf`; delete the policy, the discovery report `MDCA PoC Discovery – Pilot – Report`, and any PoC connector in `Cloud apps`; resolve the `MDCA-PoC-TESTSIGNAL` alerts; re-confirm with `MDCAFULL-Validate.ps1 -Check PoC`.

## Policy too noisy / false positives
**Symptom:** A monitor policy generates excessive or irrelevant alerts on the pilot.
**Cause:** The policy scope or thresholds are too broad, or a legitimate business workflow matches the pattern.
**Fix:** Tighten the policy scope to `MDCA Pilot Users – Pilot Ring – Pilot`, adjust thresholds/filters, and add exclusions for known-good workflows. Keep it report-only until the noise is acceptable, then enforce.

## Policy enforced or app revoked unexpectedly
**Symptom:** A pilot user was blocked, or an OAuth app was revoked, during the pilot.
**Cause:** A policy was created in enforce mode, or an app-governance policy had auto-revoke enabled, before validation.
**Fix:** Reset the policy to **report-only** (Implementation Step A5) and disable auto-revoke; confirm with the security team; re-validate before enforcing. *Enforcement/revocation decisions are the security team's.*

## Script cannot authenticate
**Symptom:** `MDCAFULL-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** (or Security Administrator for the PoC enable/teardown). Re-run the script.

## Portal menu paths don't match
**Symptom:** A navigation path in the guide doesn't exist.
**Cause:** MDCA settings are consolidating from the classic portal into `security.microsoft.com`; menus move.
**Fix:** Use global search for the feature name (e.g. "Cloud Discovery", "OAuth apps", "App governance"). *Verify current navigation in your tenant* and update your copy of the runbook.
