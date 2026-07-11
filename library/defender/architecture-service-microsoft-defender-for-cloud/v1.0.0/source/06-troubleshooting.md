# 6. Troubleshooting Guide — Architecture Service: Microsoft Defender for Cloud

Common field issues, in **symptom → cause → fix** form. Run `ARCMDC-Discovery.ps1` and `ARCMDC-Validate.ps1` first — most causes surface there.

## What-if shows unexpected changes
**Symptom:** `ARCMDC-Deploy.ps1 -WhatIf` predicts changes beyond the intended plan enablements (or on the wrong scope).
**Cause:** The Bicep parameters target the wrong management group, include plans not in the current wave, or drift from the design record.
**Fix:** Re-parameterize `main.bicep` to the pilot scope and wave-1 plans only; reconcile against `MDC Architecture Decision Record – Platform – Prod`; re-run the what-if until it shows **only** the intended changes. Do **not** `-Apply` until it is clean.

## Plan not enabling at MG scope
**Symptom:** After `-Apply`, plans still show Off/Free at `MDC Scope – Pilot MG – Pilot`.
**Cause:** The deployment identity lacks **Owner / Contributor + Security Admin** at the MG scope, the **Microsoft.Security** provider isn't registered, or the plan isn't available in the region/tenant.
**Fix:** Confirm the identity's role at the MG node (Requirements 2.3); register the provider; *verify the plan's availability/pricing in your tenant*. Re-run `ARCMDC-Deploy.ps1 -Apply` and `ARCMDC-Validate.ps1`.

## Inheritance not applying
**Symptom:** A subscription under the pilot MG shows Free / no inherited plan.
**Cause:** The plan was set at **subscription** scope (or a lower MG) instead of the intended MG node, the subscription overrides inheritance with its own setting, or the provider isn't registered on it.
**Fix:** Confirm the plan is set at the **management-group** scope; remove any conflicting per-subscription override; register **Microsoft.Security** on the subscription. Re-check with `ARCMDC-Validate.ps1` (Test 4).

## Provider not registered
**Symptom:** `ARCMDC-Validate.ps1` reports **Microsoft.Security** not registered on a subscription.
**Cause:** The provider was never registered, or a new subscription joined without it.
**Fix:** `Register-AzResourceProvider -ProviderNamespace Microsoft.Security` on the subscription, or let the MG-scope Azure Policy auto-register it. Allow a few minutes and re-validate.

## RBAC sprawl / missing governance
**Symptom:** Over-broad roles (e.g. Owner where Security Reader suffices) or no governance rule at scope.
**Cause:** Roles granted ad-hoc during rollout, or Step 4 skipped.
**Fix:** Re-align role assignments to the least-privilege model in the design record; grant at the narrowest MG node; create `MDC Governance – Platform MG – Prod` with owners/due dates and time-bound exemptions. Re-run `ARCMDC-Validate.ps1`. *Exemption acceptability is the security/compliance team's decision.*

## Continuous export no data
**Symptom:** The central Log Analytics workspace (or the SIEM) receives no recommendation/score/alert data.
**Cause:** `MDC Continuous Export – Platform MG – Prod` is misconfigured, points at the wrong workspace, the exported data types are wrong, or the SIEM connector isn't wired.
**Fix:** Confirm the export config, workspace, and exported types (recommendations + Secure Score + alerts); confirm the SIEM ingestion path; allow ingestion time. Re-run `ARCMDC-Validate.ps1` and query the workspace.

## Cost exceeds the model
**Symptom:** Actual Defender for Cloud spend is well above `ARCMDC-Report.ps1 -Mode Cost`'s estimate.
**Cause:** A plan was enabled at a higher MG node than intended (billing more descendant resources), resource counts grew, or a costly workload plan landed in an early wave.
**Fix:** Check where each plan is enabled in the MG hierarchy; move expensive plans to later waves or a narrower scope; re-run the cost report with current counts; confirm with the budget owner. *Whether the cost is acceptable is finance's decision.* Rollback: set the plan back to Free or remove the MG-scope assignment.

## Multicloud connector not reporting
**Symptom:** An AWS/GCP connector is added but no posture/recommendations appear.
**Cause:** The connector's role/service account in the target cloud is missing permissions, the connection is still initializing, or the plan for that connector isn't enabled.
**Fix:** *Verify current connector requirements*; confirm the AWS role / GCP service account permissions; allow initialization time; confirm the connector's plans are on. Re-check with `ARCMDC-Discovery.ps1`.

## Script or deployment cannot authenticate
**Symptom:** `ARCMDC-*.ps1` fails on connect, or the MG deployment errors on auth/scope.
**Cause:** The Az modules (`Az.Accounts`, `Az.Security`, `Az.Resources`) are missing, the account isn't signed in, or it lacks rights at the MG scope.
**Fix:** Let the script install the modules; `Connect-AzAccount`; confirm the identity has the required MG-scope role; for pipeline runs use a scoped deployment service principal. Re-run.
