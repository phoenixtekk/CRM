# 6. Troubleshooting — Security Optimization Assessment: Defender for Office 365

Common issues when running the read-only assessment, each as **symptom → cause → fix**. None of these fixes change email-protection configuration — they fix the *assessment run*.

## `Connect-ExchangeOnline` or `Connect-IPPSSession` fails
- **Symptom:** The module cannot connect, or the connection prompt cannot complete.
- **Cause:** The ExchangeOnlineManagement module is missing/old, or the assessor lacks a role that can open a session.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (R2); confirm the assessor holds **Global Reader** / **Security Reader** / **View-Only Configuration**; reconnect. Modern auth / MFA is expected — complete the interactive sign-in.

## Transport rules or the Tenant Allow/Block List come back empty
- **Symptom:** `SOAMDO-Discovery.ps1` produces empty transport-rule or allow/block-list files, so the bypass section looks clean.
- **Cause:** The read-only role does not include mail-flow / organization configuration read — the most dangerous gap because it hides the highest-value findings.
- **Fix:** Use a role that includes these reads (**Global Reader** generally does — *verify current role-to-cmdlet mapping*), re-run, and do **not** trust bypass results until these files populate. `SOAMDO-Validate.ps1` Gate 1 checks exactly this.

## An MDO-only policy type is empty (Safe Links / Safe Attachments / impersonation)
- **Symptom:** Safe Links/Attachments or impersonation settings are absent.
- **Cause:** The tenant is **EOP-only** (no Defender for Office 365 plan) or MDO is licensed on only some mailboxes.
- **Fix:** This is expected — score MDO-only checks as **N-A** and list them as coverage findings (a licensing decision). Confirm plan state in the admin center. *Verify current plan/feature mapping.*

## Coverage says a recipient is "uncovered" but a policy clearly exists
- **Symptom:** A user is reported as covered by nothing/weak policy despite a Strict policy existing.
- **Cause:** Policy **priority** and **recipient scope** — the Strict policy is outranked by another policy, or its recipient conditions do not include that user. This is a real finding, not a bug.
- **Fix:** Confirm with the portal's **configuration analyzer** / policy priority. The effective policy is what applies; document it as the finding.

## Advanced-hunting `EmailEvents` query is empty or times out
- **Symptom:** The threat-coverage signal is missing.
- **Cause:** `AdvancedHunting.Read.All` not consented, hunting retention exceeded, or the window is too broad.
- **Fix:** Consent the read scope (R4), narrow the time window, or accept the retention limit and note it. *Verify current hunting retention for your licensing.*

## Scorecard marks a deliberately allow-listed vendor as a finding
- **Symptom:** An intentional allow-list entry scores as a bypass finding.
- **Cause:** The assessment cannot know an allow-list entry is a deliberate business decision.
- **Fix:** Record it as an **accepted exception** in the review (Stage 7). Risk-acceptance is the customer's decision; annotate so it is not re-flagged each run — but re-confirm it is still needed periodically.

## Report findings don't match the portal on spot-check (Gate 5 fail)
- **Symptom:** A top finding reads differently in the portal than in the report.
- **Cause:** Stale discovery data (config changed after the run) or a scope mismatch.
- **Fix:** Re-run `SOAMDO-Discovery.ps1` immediately before reporting, confirm the same scope, and never deliver a report that fails the reconcile spot-check.

## Validate flags a write capability present
- **Symptom:** Gate 1 fails specifically on the "no write role" assertion.
- **Cause:** The assessor holds an admin role (e.g. Security Administrator, Exchange Administrator) — over-privileged for an assessment.
- **Fix:** Reduce to a read-only role before running. An assessment must not be able to change policy; this is by design.
