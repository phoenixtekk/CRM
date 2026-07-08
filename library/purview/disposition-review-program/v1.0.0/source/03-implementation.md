# 3. Implementation Guide

This is the ordered, pilot-first method to stand up a multi-stage disposition review program in Microsoft
Purview. It follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — and
every artefact is named per the convention in Section 1 and reused verbatim in the scripts. **Disposition
is high-impact and partly irreversible**: disposition labels are published to the **pilot scope only**, the
full review cycle is exercised on **short-duration disposable test content**, and nothing governs production
until the Section 5 gates pass. **The review requirement (which labels review, how many stages, who
reviews) is an input from records/legal** — this guide implements it, it does not author it. **Reviewers
approve dispositions in the portal; no script deletes, extends, or relabels on their behalf.**

> **Portal paths evolve and are cloud-dependent.** Paths below are Microsoft Purview portal
> (`purview.microsoft.com`) as of authoring; in GCC/GCC High/DoD the URL and some features differ
> (`*.office365.us`). **Verify the path and feature availability in your tenant/cloud** before relying on
> it. Where a step is plan-dependent (multi-stage review especially), it is flagged.

---

## Stage 0 — Connect and confirm prerequisites
1. Confirm Section 2 prerequisites: compliance licensing incl. multi-stage (2.1), the review requirement
   from records/legal (2.2), roles incl. **Disposition Management** (2.3), reviewer groups/mailboxes (2.4),
   existing label posture (2.5), the legal-hold boundary (2.6), the toolchain (2.7), and change control
   (2.8).
2. Connect the toolchain from an MFA-capable admin workstation:
   ```powershell
   Connect-IPPSSession                              # Security & Compliance PowerShell (add -ConnectionUri for Gov clouds)
   Connect-MgGraph -Scopes "Group.Read.All","User.Read.All"   # supporting reads only (reviewer/group validation)
   ```
3. Run **`Resolve-DispositionScope.ps1`** to confirm module/connection health, report the detected cloud/
   endpoint, confirm Records-management / disposition cmdlets are reachable, and resolve the **Disposition
   Management** role group and the pilot scope. **Pass/fail:** connections succeed, the expected cloud is
   reported, `Get-ComplianceTag` and `Get-RoleGroupMember -Identity "Disposition Management"` return, and
   the pilot scope resolves.

## Stage 1 — Assess (read-only)
1. Run **`Assess-DispositionPosture.ps1`** to produce `Disposition Posture – Tenant – Discovery`: every
   retention label (`Get-ComplianceTag`) with its **retention action**, and for retain-then-delete labels
   whether disposition review is **enabled** (single vs multi-stage), the **reviewer stages** and their
   reviewers, plus the **Disposition Management** role-group membership (`Get-RoleGroupMember`).
2. The script flags the key gaps: **retain-then-delete labels that auto-delete with no review**, **reviewed
   labels whose reviewers are not in Disposition Management** (they cannot act), and **stages with empty or
   unresolved reviewers**.
3. Review the baseline with records/legal and the org-wide records program (2.5): which labels *should*
   require review, which already do, and which are owned elsewhere.
4. **Pass/fail (Assess gate):** a complete label + reviewer + permission inventory exists; the auto-delete
   labels that records/legal require to be reviewed are identified; no change was made (read-only).

## Stage 2 — Design (map the review requirement to Purview)
Translate the records/legal review requirement into a concrete artefact map. Produce a design table with,
for each review category:
- **Category → label:** the retain-then-delete retention label that carries the review (existing label from
  the org-wide records product, or a new `Disposition Label – … – Pilot`).
- **Stages:** single-stage, or an **ordered** list of stages (e.g. `Records → Compliance → Legal`).
- **Reviewers per stage:** the mail-enabled group per stage (`Disposition Reviewers – <Function> – StageN`)
  and its members — all of whom go into **Disposition Management**.
- **Retention action + duration:** retain-then-delete and the period (from the schedule — not invented). For
  the **pilot**, define short-duration disposable test labels so a full cycle completes in the pilot window.
- **Application:** publish or auto-apply, scoped to `Scope – Disposition-Pilot – Static` only.
- **Evidence expectation:** the proof-of-disposal / audit trail to be captured at the end of the cycle.

