# 5. Testing & Validation

Run these after each pilot wave and before expanding. Each test states an expected **pass** and a
**fail**. Reuse the artifact names from §1. `EXOARCH-Validation.ps1` automates most of these; the
manual checks confirm the user-visible result.

---

## Test 1 — Archive mailbox provisioned
- **How:** `Get-Mailbox <pilot-user> | Format-List ArchiveStatus,ArchiveGuid,ArchiveName` (or
  `EXOARCH-Validation.ps1`).
- **Pass:** `ArchiveStatus = Active` and a non-zero `ArchiveGuid` for every licensed pilot user. In
  Outlook/OWA the user sees an **Online Archive / In-Place Archive** node.
- **Fail:** `ArchiveStatus = None` or an all-zero `ArchiveGuid`. Common cause: user not licensed for an
  archive (Requirement 2.1) or enable not yet replicated — see §6.

## Test 2 — Auto-expanding archive (if in scope)
- **How:** `Get-Mailbox <pilot-user> | Format-List AutoExpandingArchiveEnabled` and
  `Get-OrganizationConfig | Format-List AutoExpandingArchive`.
- **Pass:** `AutoExpandingArchiveEnabled = True` (per-mailbox) or the org flag is on, for the users where
  auto-expand was intended and the plan supports it.
- **Fail:** `False` where it was intended. Confirm plan support (**verify in your tenant/plan**) and that
  the switch was committed — remember it is **one-way**, so absence means it was never applied, not
  reverted.

## Test 3 — Retention policy assigned
- **How:** `Get-Mailbox <pilot-user> | Format-List RetentionPolicy`.
- **Pass:** returns `Archive Retention Policy – EXO – Prod` for every pilot mailbox.
- **Fail:** blank or a different policy. Re-run the assignment step (Implementation step 10).

## Test 4 — Tags and policy exist and are linked
- **How:** `Get-RetentionPolicy "Archive Retention Policy – EXO – Prod" | Format-List RetentionPolicyTagLinks`
  and `Get-RetentionPolicyTag | Where-Object Name -like '*Archive*'`.
- **Pass:** the policy links `Move to Archive – Default – Prod` and `Archive Now – Personal – Prod`; the
  DPT shows `RetentionAction = MoveToArchive`, `RetentionEnabled = True`, and the intended
  `AgeLimitForRetention`.
- **Fail:** missing link or a tag with `RetentionEnabled = False`. Re-run `EXOARCH-Set-MrmPolicy.ps1
  -Commit`.

## Test 5 — Move-to-archive actually moves aged mail (the key behavioral test)
- **How:** trigger and re-measure:
  ```powershell
  Start-ManagedFolderAssistant <pilot-user>
  # allow the assistant to process, then compare sizes:
  Get-MailboxStatistics <pilot-user>            # primary size / item count
  Get-MailboxStatistics <pilot-user> -Archive   # archive size / item count
  ```
- **Pass:** after the MFA has processed the mailbox (may take a work cycle / multiple runs), the
  **archive** item count/size has increased and the **primary** has decreased for a mailbox that had mail
  older than the DPT age. Aged items now appear under the Online Archive in Outlook/OWA.
- **Fail:** no movement after the MFA has run repeatedly over the expected window. Check the DPT age vs
  the mailbox's mail age, that the policy is assigned, and §6 (MRM diagnostics).

## Test 6 — PST import landed in the archive
- **How:** confirm the **`PST Import – Archive – Ingest`** job shows **Completed** in the Import service,
  then `Get-MailboxStatistics <pilot-user> -Archive` and spot-check in OWA under the Online Archive.
- **Pass:** the imported folders/items appear in the **archive** (not the primary), item counts match the
  source PSTs, and the job reports completed with no failed rows.
- **Fail:** items landed in the primary mailbox (mapping row's archive target was not set), or the job
  failed. Correct the mapping CSV (`IsArchive = TRUE`) / import role (Requirement 2.2) and re-run.

## Test 7 — Litigation hold enforced
- **How:** `Get-Mailbox <held-user> | Format-List LitigationHoldEnabled,LitigationHoldDate,
  LitigationHoldDuration`. Optionally verify preservation: delete a test item and confirm it is
  recoverable from **Recoverable Items** (it must not be purgeable while held).
- **Pass:** `LitigationHoldEnabled = True` (and the intended duration) for every mailbox on the legal
  owner's list; a hard-deleted test item remains recoverable.
- **Fail:** `False` where the determination requires a hold, or a deleted item is unrecoverable. Re-apply
  per the determination (Implementation step 12).

## Test 8 — In-Place / eDiscovery hold enforced
- **How:** in the Purview eDiscovery case, confirm `eDiscovery Hold – <Matter> – Legal` is **On** with
  the intended sources; `Get-Mailbox <held-user> | Format-List InPlaceHolds` shows the hold GUID.
- **Pass:** the hold is on, scoped to the custodians/query from the determination, and the mailbox lists
  the hold.
- **Fail:** hold off or wrong scope. Correct in the case per the legal owner; do not change scope on your
  own.

## Test 9 — Nothing under hold was disabled/removed
- **How:** re-run `EXOARCH-Discovery.ps1` and confirm no mailbox that should be held has an archive
  disabled or a hold missing.
- **Pass:** every mailbox that had a hold still has it; no held archive was disabled by the rollback path.
- **Fail:** a hold or held archive is missing — investigate immediately (a held item must never be lost).

---

**Overall pilot pass criteria:** Tests 1, 3, 4, 5 pass for the pilot scope; Tests 2, 6, 7, 8 pass for
whichever of auto-expand / PST import / holds were in scope; Test 9 passes always. Only then expand to
`Archive Scope – Broad – Stage2`.
