# 3. Implementation Guide

This is the ordered, pilot-first method to implement event-based retention in Microsoft Purview. It follows
the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — and every artifact is named
per the convention in Section 1 and reused verbatim in the scripts. **Raising a retention event starts real
retention clocks** and is high-impact: labels are published to the **pilot scope only**, test events are
raised on **disposable assets only**, and nothing drives real content until the Section 5 gates pass. The
**event-based schedule and all legal/records determinations are inputs from records/legal** — this guide
implements them, it does not author them.

> **Portal paths, property names, and cmdlet parameters evolve and are cloud-dependent.** Paths and
> parameters below are Microsoft Purview portal (`purview.microsoft.com`) / Security & Compliance PowerShell
> as of authoring; in GCC/GCC High/DoD the URL and some features differ (`*.office365.us`,
> `Connect-IPPSSession -ConnectionUri`). **Verify paths, the `Compliance Asset Id` property, and cmdlet
> parameters in your tenant/cloud** before relying on them. Where a step is plan-dependent, it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: licensing (2.1), the event-based schedule (2.2), the system of record and
   raise process (2.3), the asset-ID/keyword strategy (2.4), roles incl. event-raise authorization (2.5),
   in-scope workloads (2.6), existing posture (2.7), and change control (2.9).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                 # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Directory.Read.All"   # supporting reads only
   ```
3. Run **`Resolve-EventRetentionScope.ps1`** to confirm module/connection health, report the detected cloud,
   confirm the event/label cmdlets are reachable, and resolve the pilot scope before touching anything.
   **Pass/fail:** connections succeed, the expected cloud is reported, event-based retention cmdlets are
   reachable, and `Scope – EventRetention-Pilot – Static` resolves.

## Stage 1 — Assess (read-only)
1. Run **`Get-EventRetentionPosture.ps1`** to produce `Event Retention Posture – Tenant – Discovery`: existing
   **event types** (`Get-ComplianceRetentionEventType`), existing **event-based labels** (`Get-ComplianceTag`
   filtered to an `Event*` retention type, with record/regulatory flags and their `EventType`), the **label
   policies** that publish/auto-apply them (`Get-RetentionCompliancePolicy`/`-Rule`), and any **retention
   events** already raised (`Get-ComplianceRetentionEvent`).
2. Review the baseline with the retention/records program owners (2.7): which event types already exist (do
   not duplicate), which labels are owned by the broader program, and any overlap to reason through against
   retention precedence.
3. **Pass/fail (Assess gate):** a complete inventory export exists; existing event types/labels are
   identified so none are duplicated; no destructive action was taken (read-only).

## Stage 2 — Design (map the schedule to event types, labels, and triggers)
Translate the records/legal event-based schedule into a concrete artifact map. Produce a design table with,
for each event-based category:
- **Event → event type:** the real-world event and its named `Event Type – …`.
- **Post-event action + duration:** retain / retain-then-delete, and the period that begins **after** the
  event.
- **Record status:** none / record / **regulatory record** (regulatory only where records/legal require;
  records declaration mechanics deferred to the records product).
- **Matching mechanism + data:** **asset ID** (which identifier — employee ID / contract number / SKU — and
  who stamps the `Compliance Asset Id`, when) or **keyword** (the query, and where it applies).
- **Locations + application:** which workloads (SPO / OneDrive / Exchange) and how the label is applied
  (published / auto-apply / default).
- **Raise process:** the system of record, the signal, the owner who raises the event, and the asset-ID /
  keyword values that will be supplied.

Name every artifact now (Section 1 table) and record the **pilot scope** `Scope – EventRetention-Pilot –
Static`. **Pass/fail (Design gate):** every event-based category maps to a named event type, a named label
(with post-event action, duration, record status), a defined matching mechanism **with a stamping/keyword
plan**, locations/application, and a raise process; records/legal has signed off the mapping (especially any
regulatory-record categories).

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`.**

