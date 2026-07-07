# 3. Implementation

Follow the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — in order. Every
artifact is named per the convention in Section 1 and reused verbatim. Do not expand past the pilot
until the gates in Section 5 pass. Portal paths are given for the **Microsoft Purview portal**
(`purview.microsoft.com`); some tenants still use the classic **Microsoft Purview compliance portal**
(`compliance.microsoft.com`), and **Government clouds use different URLs (e.g. `*.office365.us`) —
verify the portal path in your cloud.** PowerShell is **Security & Compliance PowerShell**
(`Connect-IPPSSession`) for labels/policies/records and **PnP PowerShell** for library-level
application.

> **Safety posture.** Read-only assessment first. Every configuration script defaults to a dry-run /
> `-WhatIf` and only writes when `-Commit` is passed. Regulatory records and elapsed disposition are
> **irreversible** — treat them as no-rollback.

---

## Stage 0 — Connect and confirm scope

1. Connect the toolchain with modern auth (no stored credentials):
   ```powershell
   Connect-IPPSSession -UserPrincipalName admin@contoso.onmicrosoft.com   # Security & Compliance PowerShell
   Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/RecordsPilot -Interactive
   ```
   *For Government clouds pass the appropriate `-ConnectionUri` / `-AzureADAuthorizationEndpointUri`
   (S&C) and `-AzureEnvironment` (PnP) — verify the endpoints for your cloud.*
2. Confirm the pilot scope `Scope – Records-Pilot – Static` exists (the named pilot sites/libraries)
   and that owners know a record label will lock content.

**Gate 0 (pass/fail):** both connections succeed and the pilot sites resolve. If either fails, stop and
fix the toolchain/roles (Section 2) before continuing.

---

## Stage 1 — Assess (read-only)

1. **Baseline the existing Purview posture.** Enumerate what already exists so the new design aligns
   and does not conflict:
   ```powershell
   Get-ComplianceTag | Select-Object Name,IsRecordLabel,Regulatory,RetentionAction,RetentionDuration
   Get-RetentionCompliancePolicy | Select-Object Name,Enabled,Mode,SharePointLocation
   ```
2. **Assess the SharePoint content posture** with the discovery script:
   ```powershell
   .\Assess-SpoRetentionPosture.ps1 -Sites @("https://contoso.sharepoint.com/sites/RecordsPilot") -OutputPath .\out
   ```
   It enumerates the pilot sites' document libraries, reads the **default retention label** on each
   library (`Get-PnPLabel`), counts items with/without a label, and cross-references existing tenant
   labels/policies — writing `Retention Posture – SPO – Discovery` (CSV).
3. **Reconcile against the schedule.** Line the discovery output up against the records/legal schedule
   (Requirement 2.2): which categories exist as content in the pilot, which have no label yet, and
   which sites overlap existing retention.

**Gate 1 (pass/fail):** the pilot content is inventoried, the existing Purview baseline is captured,
and every pilot schedule category maps to real content. If a category has no representative content in
the pilot, either add a pilot library for it or descope it for now.

---

## Stage 2 — Design (map the schedule to labels, policies, and scopes)

Design on paper (or in the design workbook) before configuring. Produce three maps:

1. **Label map** — one **retention label** per schedule category. For each, record from the schedule:
   retention **action** (Retain / Delete / Retain-then-delete), **duration**, **trigger**
   (`CreationAgeInDays` / `ModificationAgeInDays` / `TaggedAgeInDays` / `EventAgeInDays`), **record
   status** (none / record / regulatory record), and **disposition** (automatic / review + reviewers).
   Name each per convention, e.g.:
   - `Retention Label – General-3yr – Pilot` (Delete after 3y from creation, no record)
   - `Record Label – Contracts – Pilot` (Retain 6y from event, record, disposition review)
   - `Regulatory Record Label – Financial-7yr – Pilot` (Retain-then-delete 7y, **regulatory record** —
     only if records/legal require the irreversible lock)
2. **Policy / application map** — how each label reaches content:
   - `Retention Policy – SPO-Baseline – Pilot` — a location-based **retention policy** on the pilot
     sites as the safety net (retain-only baseline; never a tenant-wide delete in a pilot).
   - `Label Policy – Contracts-AutoApply – Pilot` — **auto-apply** the contracts label by condition
     (keyword / sensitive-info type / trainable classifier) where the schedule allows automatic
     classification.
   - **Default library label** — for a library whose entire contents are one category (e.g. a
     contracts library), set the label as the library default so every item inherits it.
   - `Label Policy – Owner-Publish – Pilot` — **publish** labels so owners can apply them manually
     where classification must be human.
