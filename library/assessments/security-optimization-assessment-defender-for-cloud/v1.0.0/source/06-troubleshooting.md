# 6. Troubleshooting — Security Optimization Assessment: Defender for Cloud

Common failures when running the assessment, in **symptom → cause → fix** form. All fixes stay read-only.

## `Connect-AzAccount` succeeds but the subscription is not visible
**Symptom:** `SOAMDC-Discovery.ps1` reports no subscription, or the wrong one.
**Cause:** The default Az context points at a different subscription/tenant.
**Fix:** `Set-AzContext -Subscription '<pilot subscription id>'` before running, or pass `-SubscriptionId`. Confirm with `Get-AzContext`.

## `Search-AzGraph` throws or returns nothing
**Symptom:** `SOAMDC-Coverage.ps1` errors on the Resource Graph query, or returns an empty set.
**Cause 1:** `Az.ResourceGraph` is not installed.
**Cause 2:** The Reader role does not extend to the queried scope.
**Fix:** `Install-Module Az.ResourceGraph -Scope CurrentUser`; confirm **Reader** at the subscription/management-group scope (R2/R3). An empty set can also be legitimate (no machines in scope) — the script notes that.

## Secure Score reads 0 or "not available"
**Symptom:** The Secure Score domain shows no score on a subscription you know is active.
**Cause:** Defender for Cloud is newly registered and still populating, or `Microsoft.Security` is not registered.
**Fix:** Confirm `Get-AzResourceProvider -ProviderNamespace Microsoft.Security` shows Registered. Allow a warm-up window and re-run — Secure Score is not instantaneous (Global Requirements G5).

## Plans show Off that you expected On
**Symptom:** Validation flags Defender for Servers/Storage/SQL as Off.
**Cause:** Plans are paid and per-subscription; they are genuinely off, or on at a different subscription than the one in context.
**Fix:** Confirm in **Environment settings → Defender plans** for the exact subscription. Record off-plans as **coverage findings** (enabling them has a cost — R4).

## Required compliance standard "not mapped"
**Symptom:** The regulatory-compliance domain scores 0 / not-mapped.
**Cause:** The standard the organization needs has not been added to the compliance dashboard (or a different standard is mapped).
**Fix:** Confirm with the compliance owner which standard is required (R5) and pass it as `-RequiredStandard`. If none is mapped, that is a legitimate finding — but the *choice* of standard is the compliance team's, not the assessment's.

## Coverage query slow or throttled on large estates
**Symptom:** `SOAMDC-Coverage.ps1` is slow or returns partial pages.
**Cause:** Resource Graph throttling / large result sets across many subscriptions.
**Fix:** Scope the run to one subscription/management group at a time and combine baselines; record the scoping in `SOA Scope – Defender for Cloud – Assess`.

## Scores differ between runs on the same input
**Symptom:** `SOAMDC-Score.ps1` gives different numbers for identical validation output.
**Cause:** Edited weights, or scoring a fresh discovery rather than the saved validation file.
**Fix:** Always pass the **same** validation JSON; confirm the weights in the header were not changed. Scoring is deterministic (Testing Test 5).

## Findings contradict the live portal
**Symptom:** A finding disagrees with what the portal shows now.
**Cause:** Posture is a **point-in-time snapshot**; the baseline predates your portal view, or a change was made after the run.
**Fix:** Re-run discovery to refresh the baseline, then re-score. Trust the dated baseline over memory (Global Requirements G5).
