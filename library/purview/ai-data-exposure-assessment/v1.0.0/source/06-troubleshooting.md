# 6. Troubleshooting Guide — AI Data-Exposure Assessment (Microsoft Purview)

Field issues and fixes. Most stem from **licensing/availability** (these features are evolving and
plan-gated), **auditing being off**, the AI simply **not having been used yet** (a legitimate pre-adoption
state), or a **tenant-specific audit RecordType / sharing Operation** that differs from the default. When a
portal path or cmdlet differs from this guide, confirm the current equivalent rather than assuming.

## DSPM for AI blade is not visible
- **Likely cause:** Licensing (Requirement 2.1) or role membership (Requirement 2.2).
- **Fix:** Confirm the subscription/add-ons in the M365 admin center; confirm your account is in a
  DSPM-for-AI-capable role group in Purview → Roles & scopes. Run `AIEXPOSE-ScopeCheck.ps1` to enumerate
  what your session can see. If the capability is genuinely absent for your plan, scope around it and note
  it — the reachability signal from the audit log still supports the assessment.

## `AIEXPOSE-ScopeCheck.ps1` reports the S&C session as FAIL
- **Cause:** Not connected to Security & Compliance PowerShell.
- **Fix:** `Connect-IPPSSession` with a modern-auth/MFA admin (GR §3). Re-run. For the auditing check and
  `Search-UnifiedAuditLog`, also connect Exchange Online (`Connect-ExchangeOnline`).

## The AI-interaction signal is empty
- **Cause 1 — pre-adoption:** With no Copilot/AI usage there is nothing to report yet. **Fix:** This is
  expected — the assessment is in **pre-adoption** mode; use the oversharing signal
  (`AIEXPOSE-Discovery.ps1` broad-sharing events) to quantify exposure *before* enabling AI.
- **Cause 2 — auditing off:** AI-interaction and sharing signal is sourced from the unified audit log.
  **Fix:** Turn auditing on (Requirement 2.3); `AIEXPOSE-ScopeCheck.ps1` shows
  `UnifiedAuditLogIngestionEnabled`. Allow time for records to accumulate.
- **Cause 3 — wrong audit RecordType:** The record type that surfaces AI/Copilot interactions evolves.
  **Fix:** Confirm the current value in Purview → Audit and pass it via `-AiRecordType`.

## `Search-UnifiedAuditLog` returns nothing or errors
- **Cause:** Not connected to Exchange Online, auditing off, or the window predates auditing being on.
- **Fix:** `Connect-ExchangeOnline`; confirm auditing on; widen `-Days` within the retained window. Note
  audit data has ingestion latency — very recent activity may not appear yet.

## The oversharing / broad-sharing export is empty but you expect sharing
- **Cause:** The default sharing **Operations** don't match what your tenant logs, or the window is too
  short.
- **Fix:** Confirm the current sharing Operations in Purview → Audit and pass them via `-SharingOperations`;
  widen `-Days`. The script parameterizes these precisely because they evolve — it does not assume them.

## Discovery shows a thin taxonomy / no DLP
- **This is a finding, not an error.** Label coverage and DLP scope bound how much exposure a fix could
  reduce; their absence raises exposure. `AIEXPOSE-RiskRegister.ps1` applies a **no-lever penalty** when no
  DLP exists so this surfaces at the top of the register. Record it as a top recommendation, not a script
  failure.

## `AIEXPOSE-RiskRegister.ps1` produces an empty register
- **Cause:** No broad-sharing signal in the window (often genuine pre-adoption), or the reachability export
  wasn't produced.
- **Fix:** Confirm `AIEXPOSE-Discovery.ps1` ran (with Exchange Online connected) and wrote `Oversharing Exposure – Sites – Assess`; widen
  the reachability `-Days`. An empty register can be a valid result — `AIEXPOSE-Validate.ps1` reports it as
  a WARN (pre-adoption), not a FAIL.

## Auto-labeling cmdlet fails as "not recognized" / access denied
- **Cause:** Auto-labeling is unlicensed, or the role lacks the (simulation) policy-creation right.
- **Fix:** Confirm licensing (Requirement 2.1) and the configuration role (Requirement 2.2). Reading is
  possible with a lower role than creating; if you cannot create the simulation policy, the assessment can
  still hand off the ranked register and validate the fix path later once the role/licensing is in place.

## The pilot policy landed in an enforcing mode
- **Cause:** Wrong mode or a manual portal change.
- **Fix:** `AIEXPOSE-PilotRemediation.ps1` creates auto-labeling only in **simulation**
  (`TestWithoutNotifications`) by design and never enforces. If a policy is enforcing, return it to
  simulation (`Set-AutoSensitivityLabelPolicy -Mode TestWithoutNotifications`) or delete it.
  `AIEXPOSE-Validate.ps1` flags any non-simulation mode as a **FAIL** — this assessment does not enforce.

## Simulation results show too many would-be labels (false positives)
- **Cause:** The auto-labeling rule conditions (sensitive-info-type confidence, scope) are too broad.
- **Fix:** Tighten the rule conditions and re-simulate. The simulation exists precisely to tune the fix
  path before anyone decides to enforce it — that tuning is part of validating the recommendation, not a
  defect.

## The assessment "changed" something
- **It should not have.** Every script is read-only except `AIEXPOSE-PilotRemediation.ps1`, which requires
  `-Commit` and only ever creates a **simulation** policy that labels nothing. If you believe content
  changed, run `AIEXPOSE-Validate.ps1` and confirm the pilot policy mode; delete the simulation policy to
  return to a fully read-only state.

## Escalation boundary
Regulatory, records-retention, and legal questions — *which* risks must be remediated, what AI-exposure
level is acceptable, legal-hold implications — are **not** resolved here. Capture the technical evidence
(the exports and the ranked register) and route the determination to your compliance, records, privacy, and
legal functions (GR §5). Enforcing a validated fix is a separate, change-controlled follow-on, not part of
this assessment.
