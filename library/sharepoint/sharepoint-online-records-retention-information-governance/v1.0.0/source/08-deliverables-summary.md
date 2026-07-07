# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what SharePoint records/retention is, how labels/policies/records/disposition
  work, the reference design, what's deferred to records/legal and to the broader Purview program,
  limitations, and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing; the records schedule
  from records/legal; records/retention roles; existing Purview posture; a pilot site set; the S&C
  PowerShell / PnP toolchain; change control + rollback), each with how to verify and implement,
  building on the SharePoint category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every
  artifact named, explicit pass/fail gates per stage, and a documented rollback (including the
  irreversible parts).
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering labels, records
  lock, policies, auto-apply, disposition routing, defensible disposition, Purview alignment, and the
  compliance report.
- **Troubleshooting** — common failure modes (connection/roles, labels not appearing, records not
  locking, disposition not routing, retention conflicts, Government-cloud paths) and resolutions.
- **Best Practices** — durable governance, label/record/disposition, change-safety, and operations
  practices.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-*` (Security & Compliance PowerShell via `Connect-IPPSSession`, PnP via
`Connect-PnPOnline`); no hardcoded credentials. Assessment and reporting are read-only; configuration
scripts default to dry-run / `-WhatIf` and only write when `-Commit` is passed.

1. **`Assess-SpoRetentionPosture.ps1`** — *Discovery (read-only).* Enumerates the in-scope SharePoint
   sites' document libraries, reads each library's default retention label (`Get-PnPLabel`), counts
   labeled vs unlabeled items, and cross-references existing tenant retention labels/policies
   (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`). Produces `Retention Posture – SPO –
   Discovery` (CSV).
2. **`Apply-SpoRetentionLabels.ps1`** — *Retention-label + policy apply (`-WhatIf` default).* Builds/
   verifies retention labels and location/auto-apply policies (`New-ComplianceTag`,
   `New-RetentionCompliancePolicy`/`Rule`) and stages default library labels (`Set-PnPLabel`). Reports
   the intended changes by default; only creates/applies when `-Commit` is passed.
3. **`Set-SpoRecordsDisposition.ps1`** — *Records-declaration + disposition config (`-WhatIf`
   default).* Configures/validates record and regulatory-record labels (`-IsRecordLabel`,
   `-Regulatory`, `-ReviewerEmail`) and confirms the Disposition Management reviewer wiring. Dry-run by
   default; writes only with `-Commit`; refuses to set `-Regulatory` without an explicit confirmation
   switch.
4. **`Get-SpoRecordsComplianceReport.ps1`** — *Retention/records compliance report.* Compiles label
   coverage %, records-declared counts, and pending-disposition counts across the scope into
   `Records Compliance – SPO – Report` (CSV/HTML). Read-only.
5. **`Resolve-SpoRecordsScope.ps1`** — *Scope/health helper.* Resolves the pilot/prod site+library
   scope, checks module/connection health (`Connect-IPPSSession` / `Connect-PnPOnline`), and surfaces
   plan/cloud hints (compliance licensing, Government-cloud endpoints) before configuration. Read-only.
