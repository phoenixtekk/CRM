# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Identity

Common field issues, in **symptom → cause → fix** form. Run `POCMDI-Enable.ps1 -WhatIf` and `POCMDI-Validate.ps1` first — most causes surface there. All test signal is benign (read-only enumeration + a honeytoken decoy).

## Sensor unhealthy
**Symptom:** `MDI PoC Sensor – Pilot DC – Pilot` shows **Unhealthy** or **Not configured** in **Settings → Identities → Sensors**.
**Cause:** Missing/mis-scoped DSA, blocked outbound reach to the MDI service, insufficient DC resources, or an unsupported sensor OS.
**Fix:** Verify the DSA `MDI PoC – DSA – Pilot` under **Directory Service accounts**; confirm the DC can reach the MDI service URLs (per `global-requirements-defender.md` G5); confirm DC resources and a supported OS (*verify current sensor OS support*). Reinstall with a fresh access key if needed, then re-run `POCMDI-Validate.ps1`.

## Honeytoken not flagged
**Symptom:** Test 5 fails — touching `MDI PoC Honeytoken – Pilot` did not raise anything.
**Cause:** The account is not tagged as a honeytoken, the sensor is not yet healthy, or signal has not propagated.
**Fix:** Confirm the tag under **Settings → Identities → Entity tags → Honeytoken**; confirm Test 1 passed; allow warm-up time and re-touch the account, then re-run `POCMDI-Validate.ps1`.

## Recon signal not generated
**Symptom:** Test 3 fails — the enumeration commands are blocked or return nothing.
**Cause:** The test account cannot query AD, or a security tool blocks the enumeration on the workstation.
**Fix:** Confirm the test account can run `net group` / `nltest` / LDAP queries against the domain; run from a domain-joined test workstation; re-run `POCMDI-TestSignal.ps1`.

## No reconnaissance alert
**Symptom:** Test 4 fails — no reconnaissance alert appears after the benign enumeration.
**Cause:** The sensor is not healthy, the enumeration was too light to trip the detection threshold, or signal has not propagated.
**Fix:** Confirm sensor health (Test 1); run the full enumeration set (the script runs several patterns); allow propagation time; re-run `POCMDI-Validate.ps1`. Some detections need a recognisable enumeration pattern, not a single query.

## Hunting tables empty
**Symptom:** `POCMDI-Validate.ps1` returns no rows from `IdentityQueryEvents` / `IdentityLogonEvents` / `IdentityDirectoryEvents`.
**Cause:** Tables populate over time after sensor install, or the account lacks hunting read scope.
**Fix:** Allow warm-up (tables populate over minutes to hours); confirm `ThreatHunting.Read.All` consent and **Security Reader**; re-run the validate script.

## DSA problems
**Symptom:** The sensor installs but detections are limited or the DSA test fails.
**Cause:** The gMSA is not resolvable from the DC, lacks read permission, or is mis-registered.
**Fix:** Confirm the gMSA `MDI PoC – DSA – Pilot` is installed and resolvable on the DC and registered under **Directory Service accounts**; *verify current MDI DSA requirements*.

## Script cannot authenticate
**Symptom:** `POCMDI-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, read scopes were not consented, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** (or Security Administrator for the honeytoken tag). Re-run.

## Teardown left residue
**Symptom:** After `POCMDI-Teardown.ps1`, the sensor still appears or the honeytoken is still tagged.
**Cause:** Teardown ran in `-WhatIf` only, or the sensor service on the DC was not removed.
**Fix:** Run teardown **without** `-WhatIf`; delete the sensor in the portal **and** uninstall the sensor service on the DC; untag the honeytoken; resolve the `MDI-PoC-TESTSIGNAL` alerts; re-confirm with `POCMDI-Validate.ps1`.
