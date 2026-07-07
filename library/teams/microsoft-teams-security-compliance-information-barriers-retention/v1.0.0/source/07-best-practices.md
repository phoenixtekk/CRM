# 7. Best Practices

Durable practices for the Teams-specific compliance controls. These complement — they do not replace —
the org's broader Purview program.

## Scope and alignment
- **Stay in the Teams lane.** Configure only what is Teams-specific — information barriers, Teams
  chat/channel retention, and Teams-location DLP. Reference the org-wide Purview program for the label
  taxonomy, cross-service DLP, and records management; do not rebuild them here.
- **Reuse approved sensitive-information types and labels.** Teams DLP should match the same SITs/labels
  the Purview owner already approved, so alerts and coverage are consistent across services.
- **Keep Teams retention in its own policy.** Teams locations cannot share a retention policy with
  Exchange/SharePoint; keep them separate and name them so the split is obvious.

## Determinations stay with compliance/legal
- **Never invent the policy.** Who-must-not-talk-to-whom (IB), how long to keep what (retention), and
  what content to block (DLP) are **compliance/records/legal determinations**. Capture them in writing
  before configuring, and treat this solution as the technical implementation of those decisions.
- **Coordinate with holds.** eDiscovery holds and Litigation Hold preserve content regardless of a
  retention delete action; confirm interactions with the eDiscovery/legal owners before enabling
  delete-only or retain-then-delete on Teams.

## Information barriers
- **Pilot by attribute coverage, not by application scope.** IB application is tenant-wide; validate by
  having only pilot users carry the segment-defining attribute first, then expand the attribute.
- **Use one clean, authoritative attribute** for segments and keep it accurate — a user with no
  segment attribute is governed by no barrier.
- **Create policies Inactive, review, then activate** — and apply during a change window, because
  application evaluates every user.
- **Enable scoped directory search** and clear any conflicting address book policies **before** the
  first application run.

## Teams retention
- **Validate the schedule on a small pilot before broad delete.** Deletion is irreversible once the
  period elapses; a small scope contains the blast radius while you confirm behavior.
- **Be explicit about the end-of-life action** (`Keep`, `KeepAndDelete`, `Delete`) and the trigger, and
  record which the compliance schedule specified.
- **Cover the channel types your determination requires** (standard, private, shared) — channel-type
  parameter availability is version-dependent, so verify in your tenant.

## Teams DLP
- **Always run the audit gate first.** Deploy in a Test mode, review Activity explorer / DLP alerts,
  tune out false positives, and only then enable enforce/block.
- **Notify owners, not everyone, at first.** Start with owner notification and no block; add blocking
  once the false-positive rate is acceptable.
- **Test with synthetic data only** — never send real PII to validate a DLP rule.

## Operations, safety, and evidence
- **Safe-by-default automation.** Run the provided scripts read-only or with `-WhatIf`; the config
  helpers require an explicit `-Commit` to write. No credentials in code — use modern-auth
  `Connect-IPPSSession` / `Connect-MicrosoftTeams`.
- **Least privilege.** Use the specific Purview role groups (Information Barriers, DLP/Compliance,
  Retention) rather than Global Admin.
- **Keep a rollback ready per control** (IB → Inactive + re-apply; retention → disable; DLP → back to
  Test/Disable) and know its limits (a retention delete already executed is not reversible).
- **Re-validate after every expansion** with `TEAMSCOMP-Validation.ps1` and keep the dated output as
  evidence of the control's state for audit.
- **Verify plan/cloud specifics in your tenant.** IB and Teams DLP entitlements, channel-type coverage,
  and Government-cloud endpoints (`*.office365.us`) are plan-/version-/cloud-dependent — confirm, don't
  assume.
