# 3. Implementation

Follow the house model: **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with
pass/fail gates and a documented rollback. Name every artifact exactly as in the reference model
(§1) and reuse the names in testing, troubleshooting, and the scripts.

**High-impact warning.** Enabling auto-expanding archive is a **one-way switch** (it cannot be turned
off). Applying a hold has legal consequences. Move-to-archive changes what users see in Outlook. Treat
all of these as production changes under change control.

Throughout, connect with modern auth (no stored credentials):
```powershell
Connect-ExchangeOnline           # add -ExchangeEnvironmentName O365USGovGCCHigh / O365USGovDoD on Gov clouds
Connect-MgGraph -Scopes 'User.Read.All','Organization.Read.All','Mail.ReadWrite'  # where Graph is used
```

---

## Stage 0 — Assess (read-only)
1. **Capture the current archive/hold posture and mailbox sizes.** Run **`EXOARCH-Discovery.ps1`**
   (read-only). It reports, per mailbox: `ArchiveStatus`, `ArchiveGuid`, `AutoExpandingArchiveEnabled`,
   the retention policy applied, primary and archive mailbox sizes, `LitigationHoldEnabled`, and
   any In-Place hold GUIDs. Save the export as **`Archive Posture – EXO – Discovery`**.
2. **Confirm licensing per user (the gate).** Cross-check the assessment against archiving-capable
   licensing (Requirement 2.1). Flag any in-scope user whose plan does not include the archive — they
   cannot be enabled until licensed. *(Verify in your tenant/plan.)*
3. **Identify the drivers.** From the posture: which mailboxes are near quota (archive candidates),
   which have PSTs to ingest (Requirement 2.3), and which are subject to a hold determination
   (Requirement 2.4).

**Pass gate (Assess):** you have a saved `Archive Posture – EXO – Discovery` export, a confirmed
licensed pilot set, and a clear list of what each pilot mailbox needs (archive enable / PST import /
hold).

## Stage 1 — Design
4. **Define the pilot and broad scopes.** Choose a small, representative, **licensed** pilot set →
   `Archive Scope – Pilot – Stage1`; define the eventual broad set → `Archive Scope – Broad – Stage2`.
   Use a mail-enabled security group or an explicit UPN list.
5. **Design the MRM tags and policy.**
   - **`Move to Archive – Default – Prod`** — a **default policy tag (DPT)** with retention action
     **MoveToArchive** and an age (e.g. move items older than **730 days / 2 years**). This is the tag
     that controls the automatic move-to-archive.
   - **`Archive Now – Personal – Prod`** — an optional **personal tag** (action MoveToArchive) users can
     apply on demand from Outlook/OWA.
   - **`Archive Retention Policy – EXO – Prod`** — the **retention policy** that bundles the tags above
     and is linked to the mailboxes in scope.
   Decide the archive-move age with the service/records owner (this is a policy decision, not a technical
   default).
6. **Design the hold scope (from the legal/records determination only).** For each matter, decide
   litigation hold (`Litigation Hold – <Matter> – Legal`, mailbox-level, simple) vs In-Place/eDiscovery
   hold (`eDiscovery Hold – <Matter> – Legal`, query/date-scoped, tied to a Purview eDiscovery case).
   **Take scope and duration from the legal owner — do not invent them.**

## Stage 2 — Configure (build; safe/`-WhatIf` first)
7. **Enable archive mailboxes for the pilot.** Preview first, then apply.
   ```powershell
   # Preview — no change
   .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -WhatIf
   # Apply
   .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -Commit
   ```
   Under the hood this is `Enable-Mailbox <id> -Archive`. The helper skips users already archive-enabled
   and warns on users it cannot confirm are licensed.
8. **Enable auto-expanding archive where the plan supports it (one-way — confirm first).**
   - Org-wide: `Set-OrganizationConfig -AutoExpandingArchive` (affects all archive-enabled mailboxes;
     cannot be undone).
   - Per-mailbox: `Enable-Mailbox <id> -AutoExpandingArchive`.
   **`EXOARCH-EnableArchive.ps1 -AutoExpand`** gates this behind `-Commit` and prints the irreversibility
   warning before acting. *(Availability/limits are plan-dependent — verify in your tenant/plan.)*
