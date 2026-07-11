# 6. Troubleshooting — Security Optimization Assessment: Defender for Identity

Common issues when running the read-only assessment, each as **symptom → cause → fix**. None of these fixes change MDI configuration — they fix the *assessment run*.

## `Get-ADDomainController` returns fewer DCs than expected
- **Symptom:** The AD-derived DC list is short — the coverage denominator is wrong.
- **Cause:** A child domain or trusted forest is not being traversed, DNS/RPC to a remote DC is blocked, or the run host cannot reach every domain.
- **Fix:** Run from a host with line-of-sight to all domains, specify the domains/forest explicitly (`Get-ADForest` then per-domain queries), and reconcile with the AD team (Testing Gate 2). An incomplete denominator hides exactly the blind spots you are hunting.

## AD module not available
- **Symptom:** `Get-ADDomainController` is not recognized.
- **Cause:** RSAT / the `ActiveDirectory` PowerShell module is not installed on the run host.
- **Fix:** Install RSAT (or run from a domain controller/management host that has the module). A read-only domain account is sufficient (R2).

## Sensor list / DSA / honeytoken data comes back empty from the script
- **Symptom:** Discovery cannot programmatically read sensor health, the DSA, or tagged entities.
- **Cause:** These MDI settings may have **no public read API** in your tenant today — they live in **Settings → Identities** in the portal.
- **Fix:** This is expected. The script flags these as **verify**; confirm the values in the portal and record them (Testing Gate 3). Do not treat the flag as a run failure and do not drop the item. *Verify current MDI read-API availability.*

## `Connect-MgGraph` or advanced hunting fails
- **Symptom:** Graph connect errors, or `IdentityInfo | take 1` returns nothing.
- **Cause:** The Microsoft.Graph modules are missing, read scopes are not consented, or MDI is not sending identity data (no healthy sensors yet).
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent `SecurityEvents.Read.All` / `AdvancedHunting.Read.All` (R3). If `IdentityInfo` is genuinely empty, that itself points to a coverage problem — note it.

## Coverage shows 100% but the owner suspects blind DCs
- **Symptom:** Sensor coverage looks perfect and is not believed.
- **Cause:** Coverage was computed against MDI's own sensor list (self-referential) rather than the AD-derived DC inventory — a DC with no sensor is invisible to that denominator.
- **Fix:** Re-run `SOAMDI-Coverage.ps1` using the AD inventory as the denominator (R5). The blind DCs will appear.

## An un-sensored DC in the report is actually being decommissioned
- **Symptom:** A flagged DC is a known, intentional exception.
- **Cause:** The assessment cannot know operational plans.
- **Fix:** Record it as an **accepted exception** in the review (Stage 7). Risk-acceptance is the customer's decision; annotate so it is not re-flagged — but re-confirm it is actually gone on the next run.

## Validate flags a write scope present
- **Symptom:** Gate 1 fails on the "no write scope" assertion.
- **Cause:** The assessor holds an admin/manage role.
- **Fix:** Reduce to **Security Reader** / **Global Reader** (and a read-only domain account) before running. An assessment must not hold write access; this is by design.

## Report `verify` items not confirmed before delivery (Gate 6 risk)
- **Symptom:** The report ships with unconfirmed `verify` flags on DSA/honeytoken/sensor items.
- **Cause:** The portal-confirmation step was skipped.
- **Fix:** Before delivering, open **Settings → Identities** and confirm each `verify` item, updating the report. An unconfirmed `verify` is not a finding and must not be presented as one.
