# Implementation — Exchange Lifecycle Policies in Microsoft Purview

Follow these steps in order. The model is **Assess → Design → Configure → Pilot (limited scope /
retain-first) → Validate → Expand (enforce)** with an explicit **pass/fail gate** before you widen
scope or enable any delete action. Every object is named so precedence and scope are deliberate.

> **Before you start:** retention **delete is destructive and largely irreversible**, and Purview
> retention has **no simulation mode**. The pilot ring is your safety net. Do not point a
> keep-**then**-delete rule at all mailboxes on day one. The retention **schedule** and any **hold**
> come from records/legal (`02-requirements.md` R4/R5), not from this guide.

Named objects used throughout (rename to your convention, keep them consistent):

| Object | Name | Engine |
|---|---|---|
| Pilot ring (mail-enabled security group) | `SG-DLCEXO-Pilot` | scope |
| Purview retention policy (Exchange) | `DLCEXO-Retention-Exchange-Pilot` | Purview DLM |
| Purview retention rule | `DLCEXO-Rule-Exchange-Keep7yrThenDelete` | Purview DLM |
| MRM (cleanup) retention policy | `DLCEXO-MRM-Cleanup-Standard` | Exchange MRM |
| RPT — Deleted Items age-out | `DLCEXO-Tag-DeletedItems-30d` | Exchange MRM |
| RPT — Junk Email age-out | `DLCEXO-Tag-JunkEmail-30d` | Exchange MRM |
| DPT — move old mail to archive | `DLCEXO-Tag-Default-MoveToArchive-2yr` | Exchange MRM |

*(Durations shown — 7 years / 30 days / 2 years — are placeholders. Use the values your records
schedule specifies.)*

---

## Phase 1 — Assess

1. **Confirm licensing and roles** (`02-requirements.md` R1/R2). In the Purview portal confirm **Data
   Lifecycle Management → Retention Policies** is available and **Exchange** is a selectable location;
   confirm you hold **Retention Management / Compliance Administrator**. Confirm **Retention Management**
   in Exchange for MRM.
