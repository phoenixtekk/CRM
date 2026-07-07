# Best Practices

Durable practices for a reliable GWMME (Google Workspace Migration for Microsoft Exchange)
implementation. They complement the ordered steps in Implementation (03) and the gates in Testing (05).

## Tool selection & scope

- **Use GWMME for what it is for.** Mail, calendar, and contacts — smaller-to-mid scale, single host,
  no server infrastructure. If files (Drive/OneDrive/SharePoint) or Teams/chat are in scope, plan a
  **separate** tool (Google Workspace Migrate or a third-party) for those. Don't force GWMME past its
  data types.
- **Right-size against scale.** Very large estates strain a single-host tool. If throughput or
  parallelism needs exceed one host, evaluate a server-based platform before committing to GWMME.
- **Defer tool internals to the vendor.** Confirm supported Exchange/EWS versions, mapping columns,
  scopes, and dialogs against **Google's current GWMME documentation** for your build — flag anything
  version-dependent as "verify for your version" rather than assuming.

## Pilot-first, gate everything

- **Never scale a pipeline you haven't validated.** The pilot exists to prove permissions, connections,
  and completeness. Only pass `Gate E` when mail, calendar, and contacts are all validated.
- **One wave at a time.** Do not start `Migration Wave – <Scope> – <NN+1>` until `<NN>` passes its
  validation gate and its errors are triaged.
- **Treat mail-flow/DNS cutover as the real risk.** Data movement is largely reversible (GWMME reads
  source, writes destination, deletes nothing). MX/DNS cutover is not — gate it, schedule it in a
  change window, and keep `Rollback Plan – Cutover – Mail` on standby.

## Batching & throttling

- **Size waves to the throttling budget, not to convenience.** Firing everything at once triggers
  source/destination throttling and half-finished runs. Start conservative, measure, then increase.
- **Isolate heavy mailboxes.** Very large or item-heavy mailboxes get their own smaller waves so one
  slow mailbox doesn't stall a batch.
- **Watch retry/throttle signals in the logs.** Sustained retries mean you are over budget — reduce
  concurrency/wave size and re-plan (`gwmme_batch_planner.py`) rather than pushing harder.
- **Run a delta immediately before cutover.** Mail keeps arriving at the source during migration; a
  final delta catches it so nothing is lost at the handover.

## Identity, access & security

- **Least privilege, both sides.** Grant `Source Access – Exchange – App Impersonation` only over the
  in-scope mailboxes; grant `Service Identity – Google – Migration` only the migration scopes it needs.
- **Never commit or export credentials.** Keep the Google service credential and any source secret in a
  secure store, out of the repo, out of logs. The scripts here use OAuth/ADC and never embed keys.
- **Revoke when done.** Remove the source impersonation grant and disable/revoke the Google service
  identity's migration scopes at program end.
- **Dedicate and lock down the host.** `Migration Host – GWMME – Primary` is migration-only, patched,
  and restricted to the migration team.

## Data quality & validation

- **Validate completeness, don't assume it.** Compare source vs. destination counts for mail, calendar,
  and contacts every wave (`gwmme_validation_report.py`); spot-check recurring meetings and
  multi-field contacts by hand.
- **Classify every error.** Permission, throttling, unsupported/oversized item, delta gap — an
  unexplained error is an unvalidated wave.
- **Keep the mapping authoritative.** `Mapping – Users – Master` is the single source of truth; derive
  wave subsets from it, never hand-edit rows in isolation.

## Traceability & communication

- **Name and reuse artifacts.** `<Purpose> – <Scope> – <Stage>` across host, access, mapping, waves,
  and reports makes every run auditable.
- **Retain logs and reports.** Keep GWMME run logs and each `Validation Report – …` for audit and for
  diagnosing later waves.
- **Set user expectations.** Communicate cutover timing, what moves (mail/calendar/contacts) and what
  does not (files), and where to find migrated data in Gmail.
