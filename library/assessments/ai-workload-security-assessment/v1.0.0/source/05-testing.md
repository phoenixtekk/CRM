# 5. Testing — AI Workload Security Assessment

Testing an assessment means proving the **findings are trustworthy** before anyone acts on them: the access
is truly read-only, discovery found every AI resource, the posture reconciles with the live portal, and the
report is reproducible. Work the gates in order; each has an explicit **pass/fail**. All tests are read-only.

Scripts referenced (all read-only): **`AIWLSEC-Validate.ps1`**, **`AIWLSEC-Discovery.ps1`**,
**`AIWLSEC-NetworkIsolation.ps1`**, **`AIWLSEC-ContentSafety.ps1`**, **`AIWLSEC-Report.ps1`**.

## Gate 1 — Access is valid and read-only
Run **`AIWLSEC-Validate.ps1`**.
- **Pass:** PowerShell ≥ 7; required Az + Graph modules present; Azure and Graph connected; identity resolves
  to **Azure Reader** + **Security Reader** with **no Contributor/write role**; AI resource providers
  registered; in-scope AI resources listed.
- **Fail:** Any missing module/role, or a write role detected. Fix per Requirements R1–R4 — a missing role
  makes a review area falsely empty; a write role breaks the read-only guarantee.

## Gate 2 — Discovery found every AI resource
Run **`AIWLSEC-Discovery.ps1`** on the pilot scope, then compare against `portal.azure.com` → **All
resources** filtered to Cognitive Services / Search / Machine Learning.
- **Pass:** Every AI resource visible in the portal for the scope appears in the discovery output, and the
  per-resource posture CSV/JSON lands in **`AIWorkloadSec – Estate – Findings`**.
- **Fail:** A resource is missing from the output. Usually **Reader** isn't assigned on that resource's
  subscription/RG (R1), or the provider isn't registered (R3). Fix and re-run.

## Gate 3 — Network posture reconciles with the portal
Run **`AIWLSEC-NetworkIsolation.ps1`**, then open a sample AI resource → **Networking**.
- **Pass:** The public-network-access state and private-endpoint presence the script reports **match** the
  portal for the sampled resources.
- **Fail:** They diverge. Confirm you're reading the same resource/tenant and that Az.Network is current;
  re-run.

## Gate 4 — Content-safety findings are real (not preview false positives)
Run **`AIWLSEC-ContentSafety.ps1`**, then open a model deployment → **content filter** in Azure AI Foundry /
Azure OpenAI.
- **Pass:** Each "no content filter attached" finding is confirmed in the portal; each preview-dependent item
  (prompt shields, groundedness) is flagged "*verify availability*" rather than asserted as a hard gap.
- **Fail:** The script asserts a gap for a feature that is simply **preview/unavailable** in your region.
  Downgrade it to a "verify availability" note — do not report an unavailable feature as a missing control.

## Gate 5 — RAG exposure is confirmed by inspection
For each RAG-backing AI Search index, inspect permission-trimming per Implementation Step 2.4.
- **Pass:** Each "index not permission-trimmed" finding is confirmed by looking at the index's security
  filtering / document-level access and the app's access design.
- **Fail:** The index actually *is* trimmed by a mechanism the script couldn't see (app-side security filter).
  Record as a validated false positive with the reason.

## Gate 6 — (Optional) KQL corroboration
If diagnostics flow to Log Analytics/Sentinel (R6), run the saved query **`AIWorkloadSec – KeyAuth – Signal`**:
```kql
// Read-only. Azure OpenAI / Cognitive Services requests still authenticating with a key rather than an
// Entra token — corroborates the "local auth (keys) enabled" finding. *Verify table/column names for your
// workspace and the current diagnostic category.*
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where TimeGenerated > ago(7d)
| extend AuthType = tostring(properties_authType_s)
| summarize Requests = count() by AuthType, Resource
| order by Requests desc
```
- **Pass:** The query runs read-only and either confirms key-based auth is still occurring (supports the
  finding) or shows token-only auth (note as a compensating signal).
- **Fail:** Query errors on table/column names — adjust to your workspace schema (*verify current schema*) or
  skip; KQL corroboration is optional and does not gate the findings.

## Gate 7 — Report is complete and reproducible
Run **`AIWLSEC-Report.ps1`** for the labelled run.
- **Pass:** The report lists every AI resource with its posture, tags each finding Critical/High/Medium/Low,
  names the **AI security baseline and run date** in the header, flags preview-dependent items, and maps each
  finding to a paired remediation solution (AIFOUNDRY/AIRAG/AISAFETY/AILZ); re-running on the same inputs
  produces the same result.
- **Fail:** Missing findings, no baseline named, or non-reproducible output. Confirm all Stage-2 outputs are
  present in the input folder and re-run.

## Gate 8 — Whole-estate expand run
Repeat Gates 2–7 with the full scope labelled **`AIWorkloadSec – Estate – Full`**.
- **Pass:** All gates pass at full scope; the roadmap **`AIWorkloadSec – Estate – Roadmap`** sequences findings
  into Phase 1/2/3 and each item names its paired build solution.
- **Fail:** A resource that passed at pilot scope now fails at full scope — usually a subscription/RG where
  Reader wasn't assigned. Fix the coverage (R1, R5) and re-run.

> Passing all gates means the findings are defensible. It does **not** authorize any change — remediation is
> the paired AI build solutions' job, pilot-first and change-controlled, and acceptable-use / risk-acceptance
> decisions are the customer's.
