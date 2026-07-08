# 3. Implementation Guide

This is the ordered, pilot-first method to deliver regulatory & immutable records and a mapped file
plan in Microsoft Purview. It follows the house model — **Assess → Design → Configure → Pilot →
Validate → Expand** — and every artifact is named per the convention in Section 1 and reused verbatim in
the scripts. **Records declaration is high-impact and — for regulatory records — irreversible**: record
labels are published/auto-applied to the **pilot scope only**, regulatory labels are applied only to a
disposable test item in pilot and gated behind explicit sign-off, and nothing expands to production
until the Section 5 gates pass. The **records determination and all legal calls are inputs from
records/legal** — this guide implements them, it does not author them.

> **Portal paths evolve and are cloud-dependent.** Paths below are Microsoft Purview portal
> (`purview.microsoft.com`) as of authoring; in GCC/GCC High/DoD the URL and some features differ
> (`*.office365.us`). **Verify the path and feature availability in your tenant/cloud** before relying on
> it. Where a step is plan-dependent, it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: compliance licensing for records/file plan (2.1), the records
   determination from records/legal (2.2), roles incl. Disposition Management (2.3), in-scope workloads
   (2.4), existing posture (2.5), and change control with irreversible parts flagged (2.8).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                 # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Directory.Read.All"   # supporting reads only
   ```
3. Run **`Resolve-RecordsScope.ps1`** to confirm module/connection health and surface plan/cloud hints
   before touching anything. **Pass/fail:** both connections succeed, the script reports the expected
   cloud, and Records management (file-plan + records cmdlets) is reachable.

## Stage 1 — Assess (read-only)
1. Run **`Assess-RecordsFilePlanPosture.ps1`** to produce `Records Posture – Tenant – Discovery`: the
   existing labels (`Get-ComplianceTag`) with their **record / regulatory** flags, retention action and
   duration; the existing **file-plan descriptors** (`Get-FilePlanPropertyAuthority`,
   `-Category`, `-SubCategory`, `-Citation`, `-Department`, `-ReferenceId`); and which labels are
   currently **mapped** to descriptors vs unmapped.
2. Review the baseline with the lifecycle/records program owners (2.5): what already exists, which
   descriptors can be reused, and which labels the broader program owns.
3. **Pass/fail (Assess gate):** a complete inventory export exists; existing record/regulatory labels and
   file-plan descriptors are identified; reusable descriptors are flagged; no destructive action was
   taken (read-only).

## Stage 2 — Design (map the determination to Purview)
Translate the records/legal determination into a concrete artifact map. Produce a design table with, for
each in-scope category:
- **Category → label rung:** plain retention (out of scope here, defer to lifecycle product), **record**
  (immutable, reversible), or **regulatory record** (one-way). Only the last two are configured here.
- **Retention action + duration + trigger:** keep / keep-then-delete, the lock period, and created /
  last-modified / labeled / event trigger.
- **File-plan descriptors:** retention **authority**, **category / sub-category**, **department**,
  **citation** (+URL), **reference ID** — every record label must map to all that apply.
- **Application:** published (users declare) vs auto-apply (by condition) vs SharePoint default (deferred).
- **Disposition:** automatic vs **reviewed** (and the named reviewer group).
- **Locations:** which workloads (Exchange / SPO / OneDrive / Groups / Teams).

Name every artifact now (Section 1 table) and record the **pilot scope** `Scope – Records-Pilot – Static`
(the bounded users/sites/mailboxes and the disposable test items to prove on). **Pass/fail (Design
gate):** every in-scope category maps to a named record or regulatory label with action, duration,
trigger, descriptors, application method, disposition, and locations; records/legal has **signed off**
the mapping — especially each **regulatory-record** and its no-rollback flag.

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`;
regulatory labels additionally require `-AllowRegulatory -SignOffRef`.**

### 3a. File-plan descriptors first (so every label maps from creation)
Create the descriptors the labels will reference via **`Set-FilePlanDescriptors.ps1`** (which wraps the
`New-FilePlanProperty*` family with `-WhatIf` default). With `-Commit` it runs, for example:
```powershell
New-FilePlanPropertyAuthority   -Name "Authority – Records-Schedule-2026"
New-FilePlanPropertyCategory    -Name "Contracts"
New-FilePlanPropertySubCategory -Name "Vendor-Contracts"
New-FilePlanPropertyCitation    -Name "SOX" -CitationUrl "https://contoso.example/citations/sox" `
                                -CitationJurisdiction "US"
New-FilePlanPropertyDepartment  -Name "Finance"
New-FilePlanPropertyReferenceId -Name "REC-CON-001"
```
Reuse any existing descriptors the assessment found rather than minting duplicates. *(Use the descriptor
names your records determination defines — the above are placeholders.)*

### 3b. Record labels (immutable, reversible) with descriptors attached
Create the record labels via **`Set-ImmutableRecordLabels.ps1`** (which wraps `New-ComplianceTag` with
`-WhatIf` default). Each carries its action, duration, trigger, `-IsRecordLabel $true`, and the
**file-plan property** built from the descriptors above. The intent the script commits with `-Commit`:
```powershell
# Record label (immutable, reversible) — date-based, mapped to the file plan
New-ComplianceTag -Name "Record Label – Contracts-7yr – Pilot" -IsRecordLabel $true `
  -RetentionAction KeepAndDelete -RetentionDuration 2555 -RetentionType ModificationAgeInDays `
  -FilePlanProperty $filePlanProperty
