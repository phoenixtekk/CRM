# 6. Troubleshooting Guide — Technical Blocker Mitigation: Defender for Cloud Apps

The four blocker classes in **symptom → cause → fix** form, plus escalation. Run `TBMMCA-Discovery.ps1` and `TBMMCA-ConditionalAccess.ps1` first — most causes surface there. This *is* the troubleshooting solution, so this guide is the core reference.

## Connector authentication failure
**Symptom:** An app connector in `MDCA Blocker Triage – Affected Apps – Diagnose` shows **error / disconnected**; no `CloudAppEvents` activity for the app.
**Cause:** The connector's token expired, the app registration was revoked/changed, or the connector account lost the required permissions in the SaaS app.
**Fix:** In **Cloud apps → App connectors**, reconnect the connector — re-consent the app registration, refresh the token, and confirm the connector account still has the required permissions in the SaaS app. Confirm status returns to **connected**, then re-run `TBMMCA-Validate.ps1`.

## Cloud Discovery no-data
**Symptom:** **Cloud discovery → Dashboard** is empty; shadow-IT is invisible.
**Cause:** The discovery source is not feeding MDCA — the **Defender for Endpoint integration** is off (or devices are not onboarded to MDE), or the log collector / secure-web-gateway feed / manual upload is not arriving.
**Fix:** Confirm the intended source (Requirements 2.3). For device-based discovery, turn on the **MDE integration** under **Cloud discovery → Settings** and confirm devices are onboarded to MDE. For log-based discovery, repair the log collector / SWG feed or re-upload logs. Allow ingestion time, then re-check the dashboard.

## Session policy / CA App Control not engaging
**Symptom:** A session policy never fires; the target app session is not proxied; inline controls do nothing.
**Cause:** No enabled **Conditional Access App Control** policy applies to the session, the policy does not target the affected users/apps, or the app is not onboarded to session control.
**Fix:** Run `TBMMCA-ConditionalAccess.ps1`; confirm `Use Conditional Access App Control – Pilot Apps – Diagnose` is **enabled**, targets the affected users/apps, and its session control is **Use Conditional Access App Control**. In MDCA, confirm the app is **onboarded to session control**. Re-test with the pilot user's browser session and confirm a proxied session in the activity log.

## Licensing gap
**Symptom:** MDCA connector / session-control options are missing or greyed out.
**Cause:** The MDCA plan (or, for CA App Control, the required Entra plan) is not assigned.
**Fix:** Assign the plan(s) (**Billing → Licenses**). *Verify the exact plan requirements — availability changes; confirm in your tenant.* Re-run `TBMMCA-Discovery.ps1`.

## Script cannot authenticate
**Symptom:** `TBMMCA-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, `ThreatHunting.Read.All` / `Policy.Read.All` consent was not granted, or the account lacks Security/Global Reader.
**Fix:** Let the script install the modules; sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security/Global Reader. Re-run.

## When to escalate to Microsoft support
Escalate — and attach `MDCA Support Bundle – <case> – Escalate` — when **all** of the following hold:
- The MDCA (and Entra, for App Control) plan is assigned.
- The affected connector was re-consented with the required permissions.
- The Cloud Discovery source is confirmed feeding the service.
- The CA App Control policy is enabled and correctly scoped, and the app is onboarded to session control.
- The correct documented fix was applied and warm-up time elapsed, yet the blocker persists.
In that case the root cause is likely a **service-side issue**, not your configuration. Run `TBMMCA-SupportBundle.ps1`, open the case, and attach the bundle. *Incident-response decisions remain the SOC's; this is a service-support escalation.*
