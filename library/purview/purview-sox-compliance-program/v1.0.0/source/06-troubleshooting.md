# 6. Troubleshooting — Microsoft Purview SOX Compliance Program

The failure modes you'll hit building and maintaining a SOX/ICFR program in Purview. Each: **symptom →
likely cause → fix.** Most "the control isn't there" reports are actually licensing, a DLP policy in
the wrong mode, audit that was enabled too late, or evidence that was never linked — this guide
separates those from real faults. Automation is **Security & Compliance PowerShell**
(`Connect-IPPSSession`) plus **Exchange Online PowerShell** (`Connect-ExchangeOnline`) for the audit
config and unified audit log.

## Unified audit evidence is empty for the review period (the foundation)
- **Cause:** unified audit logging was enabled **after** the activity, or wasn't on — **audit is not
  retroactive**. **Fix:** enable it now (`PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -Commit`);
  evidence accrues from enablement forward. There is no way to recover events from before logging was
  on — capture this fact in the program rather than presenting a gap as coverage.

## The financial-data label doesn't appear for pilot users
- **Cause A — not published.** The label exists but no label policy publishes it to the pilot ring.
  **Fix:** run `PURVSOX-ConfigureControls.ps1 -Control LabelPolicy -PilotUsers "…"` (Step 4).
- **Cause B — propagation latency.** Label-policy changes take time to reach clients. **Fix:** allow
  propagation, then retest applying `Financial – SOX Reporting – Confidential` to a test document.

## The DLP policy is blocking users during the pilot
- **Cause:** the policy was created or flipped to **Enable** (enforce) instead of simulation. During the
  pilot it must be **`TestWithNotifications`** (simulation — reports without blocking).
- **Fix:** confirm `Get-DlpCompliancePolicy "DLP – SOX Financial Data – Simulation" | FL Name,Mode`; set
  it back with `PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "…" -SetMode TestWithNotifications
  -Commit` until the pilot passes, then promote to enforce deliberately (Step 11). Always `-WhatIf` first.

## DLP simulation shows no matches for financial content you expect it to catch
- **Cause A — condition mismatch.** The rule keys off the `Financial – SOX Reporting – Confidential`
  label (and/or financial SITs); the test content doesn't carry the label or match the SIT. **Fix:**
  confirm the test document is labeled / matches, and the workloads (SharePoint/OneDrive/Exchange) are
  in scope.
- **Cause B — propagation latency.** New/changed DLP policies take time to evaluate content. **Fix:**
  allow time, retest.

## Retention or audit-retention create fails on duration or priority
- **Cause A — duration/licensing.** The `RetentionDuration` value isn't accepted for your plan, or a
  long-term tier is requested without the add-on. **Fix:** verify accepted `RetentionDuration` values and
  licensing (Requirement 2.1) before `-Commit`. The retention **period comes from your records schedule
  — the script does not invent one.**
- **Cause B — duplicate priority.** Audit-retention priorities must be **unique**. **Fix:** pick an
  unused priority (lower = evaluated first).

## Retention-policy / DLP / label cmdlet "term is not recognized"
- **Cause:** wrong endpoint. `*-DlpCompliancePolicy`, `*-Label`, `*-RetentionCompliancePolicy`, and
  `*-UnifiedAuditLogRetentionPolicy` are **S&C PowerShell** (`Connect-IPPSSession`);
  `Get/Set-AdminAuditLogConfig` and `Search-UnifiedAuditLog` are **Exchange Online**
  (`Connect-ExchangeOnline`). **Fix:** connect the right endpoint; both ship in `ExchangeOnlineManagement`.

## An evidence runbook returns nothing for activity you know happened
- **Cause A — operation/record-type name.** The operation name doesn't match how the workload logs it
  (names vary by workload/version). **Fix:** confirm the exact operation via a broad
  `Search-UnifiedAuditLog` first, then narrow the runbook.
- **Cause B — ingestion latency / scope.** The event hasn't ingested yet, or the site filter excludes
  it. **Fix:** allow ingestion latency; widen `-Days`; confirm `-FinanceSites` matches the real site URL.
- **Cause C — logging coverage.** The record type wasn't being captured. **Fix:** confirm unified audit
  is on and the audit-retention policy covers those record types (Step 7).

## Compliance Manager score didn't move after configuring a control
- **Cause:** the improvement action's **evidence/implementation status wasn't updated** in the portal.
  Compliance Manager scores off recorded improvement-action status, not raw tenant state. **Fix:** attach
  the runbook artifact and set the action's status in the portal (Step 8); scores update on the portal's
  cadence. Keep the **reviewer separate from the configurer** (SoD).

## Segregation-of-duties gate fails — same person configures and reviews
- **Cause:** the configuring role and the evidence-reviewing role are held by one identity, or Global
  Admin is used for routine control work. **Fix:** separate the roles under change control
  (`PURVSOX-Scope.ps1` shows role membership); record the separation in the Compliance Manager
  assessment. This is an ITGC control in its own right.

## When to escalate beyond this solution
- **Control-design adequacy, operating-effectiveness conclusions, materiality, and whether the evidence
  satisfies the external auditor** → **management / internal audit** (this solution configures and
  evidences the controls; the SOX conclusions are theirs — deferred).
- **Records-retention schedule adequacy / disposition / file-plan** → **records, legal, and finance**
  (this configures retention; it does not decide the schedule).
- **A capability genuinely missing despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; Compliance Manager templates and Purview capabilities
  evolve.
