# 6. Troubleshooting

Common failure modes for Exchange Online Archiving, MRM move-to-archive, PST import, and holds — with
the likely root cause and the fix. Reuse the artifact names from §1. Start every investigation by
re-running `EXOARCH-Discovery.ps1` to capture the current state.

---

## Archive won't enable / `ArchiveStatus` stays `None`
- **Symptom:** `Enable-Mailbox -Archive` fails, or `ArchiveStatus = None` after enabling.
- **Likely cause:** the user's plan does not include an archive mailbox (the #1 cause), or the enable
  hasn't replicated yet.
- **Fix:** verify archiving-capable licensing for that user (Requirement 2.1 — **verify in your
  tenant/plan**); assign an archiving-capable plan / the Exchange Online Archiving add-on, then re-enable.
  If licensed, allow time and re-check with `Get-Mailbox <id> | fl ArchiveStatus,ArchiveGuid`.

## Auto-expanding archive doesn't seem to apply
- **Symptom:** archive fills to the base quota and does not grow; `AutoExpandingArchiveEnabled = False`.
- **Likely cause:** auto-expand was never committed, the mailbox isn't archive-enabled yet, or the plan
  doesn't support auto-expand.
- **Fix:** confirm the archive is Active first, then enable auto-expand (`Enable-Mailbox <id>
  -AutoExpandingArchive` or org-wide `Set-OrganizationConfig -AutoExpandingArchive`). Remember it is
  **one-way** — a `False` value means it was never turned on, not reverted. Auto-expand
  availability/limits are **plan-dependent — verify in your tenant/plan**.

## Aged mail is not moving to the archive
- **Symptom:** the archive stays empty / primary mailbox doesn't shrink after assigning the policy.
- **Likely causes & fixes:**
  1. **Managed Folder Assistant hasn't processed the mailbox yet.** Move-to-archive is not instant.
     Trigger it: `Start-ManagedFolderAssistant <id>`, then re-check after it runs (large mailboxes take
     multiple cycles). This is expected, not a failure.
  2. **Retention policy not assigned.** `Get-Mailbox <id> | fl RetentionPolicy` should return
     `Archive Retention Policy – EXO – Prod`; if blank, run Implementation step 10.
  3. **DPT disabled or wrong age.** `Get-RetentionPolicyTag "Move to Archive – Default – Prod"` should
     show `RetentionAction = MoveToArchive`, `RetentionEnabled = True`, and an `AgeLimitForRetention`
     that is actually less than the age of mail in the mailbox. If the age is set higher than the
     mailbox's mail, nothing qualifies to move yet.
  4. **Tag not linked to the policy.** Re-run `EXOARCH-Set-MrmPolicy.ps1 -Commit` to relink.

## PST import landed in the primary mailbox, not the archive
- **Symptom:** imported folders appear in the primary mailbox; the archive is empty.
- **Likely cause:** the import mapping CSV row did not set the archive as the target
  (`IsArchive` not `TRUE`).
- **Fix:** correct the mapping CSV so each row's target is the archive (`IsArchive = TRUE`) and re-run
  the **`PST Import – Archive – Ingest`** job. (Items already in the primary can be moved to the archive
  by the move-to-archive policy over time, but re-importing correctly is cleaner for large sets.)

## PST import fails immediately / access denied
- **Symptom:** the import job or the mapping submission fails with a permissions error.
- **Likely cause:** the operator lacks the **Mailbox Import Export** management role (it is not assigned
  to any role group by default).
- **Fix:** assign the role (Requirement 2.2), sign out/in to refresh the token, and re-submit. Revoke the
  role after the import window (Best Practices).

## Litigation hold set but a deleted item is unrecoverable
- **Symptom:** `LitigationHoldEnabled = True` yet a hard-deleted test item cannot be recovered.
- **Likely cause:** the hold was only just applied (there can be a short propagation delay before it is
  fully effective), or you tested the wrong mailbox.
- **Fix:** confirm `LitigationHoldEnabled = True` and `LitigationHoldDate` is set on the exact mailbox;
  allow propagation, then re-test recovery from **Recoverable Items**. If it persists, re-apply per the
  determination and escalate — a held item must never be lost.

## In-Place / eDiscovery hold not showing on the mailbox
- **Symptom:** the Purview case shows the hold but `Get-Mailbox <id> | fl InPlaceHolds` is empty (or
  vice-versa).
- **Likely causes & fixes:** the hold is still propagating (allow time), the custodian/source scope in
  the case does not include that mailbox (correct the source in the case — **with the legal owner**), or
  the hold is off. Do not change hold scope on your own initiative.

## "I disabled an archive and lost data"
- **Symptom:** archive contents gone after `Disable-Mailbox -Archive`.
- **Cause:** disabling an archive **removes its contents** (there is a limited grace period before it is
  unrecoverable).
- **Fix / prevention:** never disable an archive that received PST data or that is (or its mailbox is)
  under any hold. If within the grace period, an archive can sometimes be reconnected — act immediately
  and escalate; do not rely on it.

## Portal path or connection fails on a Government cloud
- **Symptom:** a portal URL 404s, or `Connect-ExchangeOnline` reaches the wrong tenant.
- **Cause:** Commercial paths/parameters used on **GCC High / DoD**.
- **Fix:** use the sovereign-cloud portal URLs (`*.office365.us` / `*.microsoft.us`) and
  `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (or the DoD value). Confirm the
  tenant's cloud (Requirement 2.6) — **verify on your cloud**.
