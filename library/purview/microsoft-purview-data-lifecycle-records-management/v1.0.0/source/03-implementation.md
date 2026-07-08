# 3. Implementation Guide

This is the ordered, pilot-first method to implement data lifecycle and records management org-wide in
Microsoft Purview. It follows the house model — **Assess → Design → Configure → Pilot → Validate →
Expand** — and every artifact is named per the convention in Section 1 and reused verbatim in the
scripts. **Retention, records, and disposition changes are high-impact**: policies are staged
**disabled**, labels are published to the **pilot scope only**, and nothing expands tenant-wide until
the Section 5 gates pass. The **retention schedule and all legal determinations are inputs from
records/legal** — this guide implements them, it does not author them.

> **Portal paths evolve and are cloud-dependent.** Paths below are Microsoft Purview portal
> (`purview.microsoft.com`) as of authoring; in GCC/GCC High/DoD the URL and some features differ
> (`*.office365.us`). **Verify the path and feature availability in your tenant/cloud** before relying
> on it. Where a step is plan-dependent, it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: compliance licensing (2.1), the retention schedule from records/legal
   (2.2), roles (2.3), in-scope workloads (2.4), existing posture (2.5), and change control (2.8).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                 # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Directory.Read.All"   # supporting reads only
   ```
3. Run **`Resolve-RetentionScope.ps1`** to confirm module/connection health and surface plan/cloud hints
   before touching anything. **Pass/fail:** both connections succeed and the script reports the expected
   cloud and that Data lifecycle + Records management are reachable.

## Stage 1 — Assess (read-only)
1. Run **`Assess-RetentionRecordsPosture.ps1`** to produce `Retention Posture – Tenant – Discovery`: the
   existing retention labels (`Get-ComplianceTag`, including which are record/regulatory), retention
   policies and rules and their **locations/enabled state**
   (`Get-RetentionCompliancePolicy` / `Get-RetentionComplianceRule`), existing **event types**
   (`Get-ComplianceRetentionEventType`), and **file-plan** descriptors already defined.
2. Review the baseline with the Purview program owners (2.5): what already exists, what a new policy would
   **overlap**, and which labels are owned by the broader program.
3. **Pass/fail (Assess gate):** a complete inventory export exists; overlaps with existing retention are
   identified and understood against retention precedence; no destructive action was taken (read-only).

## Stage 2 — Design (map the schedule to Purview)
Translate the records/legal retention schedule into a concrete artifact map. Produce a design table with,
for each schedule category:
- **Category → artifact:** whether it is covered by a tenant-wide **policy** (the floor), a **label**
  (records/events/review), or both.
- **Retention action + duration:** retain / delete / retain-then-delete, and the period.
- **Trigger:** created / last-modified / labeled / **event** (and which event type).
- **Record status:** none / record / **regulatory record** (regulatory only where records/legal require).
- **File-plan descriptors:** retention **authority**, **category/sub-category**, **department**,
  **citation**, **reference ID**.
- **Disposition:** automatic vs **review** (single/multi-stage) and the named reviewer group.
- **Locations:** which workloads (Exchange / SPO / OneDrive / Groups / Teams).

Name every artifact now (Section 1 table) and record the **pilot scope** `Scope – Lifecycle-Pilot –
Static` (the bounded users/sites/mailboxes to prove on). **Pass/fail (Design gate):** every schedule
category maps to a named artifact with action, duration, trigger, record status, descriptors, disposition,
and locations; records/legal has signed off the mapping (especially any regulatory-record and event-based
categories).

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`.**

### 3a. File plan descriptors (records reportability)
Create the file-plan descriptors the labels will reference so the records inventory is reportable from the
start (S&C PowerShell):
```powershell
New-FilePlanPropertyAuthority   -Name "Authority – Records-Schedule-2026"
New-FilePlanPropertyCategory    -Name "Contracts"
New-FilePlanPropertySubCategory -Name "Vendor-Contracts"
New-FilePlanPropertyCitation    -Name "SOX"      -CitationUrl "https://contoso.example/citations/sox"
New-FilePlanPropertyDepartment  -Name "Finance"
New-FilePlanPropertyReferenceId -Name "REC-CON-001"
```
*(Use the descriptor names your records schedule defines — the above are placeholders. `New-ComplianceTag
-FilePlanProperty` attaches these to a label; the config script builds this object for you.)*