2. **Run the discovery inventory.** From a workstation with `Connect-IPPSSession` **and**
   `Connect-ExchangeOnline`:
   ```powershell
   .\DLCEXO-Discovery.ps1 -IncludeMailboxSample
   ```
   Review existing Purview retention policies scoped to Exchange, existing MRM tags/policies, the
   **org default MRM policy**, archive status, and any **litigation-hold** mailboxes. Pre-existing
   retention or holds change what your new policy will (and won't) remove — reconcile them now.
   **Gate:** you have a clear picture of what already governs these mailboxes. Unresolved holds → stop
   and reconcile with legal (R5).

## Phase 2 — Design (with records/legal)

3. **Fix the retention schedule** (R4). Record, in writing: retain period, disposition
   (`Retain` / `Delete` / `KeepAndDelete`), and whether the clock runs from **created** or
   **modified** date. Example working schedule: *retain 7 years from creation, then delete.*
4. **Fix the cleanup design** (R6). Decide the MRM tags: Deleted Items → permanently delete after
   30 days; Junk Email → permanently delete after 30 days; DPT → move to archive after 2 years (only
   if archive mailboxes are/will be enabled). Decide whether users get Personal Tags.
5. **Fix the pilot ring** (R7). Confirm `SG-DLCEXO-Pilot` exists with a small, representative
   membership. Record the scope manifest:
   ```powershell
   .\DLCEXO-Set-Scope.ps1 -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete
   ```
   (2555 ≈ 7 years.) This writes a read-only manifest to configure against; it changes nothing.
   **Gate:** schedule, cleanup design, and pilot ring are all approved and named.

## Phase 3 — Configure (scoped to the pilot)

### 3a. Purview retention policy + rule (the keep / keep-then-delete engine)

6. **Create the retention policy scoped to the pilot**, Exchange location only. Prefer the helper in
   `-WhatIf` first, then `-Commit`:
   ```powershell
   # Preview (default): prints the plan, changes nothing
   .\DLCEXO-Configure.ps1 -PolicyName "DLCEXO-Retention-Exchange-Pilot" `
       -RuleName "DLCEXO-Rule-Exchange-Keep7yrThenDelete" `
       -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete -WhatIf

   # Apply
   .\DLCEXO-Configure.ps1 -PolicyName "DLCEXO-Retention-Exchange-Pilot" `
       -RuleName "DLCEXO-Rule-Exchange-Keep7yrThenDelete" `
       -PilotGroup "SG-DLCEXO-Pilot" -RetainDays 2555 -Disposition KeepAndDelete -Commit
   ```
   Under the covers this is `New-RetentionCompliancePolicy -ExchangeLocation <pilot members>` then
   `New-RetentionComplianceRule -Policy <policy> -RetentionDuration 2555 -RetentionComplianceAction
   KeepAndDelete -ExpirationDateOption CreationAgeInDays`. **Retain-first option:** pass
   `-Disposition Retain` to deploy keep-only, validate, then re-run with `KeepAndDelete` to add delete.
   > Scoping to a group targets **its current members' mailboxes**; membership changes do not auto-
   > re-scope a static policy. For dynamic membership use an **adaptive scope** (E5) at expand time.
7. **Do NOT enable Preservation Lock** at pilot. Locking is a separate, records-approved, irreversible
   decision (`01-solution-overview.md`).

### 3b. Exchange MRM policy + tags (the cleanup / archive engine)

8. **Create the retention tags**, then bundle them into the MRM policy, then assign to pilot mailboxes.
   The `-Commit` path of the helper performs these; the equivalent Exchange cmdlets are:
   ```powershell
   New-RetentionPolicyTag "DLCEXO-Tag-DeletedItems-30d" -Type DeletedItems `
       -RetentionEnabled $true -AgeLimitForRetention 30 -RetentionAction PermanentlyDelete
   New-RetentionPolicyTag "DLCEXO-Tag-JunkEmail-30d" -Type JunkEmail `
       -RetentionEnabled $true -AgeLimitForRetention 30 -RetentionAction PermanentlyDelete
   New-RetentionPolicyTag "DLCEXO-Tag-Default-MoveToArchive-2yr" -Type All `
       -RetentionEnabled $true -AgeLimitForRetention 730 -RetentionAction MoveToArchive
   New-RetentionPolicy "DLCEXO-MRM-Cleanup-Standard" -RetentionPolicyTagLinks `
       "DLCEXO-Tag-DeletedItems-30d","DLCEXO-Tag-JunkEmail-30d","DLCEXO-Tag-Default-MoveToArchive-2yr"
   ```
   Include the DPT (`-Type All … MoveToArchive`) **only if** archive mailboxes are enabled for the
   pilot users (`Enable-Mailbox -Archive`). Assign to each pilot mailbox:
   `Set-Mailbox -Identity <pilotMailbox> -RetentionPolicy "DLCEXO-MRM-Cleanup-Standard"`.
9. **Trigger a processing pass** on a pilot mailbox so you can observe results within the test window:
   ```powershell
   Start-ManagedFolderAssistant -Identity <pilotMailbox>
   ```
   **Gate (Configure):** both policies exist, are scoped to the pilot only, and the MFA has run at
   least once on a pilot mailbox. `DLCEXO-Report.ps1` should show the pilot mailboxes as covered.

## Phase 4 — Pilot & Validate

10. **Validate on the pilot ring** using `05-testing.md`. Confirm: retention is **preserving** mail
    against user deletion (Recoverable Items holds it) for in-scope pilot mailboxes; MRM is
    **cleaning** Deleted Items / Junk on schedule; MoveToArchive is **moving** old mail to the archive;
    and **no mailbox outside `SG-DLCEXO-Pilot` is affected**.
11. **Run the readiness gate:**
    ```powershell
    .\DLCEXO-Test-Readiness.ps1
    ```
    All checks **PASS** (or every **GAP** is understood and accepted by records/legal) → proceed.
    Any unexplained GAP, or any out-of-scope mailbox touched → **stop, fix, re-pilot.**

## Phase 5 — Expand (enforce)

12. **Widen the Purview retention scope** only after the gate passes: re-scope
    `DLCEXO-Retention-Exchange-Pilot` from the pilot group to **all mailboxes** or an **adaptive scope**
    (E5), and — if you piloted retain-only — **add the delete action** now
    (`Set-RetentionComplianceRule -RetentionComplianceAction KeepAndDelete`). Rename the policy to drop
    `-Pilot` if you wish, keeping the name consistent in your records.
13. **Assign the MRM policy more broadly** (or set it as the mailbox default for new mailboxes) under
    change control, staging in rings.
14. **Record the evidence.** Export the final `DLCEXO-Report.ps1` and `DLCEXO-Test-Readiness.ps1`
    output as the deployment evidence (policy names, scope, durations, coverage), and hand the
    retention-schedule mapping back to records.

## Rollback

- **Purview retention (keep-only or not yet deleted):** `Set-RetentionCompliancePolicy -Enabled $false`
  (unless **Preservation Locked** — locked policies cannot be disabled by anyone). Removing a policy
  before its delete action has run leaves mail intact.
- **Purview retention after deletion has run:** deleted mail past the Recoverable Items window is
  **not** recoverable — this is why you pilot and retain-first. There is no rollback for already-
  deleted content.
- **MRM cleanup:** unassign with `Set-Mailbox -RetentionPolicy $null` (or a benign policy) and the MFA
  stops applying the tags going forward; **already-deleted** items past recovery are not restorable.
  **MoveToArchive** is reversible in effect (content moved to the archive is still the user's and
  searchable), but re-homing it to the primary is a manual/eDiscovery operation.
- Always capture the current state with `DLCEXO-Discovery.ps1` **before** changes so rollback targets a
  known-good baseline.