Name every artefact now (Section 1 table) and record the pilot scope. **Pass/fail (Design gate):** every
review category maps to a named label with stage count/order, per-stage reviewer groups, action/duration,
application method, and pilot scope; records/legal has signed off the stage model and reviewer population,
and confirmed the final disposition authority.

## Stage 3 — Configure (build, staged safe)
Build in this order. **Configuration scripts default to `-WhatIf`/dry-run and only write with `-Commit`.**

### 3a. Reviewer stages and the Disposition Management permission
Ensure every reviewer can actually act **before** any content reaches the queue. Run
**`Set-DispositionReviewers.ps1`** to validate each stage's mail-enabled group resolves and every member is
in **Disposition Management**, adding missing members with `-Commit`:
```powershell
# Reviewers must be in the Disposition Management role group to see/act on the queue (S&C PowerShell)
Add-RoleGroupMember -Identity "Disposition Management" -Member "records-reviewer@contoso.com"
Get-RoleGroupMember  -Identity "Disposition Management"     # verify
```
*(Grant Disposition Management **only** to named reviewers — role separation, 2.3.)*

### 3b. Disposition-review labels (single- and multi-stage)
Create or update the retention labels with disposition review via **`Set-DispositionReview.ps1`** (which
wraps `New-ComplianceTag` / `Set-ComplianceTag` with a `-WhatIf` default and drives from a JSON design).
Where the label already exists (org-wide records product), the script **adds/verifies** the review
configuration rather than re-creating it. The intent the script commits with `-Commit`:
```powershell
# Single-stage disposition review (retain-then-delete; one reviewer set)
New-ComplianceTag -Name "Disposition Label - Records-7yr - Pilot" -RetentionAction KeepAndDelete `
  -RetentionDuration 2555 -RetentionType ModificationAgeInDays `
  -ReviewerEmail "disposition-reviewers-records@contoso.com"

# Multi-stage disposition review (ordered stages; disposal only after the FINAL stage approves)
# NOTE: the multi-stage property shape is newer and has changed across releases — VERIFY in your tenant.
$multiStage = @{
    MultiStageReviewSettings = @(
        @{ StageName = "Records";    Reviewers = @("disposition-reviewers-records@contoso.com") },
        @{ StageName = "Compliance"; Reviewers = @("disposition-reviewers-compliance@contoso.com") },
        @{ StageName = "Legal";      Reviewers = @("disposition-reviewers-legal@contoso.com") }
    )
} | ConvertTo-Json -Depth 4
New-ComplianceTag -Name "Disposition Label - Contracts-7yr-MS - Pilot" -RetentionAction KeepAndDelete `
  -RetentionDuration 2555 -RetentionType ModificationAgeInDays -MultiStageReviewProperty $multiStage
```
> **Confirm the parameter shape.** `-MultiStageReviewProperty` and its stage schema are relatively new and
> the exact property names/limits have changed between releases. The script builds this object for you and
> **echoes it under `-WhatIf`** so you can confirm it against the current Microsoft docs and your tenant
> **before** committing. Do not assume the shape above without verifying.

### 3c. Publish / auto-apply the disposition labels to the pilot scope
Make the labels available on pilot content only, via a pilot-scoped label policy:
```powershell
# Publish for pilot users to apply (pilot scope only)
New-RetentionCompliancePolicy -Name "Label Policy - Disposition-Publish - Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/DispositionPilot" `
  -ExchangeLocation "pilotuser@contoso.com"
New-RetentionComplianceRule -Policy "Label Policy - Disposition-Publish - Pilot" `
  -PublishComplianceTag "Disposition Label - Records-7yr - Pilot"

# OR auto-apply by a condition from the schedule (pilot scope) — condition provided, not invented
New-RetentionCompliancePolicy -Name "Label Policy - Disposition-AutoApply - Pilot" `
  -SharePointLocation "https://contoso.sharepoint.com/sites/DispositionPilot"
New-RetentionComplianceRule -Policy "Label Policy - Disposition-AutoApply - Pilot" `
  -ApplyComplianceTag "Disposition Label - Contracts-7yr-MS - Pilot" -ContentMatchQuery '"master services agreement"'
