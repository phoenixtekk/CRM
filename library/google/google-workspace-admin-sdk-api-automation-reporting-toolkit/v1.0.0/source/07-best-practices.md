# Best Practices

Durable practices for building and operating Admin SDK / API automation on Google Workspace.

## Security & credentials
- **Never put keys or secrets in code.** Use ADC, Workload Identity, or a secrets manager. Do not
  create or download service-account JSON keys unless unavoidable; if you must, store them outside the
  repo and rotate on a schedule.
- **Least scope, always.** Grant each task only the narrowest OAuth scope it needs; default to
  `*.readonly`. Add a write scope to the DWD grant only for the specific tool that needs it, and review
  the grant whenever a new automation is added.
- **Least-privilege impersonation.** Impersonate a purpose-built admin subject (`Impersonation Subject –
  Reports – ReadOnly`) with only the privileges the reports require — never a super-admin for routine
  runs.
- **Treat domain-wide delegation as sensitive.** The DWD grant `DWD Grant – AdminSDK – LeastScope` is a
  domain-level trust; audit it periodically, keep the scope list minimal and documented, and remove the
  service account's client ID promptly if the automation is retired.
- **Rotate and revoke.** Rotate credentials on a schedule; revoke immediately on suspected exposure.

## Safe automation
- **Dry-run first, apply explicitly.** Every write tool defaults to `--dry-run` and prints the exact
  plan; a change happens only with `--apply`. Keep that discipline for every new tool.
- **Idempotent by design.** Write automations should compute desired-vs-actual and make only the needed
  changes, so re-running is a no-op. Test idempotency (Gate 4-B) before trusting a tool.
- **Always log a reversible change record.** Apply runs write a per-field prior-value log enabling
  `--revert`. Keep those logs — they are your rollback.
- **Pilot before fleet.** Prove every automation on the pilot OU/group, then expand one controlled wave
  at a time.

## Reliable API access
- **Paginate everything.** Directory / Reports / Drive / Groups results are paged; never assume a single
  page. Use the shared client's pagination.
- **Back off on 429 / 5xx.** Use exponential backoff with jitter and a retry cap. Respect per-project
  quotas; keep automation in its own project so its quota is isolated.
- **Handle Reports API latency.** Activity events can lag; treat reports as point-in-time evidence and
  **verify current latency for your event types** in Google's docs before drawing real-time conclusions.
- **Prefer read-only scopes** for anything that only reports.

## Reporting & evidence
- **Name and date every artifact** `<Purpose> – <Scope> – <Stage>` with a timestamp, and write both CSV
  (for humans) and JSON (for pipelines) where useful. Consistent naming makes evidence auditable.
- **Make reports deterministic** — same inputs, same output ordering — so diffs between runs are
  meaningful.
- **Schedule for cadence, not for real-time.** Use Cloud Scheduler / cron / Task Scheduler for recurring
  evidence; ensure the scheduled context has ADC available.

## Maintainability
- **Centralize auth and the API client** so every tool requests scopes and handles pagination/retry the
  same way; a new tool should reuse them, not re-implement them.
- **Keep vendor-specific detail current.** Google console paths, API scopes, and Reports event names
  change; verify against current Google documentation and flag preview/tenant-specific behavior "verify
  in your tenant".
- **Version desired-state inputs** (provisioning CSVs) in change control so provisioning is reviewable.
