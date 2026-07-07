# 7. Best Practices — Microsoft 365 Purview eDiscovery Administration

Durable practices for running eDiscovery defensibly and repeatably.

## Governance & scope
- **Legal decides, IT executes and evidences.** Scope, custodians, holds, and production are legal/
  records determinations. Keep a matter-intake record with the named legal owner and their sign-off;
  never place a live hold or export without it.
- **One case per matter, always.** Even for a "quick" request, run it inside a named case rather than
  a loose Content Search — the case gives you holds, membership, and a contained audit trail.
- **Name everything consistently.** `<Purpose> – <Scope> – <Stage>` (e.g. `eDiscovery Case –
  Matter-A – Pilot`, `Hold Policy – Matter-A – Prod`). Reuse the exact name across searches, holds,
  review sets, exports, tests, and scripts so the matter is traceable end to end.

## Least privilege
- **Grant eDiscovery via role groups, not Global Admin.** Operators → **eDiscovery Manager** (own
  cases); a small, named group → **eDiscovery Administrator**. Review membership periodically.
- **Use compliance boundaries where policy requires** separation (region/agency/business unit).
  Define the boundary once, before matters run; the boundary policy is a legal/HR decision.

## Query & collection
- **Start narrow, widen only if needed.** Prefer explicit conditions (date range, participants,
  `kind:`/`filetype:`, sensitive-info type) over broad free-text; an over-broad KQL query is
  expensive and undermines defensibility.
- **Always estimate and preview before you export.** Read the search statistics and preview a sample
  to confirm on-topic hits across **all** in-scope workloads — including Teams messages (collected
  via the mailbox) and Teams files (via SharePoint/OneDrive).
- **Watch for unindexed/partially-indexed items.** Include them deliberately in Premium collections
  and note them; do not silently drop content that could not be indexed.

## Preservation (holds)
- **Place the hold before you collect or notify** when preservation is required — deletion between
  request and hold is the classic spoliation risk.
- **Prefer custodian holds (Premium) for people-centric matters** so preservation, communications,
  and data sources track together; use case holds (Standard) for location-centric preservation.
- **Document hold scope and keep it current** as custodians join/leave; release holds only with
  legal approval and record the release.

## Review efficiency (Premium)
- **Run analytics before human review** — email threading, near-duplicate detection, and
  de-duplication routinely cut the volume reaching expensive review. Enable de-dup on every review
  set.
- **Tag and redact in the review set, not the source.** The review set is the static, defensible
  copy; never alter source content.

## Defensible export
- **Always keep the export/results report and load file** as the evidence that the production was
  complete; reconcile item counts against the review-set/search estimate before handing anything to
  outside counsel.
- **Produce redacted/native per legal's instruction**, not by operator default.

## Safety & automation
- **Read-only or dry-run by default.** The scripts here default to reporting/`-WhatIf`; require an
  explicit `-Apply` to create searches, holds, or filters. Pilot every high-impact action
  (broad hold, export) on `Matter-A` first.
- **Modern auth only, no secrets in code.** Connect with `Connect-IPPSSession` / `Connect-MgGraph`
  (MFA); never embed credentials, tokens, or app secrets in a script or in source control.
- **Cloud/version awareness.** Government clouds use different portal hosts (e.g. `*.office365.us`)
  and the eDiscovery UI was modernized (unified Standard/Premium) — confirm paths and Graph cmdlet
  parameters **in your tenant** rather than trusting older screenshots.

## Evidence & auditing
- **Keep audit on and export the audit trail per matter.** Case, search, hold, and export activity in
  the unified audit log is the proof of a defensible process — treat it as a deliverable of every
  matter.
