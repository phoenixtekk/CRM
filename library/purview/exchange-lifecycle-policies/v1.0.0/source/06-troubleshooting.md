# Troubleshooting — Exchange Lifecycle Policies in Microsoft Purview

Field issues and how to resolve them, grouped by engine. Start every investigation with a read-only
baseline: `.\DLCEXO-Discovery.ps1 -IncludeMailboxSample` and `.\DLCEXO-Report.ps1`. Remember the two
timing realities: **Purview retention** can take time to fully provision after a policy is created, and
**MRM cleanup** runs on the **Managed Folder Assistant** cycle (roughly daily, best-effort).

---

## Connection & permissions

**`Get-RetentionCompliancePolicy` / `New-RetentionCompliancePolicy` not recognized or access denied.**
- You are not connected to **Security & Compliance PowerShell**, or lack the role. Run
  `Connect-IPPSSession` with a **Retention Management / Compliance Administrator** account
  (`02-requirements.md` R2/R3). These cmdlets do **not** exist in a plain `Connect-ExchangeOnline`
  session.

**`New-RetentionPolicyTag` / `Set-Mailbox -RetentionPolicy` fails.**
- Those are **Exchange Online** cmdlets — run `Connect-ExchangeOnline` (separate from IPPS) with the
  **Retention Management** role. The scripts expect **both** connections open.

**"You don't have sufficient permissions" on `Set-Mailbox`.**
- MRM assignment needs **Recipient Management** (or Retention Management with recipient write). Assign
  the least-privilege role rather than escalating to Global Admin.

## Purview retention (keep / keep-then-delete)

**Policy created but mail isn't being preserved yet.**
- Retention policies take time to **provision and apply** after creation (can be hours). Re-check with
  `Get-RetentionCompliancePolicy -Identity <name> -DistributionDetail | Select DistributionStatus`.
  Wait for distribution to complete before concluding the "keep" gate (G3) failed.

**A "deleted" test message really disappeared under an active retain rule.**
- Either the policy hasn't finished distributing (above), or the mailbox isn't actually in scope. Run
  `DLCEXO-Test-Readiness.ps1` — the **scope = pilot only** check shows whether the mailbox is in
  `ExchangeLocation`. Retention preserves to **Recoverable Items**; verify there / via eDiscovery, not
  just the visible folders.

**I need to remove a policy but `Set-RetentionCompliancePolicy -Enabled $false` is refused.**
- The policy is under **Preservation Lock** — by design it **cannot be disabled, deleted, or shortened
  by anyone**, including a Global Admin. This is why this solution keeps policies **unlocked** unless
  records explicitly directs locking. There is no self-service unlock.

**Delete action removed mail I did not expect.**
- Check `ExpirationDateOption` (**CreationAgeInDays** vs **ModificationAgeInDays**) — the wrong basis
  ages mail differently than intended — and the `RetentionDuration`. Because deletion past the recovery
  window is **irreversible**, treat this as an incident: freeze expansion, confirm scope, and escalate
  to records/legal if held or in-scope-but-not-approved mail was affected.

**Group-scoped policy isn't covering new members.**
- A **static** group scope targets the mailboxes that were members **when scoped**; it does not
  auto-re-scope. Either re-run configuration to refresh scope or move to an **adaptive scope** (E5) at
  expand time (`03-implementation.md` Phase 5; `07-best-practices.md`).

## Exchange MRM cleanup (Deleted Items / Junk / archive)

**Assigned the MRM policy but nothing has been cleaned.**
- The **Managed Folder Assistant** hasn't run yet. Trigger it on the pilot mailbox:
  `Start-ManagedFolderAssistant -Identity <pilotMailbox>`, then re-check. Also confirm the tags are
  **RetentionEnabled = $true** and the item is genuinely **older** than `AgeLimitForRetention`.

**MoveToArchive tag isn't moving anything.**
- The mailbox has **no archive**. `Get-Mailbox <mbx> | Select ArchiveStatus,ArchiveState` — if there is
  no archive, `Enable-Mailbox -Identity <mbx> -Archive` first (licensing permitting), then re-run the
  MFA. MoveToArchive has nowhere to move mail without an archive.

**Cleanup is deleting mail that should be kept.**
- A **hold** (litigation/eDiscovery) or a **Purview retain** rule should override an MRM delete
  (retain wins over delete — `07-best-practices.md`). If held mail was removed, treat it as a **legal
  incident** and escalate. Otherwise confirm the tag ages/types match the design (`03-implementation.md`
  Phase 3b) and that you didn't attach an unintended DPT.

**Age limits look right but items persist past the age.**
- MFA is **best-effort** and throttled by mailbox size and work-cycle; large mailboxes converge over
  multiple cycles. Confirm the tag is linked to the assigned policy (`Get-RetentionPolicy <name> |
  Select RetentionPolicyTagLinks`) and that the item's folder matches the tag **Type**.

## Scope & blast radius

**A non-pilot mailbox was affected.**
- **Stop and roll back scope immediately** (`03-implementation.md` Rollback): unassign the MRM policy
  (`Set-Mailbox -RetentionPolicy $null`) and remove the mailbox from the Purview policy's
  `ExchangeLocation`. Then re-run `DLCEXO-Test-Readiness.ps1` (the C5 blast-radius check) until it PASSes
  before continuing. Investigate how the mailbox entered scope (group membership? "All"? adaptive-scope
  query?).

**Readiness gate shows GAP on "scope = pilot only".**
- The policy is scoped to **All** or lists mailboxes outside the pilot group. Re-scope to the pilot
  before doing anything else — this is the guardrail that keeps a destructive rule off production
  mailboxes.

## Reporting & evidence

**`DLCEXO-Report.ps1` shows no per-mailbox rows.**
- The policy is likely scoped to **All** or an **adaptive scope**, so there are no explicit addresses to
  enumerate. Pass `-PilotGroup` to report per-mailbox, or accept that estate-wide scope reports at the
  policy level.

**I need audit evidence of what changed.**
- Export `DLCEXO-Report.ps1` and `DLCEXO-Test-Readiness.ps1` output at each phase and keep the
  policy/rule/tag names, scope, and durations. For end-to-end change history, use the **unified audit
  log** (retention config changes are audited) and the Purview policy's own change record.

> If a symptom isn't covered here, capture a fresh `DLCEXO-Discovery.ps1` baseline and re-run
> `DLCEXO-Test-Readiness.ps1` — most issues resolve to (a) not connected to both endpoints, (b) timing
> (distribution / MFA cycle), (c) scope drift, or (d) a hold correctly overriding a delete. Regulatory,
> records, and legal questions go to those owners, not the administrator.
