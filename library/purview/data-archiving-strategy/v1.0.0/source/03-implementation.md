# Implementation

This guide configures the archiving strategy in exact, ordered steps. **Every high-impact change is
piloted on a named test scope first**, with pass/fail gates and a rollback for each step. Cmdlet
names and portal paths follow Microsoft's public documentation; where a capability is plan-gated or
the portal is evolving, **verify your licensing/tenant**. All write operations in the provided
scripts are gated behind an explicit `-Commit` switch (default is read-only / `-WhatIf`).

**Named objects used throughout (adjust to your naming standard):**

| Object | Name used in this guide |
|--------|--------------------------|
| Pilot mailbox group (mail-enabled security group) | `grp-archive-pilot` |
| MRM move-to-archive tag (Default Policy Tag, all content) | `MTA-2yr` (Move to Archive, 730 days) |
| MRM optional personal tag | `MTA-Personal-1yr` (Move to Archive, 365 days) |
| MRM retention policy | `RP-Corp-Archive` |
| Purview DLM retention policy (keep only in pilot) | `DLM-Exchange-Keep` |
| Placeholder domain | `contoso.com` |

> Retention *durations* (730/365 days above) are **illustrative**. Use the values **records/compliance
> approved** (Requirement R5). Do **not** enable any *delete* action until records/legal has signed off.

---

## Step 0 — Preflight (read-only)

1. Connect and confirm access:
   ```powershell
   Connect-ExchangeOnline
   Connect-IPPSSession
   Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"
   ```
2. Run the scope/health helper: `.\Get-ArchiveScopeHealth.ps1 -PilotGroup grp-archive-pilot`.
3. Run discovery: `.\Invoke-ArchiveDiscovery.ps1 -OutputPath .\discovery`.

**Pass/fail gate:** All three connections succeed; discovery reports current archive status, mailbox
sizes, existing MRM tags/policies, existing DLM retention policies, and the org-level
`AutoExpandingArchive` value. **If any connection fails, stop** and resolve licensing/roles (R1–R3).

**Rollback:** None — read-only.

---

## Step 1 — Confirm licensing and the org-level auto-expanding archive posture

1. Verify Plan 2 / archiving entitlement on the pilot users (R1).
2. Check the org setting **without changing it yet**:
   ```powershell
   Get-OrganizationConfig | Format-List AutoExpandingArchive
   ```
3. **Decide the tiering design** with stakeholders: which mailboxes get archives, the age threshold
   for move-to-archive, and whether **auto-expanding archive** is needed (only for users whose
   archive will exceed the base archive quota).

**Pass/fail gate:** Entitlement confirmed on all pilot users; the design (age threshold, scope,
auto-expanding yes/no) is documented and approved.

**Rollback:** None — no change made.

> **Caution:** `Set-OrganizationConfig -AutoExpandingArchive $true` is **org-wide and not
> reversible.** Prefer **per-mailbox** `Enable-Mailbox -AutoExpandingArchive` during pilot so the
> blast radius is limited to test users.

---

## Step 2 — Enable archive mailboxes for the PILOT scope only

1. Preview with the configuration script (default `-WhatIf`):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableArchive -WhatIf
   ```
2. Apply to the pilot scope:
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableArchive -Commit
   ```
   (Equivalent manual cmdlet: `Enable-Mailbox -Identity <user> -Archive`.)
3. If the design calls for auto-expanding archive on specific pilot users:
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableAutoExpanding -Commit
   ```
   (Equivalent: `Enable-Mailbox -Identity <user> -AutoExpandingArchive`.)

**Pass/fail gate:** `Get-Mailbox <pilotuser> | fl ArchiveStatus,ArchiveGuid` shows
`ArchiveStatus = Active` and a non-empty `ArchiveGuid` for every pilot user.

**Rollback:** `Disable-Mailbox -Identity <user> -Archive` disconnects the archive; the disconnected
archive is retained for **30 days** and can be reconnected within that window, after which it is
**permanently removed**. Auto-expanding archive, once enabled, **cannot be disabled**.

---

## Step 3 — Create the MRM move-to-archive tag and retention policy

1. Preview, then create the tag and policy (script gates writes behind `-Commit`):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -CreateMrmPolicy -TagName MTA-2yr -AgeDays 730 `
       -PolicyName RP-Corp-Archive -WhatIf
   .\Set-ArchiveStrategy.ps1 -CreateMrmPolicy -TagName MTA-2yr -AgeDays 730 `
       -PolicyName RP-Corp-Archive -Commit
   ```
   Equivalent manual cmdlets:
   ```powershell
   New-RetentionPolicyTag -Name "MTA-2yr" -Type All -RetentionAction MoveToArchive `
       -AgeLimitForRetention 730 -RetentionEnabled $true
   New-RetentionPolicy   -Name "RP-Corp-Archive" -RetentionPolicyTagLinks "MTA-2yr"
   ```
2. (Optional) add a **personal** move-to-archive tag users can apply to folders:
   ```powershell
   New-RetentionPolicyTag -Name "MTA-Personal-1yr" -Type Personal `
       -RetentionAction MoveToArchive -AgeLimitForRetention 365 -RetentionEnabled $true
   Set-RetentionPolicy -Identity "RP-Corp-Archive" `
       -RetentionPolicyTagLinks "MTA-2yr","MTA-Personal-1yr"
   ```

**Pass/fail gate:** `Get-RetentionPolicyTag "MTA-2yr"` shows `RetentionAction = MoveToArchive` and the
expected `AgeLimitForRetention`; `Get-RetentionPolicy "RP-Corp-Archive"` lists the tag(s).

**Rollback:** `Set-RetentionPolicy -Identity RP-Corp-Archive -RetentionPolicyTagLinks @()` unlinks the
tags (stops future moves); `Remove-RetentionPolicyTag` / `Remove-RetentionPolicy` removes them.
**Items already moved to the archive are not moved back.**

---

## Step 4 — Assign the policy to the pilot mailboxes and run the Managed Folder Assistant

1. Assign and process (preview then commit):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -AssignPolicy RP-Corp-Archive -WhatIf
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -AssignPolicy RP-Corp-Archive -Commit
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -RunAssistant -Commit
   ```
   Equivalent manual cmdlets:
   ```powershell
   Set-Mailbox -Identity <pilotuser> -RetentionPolicy "RP-Corp-Archive"
   Start-ManagedFolderAssistant -Identity <pilotuser>
   ```

