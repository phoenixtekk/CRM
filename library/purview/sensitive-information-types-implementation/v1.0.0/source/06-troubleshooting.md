# 6. Troubleshooting — Sensitive Information Types Implementation (Microsoft Purview)

Common issues, grouped by phase. Each has a **symptom**, the **likely cause**, and a **resolution**.
This solution introduces **no enforcement**: all measurement is in the portal **Test** experience or a DLP
policy in **simulation**. `CLSSIT-Discovery.ps1`, `CLSSIT-Test.ps1`, and `CLSSIT-Report.ps1` are read-only;
`CLSSIT-BuildSimPolicy.ps1` and `CLSSIT-Set-Scope.ps1` are `-WhatIf` by default and create/scope policies
in **simulation only** (they refuse to modify an enforcing policy). A SIT that legitimately doesn't fit a
category is a **gap for another solution**, not a failure here.

## Connectivity & cmdlet availability

**Symptom:** `Connect-IPPSSession` unavailable or `Test-DataClassification` not found.
**Likely cause:** `ExchangeOnlineManagement` missing/outdated, or `Test-DataClassification` isn't present in
your tenant (it is licensing-/rollout-dependent).
**Resolution:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (or `Update-Module`). If
`Test-DataClassification` is absent, `CLSSIT-Test.ps1` degrades to guidance — use the portal SIT **Test**
experience instead. Verify your licensing/tenant; do not assume the cmdlet exists.

## Discovery & selection (Phase 0–1)

**Symptom:** a built-in SIT you expected isn't in `CLSSIT-Discovery.ps1` output.
**Likely cause:** the SIT is region-/plan-specific, or a role gap hid it.
**Resolution:** confirm the reader role and re-run; check the portal **Data classification → Classifiers →
Sensitive info types**. If it genuinely doesn't exist, record the category as a **gap** for the custom-SIT /
EDM / trainable-classifier solutions — never invent a built-in SIT.

**Symptom:** two SITs both seem to fit a category.
**Resolution:** prefer the most specific built-in SIT (a country-specific national-ID SIT over a generic
number pattern); record the chosen one and the rejected alternatives in the `SIT Selection Register`.

## Testing against the corpus (Phase 2)

**Symptom:** a positive sample only matches at Medium/Low, not High.
**Likely cause:** the sample lacks the supporting keywords or corroborating evidence the SIT's High
confidence requires.
**Resolution:** this is a real tuning signal — either accept a lower confidence for that use, or (Phase 4)
raise corroboration via a tuned copy. Record it; don't force it.

**Symptom:** a look-alike negative matches (false positive) in testing.
**Likely cause:** the built-in pattern is broad and your look-alike resembles it.
**Resolution:** capture it for Phase 4 tuning (raise confidence/instance count first; copy the SIT and add a
required nearby keyword only if the dials aren't enough). Use clearly-fake data in the corpus (Requirement 2.4).

## Building the simulation policy (Phase 3)

**Symptom:** `CLSSIT-BuildSimPolicy.ps1` made no change.
**Likely cause:** `-Commit` was omitted (default is `-WhatIf`).
**Resolution:** re-run with `-Commit`; the policy is created in **simulation** (`Test*` mode) only.

**Symptom:** the tool refuses with "policy is currently ENFORCING".
**Likely cause:** a policy of that name is in `Enable` mode.
**Resolution:** this is the safety guard — never let this solution flip a policy to enforce. Use a distinct
`SIT Measure – <Category> – Simulation` name, or adjust the enforcing policy separately under change control.

**Symptom:** simulation shows no matches after creation.
**Likely cause:** it hasn't dwelt long enough, unified audit-log ingestion is off, or the scope is too narrow.
**Resolution:** let it dwell for the agreed time; verify ingestion
(`Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled`); widen the scope if needed.

## Scoping to a pilot ring (CLSSIT-Set-Scope.ps1)

**Symptom:** `-IncludeGroup` errors or scopes nothing.
**Likely cause:** the group isn't mail-enabled, or the rule name doesn't match.
**Resolution:** `-IncludeGroup` must be a **mail-enabled** group; the rule defaults to `"<PolicyName> - Rule"`
— pass `-RuleName` if yours differs. Preview with `-WhatIf` first.

**Symptom:** SharePoint/OneDrive scope didn't narrow as expected.
**Likely cause:** `-AddSharePointLocation` **adds** an included site but the broad `All` location may still apply.
**Resolution:** to limit to only specific sites, also remove the broad `All` in the portal or set the
location explicitly, then verify the resulting scope. DLP location scoping differs per workload.

## Measuring & tuning (Phase 4)

**Symptom:** `CLSSIT-Report.ps1` returns no events.
**Likely cause:** audit ingestion off, insufficient dwell, or nothing matched.
**Resolution:** enable ingestion, allow more dwell time, and re-run. No matches is a legitimate result, not
an error.

**Symptom:** false-positive rate won't come down.
**Likely cause:** stacking multiple changes at once, or the built-in pattern is inherently broad for your data.
**Resolution:** change **one dial at a time** (confidence, then instance count), re-measure; only then create
a tuned copy of the built-in SIT and add a required keyword. The original built-in SIT is never modified.

## Validation & handoff (Phase 5)

**Symptom:** downstream DLP/labeling teams get different detection results.
**Likely cause:** they referenced the SIT at a different confidence/instance count than the registered values.
**Resolution:** the `SIT Selection Register` and `SIT Threshold Register` are authoritative — downstream
controls must consume the SIT at the **registered** confidence and instance count. Decommission the
measurement policies once validated (they were scaffolding, never enforcement).

## What this solution does NOT decide
*Which* data categories are in scope, *which* SITs legally **satisfy** a regulation, and the *acceptable*
false-positive threshold are **compliance / privacy / legal determinations** — this solution delivers an
accurate, tested, tuned detection layer and the evidence; adequacy and applicability belong to those functions.
