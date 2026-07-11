# 6. Troubleshooting — Security Optimization Assessment: Defender for Cloud Apps

Common failures when running the assessment, in **symptom → cause → fix** form. All fixes stay read-only.

## `Connect-MgGraph` fails or prompts for admin consent
**Symptom:** `Connect-MgGraph -Scopes ...` errors, or a consent screen requires an administrator.
**Cause:** The read scopes (`SecurityEvents.Read.All`, `Application.Read.All`, `Directory.Read.All`) have not been consented in the tenant, or your account lacks them.
**Fix:** Have an administrator grant admin consent for the read-only scopes once. Confirm your account holds **Security Reader** / **Global Reader** (R3). *Verify current scope names — Microsoft occasionally renames scopes.*

## `SOAMCA-Discovery.ps1` returns empty connector/policy sections
**Symptom:** The baseline JSON has empty `connectors` or `policies` sections in a tenant you know uses Cloud Apps.
**Cause 1:** The API surfaces only what the read role can see — an insufficiently privileged account.
**Cause 2:** The tenant genuinely has no API connectors / policies configured (that is a real finding, not an error).
**Fix:** Confirm you can view **Cloud apps → Policies** in the portal with the same account. If the portal shows items the script does not, re-check the Graph scopes. If the portal is also empty, record it as a **coverage finding**.

## App governance section is absent
**Symptom:** Validation reports app governance "not available" rather than "not configured."
**Cause:** App governance is a licensed add-on and is not enabled in the tenant (R2).
**Fix:** This is expected when unlicensed. Record it as a **license/enable coverage finding** — "enable app governance to gain OAuth-app monitoring." Do not treat it as a misconfiguration.

## OAuth audit lists nothing
**Symptom:** `SOAMCA-OAuthAudit.ps1` produces an empty set.
**Cause 1:** No third-party OAuth applications are consented in the tenant (possible in a small/new tenant).
**Cause 2:** `Application.Read.All` / `Directory.Read.All` not consented, so enumeration silently returns nothing.
**Fix:** Verify the scopes are consented (R4). Cross-check in Entra → **Enterprise applications**. If the portal shows apps but the script does not, the scope is missing.

## Scores differ between runs on the same baseline
**Symptom:** `SOAMCA-Score.ps1` gives different numbers for identical input.
**Cause:** A changed weight file, or the score is being computed against a *fresh* discovery rather than the saved baseline.
**Fix:** Always pass the **same** saved baseline path. Confirm the weights in the script header were not edited between runs. Scoring is deterministic for fixed input (Testing Test 5).

## Report shows no drift when a prior run exists
**Symptom:** The findings report says "no prior baseline" although you ran it before.
**Cause:** The prior baseline JSON was not passed, or its filename/path changed.
**Fix:** Point `SOAMCA-Report.ps1` at the retained prior baseline. Keep baselines with stable, dated filenames in the secure location.

## Throttling / partial results on large tenants
**Symptom:** Discovery or the OAuth audit is slow, times out, or returns partial pages.
**Cause:** Microsoft Graph throttling on large directories.
**Fix:** Re-run; the scripts page through results and honor retry-after. For very large tenants, scope the run (fewer users/apps at a time) and combine baselines — record the scoping in `SOA Scope – Cloud Apps – Assess`.

## Findings look wrong / stale versus the portal
**Symptom:** A finding contradicts what you see live in the portal.
**Cause:** Posture is a **point-in-time snapshot**; the baseline was captured earlier than your portal view, or a change was made after the run.
**Fix:** Re-run discovery to refresh the baseline, then re-score. Always trust the dated baseline over memory (Global Requirements G5).