**Pass/fail gate:** `Get-Mailbox <pilotuser> | fl RetentionPolicy` shows `RP-Corp-Archive`; after the
MFA cycle, `Get-MailboxStatistics <pilotuser> -Archive` shows a growing archive
`TotalItemSize`/`ItemCount` for items older than the age threshold.

**Rollback:** `Set-Mailbox -Identity <user> -RetentionPolicy "Default MRM Policy"` reverts to the
built-in policy; future moves stop. Already-archived items remain in the archive.

---

## Step 5 — (Optional, keep-only in pilot) stage a Purview DLM retention policy

> Only if records/compliance has approved a **keep** timeline. **Do not** enable *delete* in pilot.

1. In the **Purview portal → Data Lifecycle Management → Retention policies**, or via PowerShell:
   ```powershell
   New-RetentionCompliancePolicy -Name "DLM-Exchange-Keep" -ExchangeLocation <pilot mailbox(es)>
   New-RetentionComplianceRule   -Name "DLM-Exchange-Keep-Rule" -Policy "DLM-Exchange-Keep" `
       -RetentionDuration 2555 -RetentionComplianceAction Keep
   ```
   (`Keep` only — no `Delete`/`KeepAndDelete` until R5 sign-off. `2555` days ≈ 7 years, illustrative.)
2. Scope the policy to the **pilot mailboxes only** for the first ring.

**Pass/fail gate:** `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" | fl DistributionStatus`
reaches a healthy/`Success` distribution state and applies to the pilot scope only.

**Rollback:** `Set-RetentionCompliancePolicy -Identity "DLM-Exchange-Keep" -Enabled $false` or
`Remove-RetentionCompliancePolicy`. Because the action is **Keep**, no data is deleted, so rollback is
safe.

---

## Step 6 — Validate the pilot

Run the validation script and capture evidence:
```powershell
.\Test-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -PolicyName RP-Corp-Archive `
    -OutputPath .\validation
```

**Pass/fail gate:** All pilot users show archive enabled, `RP-Corp-Archive` assigned, MFA processed,
archive item count > 0 where aged content exists, and (if staged) the DLM policy in a healthy state.
See **Testing & Validation** for the full gate list.

**Rollback:** See each step above; disable/unlink rather than delete.

---

## Step 7 — Expand (enforce) to production under change control

Only after the pilot passes and is signed off:

1. Widen the archive-enable + policy-assignment scope from `grp-archive-pilot` to the approved
   production population (in rings, not all at once).
2. If auto-expanding archive is org-wide by design, enable it org-wide **only now** and **only with
   explicit approval** — remember it is **irreversible**:
   ```powershell
   Set-OrganizationConfig -AutoExpandingArchive $true
   ```
3. (Optional, tiering) enable **Microsoft 365 Archive** for inactive SharePoint sites from the
   **SharePoint admin center / Microsoft 365 Archive** — pay-as-you-go via an Azure subscription;
   **verify your licensing/tenant** as this capability is billing-gated and evolving.
4. Re-run `Test-ArchiveStrategy.ps1` and `Export-ArchiveReport.ps1` for each ring and archive the
   evidence.

**Pass/fail gate:** Each ring validates green before the next ring starts; reports show archive
adoption and primary-store reduction trending as designed.

**Rollback:** Pause expansion; for a ring, unlink/reassign policies and disable archives per Steps 2–4
(bearing the reversibility caveats in mind). Never enable a delete action to "clean up" a rollback.
