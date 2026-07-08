# 6. Troubleshooting — Microsoft Purview PCI-DSS Compliance Program

The failure modes you'll hit building and maintaining a PCI-DSS program in Purview. Each: **symptom →
likely cause → fix.** Most "Req 3 isn't covered" reports are actually licensing, a DLP policy in the
wrong mode, audit that was never on, or evidence that was never attached — this guide separates those
from real faults. Automation is **Security & Compliance PowerShell** (`Connect-IPPSSession`) plus
**Exchange Online PowerShell** (`Connect-ExchangeOnline`) for the audit config.

## The PCI-DSS template isn't listed / can't be added in Compliance Manager
- **Cause A — licensing.** PCI-DSS is a **premium template** requiring **E5 / E5 Compliance** (premium
  templates may be metered). **Fix:** confirm the plan (`CMPPCI-Discovery.ps1`); assign E5 / E5
  Compliance; check premium-template availability — **verify entitlement with Microsoft licensing, do
  not assume** (Requirement 2.1).
- **Cause B — role.** You lack **Compliance Manager Administrator**. **Fix:** assign the role group
  (Requirement 2.3). Template names/versions change — **verify against current Microsoft documentation.**

## The cardholder-data DLP is blocking users during the pilot
- **Cause:** the policy was created or flipped to **Enable** (enforce) instead of simulation. During the
  pilot it must be **`TestWithNotifications`** (simulation — audits/notifies, does not block).
- **Fix:** confirm `Get-DlpCompliancePolicy "DLP-PCI-CardholderData" | Select Mode`; roll it back with
  `CMPPCI-Set-Scope.ps1 -SimulateDlp -PolicyName "DLP-PCI-CardholderData" -Commit`. Enforce only after
  05-testing.md passes, deliberately (`-EnforceDlp -Commit -ConfirmEnforce`).

## DLP simulation shows no matches for a test card number
- **Cause A — propagation latency.** New/changed DLP policies take time to propagate before they
  evaluate content. **Fix:** allow time, retest.
- **Cause B — SIT/scope mismatch.** The rule's **Credit Card Number** SIT, confidence, or location scope
  doesn't cover the pilot content. **Fix:** confirm the rule's SIT name matches your tenant, the
  confidence isn't set too high, and the pilot location is in scope (Requirement 2.5/2.6). Always test
  with a **synthetic test PAN**, never a real card.

## The DLP false-matches on non-PAN 16-digit numbers (e.g. order IDs)
- **Cause:** confidence/context too loose. The Credit Card Number SIT uses a **Luhn checksum + context**;
  low confidence lets card-like numbers through. **Fix:** raise the rule's confidence or instance
  threshold, or add context requirements, and re-review the simulation **before** enforcing (Test 7).

## `New-DlpCompliancePolicy` / `Get-RoleGroupMember` — "term is not recognized"
- **Cause:** wrong endpoint. DLP, label, and role-group cmdlets are **S&C PowerShell**
  (`Connect-IPPSSession`); `Get/Set-AdminAuditLogConfig` is **Exchange Online**
  (`Connect-ExchangeOnline`). **Fix:** connect the right endpoint; both ship in `ExchangeOnlineManagement`.

## Unified audit evidence is empty for the assessment window (Req 10)
- **Cause:** unified audit logging was enabled **after** the activity, or wasn't on — **audit is not
  retroactive**. **Fix:** enable it now (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
  $true`); evidence accrues from enablement forward. Add an **audit-retention policy** meeting your
  version's Req 10 retention (Audit (Premium) enables longer retention — verify entitlement). Capture
  the gap honestly rather than presenting it as compliant.

## Compliance Score didn't move after configuring a control
- **Cause:** the improvement action's **implementation/test status and evidence weren't updated** in the
  portal. Compliance Manager scores off recorded improvement-action status, not raw tenant state.
- **Fix:** attach the artifact and set the action's status in the portal (Requirement 2.2/Req 12);
  scores update on the portal's cadence. `CMPPCI-Report.ps1` shows the tenant control state, but the
  **portal export is the authoritative score.**

## Role separation flag: someone is both administrator and contributor
- **Cause:** an identity holds two role groups that PCI-DSS Req 7 wants separated. **Fix:** if the
  overlap wasn't accepted by the governance owners, remove the excess membership with
  `CMPPCI-Set-Scope.ps1 -RoleGroup "…" -Remove user@contoso.com -Commit`. Grant the **minimum** role;
  keep QSA/auditors **read-only**.

## `CMPPCI-Set-Scope.ps1 -EnforceDlp -Commit` didn't enforce
- **Cause:** by design — enforcement is **double-gated**. `-Commit` alone is refused; you must also pass
  `-ConfirmEnforce`. **Fix:** re-run with `-EnforceDlp -Commit -ConfirmEnforce`, and only after all
  05-testing.md gates pass. This prevents an accidental enforce bundled with a membership edit.

## A requirement can't be implemented in Purview (firewalls, segmentation, physical, anti-malware, pen test)
- **Cause:** those controls live in **other systems** — Purview has no configuration for them. **Fix:**
  in `PCI Control Map – Record`, record them as **evidence links** to the owning system, not as Purview
  controls; attach their evidence to the Compliance Manager action. Don't force Purview to "cover" them.

## When to escalate beyond this solution
- **How the CDE is scoped, which SAQ/version applies, and whether the evidence satisfies PCI-DSS** →
  **QSA / compliance / legal** (this solution configures controls, the assessment, and evidence, and
  produces the posture; scope and attestation are theirs — deferred).
- **Whether a false-positive exception is acceptable in the payment workflow** → the **data/payment
  owner** with compliance.
- **A capability genuinely missing despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; Compliance Manager templates and Purview capabilities
  evolve.
