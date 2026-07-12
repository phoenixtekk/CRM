# 6. Troubleshooting Guide — Microsoft Defender for Identity

Common field issues across all three phases, in **symptom → cause → fix** form. Run `MDIFULL-Discovery.ps1` and `MDIFULL-Validate.ps1` first — most causes surface there. All PoC test signal is benign (read-only enumeration + a honeytoken decoy). For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## DSA not working
**Symptom:** Test A1 fails — `MDI Directory Service Account – Tenant – Prod` is missing, or the sensor cannot use it and enrichment detections are limited.
**Cause:** The gMSA is not registered under **Directory Service accounts**, the sensor host computer accounts lack permission to retrieve the gMSA password, or a standard account's password is wrong.
**Fix:** Confirm the DSA is registered under **Settings → Identities → Directory Service accounts**; grant the sensor hosts permission to retrieve the gMSA password; re-enter credentials for a standard account. *Verify current MDI DSA requirements.* Re-run `MDIFULL-Validate.ps1 -Check DSA`.

## Sensor unhealthy
**Symptom:** `MDI Sensor Host – Pilot DC – Pilot` shows **Unhealthy / Not configured / Stopped** in **Settings → Identities → Sensors**.
**Cause:** Blocked outbound reach to the MDI service, insufficient DC resources, an unsupported sensor OS, a mis-scoped DSA, a wrong/expired access key, or a proxy in the way.
**Fix:** Confirm the DC can reach the MDI service URLs (per `global-requirements-defender.md`); confirm DC resources and a supported OS version (*verify current sensor OS support*); verify the DSA; reinstall with a fresh access key from **Add sensor** if needed; configure the sensor proxy if one is required. Re-run `MDIFULL-Validate.ps1 -Check Sensor`.

## No identity signal
**Symptom:** Test A5 / C4 fails — one or more of `IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents` return no rows; entity-page timelines are empty.
**Cause:** The sensor is unhealthy or too newly installed, not enough traffic has passed the DC yet, or the account lacks hunting permission.
**Fix:** Confirm the pilot sensor is healthy first (A2). Allow warm-up — identity tables populate over minutes to hours. Confirm the account holds advanced-hunting read (Requirement 2.8). Generate benign authentication traffic through the DC and re-run `MDIFULL-Validate.ps1 -Check Signal`.

## Detection does not fire
**Symptom:** Test A6 fails — the controlled honeytoken touch or safe simulation produces no alert.
**Cause:** The honeytoken is not actually tagged, the sensor is unhealthy, the test did not reach a sensored DC, or not enough time has passed.
**Fix:** Confirm the honeytoken is tagged (A4) and the sensor healthy (A2); ensure the authentication/query targets a DC that has a sensor; allow time for the alert to surface in **Incidents & alerts**. Re-test with `MDIFULL-Validate.ps1 -Check Signal` to confirm the query event is recorded.

## No ISPM recommendations
**Symptom:** Test A7 / Lab 4 fails — no MDI Identity recommendations appear in **Secure Score → Recommended actions** or **Exposure management → Recommendations**.
**Cause:** Sensors are too newly onboarded for ISPM to compute, sensor coverage is too thin, ISPM is not yet available in the tenant, or you are looking at the wrong blade.
**Fix:** Confirm sensor health (A2) and allow warm-up; expand sensor coverage so more DCs report; try both **Secure Score** and **Exposure management → Recommendations** (menus move — *verify current navigation*); *verify current ISPM availability in your tenant.* Re-run `MDIFULL-Report.ps1 -SaveBaseline`.

## Honeytoken generating noise
**Symptom:** The honeytoken account fires alerts from legitimate activity.
**Cause:** A real process (logon script, service, scheduled task, or a person) is using the decoy account, so it is no longer idle.
**Fix:** Identify and remove the legitimate use (the **Honeytoken** section of `MDIFULL-LabQueries.kql` shows what touched it), or retire the account and create a genuinely idle replacement named `MDI Honeytoken – Decoy Identity – Pilot`. Re-tag and re-validate (A4).

