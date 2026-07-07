# 7. Best Practices

Durable practices for running Exchange Online Archiving, MRM, PST import, and holds well. These outlast
any single rollout.

## Licensing & entitlement
- **Verify archiving entitlement before you enable anything.** Archive and auto-expanding archive
  availability are plan-dependent and change over time — confirm per user (Requirement 2.1), never
  assume. A batch enable against unlicensed users produces silent no-ops and confusing tickets.
- **Right-size scope to entitlement.** Enable archives for users who actually need them (near quota,
  PSTs to ingest, or a hold obligation) rather than the whole tenant blindly.

## Auto-expanding archive (treat as irreversible)
- **Enable auto-expanding archive deliberately, with sign-off.** It **cannot be turned off**. Enable it
  where mailboxes will genuinely exceed the base archive quota, not reflexively.
- **Expect slower mailbox moves** for auto-expanded (multi-chunk) archives; factor that into any future
  migration or region move.

## MRM tags & policy hygiene
- **One archive DPT, named and reused.** Keep a single `Move to Archive – Default – Prod` DPT and one
  `Archive Retention Policy – EXO – Prod`; don't proliferate near-duplicate tags. Fewer, well-named
  artifacts are easier to validate and troubleshoot.
- **Set the archive-move age with the records owner**, and document it. It is a policy decision (how old
  before mail moves), not a technical default.
- **Trigger the Managed Folder Assistant to validate, but let it run naturally in production.**
  `Start-ManagedFolderAssistant` is for pilots/validation; don't script constant forced runs fleet-wide.
- **Remember the MRM vs Purview boundary.** MRM archive tags move items to the archive. For
  retention/deletion across workloads, DLP, or sensitivity labels, use the separate Purview product —
  keep the two models from silently overlapping on the same mailboxes without intent.

## PST import
- **Assign the Mailbox Import Export role explicitly and remove it after.** It is off by default and
  powerful — grant it for the import window under change control, then revoke.
- **Always target the archive (`IsArchive = TRUE`) for historical PST data**, so ingestion controls the
  primary mailbox rather than inflating it.
- **Validate item counts** against the source PSTs; a "completed" job with a lower count means dropped
  rows — reconcile before retiring the source PSTs.
- **Do not delete source PSTs until import is validated** and (if relevant) the archive is under the
  intended policy/hold.

## Holds & preservation
- **Holds follow a documented legal/records determination — always.** The implementer applies; the
  legal/records owner decides scope and duration. Record the matter ID in the artifact name
  (`Litigation Hold – <Matter> – Legal` / `eDiscovery Hold – <Matter> – Legal`).
- **Never disable an archive or release a hold on a held mailbox on your own initiative.** A held item
  lost is a defensibility failure. Rollback paths explicitly exclude held mailboxes.
- **Prefer litigation hold for simple, mailbox-wide preservation** and In-Place/eDiscovery holds when
  scope must be query- or date-bound to a matter.
- **Track hold inventory.** Periodically report which mailboxes are held and why, so holds are released
  when the legal owner closes the matter — stale holds accumulate cost and risk.

## Change discipline
- **Pilot-first, every time**, with the §5 pass/fail gates and the §3 rollback ready before touching
  production. Archive enablement, move-to-archive, and holds are all user- or legally-visible.
- **Keep artifact names verbatim** across EAC, Purview, docs, and scripts — consistent names are what
  make validation and troubleshooting fast.
- **Confirm your cloud.** Substitute the correct portal URLs and `Connect-ExchangeOnline
  -ExchangeEnvironmentName` value on GCC High / DoD; don't assume Commercial paths.
- **No secrets in automation.** Use modern-auth `Connect-ExchangeOnline` / `Connect-MgGraph`; never store
  credentials in scripts or scheduled tasks.
