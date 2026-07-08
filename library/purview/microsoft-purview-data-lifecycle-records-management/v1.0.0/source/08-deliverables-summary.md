# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what org-wide data lifecycle & records management is; the **retention policy
  vs retention label** distinction; how records declaration, the file plan, regulatory records,
  event-based retention, and disposition review work across Exchange/SharePoint/OneDrive/Teams;
  retention precedence; the reference design; what's deferred to records/legal, to the broader Purview
  program, and to the SharePoint records product; limitations; and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing for records/advanced
  retention; the retention schedule from records/legal; lifecycle/records roles incl. Disposition
  Management; in-scope workloads; existing Purview posture; SharePoint mechanics referenced not rebuilt;
  the S&C PowerShell / Graph toolchain; change control + rollback), each with how to verify and
  implement, building on the Purview category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every
  artifact named, file plan / event types / labels / policies / label policies / disposition built in
  order, policies staged **disabled** and labels published to the pilot scope, explicit pass/fail gates
  per stage, and a documented rollback that flags the **irreversible** parts (regulatory records,
  completed disposition, elapsed event deletions).
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering toolchain/scope,
  baseline inventory, labels, staged policy, publish/auto-apply, records lock, event-based trigger,
  disposition routing, retention precedence, and the compliance report.
- **Troubleshooting** — common failure modes (connection/roles/plan, labels/policies not appearing or
  applying, records not locking, events not triggering, disposition not routing, retention conflicts,
  Government-cloud paths, propagation latency) and resolutions.
- **Best Practices** — governance/ownership, policy-vs-label discipline, records & file plan,
  event-based retention, change-safety, operations & evidence, and alignment with the broader program.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-IPPSSession` (Security & Compliance PowerShell) and `Connect-MgGraph` where
noted; **no hardcoded credentials**. Assessment and reporting are read-only; configuration scripts
default to dry-run / `-WhatIf` and only write when `-Commit` is passed; regulatory-record actions are
gated behind an explicit `-AllowRegulatory -SignOffRef`.

1. **`Resolve-RetentionScope.ps1`** — *Scope/health helper (read-only).* Checks S&C PowerShell (and
   optional Graph) connectivity, reports the detected cloud/endpoint, confirms Data lifecycle / Records
   management cmdlets are reachable, and resolves the pilot scope — the preflight before Stage 3.
2. **`Assess-RetentionRecordsPosture.ps1`** — *Discovery (read-only).* Inventories existing retention
   labels (record/regulatory flags), retention policies + rules with **workload locations and enabled
   state**, event types, and file-plan descriptors; flags overlaps for retention-precedence review.
   Produces `Retention Posture – Tenant – Discovery` (CSVs).
3. **`Set-RetentionPolicyAndLabels.ps1`** — *Retention-policy + label config helper (`-WhatIf`
   default).* Creates/verifies retention **labels** (`New-ComplianceTag`) and a tenant/pilot retention
   **policy + rule** (`New-RetentionCompliancePolicy`/`-Rule`) from a JSON design; policies are created
   **disabled** and label policies scoped to pilot locations. Dry-run by default; writes with `-Commit`;
   refuses regulatory labels without `-AllowRegulatory -SignOffRef`.
4. **`Set-RecordsFilePlanDisposition.ps1`** — *Records/file-plan/event/disposition config helper
   (`-WhatIf` default).* Creates/verifies **file-plan descriptors** (`New-FilePlanProperty*`) and
   **event types** (`New-ComplianceRetentionEventType`), and validates records/disposition wiring
   (record/regulatory labels and reviewer emails, plus the Disposition Management reminder). Dry-run by
   default; writes with `-Commit`.
5. **`Get-RetentionDispositionReport.ps1`** — *Retention/disposition compliance report (read-only).*
   Compiles label coverage (record/regulatory/event/reviewed/file-plan), policy locations + enabled
   state, and event-type counts into `Lifecycle Compliance – Tenant – Report` (CSV + HTML), flagging
   gaps and pointing reviewers to the portal Disposition queue.