## Honeytoken candidate list empty (`signInActivity` blank)
**Symptom:** `MDIFULL-Discovery.ps1` lists no candidate accounts or blank last-sign-in.
**Cause:** `signInActivity` requires **Entra ID P1/P2** and `AuditLog.Read.All`; without them the property is empty.
**Fix:** Confirm the Entra plan and the scope (*verify availability*). If unavailable, the facilitator picks a decoy account manually (create `svc-legacy-backup` in the lab) — the honeytoken does not depend on this list.

## Entity pages / advanced hunting empty during the labs
**Symptom:** `IdentityInfo | take 5` returns nothing; user entity pages have empty timelines.
**Cause:** Sensors only just onboarded (warm-up), the `Identity*` tables are not yet populated, or the attendee lacks hunting permission.
**Fix:** Allow a warm-up window; confirm the attendee role includes advanced-hunting read (Requirement 2.8, 2.11). A quiet tenant is fine for teaching — use the runbook descriptions and the honeytoken lab to generate signal in a **lab**. Re-run `MDIFULL-Validate.ps1`.

## Response actions greyed out (Lab 5)
**Symptom:** **Disable user / Force password reset** are unavailable on the entity page.
**Cause:** The attendee holds a read-only role (by design), or the action requires higher privilege / the approval gate.
**Fix:** This is expected — attendees learn read-only and **rehearse** response. Only the facilitator (with the appropriate role) demonstrates the action, and only in a lab / with approval. Do not execute against a production identity during training.

## Recon signal not generated (PoC)
**Symptom:** Test C1 fails — the enumeration commands are blocked or return nothing.
**Cause:** The test account cannot query AD, or a security tool blocks the enumeration on the workstation.
**Fix:** Confirm the test account can run `net group` / `nltest` / LDAP queries against the domain; run `MDIFULL-TestSignal.ps1` from a domain-joined test workstation.

## No reconnaissance alert (PoC)
**Symptom:** Test C2 fails — no reconnaissance alert after the benign enumeration.
**Cause:** The sensor is not healthy, the enumeration was too light to trip the detection threshold, or signal has not propagated.
**Fix:** Confirm sensor health (A2); run the full enumeration set (the script runs several patterns); allow propagation time; re-run `MDIFULL-Validate.ps1 -Check Signal`. Some detections need a recognisable enumeration pattern, not a single query.

## Teardown left residue (PoC)
**Symptom:** After `MDIFULL-Deploy.ps1 -Rollback`, a PoC-only decoy is still tagged or `MDI-TESTSIGNAL` alerts remain open.
**Cause:** Rollback ran in `-WhatIf` only, or the alerts were not resolved.
**Fix:** Run rollback **without** `-WhatIf`; untag any PoC-only decoy under **Entity tags → Honeytoken**; resolve the `MDI-TESTSIGNAL` alerts in **Incidents & alerts** as "Not a threat / test." Re-confirm with `MDIFULL-Validate.ps1`. Note: the production sensor, retained honeytokens, tags, and saved queries are **kept** — only demo-only artefacts are removed.

## Response action acted without approval
**Symptom:** A user was disabled or a password reset forced automatically.
**Cause:** A response action was configured for automatic execution rather than approval-gated.
**Fix:** Reset the action to approval-gated (Implementation Step 7), confirm with the SOC, and record the configuration with `MDIFULL-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDIFULL-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, the account lacks Security Reader, or the AD read helpers are run off a machine without the AD module.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security Reader (or Security Administrator for the honeytoken tag); run the AD-inventory portion from a domain-joined host with `RSAT-AD-PowerShell`. Re-run the script.

## Portal menu paths don't match
**Symptom:** A navigation path in the guide doesn't exist.
**Cause:** Microsoft periodically relocates Defender portal menus.
**Fix:** Use global search (top bar) for the feature name (e.g. "Honeytoken", "Entity tags", "ISPM", "Sensors"). *Verify current navigation in your tenant* and update your copy of the guide.