9. **Create the MRM tags and retention policy.** Use **`EXOARCH-Set-MrmPolicy.ps1`** (supports
   `-WhatIf`), which is idempotent:
   ```powershell
   .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -WhatIf   # preview the tag/policy it will create
   .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -Commit   # create/update
   ```
   It creates:
   - `New-RetentionPolicyTag "Move to Archive – Default – Prod" -Type All -RetentionAction MoveToArchive -AgeLimitForRetention 730 -RetentionEnabled $true`
   - `New-RetentionPolicyTag "Archive Now – Personal – Prod" -Type Personal -RetentionAction MoveToArchive -AgeLimitForRetention 0 -RetentionEnabled $true`
   - `New-RetentionPolicy "Archive Retention Policy – EXO – Prod" -RetentionPolicyTagLinks "Move to Archive – Default – Prod","Archive Now – Personal – Prod"`
   (If a tag/policy already exists, it updates the links with `Set-*` instead of failing.)
10. **Assign the retention policy to the pilot scope, then run the assistant.**
    ```powershell
    Get-Content .\pilot.txt | ForEach-Object { Set-Mailbox $_ -RetentionPolicy "Archive Retention Policy – EXO – Prod" }
    Get-Content .\pilot.txt | ForEach-Object { Start-ManagedFolderAssistant $_ }   # trigger processing
    ```
11. **Import PSTs to the archive (if in scope).** Build the import mapping CSV so each PST targets the
    user's **archive** (`IsArchive` = `TRUE`), name the job **`PST Import – Archive – Ingest`**, and use
    the Microsoft Purview / Microsoft 365 **Import** service (network upload with AzCopy, or drive
    shipping) per Microsoft's documented steps. The mapping CSV columns and the `SAS` upload URL come
    from the Import job in the portal — **follow the portal's current wizard**; do not hardcode a SAS URL.
    Confirm each row's target is the archive before submitting.
12. **Apply holds (from the legal/records determination only).**
    - **Litigation hold:** `Set-Mailbox <id> -LitigationHoldEnabled $true` (optionally
      `-LitigationHoldDuration <days>` and `-LitigationHoldOwner <name>`), recorded as
      `Litigation Hold – <Matter> – Legal`.
    - **In-Place / eDiscovery hold:** create the hold inside a **Microsoft Purview eDiscovery (Standard)**
      case, scoped by custodian and query/date range, recorded as `eDiscovery Hold – <Matter> – Legal`.
    Use **`EXOARCH-Set-Holds.ps1 -WhatIf`** to preview and to *report* current holds; apply only with
    `-Commit` and only against the legal-owner-provided list.

## Stage 3 — Pilot validate (pass/fail gates)
13. Run the validation script and the tests in **§5**:
    ```powershell
    .\EXOARCH-Validation.ps1 -Identities (Get-Content .\pilot.txt)
    ```
    **Pass gates (all must hold for the pilot before expanding):**
    - Every licensed pilot mailbox shows `ArchiveStatus = Active` (and `AutoExpandingArchiveEnabled =
      True` if that was in scope).
    - The pilot mailboxes have `Archive Retention Policy – EXO – Prod` assigned, and after the MFA has
      run, aged items have moved to the archive (archive item count/size increased; primary decreased).
    - Imported PSTs appear in the target archives (`PST Import – Archive – Ingest` shows completed).
    - Held mailboxes report the expected `LitigationHoldEnabled = True` and/or the In-Place hold GUID.
    **Fail:** if any gate fails, stop, diagnose with **§6**, and do not expand.

## Stage 4 — Expand
14. Repeat Stages 2–3 against `Archive Scope – Broad – Stage2` in controlled waves (enable archives →
    assign policy → trigger MFA → import PSTs → apply holds per determination), validating each wave with
    **`EXOARCH-Validation.ps1`** before the next.
15. **Report.** Produce **`Archive Validation – EXO – Report`** with **`EXOARCH-Report.ps1`** for the
    service/records owner: archives enabled, auto-expand status, policy coverage, archive growth, PST
    imports completed, and holds in force.

---

## Rollback
- **Archive move-to-archive:** remove the retention policy from a mailbox
  (`Set-Mailbox <id> -RetentionPolicy $null` or reassign the prior policy). Items already moved to the
  archive **stay in the archive** — MRM does not move them back; users still access them from the archive.
- **Retention tags/policy:** an unused tag/policy can be removed (`Remove-RetentionPolicyTag` /
  `Remove-RetentionPolicy`) once no mailbox references it.
- **Archive mailbox:** an archive can be disabled (`Disable-Mailbox <id> -Archive`), but **archive
  contents are removed on disable** and there is a grace period before the archive is unrecoverable — do
  not disable an archive that received PST data or that is under any hold. **Auto-expanding archive
  cannot be turned off** once enabled — there is no rollback for that switch; do not enable it without
  sign-off.
- **Holds:** a hold is released only on the legal/records owner's instruction (litigation:
  `Set-Mailbox <id> -LitigationHoldEnabled $false`; In-Place/eDiscovery: remove/close in the Purview
  case). **Never release a hold on your own initiative.**
