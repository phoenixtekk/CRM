# 6. Troubleshooting Guide — Data Classification Framework & Strategy

Common failure modes when standing up the classification framework, with the symptom, the likely
cause, and the resolution. Work top-down; most issues are connectivity, role, licensing, or
publish-scope problems. All fixes stay inside the **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand** model — never enforce to resolve a test problem.

> **Determinations stay deferred.** If a fix implies changing a tier definition, a DLP enforcement
> decision, or a retention period/action, that is a **governance/records/legal** call (see §2) — the
> steps below only correct the *technical* configuration.

---

## Connectivity & permissions

**`Connect-IPPSSession` / `New-Label` / `Get-DlpCompliancePolicy` is not recognized**
- **Cause:** the ExchangeOnlineManagement module is not installed, or the session is not connected.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`, then `Connect-IPPSSession`
  with a modern-auth / MFA admin. Re-run `Get-Label` to confirm the session is live. The scripts call
  `Connect-IPPSSession` if no session is detected — accept the sign-in prompt.

**Cmdlet returns "The operation couldn't be performed because ... access denied" / no results**
- **Cause:** the account lacks the least-privilege role for that control family (§2.2).
- **Fix:** confirm membership in **Information Protection Admin** (labels), **Compliance
  Administrator / DLP Compliance Management** (DLP), and **Records Management / Compliance
  Administrator** (retention) in Purview → **Roles & scopes → Permissions**. Allow role propagation
  (can take time) before retrying.

**A cmdlet parameter is rejected (e.g. `-Mode`, `-EncryptionEnabled`)**
- **Cause:** the S&C PowerShell surface evolved, or the module is out of date.
- **Fix:** `Update-Module ExchangeOnlineManagement`; verify the parameter with `Get-Help New-Label
  -Full`. Portal paths and some parameters change — **verify in your tenant**; do not force a
  parameter the current module does not expose.

## Labels not visible or not protecting

**Tier labels don't appear in Office for pilot users**
- **Cause:** labels are created but **not published**, the user isn't in the pilot group, or the
  client hasn't synced.
- **Fix:** confirm `CLS Policy – Pilot – Ring1` is published to the pilot group (Purview →
  **Information Protection → Label policies**); confirm the user is a member; allow client sync time
  (sign out/in of Office). Labels only surface once a policy publishes them — creating a label is not
  enough.

**Labels visible to users who are NOT in the pilot**
- **Cause:** the label policy is scoped to All users instead of the pilot group.
- **Fix:** re-scope `CLS Policy – Pilot – Ring1` to the pilot group only; do not use
  `-PublishLabels -AllUsers` until Step 10. Rollback: `Remove-LabelPolicy "CLS Policy – Pilot –
  Ring1"` unpublishes without deleting the labels.

**An encrypting tier (`Confidential`/`Restricted`) does not deny an unauthorized user**
- **Cause:** the protection (Azure Rights Management) service is not activated, or the label's
  `EncryptionRightsDefinitions` grant too broadly (§2.7).
- **Fix:** confirm the protection service is **active**; review the rights definition targets the
  intended group only; re-apply the label to a fresh test file (already-protected files keep their
  original policy). **Do not publish broadly** (Step 10) until Test 3 passes.

## DLP baseline issues

**`CLS DLP – Tier2-3 – Test` is blocking / enforcing before sign-off**
- **Cause:** the policy `Mode` was set to `Enable` prematurely.
- **Fix:** `Set-DlpCompliancePolicy "CLS DLP – Tier2-3 – Test" -Mode Disable`, investigate why it was
  enabled, then return it to a **Test** value. Enforcement is Step 10 only, and only after the data
  owner accepts the test-mode match reports (Test 5).

**DLP over-matches or under-matches**
- **Cause:** the rule's sensitive-info-type conditions or instance/confidence thresholds don't align
  to the tier conditions (§2.5).
- **Fix:** tune `New-DlpComplianceRule` conditions (info types, min/max instance counts, confidence),
  re-run in **test**, and re-check the match report. Keep iterating in test — never tune by enabling.

**No DLP match reports appear**
- **Cause:** test content didn't reach an in-scope location, or reporting latency.
- **Fix:** confirm the policy locations (Exchange/SharePoint/OneDrive/Teams) include where you tested;
  allow reporting latency; use clearly-matching **test** data (never real regulated data) for the
  sensitive info type.

## Retention issues

**Tier retention labels not offered to pilot users**
- **Cause:** the retention labels are created (`New-ComplianceTag`) but the publish policy
  (`CLS Retain Publish – Pilot – Ring1`) isn't scoped to the pilot or hasn't propagated.
- **Fix:** confirm `New-RetentionComplianceRule -PublishComplianceTag` published the tier tags to the
  pilot scope; allow propagation (retention publishing can take time to surface in
  SharePoint/Outlook).

**A retention label with a delete action behaved unexpectedly in testing**
- **Cause:** the action/trigger (Keep/Delete, creation vs modification, period) doesn't match the
  intended records/legal determination.
- **Fix:** **halt broad reliance immediately**; review the label's action and trigger with
  records/legal (§2 deferral) before applying it anywhere real. Test 7 must pass on a disposable item
  before any tier with a delete action is trusted.

## Crosswalk / coverage

**`CLSFRAME-Validation.ps1` reports an orphan tier**
- **Cause:** a tier has a label but no retention (or a DLP posture with no matching tier label, etc.)
  — the crosswalk row is incomplete.
- **Fix:** build the missing artifact with `CLSFRAME-FrameworkConfig.ps1` for that tier, then
  re-validate. Do not expand until every tier row is complete and consistently named.

**Live crosswalk (`CLSFRAME-Crosswalk.ps1`) drifts from the signed-off standard**
- **Cause:** config changed outside the standard, or the standard changed without updating config.
- **Fix:** reconcile — either correct the tenant config or update the standard **with governance
  sign-off**. The live crosswalk must equal the standard before expansion (Test 9).

**`CLSFRAME-Coverage.ps1` returns no activity data**
- **Cause:** activity/content explorer (`Export-ActivityExplorerData`) is **E5-tier** and may be
  unlicensed, or there's simply no pilot activity yet.
- **Fix:** **verify your licensing/tenant**; the script degrades to a health-only report when the
  activity API is unavailable. Generate pilot labeling activity, then re-run.

---
### If a step's gate can't be met
Stop at that gate — do **not** work around it by expanding scope or enabling enforcement. Re-run the
relevant read-only script (`Discovery`, `Validation`, `Crosswalk`, `Coverage`), capture the evidence,
and resolve the specific technical cause above (or escalate a *determination* to the accountable
governance/records/legal owner) before proceeding.