### 3a. Event types
Create the event type per category (S&C PowerShell). `Set-EventTypesAndLabels.ps1` stages these with
`-WhatIf`; with `-Commit` it runs:
```powershell
New-ComplianceRetentionEventType -Name "Event Type – Employee-Termination"
New-ComplianceRetentionEventType -Name "Event Type – Contract-Expiration"
New-ComplianceRetentionEventType -Name "Event Type – Product-EndOfLife"
```
Reuse an existing event type from the assessment rather than creating a duplicate.

### 3b. Event-based labels
Create each event-based retention/record label, bound to its event type, via
**`Set-EventTypesAndLabels.ps1`** (which wraps `New-ComplianceTag` with a `-WhatIf` default). The retention
trigger is an **event** type (`-RetentionType EventAgeInDays`) and the duration is the period that begins
**after** the event. Examples of the intent the script commits with `-Commit`:
```powershell
# Event-based retention label (retain N years after the event, then delete)
New-ComplianceTag -Name "Retention Label – Termination-7yr – Pilot" `
  -RetentionAction KeepAndDelete -RetentionDuration 2555 `
  -RetentionType EventAgeInDays -EventType "Event Type – Employee-Termination"

# Event-based RECORD label (records-grade; records mechanics deferred to the records product)
New-ComplianceTag -Name "Record Label – Contracts-EventExpiry-7yr – Pilot" -IsRecordLabel $true `
  -RetentionAction KeepAndDelete -RetentionDuration 2555 `
  -RetentionType EventAgeInDays -EventType "Event Type – Contract-Expiration"
```
> **Regulatory records are irreversible.** Where a category is a regulatory record, the config script refuses
> to set the regulatory flag without an explicit confirmation switch and a records/legal sign-off reference.
> Do not apply a regulatory event-based label beyond a disposable test item in pilot. *(Verify the exact
> `-RetentionType` value and record parameters for event-based labels in your tenant/module version.)*

### 3c. Label policies (publish / auto-apply to the pilot)
Publish the labels to pilot users, or auto-apply by condition, scoped to the **pilot only**:
```powershell
# Publish event-based labels for users to apply (pilot scope)
New-RetentionCompliancePolicy -Name "Label Policy – EventBased-Publish – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/EventRetentionPilot" `
  -OneDriveLocation "https://contoso-my.sharepoint.com/personal/pilotuser_contoso_com"
New-RetentionComplianceRule -Policy "Label Policy – EventBased-Publish – Pilot" `
  -PublishComplianceTag "Retention Label – Termination-7yr – Pilot"

# Auto-apply an event-based label by condition (pilot scope) — condition from the schedule, not invented
New-RetentionCompliancePolicy -Name "Label Policy – EventBased-AutoApply – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/EventRetentionPilot"
New-RetentionComplianceRule -Policy "Label Policy – EventBased-AutoApply – Pilot" `
  -ApplyComplianceTag "Record Label – Contracts-EventExpiry-7yr – Pilot" `
  -ContentMatchQuery '"master services agreement"'
```
*(SharePoint default-library-label application is deferred to the SharePoint records/retention product.)*

### 3d. Stamp the asset ID on pilot content (the matching data)
For asset-ID categories, ensure the **`Compliance Asset Id`** managed-metadata property is present on the
in-scope SharePoint/OneDrive documents and **stamp the identifier** (employee ID / contract number / SKU)
onto the pilot documents — via the library UI, a content-type default, or an automated stamping process at
ingestion. This is the data a future event matches on; without it the event finds nothing. For **keyword**
categories, confirm the query matches the pilot content (and excludes out-of-scope content). **Pass/fail
(Configure gate):** every designed event type and label exists, label policies are pilot-scoped, and the
matching data (asset ID stamped, or keyword validated) is present on the pilot content; no label reaches
content outside the pilot.

## Stage 4 — Pilot (prove the trigger on a disposable asset)
1. Confirm labeled pilot content is in the **pending** state: it shows *"retention starts on event"* — the
   label and duration are set, but no clock is running yet.
