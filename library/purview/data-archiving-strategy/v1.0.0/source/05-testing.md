# Testing & Validation

Validation proves the archiving strategy is configured, took effect, and is defensible — with
**explicit pass/fail gates** and captured evidence. Run these against the **pilot scope first**, then
against each expansion ring. Most checks are automated by `Test-ArchiveStrategy.ps1` (read-only);
the manual cmdlets are given so results can be reproduced by hand.

> All checks are **read-only**. None of them move or delete data.

---

## Gate 1 — Licensing and connectivity

| Check | Method | Pass |
|-------|--------|------|
| Admin can reach both surfaces | `Connect-ExchangeOnline` + `Connect-IPPSSession` succeed | No auth error |
| Pilot users are archiving-entitled | `Get-Mailbox <user> \| fl PersistedCapabilities` / license check in admin center | Plan 2 / archiving add-on present |

**Fail action:** resolve licensing (R1) / roles (R2) before continuing.

## Gate 2 — Archive mailbox provisioned

| Check | Method | Pass |
|-------|--------|------|
| Archive enabled for every pilot user | `Get-Mailbox <user> \| fl ArchiveStatus,ArchiveGuid` | `ArchiveStatus = Active`, non-empty `ArchiveGuid` |
| Auto-expanding archive matches design | `Get-Mailbox <user> \| fl AutoExpandingArchiveEnabled` and `Get-OrganizationConfig \| fl AutoExpandingArchive` | Matches the approved design |

## Gate 3 — MRM tag and policy correct

| Check | Method | Pass |
|-------|--------|------|
| Move-to-archive tag exists and is correct | `Get-RetentionPolicyTag "MTA-2yr" \| fl RetentionAction,AgeLimitForRetention,RetentionEnabled` | `RetentionAction = MoveToArchive`, expected age, `RetentionEnabled = True` |
| Policy links the tag | `Get-RetentionPolicy "RP-Corp-Archive" \| fl RetentionPolicyTagLinks` | Includes `MTA-2yr` |
| Policy assigned to pilot mailboxes | `Get-Mailbox <user> \| fl RetentionPolicy` | `RP-Corp-Archive` |

## Gate 4 — Managed Folder Assistant processed and items moved

| Check | Method | Pass |
|-------|--------|------|
| MFA has processed the mailbox | Confirm the MFA work cycle completed (or `Start-ManagedFolderAssistant` was run) and no error | Processed without error |
| Aged items are in the archive | `Get-MailboxStatistics <user> -Archive \| fl ItemCount,TotalItemSize` before vs. after | Archive `ItemCount`/`TotalItemSize` increased for users with content older than the age threshold |
| Primary store reduced | Compare `Get-MailboxStatistics <user>` primary size before/after | Primary `TotalItemSize` trending down where content aged out |

> If aged content exists but nothing moved, MFA may not have run yet (it is throttled/asynchronous),
> or the tag age/enabled flag is wrong — see Troubleshooting.

## Gate 5 — Purview DLM retention policy (if staged)

| Check | Method | Pass |
|-------|--------|------|
| Policy distributed successfully | `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" \| fl DistributionStatus,Enabled` | Healthy/`Success`, `Enabled = True` |
| Action is Keep only in pilot | `Get-RetentionComplianceRule -Policy "DLM-Exchange-Keep" \| fl RetentionComplianceAction` | `Keep` (no delete in pilot) |
| Scope is pilot-only | `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" \| fl ExchangeLocation` | Pilot mailboxes only |

## Gate 6 — No unintended deletion / hold conflict

| Check | Method | Pass |
|-------|--------|------|
| No delete action active in pilot | Review all MRM tags in `RP-Corp-Archive` and the DLM rule | No `DeleteAndAllowRecovery` / `Delete` / `KeepAndDelete` enabled |
| Legal holds respected | Confirm with legal that any holds are in place and unaffected | Holds intact; archiving does not bypass hold |

**Fail action for any gate:** stop expansion, record the failing gate, apply the matching
Troubleshooting fix, re-run the gate, and only proceed when green.

---

## Evidence to capture

- Discovery output (baseline) and validation output (post-change) from the scripts.
- `Get-Mailbox`/`Get-MailboxStatistics` before/after for a sample of pilot users (archive growth,
  primary reduction).
- The MRM tag/policy definitions and the DLM policy distribution status.
- The adoption/tiering report from `Export-ArchiveReport.ps1`.
- Records/compliance/legal sign-off reference for the retention timeline (R5).

Store the evidence with the change record so the archiving strategy is **defensible** on audit.
