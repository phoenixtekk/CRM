# 6. Troubleshooting — Workshop: Microsoft Defender for Identity

Symptom → cause → fix for the common issues when running the workshop and its lab helpers. For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## Sensor shows Unhealthy or no sensors listed
- **Symptom:** **Settings → Identities → Sensors** shows no sensor, or a sensor is **Unhealthy**; entity pages are empty.
- **Cause:** MDI sensors are not onboarded, the service account/credentials are wrong, or outbound access to the MDI service is blocked.
- **Fix:** This workshop assumes onboarding is done — use the **Defender XDR Deployment / Unified Onboarding** solution to install/repair sensors. Confirm outbound HTTPS to the MDI service endpoints (global requirement G5). Do not run the labs until at least one sensor is **Healthy** (R1).

## Entity pages / advanced hunting return no identity data
- **Symptom:** `IdentityInfo | take 5` returns nothing; user entity pages have empty timelines.
- **Cause:** Sensors only just onboarded (warm-up), the `Identity*` tables are not yet populated, or the account lacks hunting permission.
- **Fix:** Allow a warm-up window after onboarding (*timing varies — verify in your tenant*). Confirm the attendee role includes advanced-hunting read (R5). Re-run `WSMDI-Validate.ps1`.

## ISPM recommendations are empty (Lab 4)
- **Symptom:** Filtering Secure Score / Exposure management to **Identity** shows no recommendations.
- **Cause:** ISPM assessments have not populated yet, or you are looking at the wrong blade.
- **Fix:** Wait for assessments to run after sensor onboarding (R3). Try both **Secure Score** and **Exposure management → Recommendations**; menus move — *verify current navigation*. Confirm sensors are healthy first.

## `Connect-MgGraph` fails or scopes are not granted
- **Symptom:** The lab scripts error on connect, or `WSMDI-Validate.ps1` reports fewer scopes than requested.
- **Cause:** The delegated read scopes were not consented, or the account lacks the directory role to consent.
- **Fix:** Have a Global Administrator consent the read scopes once (`SecurityAlert.Read.All`, `SecurityEvents.Read.All`, `AuditLog.Read.All`, `User.Read.All`), or register a read-only workshop app. Never grant write/response scopes for the labs (R6).

## `Get-MgSecurityAlertV2` returns nothing
- **Symptom:** Discovery/report show 0 MDI alerts.
- **Cause:** A genuinely quiet tenant, alerts outside the query window, or the provider filter excluded them.
- **Fix:** A quiet tenant is fine for teaching — use the runbook descriptions and the honeytoken lab to generate signal in a **lab**. Widen the time range. Confirm Defender for Identity is licensed and active (global requirement G2).

## `signInActivity` is blank (honeytoken candidate list empty)
- **Symptom:** `WSMDI-Discovery.ps1` / `WSMDI-Honeytoken-Lab.ps1` list no candidates or blank last-sign-in.
- **Cause:** `signInActivity` requires **Entra ID P1/P2** and `AuditLog.Read.All`; without them the property is empty.
- **Fix:** Confirm the Entra plan and the scope (*verify availability*). If unavailable, the facilitator picks a decoy account manually (create `svc-legacy-backup` in the lab) — the honeytoken does not depend on this list.

## Honeytoken detection did not fire in the demo
- **Symptom:** After a benign lab sign-in as the honeytoken, no **"Honeytoken activity"** alert appears.
- **Cause:** The account was not correctly tagged, detection latency, or the auth path was not observed by a sensor.
- **Fix:** Confirm the tag under **Entity tags → Honeytoken**; allow detection latency; ensure the authentication traversed a monitored DC. Never test honeytokens in production — only in a lab.

## Response actions greyed out (Lab 5)
- **Symptom:** **Disable user / Force password reset** are unavailable on the entity page.
- **Cause:** The attendee holds a read-only role (by design), or the action requires higher privilege / the approval gate.
- **Fix:** This is expected — attendees learn read-only and **rehearse** response. Only the facilitator (with the appropriate role) demonstrates the action, and only in a lab / with approval. Do not execute against a production identity during training.

## Portal menu paths don't match
- **Symptom:** A navigation path in the runbook doesn't exist.
- **Cause:** Microsoft periodically relocates Defender portal menus.
- **Fix:** Use global search (top bar) for the feature name (e.g. "Honeytoken", "Entity tags", "ISPM"). *Verify current navigation in your tenant* and update your copy of the runbook.
