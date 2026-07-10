# 6. Troubleshooting — Microsoft 365 Copilot Data Governance & DLP Guardrails

Common failures, their cause, and the fix. Symptoms map to the implementation steps.

## Cannot connect Security & Compliance PowerShell
- **Symptom:** `Connect-IPPSSession` fails or cmdlets like `Get-Label` are not found.
- **Cause:** Missing/old `ExchangeOnlineManagement` module, or insufficient role.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (or `Update-Module`); reconnect;
  confirm a Compliance/Information Protection role (Requirement 2.2). PowerShell 7+ recommended.

## The Microsoft 365 Copilot DLP location is not offered
- **Symptom:** Creating a DLP policy shows no **Microsoft 365 Copilot** location.
- **Cause:** DLP-for-Copilot is licensing-gated and/or in preview and not enabled in your tenant.
  *(Verify current availability.)*
- **Fix:** Confirm the required Purview plan; where the location is genuinely unavailable, govern the
  "keep out of Copilot" content via label **encryption/usage rights** (honored by Copilot) as the interim
  control and note DLP-for-Copilot as pending. `CPLTGOV-Guardrails.ps1` parameterizes the location and
  will warn rather than assume it.

## Discovery shows no labels / no sensitive info types
- **Symptom:** `Copilot Label Coverage – Estate – Assess` lists no labels or SITs.
- **Cause:** No published label taxonomy yet, or the session lacks read access.
- **Fix:** Publish a baseline taxonomy first (Requirement 2.4 / the Purview information-protection
  solutions); reconnect `Connect-IPPSSession`; re-run. This solution enforces labels; it does not design
  the taxonomy.

## Auto-labeling policy created but it labelled content immediately
- **Symptom:** Content got labelled before the simulation review.
- **Cause:** The policy was created in **on** mode rather than simulation.
- **Fix:** Recreate in **simulation** (`CPLTGOV-Guardrails.ps1 -Action AutoLabel` defaults to a
  simulation/`-WhatIf` posture). Simulation labels nothing — it only shows what it *would* label. Review
  first, enforce later.

## DLP-for-Copilot test policy is blocking Copilot in the pilot
- **Symptom:** Copilot won't process content for pilot users during the test window.
- **Cause:** The policy was set to enforce rather than **test/disabled**, or the condition is too broad.
- **Fix:** Set the policy back to **test/disabled** (`CPLTGOV-Validate.ps1` confirms mode); tune the label/
  SIT condition; only move to enforce after the false-positive review passes (Testing Test 7).

## No Copilot interaction events in the audit search
- **Symptom:** `CPLTGOV-AuditSearch.ps1` returns nothing for the pilot users.
- **Cause 1 — auditing off/recently enabled:** **Fix:** Enable Purview **Audit**; allow backfill time;
  re-run.
- **Cause 2 — latency:** Audit events can lag the interaction. **Fix:** Wait and re-run; widen the time
  window and confirm the correct operation/record types for Copilot in your tenant *(verify)*.
- **Cause 3 — scope/role:** **Fix:** Confirm `AuditLog.Read.All` (Graph) or the audit-search role.

## Simulation shows too many false positives
- **Symptom:** Auto-labeling or DLP-for-Copilot would match far more than intended.
- **Cause:** The condition (sensitive info type / label) is too broad, or confidence/instance thresholds
  are loose.
- **Fix:** Narrow the sensitive-info-type set, raise confidence/instance-count thresholds, tighten the
  "keep out of Copilot" label list, and re-run the simulation. Keep the highly-confidential tier small.

## Copilot still uses content you expected the label to keep out
- **Symptom:** After labeling, Copilot still surfaces the content.
- **Cause 1:** The label has no **encryption/usage rights** — a visual-marking-only label does not stop
  Copilot from reading the content. **Fix:** Apply a label configured with encryption/usage rights for the
  do-not-use-in-AI tier.
- **Cause 2:** DLP-for-Copilot is still in **test** (not enforcing). **Fix:** Complete the pilot gate and
  move to enforce.
- **Cause 3 — indexing latency:** **Fix:** Allow time for the label/DLP change to propagate; re-test and
  record the time.

## Enforcement change didn't take effect
- **Symptom:** After `CPLTGOV-Guardrails.ps1 -Action Enforce -Commit`, policies still show
  simulation/test.
- **Cause:** `-Commit` omitted, wrong policy name, or insufficient role.
- **Fix:** Re-run with `-Commit` and the exact object names (`Auto-Label Sensitive – Pilot – Simulation`,
  `DLP for Copilot – Pilot – Test`); confirm the compliance role; verify in the portal.

## eDiscovery can't find Copilot interactions
- **Symptom:** An eDiscovery search returns no Copilot prompts/responses.
- **Cause:** Auditing off during the period, wrong search scope, or eDiscovery role missing.
- **Fix:** Confirm auditing was on for the period, use the correct location/scope, and confirm the
  **eDiscovery Manager** role (Requirement 2.2).
