# 6. Troubleshooting Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Field issues and fixes. Most stem from **licensing/availability** (these features are evolving and
plan-gated), **auditing being off**, or the AI simply **not having been used yet**. When a portal path
differs from this guide, confirm the current equivalent rather than assuming.

## DSPM or DSPM for AI blade is not visible
- **Likely cause:** Licensing (Requirement 2.1) or role membership (Requirement 2.2).
- **Fix:** Confirm the subscription/add-ons in the M365 admin center; confirm your account is in a
  DSPM-capable role group in Purview → Roles & scopes. Run `PURVDSPM-ScopeConfig.ps1` to enumerate what
  your session can see. If the capability is genuinely absent for your plan, scope around it and note it.

## `PURVDSPM-ScopeConfig.ps1` reports the S&C session as FAIL
- **Cause:** Not connected to Security & Compliance PowerShell.
- **Fix:** `Connect-IPPSSession` with a modern-auth/MFA admin (GR §3). Re-run. For the auditing check and
  `Search-UnifiedAuditLog`, also connect Exchange Online (`Connect-ExchangeOnline`).

## DSPM for AI reports are empty
- **Cause 1 — auditing off:** Prompt/response and AI-interaction reporting is sourced from the unified
  audit log. **Fix:** Turn auditing on (Requirement 2.3); `PURVDSPM-ScopeConfig.ps1` shows
  `UnifiedAuditLogIngestionEnabled`. Allow time for records to accumulate.
- **Cause 2 — no AI usage yet:** With no Copilot/AI activity there is nothing to report. **Fix:** This is
  expected pre-adoption — use the oversharing signal (`PURVDSPM-AIExposure.ps1` sharing events) to reduce
  exposure before enabling Copilot.
- **Cause 3 — wrong audit RecordType/Operations:** The record types/operations that surface AI
  interactions evolve. **Fix:** Confirm the current values in Purview → Audit and pass them via
  `-AiRecordTypes` / `-SharingOperations`.

## `Search-UnifiedAuditLog` returns nothing or errors
- **Cause:** Not connected to Exchange Online, auditing off, or the window predates auditing being on.
- **Fix:** `Connect-ExchangeOnline`; confirm auditing on; widen `-Days` within the retained window. Note
  audit data has ingestion latency — very recent activity may not appear yet.

## Auto-labeling or DLP cmdlet fails as "not recognized" / access denied
- **Cause:** Auto-labeling / advanced DLP is unlicensed, or the role lacks configuration rights.
- **Fix:** Confirm licensing (Requirement 2.1) and the configuration role (Requirement 2.2). Reading is
  possible with a lower role than creating; `PURVDSPM-Discovery.ps1` will warn where a feature isn't
  readable.

## `PURVDSPM-Reduce-Oversharing.ps1 -Action DlpForAI` stops asking for `-DlpAiLocation`
- **This is intentional.** The DLP location that scopes a policy to Microsoft 365 Copilot / AI is
  licensing-dependent and evolving, so the script will not assume it. **Fix:** Confirm the exact location
  name in Purview → DLP (or use the DSPM-for-AI one-click "protect sensitive data in Copilot" policy in
  the portal if present), then pass it via `-DlpAiLocation`.

## A pilot policy landed in an enforcing state
- **Cause:** Wrong mode or a manual portal change.
- **Fix:** `PURVDSPM-Reduce-Oversharing.ps1` creates auto-labeling in **simulation**
  (`TestWithoutNotifications`) and DLP in **test** by design. If a policy is enforcing before the gate,
  return it to test/simulation (Set-*Policy -Mode TestWithoutNotifications) and re-validate. Never enforce
  before Testing Test 9 passes.

## Simulation/test shows too many false positives
- **Cause:** Conditions too broad (sensitive-info-type confidence, label scope).
- **Fix:** Tighten the auto-labeling rule conditions / DLP rule and **re-simulate** — do not enforce.
  The whole point of simulation/test is to tune before anyone is affected.

## Recommendations don't change after acting
- **Cause:** Posture re-evaluation latency, or the action didn't address the specific recommendation.
- **Fix:** Allow the portal time to re-evaluate; re-run `PURVDSPM-Tracker.ps1` and compare policy state to
  the baseline. Confirm the change you made maps to the recommendation you intended to close (record the
  mapping in the tracker's Notes column).

## Enforcement broke legitimate collaboration
- **Cause:** A sharing restriction or DLP-for-AI block was too broad.
- **Fix:** Execute the documented rollback — return the policy to test/simulation (or delete it) and
  restore the prior sharing on the affected site. Use `DSPM Recommendations – Estate – Tracker` as the
  before-state, tune conditions, re-simulate, then re-expand.

## Escalation boundary
Regulatory, records-retention, and legal questions — what *must* be restricted or retained, what
AI-exposure level is acceptable, legal-hold implications — are **not** resolved here. Capture the
technical evidence (the exports and tracker) and route the determination to your compliance, records,
privacy, and legal functions (GR §5).
