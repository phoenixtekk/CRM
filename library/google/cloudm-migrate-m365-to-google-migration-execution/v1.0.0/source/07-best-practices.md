# Best Practices

Durable practices for executing M365→Google migrations with CloudM Migrate reliably at scale.

## Sequencing & waves

- **Always pilot first.** Prove `Migration Profile – Mail+Drive – Standard` and both connections on
  `Migration Wave – Pilot – Wave0` before any production wave. Choose pilot users who span the hardest
  data types (huge mailbox, large OneDrive, Shared-Drive/SharePoint heavy).
- **Pre-stage everything you can.** Move the historical bulk of bytes days before the change window so
  the cutover-window delta is small and fast. Cutover risk scales with how much data crosses during
  the window — keep it minimal.
- **One profile, many waves.** Reuse a single approved profile across waves so behavior is consistent
  and predictable; change the profile only through review.
- **Cohort waves to departments/sites.** Keeps communications, support, and rollback contained to a
  known group.
- **Sequence waves under the throttling ceiling.** Don't run so many concurrent pre-stage/delta passes
  that you saturate Microsoft Graph or Gmail API quotas — use `plan-migration-waves.py` guidance.

## Throttling & throughput

- **Expect provider throttling, design for it.** Microsoft (Graph/Exchange) and Google (Gmail/Drive)
  both throttle; treat 429/backoff as normal signal, not failure. Tune concurrency down when throttled
  rather than retrying blindly.
- **Scale self-hosted horizontally** if throughput is the bottleneck — more migration servers/workers,
  not just bigger ones (**verify scaling model for your CloudM version**).
- **Run pre-stage off-hours** where provider quotas are less contended; reserve the change window for
  the small final delta.

## Validation & data integrity

- **Reconcile against the Scan baseline, not against a guess.** Capture per-user scan totals before
  pre-stage and compare final counts to them.
- **Agree a variance tolerance up front** and subtract known exclusions (Recoverable Items, filtered
  date ranges) so the comparison is honest.
- **Always run a post-cutover delta.** Items delivered to M365 during the MX switch must be swept.
- **Check permissions and over-sharing explicitly.** Confirm migrated Drive/Shared-Drive sharing
  matches intent and that no unintended "anyone" links were created.

## Change control & safety

- **Treat MX/DNS cutover as the highest-impact change.** Stage it under change control with a written
  runbook and a pre-agreed rollback (revert MX, M365 stays authoritative).
- **Keep the source read-only in effect until validated.** Don't decommission M365 mailboxes/data
  until the wave passes its validation gate — the source is your rollback.
- **Verify SPF/DKIM/DMARC before and after** each cutover; misaligned auth silently damages
  deliverability.

## Security & credentials

- **Never put secrets in code or the repo.** Entra client secrets/certs and the Google service-account
  JSON key live only in the CloudM platform's secured credential store / your secrets manager. The
  included scripts use OAuth/ADC and read no secrets from source.
- **Least privilege on both sides.** Grant only the Graph permissions and DWD scopes CloudM's
  connectors require (**verify the exact lists for your version**); remove them after the project.
- **Rotate and revoke on completion.** Retire the app registration secret, the service-account key,
  and the DWD grant when the migration closes.

## Operations

- **Watch health between passes.** Run `check-migration-health.py` to catch rising error/throttling
  rates and destination license/account issues before they compound across waves.
- **Document per-wave outcomes.** Keep each `Validation Report – <Scope> – <Stage>` as the audit
  record of what moved and how it was verified.
- **Defer CloudM specifics to CloudM.** For console behavior, licensing, fidelity matrices, and
  version-specific features, use CloudM's own documentation and support — this playbook governs
  procedure and sequencing, not the tool's internals.