### 3b. Event types (event-based retention)
For each event-based category, create the **event type** the label will use:
```powershell
New-ComplianceRetentionEventType -Name "Event Type – Employee-Termination"
New-ComplianceRetentionEventType -Name "Event Type – Contract-Expiration"
```
Record the operational process for **raising** the event (who, when, and the asset ID / keyword that will
match the affected content). The event itself is raised later (Stage 5 / operations), not at config time.

### 3c. Retention labels (records-grade categories)
Create the retention/record labels via **`Set-RetentionPolicyAndLabels.ps1`** (which wraps
`New-ComplianceTag` with `-WhatIf` default). Each label carries its action, duration, trigger, optional
records setting, file-plan descriptors, and — where reviewed — reviewer emails. Examples of the intent the
script commits with `-Commit`:
```powershell
# Plain retention label (date-based)
New-ComplianceTag -Name "Retention Label – General-3yr – Pilot" -RetentionAction Keep `
  -RetentionDuration 1095 -RetentionType ModificationAgeInDays

# Record label with disposition review (event-based, records-grade)
New-ComplianceTag -Name "Record Label – Contracts-7yr – Pilot" -IsRecordLabel $true `
  -RetentionAction KeepAndDelete -RetentionDuration 2555 -RetentionType EventAgeInDays `
  -EventType "Event Type – Contract-Expiration" -ReviewerEmail "records-reviewers@contoso.com" `
  -FilePlanProperty $filePlanObject

# Regulatory record label — ONE-WAY. Only where records/legal require; gated behind an explicit switch.
New-ComplianceTag -Name "Regulatory Record Label – Financial-7yr – Pilot" -Regulatory $true `
  -RetentionAction Keep -RetentionDuration 2555 -RetentionType CreationAgeInDays
```
> **Regulatory records are irreversible.** The config script refuses to set `-Regulatory` without an
> explicit confirmation switch and a records/legal sign-off reference. Do not apply regulatory labels in a
> pilot beyond a disposable test item.

### 3d. Retention policies (the tenant-wide floor)
Create the baseline retention policy **disabled**, with the in-scope locations, then attach its rule
(action + duration). `Set-RetentionPolicyAndLabels.ps1` stages this with `-WhatIf`; with `-Commit` it runs:
```powershell
New-RetentionCompliancePolicy -Name "Retention Policy – Tenant-Baseline – Pilot" -Enabled $false `
  -ExchangeLocation All -SharePointLocation All -OneDriveLocation All `
  -ModernGroupLocation All -TeamsChannelLocation All -TeamsChatLocation All
New-RetentionComplianceRule -Policy "Retention Policy – Tenant-Baseline – Pilot" `
  -RetentionComplianceAction Keep -RetentionDuration 1095 -RetentionDurationDisplayHint Days
```
For the pilot, scope the policy to the **pilot locations only** (specific mailboxes/sites) rather than
`All`, or use an **adaptive scope** limited to the pilot — created in **Data lifecycle management →
Adaptive scopes** and attached with `-AdaptiveScopeLocation`. **Leave `-Enabled $false` until validated.**

### 3e. Label policies (publish / auto-apply to the pilot)
Publish labels to the pilot users, or auto-apply by condition, scoped to the pilot:
```powershell
# Publish labels for users to apply (pilot scope)
New-RetentionCompliancePolicy -Name "Label Policy – User-Publish – Pilot" `
  -ExchangeLocation "pilotuser@contoso.com" -SharePointLocation "https://contoso.sharepoint.com/sites/LifecyclePilot"