```
The `$filePlanProperty` object is built from the descriptor names per Microsoft's documented file-plan
property format (authority / category / sub-category / citation / department / reference ID) — the script
assembles it for you from the design JSON. Applying this label **declares an in-place record** and locks
the item; a records manager can later **un-declare** it (evidenced) because it is non-regulatory.

### 3c. Regulatory-record labels (one-way) — gated, pilot only on a disposable item
Only for categories records/legal designate as irreversible, and only with the explicit switch and a
sign-off reference:
```powershell
# Regulatory record label — ONE-WAY: cannot be removed, changed, un-declared, or shortened.
New-ComplianceTag -Name "Regulatory Record Label – Financial-7yr – Pilot" -Regulatory $true `
  -RetentionAction Keep -RetentionDuration 2555 -RetentionType CreationAgeInDays `
  -FilePlanProperty $filePlanProperty
```
> **Regulatory records are irreversible.** `Set-ImmutableRecordLabels.ps1` refuses to set `-Regulatory`
> without `-AllowRegulatory -SignOffRef "<records/legal ref>"`. In pilot, apply a regulatory label **only
> to a disposable test item you are prepared to keep for its full period** — never to real content.

### 3d. Label policies (publish / auto-apply to the pilot)
Publish the record labels to pilot users (manual declaration) or auto-apply by condition, scoped to the
pilot:
```powershell
# Publish record labels for users to declare (pilot scope)
New-RetentionCompliancePolicy -Name "Label Policy – Records-Publish – Pilot" `
  -ExchangeLocation "pilotuser@contoso.com" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/RecordsPilot"
New-RetentionComplianceRule -Policy "Label Policy – Records-Publish – Pilot" `
  -PublishComplianceTag "Record Label – Contracts-7yr – Pilot"

# Auto-apply a record label by condition (pilot scope) — condition from the determination, not invented
New-RetentionCompliancePolicy -Name "Label Policy – Records-AutoApply – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/RecordsPilot"
New-RetentionComplianceRule -Policy "Label Policy – Records-AutoApply – Pilot" `
  -ApplyComplianceTag "Record Label – Contracts-7yr – Pilot" -ContentMatchQuery '"master services agreement"'
```
*(SharePoint default-library-label application is deferred to the SharePoint records/retention product.)*

### 3e. Disposition reviewers
Ensure the named reviewer accounts are in the **Disposition Management** role group (2.3) so any
reviewed-disposition categories can be actioned in the portal. Keep records configuration and disposition
review as separate duties. **Pass/fail (Configure gate):** every designed descriptor and label exists,
every record label is **mapped** to its file-plan descriptors, regulatory labels exist only where
signed off, label policies are **pilot-scoped**, reviewers are in Disposition Management, and no label is
published to production yet.

## Stage 4 — Pilot (prove on the bounded scope)
1. Confirm the label policies publish/auto-apply to the **pilot only**.
2. **Declare a record:** as a pilot user, apply `Record Label – Contracts-7yr – Pilot` to a disposable
   test item, then attempt to edit/delete/move it — it must be **locked**.
3. **Regulatory (test only):** apply the regulatory label to a **single disposable test item you will
   keep for its full period**; confirm it cannot be removed or changed. Do this only if a regulatory
   category is in pilot scope and signed off.
4. **Auto-apply:** create content matching an auto-apply condition; allow for **propagation** (hours to
   days — up to 7 days for existing content) and confirm the record label applies and locks.
5. Allow for propagation, then run the Stage 5 validation.
6. **Pass/fail (Pilot gate):** on pilot content, record labels declare and **lock** as designed, every
   applied label is **mapped** to the file plan, the regulatory lock is confirmed irreversible on the
   disposable test item, and **no content outside the pilot scope is affected**.

## Stage 5 — Validate
Run **`Get-RecordsFilePlanReport.ps1`** to produce `Records & File Plan – Tenant – Report` and work the
Section 5 test procedures. Every gate has an explicit pass/fail. Do not expand until all pass.

## Stage 6 — Expand (enforce to production scope)
1. Mint the **production** artifacts by swapping `– Pilot` for `– Prod` (never edit a validated pilot
   artifact in place, and never re-declare a regulatory record): e.g. `Record Label – Contracts-7yr –
   Prod`, `Label Policy – Records-Publish – Prod`. Descriptors are reused as-is (they are not
   stage-suffixed).
2. Broaden the label-policy locations to the full in-scope workloads (or attach **adaptive scopes** so
   coverage tracks the estate), and publish/auto-apply under change control.
3. Stage the rollout in **rings** (by department/site) rather than a single flip where the determination
   allows; re-run reporting after each ring.
4. **Pass/fail (Expand gate):** production record labels declare and lock across the in-scope workloads,
   the report shows every record label mapped to the file plan, regulatory categories are applied only
   where signed off, and no unexpected retention conflicts appear.

---

## Rollback (per stage)
- **Label policies (reversible):** unpublish a record label by disabling/removing its rule
  (`Set-RetentionComplianceRule` / remove the rule) or reducing its locations; disable an auto-apply
  policy so no further content is declared.
- **Record labels — non-regulatory (reversible):** a **records manager** can **un-declare** a
  non-regulatory record (auditable), restoring edit/delete; a published label can be unpublished and an
  unused non-record label deleted. **Do this only per records/legal direction.**
- **File-plan descriptors (reversible before use):** an unused descriptor can be removed; a descriptor in
  use by a label is retained until the label is retired.
- **IRREVERSIBLE — no rollback:** a **regulatory-record** label (cannot be removed, changed, un-declared,
  or shortened) and any **completed disposition** (content permanently deleted). These are gated on
  records/legal sign-off and must never be exercised beyond a single disposable test item in pilot.

Every production change carries a change ticket, an approver, and this rollback written out for the
specific categories in scope, with the **regulatory** categories explicitly flagged **no-rollback**.