3. **Scope map** — pilot uses **static** scopes (`Scope – Records-Pilot – Static`, the named sites).
   Design the **adaptive** scope `Scope – Records-Prod – Adaptive` (a site query, e.g. by site
   property/URL) for expansion, but do not attach it until Stage 6.

**Gate 2 (pass/fail):** every schedule category has exactly one designed label with action, duration,
trigger, record status, and disposition specified; each label has a designated application method; and
the retention-precedence interaction with existing policies (Requirement 2.4) has been checked. Get
records/legal sign-off on the label map before configuring.

---

## Stage 3 — Configure (labels, policies, records, disposition)

Create everything in a **disabled / unpublished / dry-run** posture first; nothing applies to content
until Stage 4 (Pilot).

### 3a. Create the retention & record labels
Create labels in the portal (**Purview → Records management → File plan → Create a label**, or **Data
lifecycle management → Retention labels**) or via PowerShell. Import **file-plan descriptors**
(retention authority, category, sub-category) so the file plan is reportable. Examples:

```powershell
# General retention label (no record) — delete 3 years after creation
New-ComplianceTag -Name "Retention Label – General-3yr – Pilot" `
  -RetentionAction Delete -RetentionDuration 1095 -RetentionType CreationAgeInDays `
  -Comment "Delete 3y from creation. Category from records schedule."

# Record label — retain 6y, mark as record, route to disposition review
New-ComplianceTag -Name "Record Label – Contracts – Pilot" `
  -RetentionAction Keep -RetentionDuration 2190 -RetentionType TaggedAgeInDays `
  -IsRecordLabel $true -ReviewerEmail @("dispositionreviewers@contoso.com") `
  -Comment "Contracts. Record. Disposition review at end of retention."
```
- `-IsRecordLabel $true` makes the label declare content a **record** (in-place record, locked).
- `-Regulatory $true` makes it a **regulatory record** — **irreversible**; use only where records/legal
  require it, and never in a reversible pilot unless explicitly approved.
- `-ReviewerEmail` routes the label to **disposition review** at end of retention (the reviewers are
  the `Disposition Reviewers – Records – Stage1` group). *Multi-stage review and event-based retention
  are plan-dependent — verify in your tenant.*
- The `Set-SpoRecordsDisposition.ps1` helper builds/validates the record + disposition configuration
  and defaults to `-WhatIf`.

### 3b. Configure the disposition reviewers
1. In **Purview → Roles & scopes → Permissions**, ensure the reviewer accounts are in the
   **Disposition Management** role group — this is what lets `dispositionreviewers@contoso.com` see the
   disposition queue.
2. Confirm each record/label that ends in review names the correct reviewer group; single-stage for the
   pilot, multi-stage only where the schedule requires it.

### 3c. Create the retention policies (disabled)
```powershell
# Location-based baseline safety net on the pilot sites — retain-only, created disabled
New-RetentionCompliancePolicy -Name "Retention Policy – SPO-Baseline – Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/RecordsPilot" -Enabled $false
New-RetentionComplianceRule -Policy "Retention Policy – SPO-Baseline – Pilot" `
  -RetentionComplianceAction Keep -RetentionDuration Unlimited
```
- Create it **`-Enabled $false`**; you enable it in Stage 4.
- For **auto-apply**, create `Label Policy – Contracts-AutoApply – Pilot` similarly (a retention policy
  whose rule uses `-ApplyComplianceTag "Record Label – Contracts – Pilot"` with a match condition),
  disabled, then enable in the pilot. The `Apply-SpoRetentionLabels.ps1` helper builds these and
  defaults to `-WhatIf`; pass `-Commit` only under change control.

### 3d. Set default library labels (do not apply yet)
For a single-category library, plan the **default label** application; the helper stages it and only
writes with `-Commit`:
```powershell
Set-PnPLabel -List "Documents" -Label "Record Label – Contracts – Pilot" -SyncToItems $true
```
Stage this command for the pilot library but hold it until Stage 4.

