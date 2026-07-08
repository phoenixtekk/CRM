# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
- **Solution Overview** — what event-based retention is and why the calendar cannot express it; the
  **event type → event-based label → retention event** mechanic; **asset-ID vs keyword** triggering (the
  `Compliance Asset Id` property for SharePoint/OneDrive, keywords for Exchange); how content sits **pending**
  until an event is raised; the reference design; what's deferred to records/legal and to the broader data
  lifecycle & records product; limitations; and the deployment model.
- **Requirements Guide** — solution-specific prerequisites (compliance licensing for event-based retention/
  records; the event-based schedule from records/legal; the **system of record and event-raise process**;
  the **asset-ID / keyword matching strategy and its data**; roles incl. event-raise authorization; in-scope
  workloads; alignment with the broader program; the S&C PowerShell / Graph toolchain; change control +
  rollback), each with how to verify and implement, building on the Purview category global requirements.
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, with every artifact
  named, event types / labels / label policies built in order, asset IDs stamped on pilot content, the
  trigger proven by a **test event on a disposable asset**, explicit pass/fail gates per stage, and a
  documented rollback that flags the **irreversible** parts (elapsed event-based deletions, regulatory
  records).
- **Testing & Validation** — 9 procedures, each with an explicit pass/fail, covering toolchain/scope,
  baseline inventory, event types, label-to-event-type binding, publish/auto-apply scope, the pending state,
  asset-ID / keyword matching data, the test event starting the clock on exactly the matching content, and
  reporting.
- **Troubleshooting** — common failure modes (connection/roles/plan, labels not appearing or applying, the
  clock never starting, events matching nothing or too much, asset-ID not stamped, wrong event date,
  Government-cloud differences, propagation latency) and resolutions.
- **Best Practices** — governance/ownership, the raise process as the deliverable, asset-ID / keyword
  matching, change-safety, operations & evidence, and alignment with the broader program.
- **Executive Summary** — the outcome, approach, and why it is low-risk, for decision-makers.

## PowerShell scripts (5)
All use modern-auth `Connect-IPPSSession` (Security & Compliance PowerShell) and `Connect-MgGraph` where
noted; **no hardcoded credentials**. Assessment, validation, and reporting are read-only; the configuration
script (including event-raising) defaults to dry-run / `-WhatIf` and only writes when `-Commit` is passed;
regulatory-record actions are gated behind an explicit `-AllowRegulatory -SignOffRef`, and raising a real
event is a deliberate, gated action.

1. **`Resolve-EventRetentionScope.ps1`** — *Scope/health helper (read-only).* Checks S&C PowerShell (and
   optional Graph) connectivity, reports the detected cloud/endpoint, confirms the event-based retention
   cmdlets (`Get-ComplianceRetentionEventType`, `Get-ComplianceTag`, `Get-ComplianceRetentionEvent`) are
   reachable, and resolves the pilot scope — the preflight before Stage 3.
2. **`Get-EventRetentionPosture.ps1`** — *Discovery (read-only).* Inventories existing **event types**,
   existing **event-based labels** (those with an `Event*` retention type, with their `EventType` and
   record/regulatory flags), the **label policies** publishing/auto-applying them, and any **raised events**.
   Produces `Event Retention Posture – Tenant – Discovery` (CSVs), flagging duplicates and orphans.
3. **`Set-EventTypesAndLabels.ps1`** — *Configuration/remediation helper (`-WhatIf` default).* Creates/verifies
   **event types** (`New-ComplianceRetentionEventType`) and **event-based labels** (`New-ComplianceTag
   -RetentionType EventAgeInDays -EventType …`) from a JSON design, and — with `-RaiseEvent` — raises a
   retention event (`New-ComplianceRetentionEvent`) against asset IDs / keywords. Dry-run by default; writes
   only with `-Commit`; refuses regulatory labels without `-AllowRegulatory -SignOffRef`; test events on
   disposable assets.
4. **`Test-EventRetentionConfig.ps1`** — *Validation (read-only).* Checks each designed event type exists,
   each label uses an **event** trigger bound to the **correct** event type, label policies target the pilot
   scope, and reports asset-ID / keyword readiness and linkage gaps — the Stage 5 gate check. Makes no
   changes.
5. **`Get-EventRetentionReport.ps1`** — *Compliance report (read-only).* Compiles event-type coverage,
   event-based label coverage (event type / record / regulatory / action / duration), and raised events into
   `Event Retention Compliance – Tenant – Report` (CSV + HTML), flagging gaps (labels with no event type,
   event types with no label, events that matched nothing) and pointing to the portal for disposition.
