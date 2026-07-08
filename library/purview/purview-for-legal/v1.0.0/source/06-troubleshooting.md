# 6. Troubleshooting — Microsoft Purview for Legal

Common failure modes across the four control domains and their fixes. Each: **Symptom → Likely cause →
Resolution.** Stay read-only or `-WhatIf` while diagnosing; keep high-impact changes (encryption, DLP
enforcement, regulatory records) piloted. Determinations (privilege, matter mapping, retention, legal
hold) stay with legal/records — a "fix" here means the *control* behaves as designed, not that the
program *satisfies* a legal obligation.

## A capability is missing from the portal or a cmdlet errors "not recognized"
- **Likely cause:** the feature is **not licensed** (encryption labels, Teams/Endpoint DLP,
  records/regulatory records, Audit Premium need **E5 / E5 Compliance**), or the module/role is missing.
- **Resolution:** run `INDLEGAL-Discovery.ps1` licensing section and confirm the plan is present **and
  assigned to the legal population**; **verify plan/service-plan names for your tenant — they change.**
  Install `ExchangeOnlineManagement` / `Microsoft.Graph`, and confirm the least-privilege role
  (Requirement 2.2). A missing plan is a licensing gap, not a config defect.

## Sensitivity labels don't appear for pilot users
- **Likely cause:** the label **policy** isn't published to those users, or publication latency (labels
  can take time to appear in Office/Outlook).
- **Resolution:** `Get-LabelPolicy` — confirm `Legal Pilot – Privileged Data – Stage1` targets the pilot
  population; wait for propagation and re-check. Confirm the user's app is signed in with the licensed account.

## The privileged label doesn't encrypt, or encrypts the wrong people out
- **Likely cause:** encryption isn't enabled on the label, or the **permission/decryption scope** doesn't
  match legal's approved design (external counsel/courts blocked, or too broad).
- **Resolution:** `Get-Label` — confirm `EncryptionEnabled`/`EncryptionProtectionType` on
  `Protect – Legal Privileged – Restricted`; set the rights/permissions **to legal's approved scope**
  in-portal. **Test with benign content**, confirm intended internal/external recipients can open it.
  **Do not broaden decryption beyond legal's approval.** Remember already-encrypted content stays
  encrypted by design.

## DLP is over-matching — it flags legitimate legal sharing
- **Likely cause:** the rule's match criteria (labels / sensitive info types) are too broad, or there are
  no exceptions for approved co-counsel/court/client sharing.
- **Resolution:** because the policy is **in simulation**, nothing is blocked — review the simulation
  match report, tune the rule (tighten info types, match on the privileged/matter **labels**, add the
  external-sharing exceptions legal specified) **still in simulation**, and re-review. Match criteria are
  **legal's determination** — operationalize what they define. **Do not switch to Enable until the match
  review is clean and legal signs off.**

## DLP appears to "do nothing"
- **Likely cause:** this is expected — the policy is in **simulation/test** mode (`TestWithNotifications`
  / `TestWithoutNotifications`), which surfaces matches but **blocks nothing** by design.
- **Resolution:** confirm mode with `Get-DlpCompliancePolicy` / `INDLEGAL-Discovery.ps1`. Review the
  **simulation matches** in-portal; that *is* the pilot working. Move to `Enable` **in-portal only** after
  match review and legal sign-off (Implementation Step 9). Note Teams/Endpoint locations require E5.

## Matter-records retention isn't preserving content
- **Likely cause:** the publish policy isn't scoped to the matter workloads, the label isn't a **record**
  label, or publication latency.
- **Resolution:** `Get-RetentionCompliancePolicy` / `Get-ComplianceTag` — confirm
  `Retention – Legal Matter Records – Publish` covers the pilot matter sites and the label has
  `IsRecordLabel = $true`; correct scope/type with `INDLEGAL-Configure.ps1 -Control Retention` and
  re-verify. Retention duration is **records' determination**.

## A regulatory-records label can't be removed or shortened
- **Likely cause:** this is **by design** — a **regulatory record** label is immutable, non-removable, and
  its retention cannot be shortened.
- **Resolution:** there is no "fix" — this is the intended irreversibility. This is exactly why you
  **pilot with a non-regulatory label first** and apply the regulatory label only under explicit
  legal/records sign-off, on the approved scope. **Verify the exact behavior in your tenant before wider
  application.** When in doubt, stop.

## Disposal happened (or is about to) on content legal needs held
- **Likely cause:** a matter is under (or should be under) a **legal hold** that overrides disposal, but
  the hold interaction wasn't coordinated with retention/disposition.
- **Resolution:** **legal hold is the legal function's action in eDiscovery** — refer it to legal to
  create/confirm the hold; this solution only **references** hold coverage read-only
  (`Get-CaseHoldPolicy` in `INDLEGAL-Discovery.ps1`). Surface the retention↔hold interaction; do **not**
  create, release, or scope a hold yourself. Configure `Disposition – Legal Records – Review` so disposal
  is reviewed, not automatic.

## Audit shows no evidence / `Get-AdminAuditLogConfig` unavailable
- **Likely cause:** unified audit ingestion is **off** (it can be disabled and is **not retroactive**), or
  `Get-AdminAuditLogConfig` needs an **Exchange Online** (not just S&C) connection.
- **Resolution:** `Connect-ExchangeOnline`, confirm `UnifiedAuditLogIngestionEnabled = True`; enable under
  change control if off. Then confirm `Audit Retention – Legal Evidence – LongTerm` exists with the agreed
  duration/priority (`Get-UnifiedAuditLogRetentionPolicy`). No evidence is written for the period ingestion
  was off.

## "Which cmdlet / which endpoint?" confusion
- **Likely cause:** label/DLP/retention/hold cmdlets live in **Security & Compliance PowerShell**
  (`Connect-IPPSSession`); `Get-AdminAuditLogConfig` lives in **Exchange Online**
  (`Connect-ExchangeOnline`); licensing reads use **Microsoft Graph** (`Connect-MgGraph`).
- **Resolution:** connect to the right endpoint for the task; `INDLEGAL-Discovery.ps1` /
  `INDLEGAL-Scope.ps1` report which endpoints are reachable. Confirm cmdlet availability for your tenant —
  the portal and cmdlet surface evolve.

## The evidence binder has gaps (MISSING/REVIEW rows)
- **Likely cause:** a control isn't configured yet, or a control exists with no captured proof.
- **Resolution:** `INDLEGAL-Report.ps1` lists each control's Status — fill the specific gap (configure the
  missing control or capture its proof) and re-run. A control with no evidence fails an audit. Cross-check
  every row against `Control Map – Legal – Purview`.

## Validation scorecard is red after changes
- **Likely cause:** a policy slipped (DLP reverted to test post-enforcement, a label unpublished, retention
  disabled, audit turned off, a lapsed license).
- **Resolution:** run `INDLEGAL-Validate.ps1`, address the specific red gate, and re-run. Schedule the
  read-only chain (`Discovery → Validate → Report`) so drift is caught before an auditor or opposing party
  finds it. Use `-RequireEnforced` on `INDLEGAL-Validate.ps1` post-expand to assert DLP is in Enable.

> **Boundary reminder:** these fixes make the **control** behave as designed. Whether the control
> **satisfies** a legal obligation — privilege determination, matter mapping, retention adequacy,
> disposition triggers, legal-hold scope — is a **legal/records determination**. **Legal holds and
> eDiscovery actions remain the legal function's; verify capability availability against your licensing
> and current Microsoft documentation.**