**Gate 3 (pass/fail):** all designed labels exist; policies exist **disabled/unpublished**; reviewers
are in Disposition Management; no content has been affected yet. Verify with `Get-ComplianceTag` and
`Get-RetentionCompliancePolicy` (Enabled = False).

---

## Stage 4 — Pilot (apply to `Scope – Records-Pilot – Static` only)

Apply to the pilot sites only, one change at a time, watching each propagate before the next.

1. **Publish/enable manual labels first** (lowest impact): enable `Label Policy – Owner-Publish – Pilot`
   so pilot owners can apply labels; confirm the labels appear in the pilot library's **Apply label**
   column after propagation (can take up to a day).
2. **Set the default library label** on the pilot single-category library:
   ```powershell
   Set-PnPLabel -List "Documents" -Label "Record Label – Contracts – Pilot" -SyncToItems $true
   ```
   New and existing items inherit the label; record items become **in-place records** (locked).
3. **Enable the baseline retention policy** and any auto-apply policy on the pilot:
   ```powershell
   Set-RetentionCompliancePolicy -Identity "Retention Policy – SPO-Baseline – Pilot" -Enabled $true
   ```
4. **Declare a test record and confirm the lock:** apply `Record Label – Contracts – Pilot` to a test
   document, then confirm it cannot be edited/deleted (SharePoint blocks it; the activity is audited).
5. **Exercise disposition (accelerated where possible):** for a label whose retention has elapsed (use a
   short-duration test label or an item already past its trigger), confirm the item appears in
   **Purview → Records management → Disposition**, and have a `Disposition Reviewers – Records – Stage1`
   reviewer **approve disposal** (or extend/relabel) — confirming a **disposition record** is retained.

**Gate 4 (pass/fail):** on the pilot only — labels are applied, a record is declared and demonstrably
locked, the baseline policy is enabled, and one disposition decision has been made and evidenced, with
no unexpected content impact. Run `Test-SpoRetentionRecords.ps1` (Section 5) and require all checks
green before Stage 5.

---

## Stage 5 — Validate

Run the validation procedures in **Section 5 (Testing)** against the pilot. Confirm label coverage on
the pilot libraries, record lock behavior, policy enabled-state, disposition-review routing, and the
disposition record. Produce `Records Compliance – SPO – Report` with
`Get-SpoRecordsComplianceReport.ps1`. Records/legal signs off that the implemented behavior matches the
schedule.

**Gate 5 (pass/fail):** every test in Section 5 passes on the pilot and records/legal has signed off.
Any failure loops back to Stage 3/4 — do not expand.

---

## Stage 6 — Expand (tenant-wide, under change control)

1. **Mint production artifacts** by swapping `– Pilot` for `– Prod` (e.g. `Record Label – Contracts –
   Prod`) — never edit a validated pilot artifact in place.
2. **Attach the adaptive scope** `Scope – Records-Prod – Adaptive` (a site query) to the production
   policies so new/changed sites are covered automatically. *Adaptive scopes are plan-dependent —
   verify in your tenant.*
3. **Roll out in waves**, not all-at-once: enable production policies scope-by-scope, re-running
   `Test-SpoRetentionRecords.ps1` and `Get-SpoRecordsComplianceReport.ps1` after each wave.
4. **Operate the disposition queue** as a recurring duty: reviewers work the queue on cadence; the
   report tracks coverage, records declared, and pending dispositions over time.

**Gate 6 (pass/fail):** each production wave passes the same validation as the pilot before the next
wave; the disposition queue is being worked; the compliance report shows the intended coverage.

---

## Rollback (documented, rehearsed)

Roll back the **reversible** parts; consciously accept the **irreversible** ones.

- **Disable a policy:** `Set-RetentionCompliancePolicy -Identity "<name>" -Enabled $false` — stops the
  policy applying/enforcing.
- **Remove a default library label:** `Set-PnPLabel -List "<library>" -Label "" ` (clear) or re-set to
  a benign label; existing item labels may need per-item removal.
- **Un-declare a (non-regulatory) record:** a user/admin with rights can remove the record label; the
  un-declare is audited.
- **IRREVERSIBLE — no rollback:** a **regulatory-record** label cannot be removed or shortened, and a
  **completed disposition** (approved permanent deletion) cannot be undone. Confirm records/legal
  sign-off before applying any regulatory-record label or approving any disposal. This is why the
  pilot uses non-regulatory records wherever possible.

Every production change references its change ticket and this rollback before it is made.
