# Deliverables Summary

This solution delivers a complete, pilot-first playbook for implementing **Google Workspace Migration
for Microsoft Exchange (GWMME)** — migrating **mail, calendar, and contacts** from Exchange/M365 into
Gmail — plus five Python automation tools. Tool internals are deferred to Google's current GWMME
documentation; everything here is the **procedure, sequencing, and automation** around it.

## Documentation

- **01 — Solution Overview.** What GWMME migrates, where it fits vs. Google Workspace Migrate and
  third-party tools, the reference model (host → source EWS → Google service identity → mapping →
  batches → validation), the naming convention, benefits, and limitations.
- **02 — Requirements.** Solution-specific prerequisites (migration host, source Exchange/M365 access +
  read identity, Google destination service identity, provisioned targets + master mapping, source
  sizing, cutover coexistence + rollback), each with verify/implement, building on the shared Google
  category requirements.
- **03 — Implementation.** Ordered **Assess → Design → Configure → Pilot → Validate → Expand** steps
  with named artifacts, explicit pass/fail gates at each phase, MX/DNS cutover, and a rollback table.
- **05 — Testing & Validation.** Nine validations (prereq readiness, mapping integrity, mail/calendar/
  contacts completeness, error triage, throttling headroom, per-wave completeness, cutover mail flow),
  each with expected pass/fail.
- **06 — Troubleshooting.** Common GWMME failure modes — throttling/API limits, permission/access
  errors, incomplete/delta items, connection/mapping issues, cutover mail-flow — with resolutions.
- **07 — Best Practices.** Durable practices for tool selection, pilot-first gating, batching/
  throttling, identity/security, data quality, and traceability.
- **Executive Summary.** Outcome, approach, and why the migration is low-risk.

## Python tools (5)

All tools are **read-only or dry-run by default**, use **OAuth/ADC** (no credentials or keys in code),
and standard-library-first (Google client libraries only where the Admin SDK / Workspace APIs are read).

1. **`gwmme_discovery.py`** — *Assessment / discovery (read-only).* Reconciles the source mailbox
   inventory against provisioned Google users via the Directory API and emits `Mapping – Users – Master`
   plus a gap report (sources without targets, targets without sources).
2. **`gwmme_prereq_validator.py`** — *Prerequisite / health check (read-only).* Verifies host
   reachability to the source EWS and Google endpoints, that the Google service identity authenticates,
   and that the master mapping is well-formed — the Gate C readiness check before installing GWMME.
3. **`gwmme_batch_planner.py`** — *Throttle-aware batch planner (dry-run).* Groups mailboxes into a
   pilot wave and throttle-budgeted production waves, isolating oversized mailboxes into dedicated
   waves; writes the wave assignment back to the mapping.
4. **`gwmme_validation_report.py`** — *Post-migration validation/report (read-only).* Compares source
   vs. destination **mail, calendar, and contacts** counts per user (Gmail/Calendar/People read-only
   APIs), flags shortfalls beyond tolerance, and writes `Validation Report – <Scope> – <NN>`.
5. **`gwmme_config_helper.py`** — *Scope/config helper (read-only / generate-only).* Validates mapping
   integrity, derives per-wave subset CSVs GWMME consumes, and computes a per-wave throttle-budget /
   run-time estimate.

## Outcome

Exchange/M365 mailboxes migrated to Gmail **complete and intact** — GWMME configured, source and
destination access granted, mailboxes mapped, batches run and validated, and mail flow cut over to
Google under change control with a rehearsed rollback.
