# 6. Troubleshooting — Microsoft Purview NIST 800-53 Compliance Program

The failure modes you'll hit building and maintaining a NIST 800-53 program in Purview. Each:
**symptom → likely cause → fix.** Many "the control isn't there" reports are actually licensing, a DLP policy
in the wrong mode, or evidence that was never attached — this guide separates those from real faults.

## The NIST SP 800-53 template isn't listed / can't be added in Compliance Manager
- **Cause A — licensing.** NIST 800-53 is a **premium template** requiring **E5 / E5 Compliance** (and premium
  templates may be metered in your tenant). **Fix:** confirm the plan (`CMPNIST-Scope.ps1`); assign E5/E5
  Compliance; check premium-template availability for your licensing (Requirement 2.1).
- **Cause B — role.** You lack **Compliance Manager Administrator**. **Fix:** assign the Compliance Manager
  role group (Requirement 2.2). **Verify against current Microsoft documentation** — template names/versions
  change.

## `CMPNIST-Scope.ps1` reports a plan is missing but you believe you have E5
- **Cause:** the service-plan name checked (e.g. a compliance/DSPM plan) differs from what your tenant carries,
  or the SKU is assigned but the specific service plan is disabled. **Fix:** treat the check as a **flag, not a
  verdict** — confirm in M365 admin center → `Billing → Licenses` and the Purview portal; plan names change,
  so **verify your licensing/tenant**.

## Discovery shows no DLP policies, but you know some exist
- **Cause A — endpoint/role.** Not connected to **Security & Compliance PowerShell** (`Connect-IPPSSession`),
  or missing the DLP read role. **Fix:** confirm `Connect-IPPSSession` succeeded and the DLP/Compliance role is
  assigned (Requirement 2.2).
- **Cause B — scope.** Policies exist but outside the queried scope. **Fix:** re-run `CMPNIST-Discovery.ps1`
  without scope filters to list all, then narrow.

## DLP policy created but it's blocking users during validation
- **Cause:** the policy was created (or flipped) to **Enable** (enforce) instead of simulation. During
  validation it should be **`TestWithoutNotifications`** (simulation) — detect, don't block.
- **Fix:** confirm `Get-DlpCompliancePolicy | FL Name,Mode`; set it back to simulation
  (`CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "…" -SetMode TestWithoutNotifications -Commit`) until the
  pilot passes, then promote to enforce deliberately (Step 9). Always preview with `-WhatIf` first.

## DLP simulation shows no matches for content you expect it to catch
- **Cause A — propagation latency.** New/changed DLP policies take time to propagate before they evaluate
  content. **Fix:** allow time, then retest.
- **Cause B — condition mismatch.** The rule's sensitive-information-type or label condition doesn't match your
  test content (or the information-type applicability was mis-scoped). **Fix:** review the rule conditions
  against your impact-level data (Requirement 2.4) — *which* information types apply is a compliance/security
  determination, adjust the rule to it. **Fix C — scope:** confirm the pilot group is actually in the policy
  location scope.

## AU evidence is empty for the assessment window
- **Cause:** unified audit logging was enabled **after** the activity, or wasn't on at all — **audit is not
  retroactive**. **Fix:** enable it now (`CMPNIST-Set-ControlPolicy.ps1 -EnableUnifiedAudit -Commit`); evidence
  accrues from enablement forward. There is no way to recover events from before logging was on — capture this
  fact in the package rather than presenting a gap as compliance.

## Audit-retention policy create fails on duration or priority
- **Cause A — duration/licensing.** The `RetentionDuration` value isn't accepted for your plan, or a long-term
  tier is requested without the add-on. **Fix:** verify accepted `RetentionDuration` values and licensing
  (Requirement 2.1) before `-Commit`.
- **Cause B — duplicate priority.** Priorities must be **unique**. **Fix:** pick an unused priority (lower =
  evaluated first).

## Retention-policy / DLP cmdlet "term not recognized"
- **Cause:** wrong endpoint. `*-DlpCompliancePolicy`, `*-Label`, `*-RetentionCompliancePolicy`, and
  `*-UnifiedAuditLogRetentionPolicy` are **Security & Compliance PowerShell** (`Connect-IPPSSession`);
  `Get/Set-AdminAuditLogConfig` is **Exchange Online** (`Connect-ExchangeOnline`). **Fix:** connect with the
  right endpoint for the task; both ship in `ExchangeOnlineManagement`.

## Validation is red for a family you consider covered elsewhere
- **Cause:** the control is implemented **outside Purview** (identity/Conditional Access in **Entra**, endpoint
  config, physical) — Purview has no evidence to show for it. **Fix:** in `NIST 800-53 – Control-to-Purview –
  Map`, mark it **inherited/deferred** and point to the owning system; don't force Purview to "cover" it. The
  validator only checks Purview-covered families.

## Compliance Manager score didn't move after configuring a control
- **Cause:** the improvement action's **evidence/implementation status wasn't updated** in the portal, or the
  test hasn't been marked. Compliance Manager scores off recorded improvement-action status, not off the raw
  tenant state. **Fix:** attach the artifact and set the improvement action's status in the portal
  (Requirement 2.8); scores update on the portal's cadence.

## Assessor says the evidence is insufficient
- **Cause:** evidence sufficiency is the **assessor's / AO's** determination, not the tool's. **Fix:** provide
  the requested additional artifact (policy export, audit snapshot, screenshot) via `CMPNIST-Report.ps1` +
  Discovery outputs. **The sufficiency and authorization judgments are theirs — deferred** — the solution
  supplies artifacts, not the ruling.

## When to escalate beyond this solution
- **Control applicability/tailoring, residual-risk acceptance, the authorization boundary, or the ATO** →
  **Authorizing Official / security / compliance / legal** (this solution configures and evidences; it does
  not authorize).
- **Retention-schedule adequacy or legal hold** → **compliance, records, privacy, and legal**.
- **Insider-risk / communication-compliance outcomes** (if used as SI/AU evidence) → **HR/legal** with
  privacy-by-design and role separation; the solution provides the technical signal, not the case action.
- **Feature genuinely absent despite correct licensing** → verify against current Microsoft documentation and
  open a Microsoft support case; Compliance Manager templates and Purview capabilities evolve.
