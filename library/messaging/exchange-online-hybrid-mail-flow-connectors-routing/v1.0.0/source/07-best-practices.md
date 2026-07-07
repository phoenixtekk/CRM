# Best Practices

Durable practices for designing, operating, and troubleshooting Exchange/M365 hybrid mail flow. These
outlast any single change and keep routing correct and diagnosable over time.

## Architecture & design

- **Type accepted domains to reality, not to habit.** Use `InternalRelay` while a domain is shared with
  on-prem or a partner; move to `Authoritative` only after every recipient for that domain lives in
  Exchange Online. The wrong type is the #1 cause of "some users get mail, some get NDRs."
- **Never hand-edit HCW connectors.** Treat the Hybrid Configuration Wizard as the owner of hybrid
  connectors, certificates, and organization relationships. To change them, **re-run HCW** — manual
  edits drift and break on the next HCW run.
- **Make centralized mail transport a decision, not an accident.** Enable CMT only when on-prem must
  process outbound *cloud* mail (DLP/encryption/disclaimer gateway, or a required on-prem-only smart
  host). Default to **CMT off** so EXO sends outbound directly — less latency, fewer dependencies,
  simpler tracing.
- **Prefer the simplest routing topology that meets the requirement.** Cloud-authoritative (MX → EOP)
  is the target end-state for most tenants; add on-prem-inbound or CMT only for a concrete reason.
- **Require TLS on partner connectors.** For B2B partners and gateways, enforce TLS (by certificate
  subject or domain validation) rather than accepting opportunistic/plaintext mail.

## Naming & change discipline

- **Name every artifact `<Purpose> – <Scope> – <Stage>`** and reuse the exact name in tests,
  troubleshooting, and scripts (e.g. `Inbound Connector – Partner – Prod`, `Transport Rule – Partner
  TLS – Prod`). Consistent names make traces, reports, and handoffs unambiguous.
- **One mail-flow change per change window.** Connectors, domain types, DNS, and transport rules are
  high-impact; changing several at once makes a failure impossible to attribute. Validate after each.
- **Always keep a current baseline.** Re-run Discovery before any change and store the report with the
  change record — it is your rollback reference and your loop-detection starting point.
- **Change DNS last.** MX/host-record changes are the slowest to revert (TTL). Validate connectors and
  routing first; move DNS only when the topology change genuinely requires it.

## Transport rules

- **Keep the rule set small and scoped.** Every rule is transit-time logic that can loop or silently
  redirect. Scope each to specific senders/recipients/domains and give it an explicit priority.
- **Avoid mutual redirects.** Never let two rules redirect to each other; audit `redirect`/`BccTo`
  actions specifically for loop potential.
- **Disable before delete.** When retiring a rule, disable it first, confirm mail flow recovers, then
  remove — a fast, non-destructive rollback.

## Troubleshooting method

- **Work outermost-in: trace → headers → queues.** Start with message trace (where did it go / last
  status), escalate to headers (hop-by-hop path, connector, SCL, auth results), and only then to
  on-prem queues/SMTP logs for the legs trace can't see.
- **Read the `Received:` chain bottom-up.** It is the ground truth of the actual path a message took —
  more reliable than assumptions about how routing "should" work.
- **Know your trace window.** Real-time trace covers roughly the last ~10 days; use historical search
  for older incidents (window/retention is **service-dependent — verify in your tenant**).
- **Capture on-prem evidence proactively.** Confirm on-prem transport logging is enabled *before* an
  incident, so `Get-Queue` and protocol logs have the data when you need them.

## Automation & safety

- **Safe by default.** Run discovery/validation/reporting read-only; run configuration with `-WhatIf`
  and require an explicit `-Commit` to change anything. Preview every write.
- **Modern auth, no secrets in code.** Connect with `Connect-ExchangeOnline` / `Connect-MgGraph`
  (interactive or app-based with a certificate) — never embed passwords, app secrets, or tokens in
  scripts.
- **Export before you change.** Every configuration action should be preceded by an exported baseline
  of the object it touches, so rollback is a restore, not a reconstruction.

## Government cloud

- **Don't assume Commercial paths are universal.** On GCC/GCC High/DoD, use the `*.office365.us`
  portals and **verify each feature/endpoint in your own cloud** — availability and behavior can differ
  from Commercial. Document the cloud instance in every runbook.
