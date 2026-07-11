# 6. Troubleshooting — AI Workload Security Assessment

Common failures when running the assessment, as **symptom → cause → fix**. Everything here stays read-only —
no fix below changes an AI resource.

## An AI resource is missing from discovery
**Symptom:** `AIWLSEC-Discovery.ps1` returns some AI resources but not one you can see in the portal.
**Cause:** Azure **Reader** isn't assigned on that resource's subscription/RG (R1), or the resource provider
isn't registered (R3), or your context is set to a different subscription.
**Fix:** Run `AIWLSEC-Validate.ps1` to confirm the visible subscriptions and providers; assign **Reader** at
the missing scope, `Set-AzContext` to the right subscription, and re-run. Never assume "not found" means
"doesn't exist" until access is confirmed.

## A whole review area is empty
**Symptom:** Discovery works but the network-isolation or content-safety review returns nothing.
**Cause:** The specific module or provider for that area is missing/old — network needs **Az.Network**,
content safety reads Cognitive Services deployments; version drift is common (R4).
**Fix:** `Get-Module Az.Network,Az.CognitiveServices -ListAvailable`; update with `Install-Module Az`. Re-run
after confirming the modules and the Reader role for those resources.

## `Connect-AzAccount` succeeds but no AI resources appear
**Symptom:** Azure connects, but the AI estate looks empty.
**Cause:** Wrong subscription context, or Reader assigned at a different scope than where the AI resources live.
**Fix:** `Get-AzSubscription` and `Get-AzContext`; `Set-AzContext -SubscriptionId <the AI sub>`. Pass the
correct `-SubscriptionIds` to the scripts. Re-run.

## Content-safety script reports a gap for a preview feature
**Symptom:** The script flags "no prompt shield / no groundedness detection" but you know it's not yet GA in
your region.
**Cause:** Several AI safety controls are **preview** or region-limited; absence ≠ misconfiguration.
**Fix:** The script marks these "verify availability" by design — treat them as a note, not a hard finding.
*Verify current availability and preview status* before reporting a gap (Best Practices, Testing Gate 4).

## RAG index flagged as "not permission-trimmed" but it is
**Symptom:** The assessment flags an AI Search index as exposing the whole corpus, but the app enforces
document-level access.
**Cause:** Permission-trimming can be enforced **app-side** (a security filter the app injects at query time)
which the resource-level scan can't see.
**Fix:** Confirm by inspection (Implementation Step 2.4). If it's genuinely trimmed, record a **validated
false positive** with the mechanism noted — don't delete it silently. If trimming is only in one code path,
the finding may still stand for the others.

## Graph calls fail with `Authorization_RequestDenied`
**Symptom:** The identity/RBAC portion errors on Graph.
**Cause:** The **Security Reader** role or the `Directory.Read.All` scope isn't granted (R2, R3).
**Fix:** Assign **Security Reader**; re-run `Connect-MgGraph -Scopes "Directory.Read.All"` and consent. Never
substitute a write scope.

## KQL query errors on table or column names
**Symptom:** The `AIWorkloadSec – KeyAuth – Signal` query fails with an unknown table/column.
**Cause:** Diagnostic category and schema for Cognitive Services vary and evolve; the resource may log to a
resource-specific table rather than `AzureDiagnostics`.
**Fix:** Adjust the table/column names to your workspace and the current diagnostic category (*verify current
schema*), or skip it — the KQL is **optional** corroboration and does not gate the findings.

## Report scores aren't reproducible
**Symptom:** Re-running `AIWLSEC-Report.ps1` yields different results on the "same" data.
**Cause:** The input folder changed between runs, or pilot and full-estate outputs were mixed.
**Fix:** Ensure all Stage-2 outputs for the run label are present and complete; keep `... – Pilot` and
`... – Full` outputs in clearly labelled subfolders. Re-run.

## The assessment found a resource with no owner / no governance
**Symptom:** A model deployment has no content-filter policy, no documented owner, and no review.
**Cause:** This is a **finding, not an error** — ungoverned model use is exactly what the assessment surfaces.
**Fix:** Record it and map it to **AISAFETY** (content safety / responsible-AI) for remediation. Assigning an
owner and a governance standard is the customer's decision, done under change control — not part of this
read-only assessment.