```
*(Retention-label/policy mechanics in depth are the org-wide Data Lifecycle & Records Management product's
province — referenced here, scoped to the pilot.)*

**Pass/fail (Configure gate):** every designed disposition label exists with the correct action, duration,
and **review configuration** (single/multi-stage as designed); every stage's reviewers are in **Disposition
Management**; the label policy is scoped to the **pilot only**; and nothing is published tenant-wide.

## Stage 4 — Pilot (prove a full review cycle on the bounded scope)
1. Apply a **short-duration disposable test** disposition label to test content in `Scope – Disposition-
   Pilot – Static` (publish for pilot users, or let auto-apply match). Use a test label with a very short
   retention so the item reaches expiry within the pilot window.
2. Let the item **reach expiry** and enter the **Disposition** queue (Microsoft Purview → **Records
   management → Disposition**). Confirm reviewers receive **notification** email.
3. **Exercise the full cycle in the portal** as the reviewers:
   - Confirm each stage's reviewers see **only** their labels' items.
   - **Single-stage:** one reviewer approves permanent deletion → item is disposed.
   - **Multi-stage:** Stage 1 approves → item advances to Stage 2 → … → **final** stage approves → item is
     disposed. Also test the **extend** and **relabel** actions on separate test items (they stop disposal).
4. After the (test) disposition completes, **capture the evidence**: the disposition record / proof of
   disposal in the portal and the corresponding **audit** events. Run `Get-DispositionEvidenceReport.ps1`
   to compile the configuration + evidence pointers.
5. Allow for **propagation** (hours to days — do not judge in minutes). **Pass/fail (Pilot gate):** on pilot
   content, review-enabled items route to review (never auto-delete), stages advance in order, disposal
   occurs only after the **final** approval, extend/relabel stop disposal, reviewers see only their scope,
   and a **proof-of-disposal + audit trail exists** — all without affecting content outside the pilot.

## Stage 5 — Validate
Work the Section 5 test procedures; every gate has an explicit pass/fail, including the **evidence** gate.
Run **`Get-DispositionEvidenceReport.ps1`** to produce `Disposition Evidence – Tenant – Report`. Do not
expand until all pass.

## Stage 6 — Expand (govern production content)
1. Mint the **production** artefacts by swapping `– Pilot` for `– Prod` (never edit a validated pilot
   artefact in place): e.g. `Disposition Label – Records-7yr – Prod`, `Label Policy – Disposition-Publish –
   Prod`. Use the **real** retention durations from the schedule (not the short test durations).
2. Publish/auto-apply the production disposition labels to the in-scope locations under change control —
   staged in **rings** (by department/site) rather than a single tenant-wide flip where the schedule allows.
3. Confirm reviewer stages and Disposition Management membership are in place at production scale; re-run
   the evidence report after each ring.
4. **Pass/fail (Expand gate):** production disposition labels apply across the in-scope locations, the
   Disposition queue populates for review categories, disposal occurs only after final-stage approval, and
   the evidence report shows expected coverage with no review category silently auto-deleting.

---

## Rollback (per stage)
- **Label policies / publication (reversible):** disable or unpublish the label policy
  (`Set-RetentionCompliancePolicy -Enabled $false`, or remove/disable its rule) so the disposition label is
  no longer published/auto-applied. Content already labelled keeps its label until changed.
- **Review configuration on a not-yet-expired label (reversible):** a disposition label whose items have not
  yet reached expiry can have its review configuration adjusted or the label removed from items; adjust
  reviewer-group membership (`Remove-RoleGroupMember`, edit the mail-enabled group) as needed.
- **Reviewer permission (reversible):** remove an account from **Disposition Management**
  (`Remove-RoleGroupMember -Identity "Disposition Management"`) to revoke queue access.
- **IRREVERSIBLE — no rollback:** a **completed (approved) disposition** — content is permanently deleted.
  This is why the full cycle is exercised only on **disposable test content** in pilot and why the final
  disposition authority is records/legal. Never exercise a real disposition to "test" rollback.

Every production change carries a change ticket, an approver, and this rollback written out for the specific
categories in scope, with **completed disposition** explicitly flagged **no-rollback**.
