# Troubleshooting

Common failure signatures when standing up the archiving strategy, and how to resolve them. All
diagnostic cmdlets below are **read-only**.

---

## Archive mailbox will not enable

**Signature:** `Enable-Mailbox -Archive` errors, or `ArchiveStatus` stays `None`.

- **Licensing.** Archiving requires **Exchange Online Plan 2** (E3/E5) or **Plan 1 + Exchange Online
  Archiving add-on** — *verify your licensing/tenant*. Confirm the user's assigned plan in the admin
  center, then retry. (R1)
- **Role.** You need Recipient Management (mail-recipient) rights. Check
  `Get-ManagementRoleAssignment -RoleAssignee <you>`. (R2)
- **Replication lag.** After enabling, `ArchiveStatus` and `ArchiveGuid` can take time to populate.
  Re-check `Get-Mailbox <user> | fl ArchiveStatus,ArchiveGuid` after a short wait.

## Auto-expanding archive can't be turned off

**Signature:** you enabled `-AutoExpandingArchive` and now need to reverse it.

- **It is not reversible.** Auto-expanding archive **cannot be disabled** once enabled, per Microsoft.
  This is why the Implementation Guide enables it per-mailbox in pilot and only org-wide at expansion
  with explicit approval. There is no fix — plan around it.

## Items are not moving to the archive

**Signature:** archive is enabled and the policy is assigned, but `Get-MailboxStatistics -Archive`
shows `ItemCount = 0` or no growth.

- **The Managed Folder Assistant hasn't run.** MFA is asynchronous and throttled. Force it on a pilot
  mailbox: `Start-ManagedFolderAssistant -Identity <user>`, then re-check after it completes.
- **Tag age not reached.** `MoveToArchive` only moves items **older than** `AgeLimitForRetention`. If
  the mailbox has no content older than the threshold, nothing moves — that is correct. Verify with a
  user who has aged mail, or temporarily test with a smaller age on a **test** mailbox.
- **Tag disabled or wrong action.** Confirm
  `Get-RetentionPolicyTag <tag> | fl RetentionAction,RetentionEnabled` shows `MoveToArchive` and
  `True`.
- **Tag not linked / policy not assigned.** Confirm `Get-RetentionPolicy <policy>` lists the tag and
  `Get-Mailbox <user> | fl RetentionPolicy` shows the policy.
- **Item on hold.** Litigation/In-Place hold or Purview retention can keep an item in place; this is
  expected and takes precedence over the archive move.

## Retention policy assigned but behaviour unchanged

**Signature:** `Set-Mailbox -RetentionPolicy` succeeded but nothing happens.

- Retention-policy changes only take effect on the **next MFA cycle**. Trigger MFA and wait.
- Confirm the assignment actually stuck: `Get-Mailbox <user> | fl RetentionPolicy`.

## Purview DLM retention policy stuck or not applying

**Signature:** `Get-RetentionCompliancePolicy | fl DistributionStatus` shows a pending/error state.

- **Distribution takes time.** New DLM policies can take time to reach all locations; recheck later.
- **Connect the right session.** DLM cmdlets require **Security & Compliance PowerShell**
  (`Connect-IPPSSession`), *not* the Exchange Online session.
- **Scope/location.** Confirm `ExchangeLocation` includes the intended (pilot) mailboxes and nothing
  unintended.
- **Never add a delete action to "fix" it.** Keep the action `Keep` until records/legal signs off
  (R5). If a delete action appears in pilot, it was misconfigured — remove it.

## `Get-RetentionCompliancePolicy` / DLM cmdlets not found

**Signature:** command not recognized.

- You are in the wrong session. Run `Connect-IPPSSession` (Security & Compliance PowerShell). Use
  `Get-ArchiveScopeHealth.ps1` to confirm both sessions are connected.

## Pilot group resolves to zero mailboxes

**Signature:** scripts report `0 mailbox member(s)`.

- Confirm the group name/identity and that its members are **mailboxes** (not contacts or nested
  groups the cmdlet doesn't expand). Check `Get-DistributionGroupMember -Identity <group>`.

## Script made no change

**Signature:** `Set-ArchiveStrategy.ps1` printed a plan but changed nothing.

- **Working as designed.** The script is `-WhatIf` by default. Re-run with **`-Commit`** to apply,
  after reviewing the preview.

---

If a **Testing & Validation** gate keeps failing after these steps, stop the expansion, capture the
discovery/validation output, and review against the Implementation Guide's pass/fail gate for that
step before proceeding. Remember the reversibility limits — never enable a delete action as a
"cleanup" during troubleshooting.
