# 6. Troubleshooting Guide — Technical Blocker Mitigation: Defender for Identity

The four blocker classes in **symptom → cause → fix** form, plus escalation. Run `TBMMDI-Discovery.ps1` and `TBMMDI-AuditPolicy.ps1` (on the affected DC) first — most causes surface there. This *is* the troubleshooting solution, so this guide is the core reference.

## MDI sensor unhealthy
**Symptom:** The sensor on a DC in `MDI Blocker Triage – Affected Sensors – Diagnose` shows **Unhealthy**, **Not configured**, or **disconnected** in **Settings → Identities → Sensors**.
**Cause:** Blocked outbound reach to the MDI service, an out-of-date or corrupt sensor, an unsupported OS, or the sensor service stopped.
**Fix:** Run the sensor's built-in connectivity test; allow the MDI **service endpoints** at the proxy/firewall (per `global-requirements-defender.md` G5 — *verify the current endpoint list*). Confirm a supported OS and resources, update the sensor to the current version, and reinstall with a fresh access key if corrupt. Confirm the sensor service is running. Re-check health and re-run `TBMMDI-Validate.ps1`.

## DSA missing or under-permissioned
**Symptom:** The sensor is healthy, but AD-context detections are limited and `IdentityQueryEvents` returns nothing.
**Cause:** No **Directory Service Account** is registered, or it lacks the read permissions MDI needs.
**Fix:** Create/register a read-only **DSA** (gMSA recommended) under **Settings → Identities → Directory Service accounts** with the current required permissions (*verify current DSA requirements*). Allow time, then re-run `TBMMDI-Validate.ps1` and confirm query signal.

## Missing network traffic / NNR blind
**Symptom:** The sensor is healthy but network-based detections are silent; the sensor UI shows **NNR** resolution warnings.
**Cause:** The **NNR ports** from the DC to endpoints are blocked, or the sensor is bound to the wrong network adapter and does not see the DC's traffic.
**Fix:** Open the required **NNR ports** (*verify current NNR port requirements*); confirm the sensor binds the adapter carrying the DC's traffic. Re-run `TBMMDI-AuditPolicy.ps1` (NNR readiness) and confirm the sensor resolves endpoints.

## Event-collection gap
**Symptom:** `IdentityLogonEvents` / `IdentityDirectoryEvents` return nothing even though the sensor is healthy.
**Cause:** The required **advanced audit policy** subcategories are not enabled on the DC, so the sensor never receives the Windows Security events its detections depend on (or, for non-DC sensors, event forwarding is not configured).
**Fix:** Enable the required advanced-audit subcategories on the DC per current MDI guidance (`TBMMDI-AuditPolicy.ps1` shows which are missing); configure the documented event forwarding for non-DC sensors. Allow time, then re-run `TBMMDI-Validate.ps1`.

## Licensing / activation blocker
**Symptom:** MDI options are missing, or the Identities workspace is not activated.
**Cause:** No MDI plan assigned, or first-time workspace activation never completed.
**Fix:** Assign the plan (**Billing → Licenses**) and activate the workspace in **Settings → Identities**. *Verify the exact plan the feature needs — availability changes; confirm in your tenant.* Re-run `TBMMDI-Discovery.ps1`.

## Script cannot authenticate / run
**Symptom:** `TBMMDI-Discovery.ps1` / `TBMMDI-Validate.ps1` fails on connect; `TBMMDI-AuditPolicy.ps1` cannot read the policy.
**Cause:** The Microsoft Graph modules are missing, `ThreatHunting.Read.All` consent was not granted, the account lacks Security Reader, or the audit script was not run with local read rights on the DC.
**Fix:** Let the cloud scripts install the modules; sign in with `Connect-MgGraph` and consent to the read scope; confirm Security Reader. Run `TBMMDI-AuditPolicy.ps1` locally on the DC with sufficient rights. Re-run.

## When to escalate to Microsoft support
Escalate — and attach `MDI Support Bundle – <case> – Escalate` — when **all** of the following hold:
- The sensor is on a supported OS with confirmed outbound service reach.
- The DSA is registered with the required permissions.
- The required audit subcategories are enabled and NNR ports are open.
- The correct documented fix was applied and warm-up time elapsed, yet the sensor still will not go healthy or stream.
In that case the root cause is likely a **service-side issue**, not your configuration. Run `TBMMDI-SupportBundle.ps1`, run the **sensor's own log-collection** on the DC, open the case, and attach both. *Incident-response decisions remain the SOC's; this is a service-support escalation.*
