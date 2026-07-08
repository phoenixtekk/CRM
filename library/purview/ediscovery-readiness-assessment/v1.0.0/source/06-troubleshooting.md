# 6. Troubleshooting — eDiscovery Readiness Assessment (Microsoft Purview)

Common readiness failure modes, what causes them, and how to resolve — keyed to the four domains and
the named proof artifacts. Re-run the read-only scripts (`EDREADY-Discovery.ps1`, `EDREADY-Scope.ps1`,
`EDREADY-Validation.ps1`) after each fix to confirm the gate flips to pass.

## Unified audit log is OFF (high-severity H gap)
- **Symptom:** `EDREADY-Discovery.ps1` / `EDREADY-Validation.ps1` report
  `UnifiedAuditLogIngestionEnabled = False`; the Audit solution returns nothing.
- **Cause:** Auditing was never enabled, or was disabled. Without it, preservation actions cannot be
  proven — the defensibility evidence does not exist.
- **Resolve:** `EDREADY-Remediation.ps1 -EnableAudit -Commit` (or Purview → **Audit → turn on**). Then
  **wait** — events take time to populate; re-run validation later. Enabling auditing is a one-way
  readiness improvement; do not disable it.

## No members in the eDiscovery role groups / matters run as Global Admin (R gap)
- **Symptom:** `eDiscovery Manager` / `eDiscovery Administrator` show `(no members)`, or the discovery
  script flags a member who is **also a Global Admin**.
- **Cause:** eDiscovery access was never delegated, or was granted via Global Admin (over-privileged).
- **Resolve:** Add operators with `EDREADY-Remediation.ps1 -AddManagers <upns> -Commit` and the
  lead(s) with `-AddAdministrators <upn> -Commit`; remove standing Global-Admin use for matters. Grant
  eDiscovery **only** through the role groups.

## Only one trained operator (coverage gap, R)
- **Symptom:** Validation flags fewer than two `eDiscovery Manager` members.
- **Cause:** Single point of failure — one person on leave stops a hold.
- **Resolve:** Add and **train** at least a second operator; document who does what. Coverage is part
  of readiness, not just having *a* role holder.

## The readiness-proof hold does not preserve (H — the core proof fails)
- **Symptom:** `Readiness Hold Policy – Proof – Pilot` shows disabled/error, or a deleted seeded item
  on the **test account** is permanently gone (Test 3 fails).
- **Cause:** The hold was not enabled, the policy did not target the test mailbox, replication had not
  completed, or the account is unlicensed for the hold.
- **Resolve:** Confirm the policy/rule exist and are **enabled** over the **test mailbox**
  (`Get-CaseHoldPolicy`/`Get-CaseHoldRule`); allow time for the hold to take effect before deleting a
  test item; verify the test account's licensing. Rebuild with `EDREADY-Remediation.ps1 -BuildProof
  -ProofMailbox <test> -Commit` if needed. Do **not** conclude readiness until preservation is proven.

## Proof hold still present after the assessment (H — cleanup gap)
- **Symptom:** Post-assessment, `Readiness Hold Policy – Proof – Pilot` still exists (Test 4 fails).
- **Cause:** The Stage-D cleanup step was skipped.
- **Resolve:** Remove it — `Remove-CaseHoldRule 'Readiness Hold Rule – Proof – Pilot'` then
  `Remove-CaseHoldPolicy 'Readiness Hold Policy – Proof – Pilot'`. A rehearsal must not leave a
  standing hold; it only ever covered the test account, so removal releases nothing real.

## Inactive / legacy mailboxes not covered (S blind spot)
- **Symptom:** `EDREADY-Scope.ps1` lists inactive mailboxes; the scope note does not account for them.
- **Cause:** Inactive/legacy mailboxes are a classic preservation blind spot — content persists but is
  easy to forget.
- **Resolve:** Inventory every inactive mailbox and confirm whether it is in scope; ensure in-scope
  ones would be covered by a hold. Record the decision in the scope note (a legal/records call on
  what is in scope).

## Teams / M365-Group content missing from scope (S gap)
- **Symptom:** The scope note covers mailboxes but not **Teams chat**, **Teams files**, or **M365
  Group** sites; a collection would under-collect.
- **Cause:** A mailbox-only mental model. **Teams chat lives in mailboxes**; **Teams files and M365
  Group content live in SharePoint/OneDrive.**
- **Resolve:** Add Teams (chat via mailboxes) and M365 Group/Teams sites (SharePoint/OneDrive) to the
  scope note and confirm they are discoverable in the portal — **verify in your tenant.**

## Premium features (custodians / review sets / analytics / export) absent (tier)
- **Symptom:** You cannot create custodians or review sets; Premium readiness cannot be claimed.
- **Cause:** The tenant/operators are licensed for **Standard** only; Premium requires **E5 / E5
  eDiscovery and Audit** (Requirement 2.1).
- **Resolve:** Record the **actual tier** in the scorecard (do not claim Premium review readiness
  without it). If a Premium review workflow is required, assign the licensing, then re-assess. **Plan
  names and gating change — verify in your tenant.**

## Process artifacts missing (P — "tooling but not ready")
- **Symptom:** No matter-intake template, no legal sign-off gate, no naming standard, no change
  control/rollback, no evidence-pack owner (Test 7 fails).
- **Cause:** Readiness was treated as purely technical.
- **Resolve:** Adopt the four process artifacts (documentation deliverables). An org with perfect
  tooling but no intake/sign-off process is **not ready** — scope and holds are legal determinations
  that must be captured *before* configuration.

## PowerShell connect / module errors
- **Symptom:** `Connect-IPPSSession` or `Connect-ExchangeOnline` fails; cmdlets not found.
- **Cause:** Module not installed, or legacy/basic auth.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; connect with **modern
  auth/MFA**. For Premium signals also `Install-Module Microsoft.Graph.Security`. **Never** store
  credentials or app secrets in the scripts (Requirement 2.6).

## Insufficient role to read config
- **Symptom:** Discovery/scope scripts report "could not read" for audit config, mailboxes, or role
  membership.
- **Cause:** The assessor lacks the Purview/Exchange role to read that object.
- **Resolve:** Grant the least-privilege read role (category GR #2 / Requirement 2.2) and re-run — do
  not escalate to Global Admin to work around it.

## Government cloud paths differ
- **Symptom:** Portal paths/hosts in this guide do not match your tenant.
- **Cause:** GCC High / DoD use different hosts (e.g. `*.office365.us`) and some features lag
  Commercial.
- **Resolve:** Use your cloud's portal host and **verify in your tenant**; the cmdlets are the same,
  the paths and availability may differ.
