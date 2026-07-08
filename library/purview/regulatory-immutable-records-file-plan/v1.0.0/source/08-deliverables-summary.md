# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what the immutability + file-plan layer is; the **retention vs record vs
  regulatory-record** distinction; how record labels lock content, how regulatory-record labels are the
  one-way lock, and how the **mapped file plan** (authority / category / department / citation / reference
  ID) makes records reportable and defensible; the reference design; what's deferred to records/legal, to
  the broader lifecycle & records product, and to the SharePoint records product; limitations; and the
  deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing for records management &
  the file plan; the records determination from records/legal; records/file-plan/disposition roles incl.
  Disposition Management; in-scope workloads; existing records posture; SharePoint mechanics referenced
  not rebuilt; the S&C PowerShell / Graph toolchain; change control + rollback with the irreversible parts
  flagged), each with how to verify and implement, building on the Purview category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every artifact
  named, file-plan descriptors built first, record labels created and **mapped**, regulatory labels gated
  behind explicit sign-off and applied only to a disposable test item in pilot, label policies pilot-
  scoped, explicit pass/fail gates per stage, and a documented rollback that flags the **irreversible**
  parts (regulatory records, completed disposition).
- **Testing & Validation** — 10 procedures, each with an explicit pass/fail, covering toolchain/scope,
  baseline inventory, file-plan descriptors, record labels mapped, regulatory labels signed-off-only,
  record declaration locking, the irreversible regulatory lock (disposable test only), publish/auto-apply
  scope, mapping completeness (authority/citation), and the records & file-plan report.
- **Troubleshooting** — common failure modes (connection/roles/plan, record labels not locking, regulatory
  vs record confusion, unmapped labels, auto-apply latency, disposition not routing, Government-cloud
  paths, propagation latency) and resolutions.
- **Best Practices** — governance/ownership, immutability discipline (record vs regulatory), the file plan
  (map everything from day one), change-safety, operations & evidence, and alignment with the broader
  program.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-IPPSSession` (Security & Compliance PowerShell) and `Connect-MgGraph` where
noted; **no hardcoded credentials**. Assessment and reporting are read-only; configuration scripts default
to dry-run / `-WhatIf` and only write when `-Commit` is passed; regulatory-record actions are additionally
gated behind an explicit `-AllowRegulatory -SignOffRef`.

1. **`Resolve-RecordsScope.ps1`** — *Scope/health helper (read-only).* Checks S&C PowerShell (and optional
   Graph) connectivity, reports the detected cloud/endpoint, confirms the Records management / file-plan
   cmdlets are reachable, and resolves the pilot scope — the preflight before Stage 3.
2. **`Assess-RecordsFilePlanPosture.ps1`** — *Discovery (read-only).* Inventories existing labels
   (`Get-ComplianceTag`) with **record / regulatory** flags, action, and duration, and the existing
   **file-plan descriptors** (`Get-FilePlanProperty*`); flags each label as **mapped vs unmapped** and
   identifies reusable descriptors. Produces `Records Posture – Tenant – Discovery` (CSVs).
3. **`Set-FilePlanDescriptors.ps1`** — *File-plan descriptor config helper (`-WhatIf` default).*
   Creates/verifies the **file-plan descriptors** (`New-FilePlanPropertyAuthority` / `-Category` /
   `-SubCategory` / `-Citation` / `-Department` / `-ReferenceId`) from a JSON design, reusing existing
   descriptors rather than duplicating. Dry-run by default; writes with `-Commit`.
4. **`Set-ImmutableRecordLabels.ps1`** — *Record + regulatory label config helper (`-WhatIf` default).*
   Creates/verifies **record labels** (`New-ComplianceTag -IsRecordLabel`) with the **file-plan property
   attached** from the design, and — only with `-AllowRegulatory -SignOffRef` — **regulatory-record
   labels** (`-Regulatory`). Dry-run by default; writes with `-Commit`; refuses regulatory labels without
   the explicit switch + sign-off reference, and refuses to create an **unmapped** record label.
5. **`Get-RecordsFilePlanReport.ps1`** — *Records & file-plan compliance report (read-only).* Compiles
   record/regulatory label counts, **file-plan mapping completeness** (every record label → authority/
   citation/category/department/reference ID), label-policy locations + enabled state, and disposition-
   reviewer pointers into `Records & File Plan – Tenant – Report` (CSV + HTML), flagging any **unmapped**
   record label and pointing reviewers to the portal Disposition queue.
