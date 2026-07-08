# 6. Troubleshooting Guide — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

Field issues and fixes. Most stem from **licensing/availability** (these AI-governance features are new,
evolving, and plan-gated), **auditing being off**, **Copilot/AI not having been used yet**, or a
**privacy/role-separation** misconfiguration. When a portal path differs from this guide, confirm the current
equivalent rather than assuming.

## Communication Compliance, DLP, or DSPM for AI blade is not visible
- **Likely cause:** Licensing (Requirement 2.1) or role membership (Requirement 2.2).
- **Fix:** Confirm the subscription/add-ons in the M365 admin center; confirm your account is in the matching
  role group in Purview → Roles & scopes. Run `AIPROMPT-ScopeConfig.ps1` to enumerate what your session can
  see. If the capability is genuinely absent for your plan, scope around it and note it.

## `AIPROMPT-ScopeConfig.ps1` reports the session as FAIL
- **Cause:** Not connected to Security & Compliance PowerShell / Exchange Online.
- **Fix:** `Connect-IPPSSession` (for policy cmdlets) and `Connect-ExchangeOnline` (for
  `Search-UnifiedAuditLog` and the audit-config check) with a modern-auth/MFA admin (GR §3). For Graph checks,
  `Connect-MgGraph`. Re-run.

## AI usage monitoring is empty (`AIPROMPT-Monitor.ps1` returns nothing)
- **Cause 1 — auditing off:** AI prompt/response monitoring is sourced from the unified audit log. **Fix:**
  Turn auditing on (Requirement 2.3); `AIPROMPT-ScopeConfig.ps1` shows `UnifiedAuditLogIngestionEnabled`.
  Allow time for records to accumulate.
- **Cause 2 — no AI usage yet:** With no Copilot/AI activity there is nothing to monitor. **Fix:** Expected
  pre-adoption — stage the policy so governance is live once Copilot is enabled.
- **Cause 3 — wrong audit RecordType:** The record type/operations that surface AI interactions evolve
  (e.g. `CopilotInteraction`). **Fix:** Confirm the current value in Purview → Audit and pass it via
  `-AiRecordTypes`.

## `Search-UnifiedAuditLog` returns nothing or errors
- **Cause:** Not connected to Exchange Online, auditing off, or the window predates auditing being on.
- **Fix:** `Connect-ExchangeOnline`; confirm auditing on; widen `-Days` within the retained window. Audit
  data has ingestion latency — very recent activity may not appear yet.

## The Communication-Compliance policy can't target Copilot/AI interactions
- **Cause:** The Copilot/AI monitored source is not present in your tenant (licensing/rollout) — this is a
  new, evolving capability.
- **Fix:** Confirm availability in Purview → Communication Compliance when creating the policy. If the source
  is absent, monitor AI prompt/response activity via the audit signal (`AIPROMPT-Monitor.ps1`) and govern the
  content with DLP for AI; add the Communication-Compliance source when it becomes available. **Verify in your
  tenant** — do not assume the source exists.

## Reviewers can see real usernames (anonymization not working)
- **Cause:** Anonymization is off, or the reviewer holds an Investigator (de-anonymized) role.
- **Fix:** Purview → Communication Compliance → **Settings → Privacy** — turn **anonymization on**
  (Requirement 2.4). Confirm Analysts hold the pseudonymized role and only gated Investigators can
  de-anonymize (Requirement 2.2). **This is a privacy gate — do not run the pilot on real people until it is
  correct.**

## `AIPROMPT-Configure-Governance.ps1 -Action DlpForAI` stops asking for `-DlpAiLocation`
- **This is intentional.** The DLP location that scopes a policy to Microsoft 365 Copilot / AI is
  licensing-dependent and evolving, so the script will not assume it. **Fix:** Confirm the exact location name
  in Purview → DLP (or use the DSPM-for-AI one-click "protect sensitive data from Copilot" policy in the
  portal if present), then pass it via `-DlpAiLocation`.

## DLP-for-AI cmdlet fails as "not recognized" / access denied, or the Copilot location is rejected
- **Cause:** Advanced DLP or the Copilot location is unlicensed/absent, or the role lacks configuration
  rights.
- **Fix:** Confirm licensing (Requirement 2.1) and the DLP configuration role (Requirement 2.2). If the
  Copilot location is not offered, use the portal DSPM-for-AI one-click policy where present, or scope to
  monitoring + Communication Compliance only. `AIPROMPT-Discovery.ps1` warns where a feature isn't readable.

## A DLP-for-AI policy landed in an enforcing state
- **Cause:** Wrong mode or a manual portal change.
- **Fix:** `AIPROMPT-Configure-Governance.ps1 -Action DlpForAI` creates the DLP policy in **test** mode by
  design. If a policy is enforcing before the gate, return it to test (`Set-DlpCompliancePolicy -Mode
  TestWithoutNotifications`) and re-validate. Never enforce before Testing Test 8 passes and HR/privacy/legal
  sign off.

## Too many false positives in the pilot
- **Cause:** Conditions too broad (sensitive-info-type confidence, label scope, classifier sensitivity).
- **Fix:** Tighten the Communication-Compliance conditions and/or the DLP rule and **re-run the pilot** — do
  not enforce or expand. The whole point of the limited/test pilot is to tune before anyone is affected.

## Reviewers are overwhelmed after expanding scope
- **Cause:** Match volume at broad scope exceeds reviewer capacity.
- **Fix:** Narrow the Communication-Compliance conditions, confirm reviewer capacity before widening
  (Best Practices), and expand in stages (`AI Governance – Pilot – Ring1` → `AI Governance – Broad – Stage2`).

## Insider Risk "risky AI usage" is unavailable
- **Cause:** The risky-AI-usage template/indicators are preview and licensing-dependent.
- **Fix:** This step is optional (Implementation Step 6). Confirm availability with
  `AIPROMPT-Configure-Governance.ps1 -Action InsiderRiskCheck`; if absent, the Communication-Compliance policy
  and monitoring cover the core scope. **Verify in your tenant** — do not assume the template exists.

## Escalation boundary
HR, regulatory, records-retention, and legal questions — whether a given AI usage is *acceptable*, what a
policy match *means* for an individual, disciplinary action, and records/legal-hold implications — are **not**
resolved here. Capture the technical evidence (the monitoring and validation exports) and route the
determination to your HR, compliance, privacy, and legal functions (GR §5).
