# 7. Best Practices — Risk & Compliance Dashboard (Microsoft Purview)

Field-proven recommendations for a trustworthy, low-maintenance consolidated dashboard.

## Design
- **Treat it as a reporting layer, not a control.** The dashboard reflects posture; it never enforces DLP,
  applies labels, or makes a retention/records call. Keep those decisions in their own Purview solutions
  and their governance owners — the dashboard's credibility depends on it staying read-only.
- **Thresholds are policy, not defaults.** RAG bands (what counts as red) are an organizational decision —
  agree them with compliance/records/legal (Requirement 2.7) and record them in the config, not in
  someone's head. Revisit them as posture matures.
- **One tile per signal, with an honest source badge.** Every tile shows whether it's a **live** read or an
  **owner-captured** figure. Never blur the two; a fabricated number destroys trust in the whole board.
- **Start with what you can reconcile.** Ship the `live` feeds you can validate against the portal first
  (DLP/label/retention/audit); add `owner-captured` tiles as owners commit to a cadence.

## Sources & honesty
- **Never invent a feed.** Where Microsoft exposes no reliable public read (Compliance Manager score,
  Insider Risk / Communication Compliance detail, DSPM), capture the figure from the portal via a named
  owner — and flag **"verify your licensing/tenant."** If Microsoft later ships a stable interface, switch
  that tile to `live` and reconcile it.
- **Show licensing state.** An E5-gated signal in an E3 tenant is a "not licensed" tile, not a blank.
  Buyers and auditors should see *why* a tile is empty.
- **Date every owner-captured figure.** A number with no "captured on" date is untrustworthy; validation
  flags stale figures so the board never quietly drifts.

## Privacy & role separation (Insider Risk & Communication Compliance)
- **Aggregate only — always.** These HR-sensitive feeds appear as **counts** (policies active, open
  alerts), never as names, case content, or reviewable items. The dashboard must never become a back-door
  into case data.
- **Keep the collector out of investigator roles.** The account that builds the dashboard holds
  least-privilege **read** roles only and is **not** in Insider Risk / Communication Compliance
  investigator role groups. The program owners enter the aggregate figures themselves.
- **Distribute deliberately.** The rendered HTML is for the intended audience; do not scatter the raw
  dataset if any owner-captured figure is sensitive beyond that audience.

## Audit
- **Enable ingestion once, deliberately.** If you enable unified audit-log ingestion, do it under change
  control (`-Commit`, piloted) — it is tenant-wide. Remember audit captures **from enablement forward**;
  set expectations that early dashboards have a short volume history.
- **Know Standard vs Premium.** Premium extends retention and adds record types; reflect which you have on
  the Audit tile so volume tiles are read in the right context.

## Operations
- **Pilot, reconcile, then schedule.** Prove the numbers against the portal (Testing Trust gate) before
  anyone makes a decision from the board. Re-validate after every scheduled run and every added signal.
- **Schedule under a least-privilege identity, no secrets.** Run the collector as a service identity with
  only the read roles it needs; never embed credentials, tokens, or connection secrets in the scripts.
- **Version the config.** Keep `RiskComplianceDashboard.config.json` in source control (thresholds are
  policy) so changes to RAG bands or scope are reviewable and reversible.
- **Document rollback.** Deleting the local artifacts removes the dashboard with **no tenant change**; only
  audit-ingestion enablement is a tenant change — revert it only with compliance sign-off (disabling audit
  reduces evidence).

## Automation & security
- **Read-only by default.** `CMPDASH-Discovery` / `CMPDASH-Scope` / `CMPDASH-Report` / `CMPDASH-Validation`
  are read-only; `CMPDASH-Set-Configuration` defaults to **`-WhatIf`** — preview before `-Commit`.
- **Least Graph scopes.** Connect with only the read scopes each run needs (e.g. `AuditLog.Read.All`);
  don't request write scopes for a reporting job.
- **Defer determinations.** The dashboard evidences posture; regulatory, records, and legal calls belong
  to the governance functions — keep that boundary explicit in how the board is presented.
