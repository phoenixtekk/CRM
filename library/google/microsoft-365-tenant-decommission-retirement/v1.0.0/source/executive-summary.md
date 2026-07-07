# Executive Summary

## The situation

The enterprise has moved its people to Google Workspace, Google Cloud Platform, and Gemini Enterprise.
The migration project ended at "everyone is live on Google" — but the **old Microsoft 365 tenant is
still running**. It is still licensed (duplicate cost), still holds mailboxes, files, and identities
(risk and orphaned data), and is still trusted by lingering app integrations and DNS records. Left
alone, that residual tenant bleeds spend for months and carries real security and compliance exposure;
shut down carelessly, it loses records the organization may be legally required to keep, or breaks
integrations still quietly depending on it.

## The outcome

A **clean, auditable retirement** of the Microsoft 365 tenant: migration completeness proven with
data, data disposition handled in line with retention and legal-hold obligations, licensing wound down
to stop duplicate spend, Entra app registrations and orphaned identities cleaned up, DNS and
integrations re-pointed to Google or removed, and the tenant **formally closed** — with evidence
captured at every step. The cost stops, the attack surface shrinks, and the closure survives audit.

## The approach — safe and governed by design

- **Pilot-first, gated, reversible.** The work runs as six phases —
  Assess → Completeness → Disposition → Licensing → Identity → DNS → Closure — each with an explicit
  pass/fail gate and a documented rollback. Everything reversible (disable before delete, re-assign a
  license, restore a DNS zone) happens **before** the tenant enters the irreversible deletion window.
  A bounded pilot scope proves the whole procedure before it touches the full tenant.
- **Nothing torn down until completeness passes.** No disposition or closure step runs while any user
  still depends on Microsoft 365 — the completeness gate is a hard stop.
- **Legal owns the records call; the runbook owns the method and the evidence.** Legal-hold and
  retention determinations stay with the legal/records/compliance functions. This solution inventories
  the data, exports what must be preserved to a governed store, and hands the evidence over — it never
  disposes of data on its own authority.
- **Safe-by-default automation.** Five included Python tools read the Microsoft tenant through the
  Microsoft Graph API and default to read-only or dry-run; any change requires an explicit `--apply`,
  applied to the pilot scope first. Verification uses least-privilege read access, and no credentials
  or keys ever live in code.

## Why it is low-risk

Every phase leaves an evidence file; every production change (licensing, identity, DNS, closure) is
gated, piloted, and reversible until the final deletion window; and the one truly irreversible
action — closing the tenant — runs last, only after a pre-closure guardrail check confirms nothing is
orphaned and every obligation is met. The result is the duplicate cost and residual risk gone for
good, with an audit trail that proves it was done cleanly.