2. Stamp a **disposable test document** with a test asset ID (e.g. `TEST-ASSET-001`) and apply the
   event-based label to it.
3. Raise a **test retention event** for the category, on the disposable asset only, via
   **`Set-EventTypesAndLabels.ps1 -RaiseEvent`** (dry-run by default; `-Commit` calls
   `New-ComplianceRetentionEvent`):
   ```powershell
   New-ComplianceRetentionEvent -Name "Retention Event – TEST-Termination – Pilot" `
     -EventType "Event Type – Employee-Termination" `
     -EventTags "Retention Label – Termination-7yr – Pilot" `
     -AssetId "TEST-ASSET-001" -EventDateTime (Get-Date)
   ```
   *(Use the asset ID for asset-ID categories, or the keyword parameter for keyword categories — verify the
   exact parameter names in your tenant/module version.)*
4. Allow for **propagation** (hours to days — do not judge in minutes). Then run the Stage 5 validation to
   confirm the clock started on **exactly** the matching asset and on nothing else.
5. **Pass/fail (Pilot gate):** the test event starts the retention clock on the matching disposable asset
   from the event date, un-matched content stays pending, and no content outside the pilot scope is affected.

## Stage 5 — Validate
Run **`Test-EventRetentionConfig.ps1`** (read-only) to confirm every designed event type exists, each label
uses an event trigger bound to the correct event type, label policies target the pilot scope, and asset-ID /
keyword readiness is in place; then run **`Get-EventRetentionReport.ps1`** to produce `Event Retention
Compliance – Tenant – Report` and work the Section 5 test procedures. Every gate has an explicit pass/fail.
Do not expand until all pass.

## Stage 6 — Expand (production)
1. Mint the **production** labels by swapping `– Pilot` for `– Prod` (never edit a validated pilot artifact in
   place): e.g. `Retention Label – Termination-7yr – Prod`, `Label Policy – EventBased-Publish – Prod`.
   Event types are reusable and carried forward.
2. Broaden the label policies to the full in-scope locations, and roll out **asset-ID stamping at
   ingestion** (or the validated keyword strategy) across production content so future events match.
3. **Wire the real raise process** to the system of record (2.3): the owner raises the production event
   (`New-ComplianceRetentionEvent`) when HR/CLM/PLM signals it, supplying the real asset IDs / keywords and
   the real event date. Stage the rollout in **rings** (by department/site/category) where possible.
4. **Pass/fail (Expand gate):** production labels apply across the in-scope workloads, asset-ID / keyword
   matching data is present on production content, the raise process is operable and tested against the
   system of record, the compliance report shows expected coverage, and no unexpected retention conflicts
   appear.

---

## Rollback (per stage)
- **Label policies (reversible):** unpublish/disable a label policy by disabling or removing its rule
  (`Set-RetentionComplianceRule`), or reduce its locations. This stops the label reaching new content; it
  does not un-apply labels already on items.
- **Event-based labels (reversible if not a record):** remove a non-record event-based label from items and
  delete the unused label; a published label can be unpublished; auto-apply can be disabled.
- **Records (partly reversible):** a **non-regulatory** record can be **un-declared** by a records manager
  (auditable) — do this only per records/legal direction; the mechanic is the records product's.
- **A raised event before its clock elapses (mitigable):** while a `KeepAndDelete` clock is still running you
  can extend, relabel, or remove the label to change the outcome — treat this as mitigation, not clean
  rollback, and act before the delete date.
- **IRREVERSIBLE — no rollback:** an **elapsed event-based deletion** (content already disposed) and a
  **regulatory-record** designation (cannot be removed/shortened). These are gated on records/legal sign-off
  and must never be exercised beyond a disposable test item in pilot.

Every production change carries a change ticket, an approver, and this rollback written out for the specific
categories in scope, with irreversible categories/actions explicitly flagged **no-rollback**. Raise real
(non-test) events only through the authorized, change-controlled process.