New-RetentionComplianceRule -Policy "Label Policy – User-Publish – Pilot" `
  -PublishComplianceTag "Retention Label – General-3yr – Pilot"

# Auto-apply a label by condition (pilot scope) — condition from the schedule, not invented
New-RetentionCompliancePolicy -Name "Label Policy – Contracts-AutoApply – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/LifecyclePilot"
New-RetentionComplianceRule -Policy "Label Policy – Contracts-AutoApply – Pilot" `
  -ApplyComplianceTag "Record Label – Contracts-7yr – Pilot" -ContentMatchQuery '"master services agreement"'
```
*(SharePoint default-library-label application is deferred to the SharePoint records/retention product.)*

### 3f. Disposition reviewers
Ensure the named reviewer accounts are in the **Disposition Management** role group (2.3) so the labels'
`-ReviewerEmail` recipients can act on the Disposition queue in the portal. **Pass/fail (Configure gate):**
every designed artifact exists (labels, policies disabled, label policies pilot-scoped, event types, file
plan), reviewers are in Disposition Management, and no policy is enabled tenant-wide yet.

## Stage 4 — Pilot (prove on the bounded scope)
1. **Enable the pilot-scoped policy:** set `Retention Policy – Tenant-Baseline – Pilot` (scoped to pilot
   locations) `-Enabled $true`; confirm the label policies are published/auto-applying to the pilot only.
2. Apply/observe labels on pilot content: publish appears for pilot users; auto-apply matches; a record
   label **locks** a declared test item; an event-based label shows "retention starts on event".
3. Raise a **test retention event** for an event-based category on a disposable test asset:
   ```powershell
   New-ComplianceRetentionEvent -Name "TEST – Contract-Expiration – Pilot" `
     -EventType "Event Type – Contract-Expiration" -EventTags "Record Label – Contracts-7yr – Pilot" `
     -AssetId "TEST-ASSET-001"
   ```
4. Allow for **propagation** (hours to days — do not judge in minutes). Then run the Stage 5 validation.
5. **Pass/fail (Pilot gate):** on pilot content, policies and labels apply as designed, records lock,
   event-based retention triggers, and disposition-configured items are routed to review — all without
   affecting content outside the pilot scope.

## Stage 5 — Validate
Run **`Get-RetentionDispositionReport.ps1`** to produce `Lifecycle Compliance – Tenant – Report` and work
the Section 5 test procedures. Every gate has an explicit pass/fail. Do not expand until all pass.

## Stage 6 — Expand (enforce tenant-wide)
1. Mint the **production** artifacts by swapping `– Pilot` for `– Prod` (never edit a validated pilot
   artifact in place): e.g. `Retention Policy – Tenant-Baseline – Prod`, `Record Label – Contracts-7yr –
   Prod`, `Label Policy – User-Publish – Prod`.
2. Broaden locations to the full workloads (or attach **adaptive scopes** so policies track locations
   automatically), and enable under change control.
3. Stage the rollout in **rings** (e.g. by department/site) rather than a single tenant-wide flip where
   the schedule allows; re-run reporting after each ring.
4. **Pass/fail (Expand gate):** production policies/labels apply across the in-scope workloads, the
   compliance report shows expected coverage, disposition queues are populated for reviewed categories,
   and no unexpected retention conflicts appear.

---

## Rollback (per stage)
- **Retention/label policies (reversible):** disable the policy (`Set-RetentionCompliancePolicy -Enabled
  $false`) or reduce its locations; unpublish a label policy by disabling/removing its rule. Disabling a
  **retain-and-delete** policy stops future deletions from that policy.
- **Retention labels (reversible if not a record):** remove a non-record label from items and delete the
  unused label. A published label can be unpublished; auto-apply can be disabled.
- **Records (partly reversible):** a **non-regulatory** record can be **un-declared** by a records manager
  (auditable); this restores edit/delete. **Do this only per records/legal direction.**
- **IRREVERSIBLE — no rollback:** a **regulatory-record** label (cannot be removed/shortened), a
  **completed disposition** (content permanently deleted), and an **elapsed event-based deletion**. These
  are gated on records/legal sign-off and must never be exercised beyond a disposable test item in pilot.

Every production change carries a change ticket, an approver, and this rollback written out for the
specific categories in scope, with irreversible categories explicitly flagged **no-rollback**.
