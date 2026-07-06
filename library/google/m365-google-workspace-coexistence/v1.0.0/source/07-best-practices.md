# 7. Best Practices — A Stable Transition Period

Coexistence is a **transition state**, not a destination. These practices keep the split
organization stable for the migration window and set up a clean exit at consolidation. They apply
across all three pillars and reuse the runbook's named objects.

---

## Treat it as one system, piloted and reversible

- **Always pilot first.** Every mail-flow, DNS, and identity change goes through
  **`Coexistence – Pilot Members`** before the fleet. Mail routing is the highest-blast-radius pillar
  — a bad relay or split-delivery rule NDRs real mail.
- **Capture the baseline before you touch anything.** The Phase 1 baseline (MX/SPF/DKIM/DMARC,
  accepted-domain types, connectors, Interop state) is your rollback. Never change production before
  it is recorded.
- **Change control on the shared surfaces.** DNS, connectors, the Google routing rule, and GCDS search
  rules are the shared surfaces — schedule them in windows with approvals, not ad hoc.

## Mail routing / split delivery

- **Lower DNS TTLs before an MX change**, and stage the flip during a low-volume window; raise TTLs
  back afterward.
- **Keep exactly one MX-primary** at a time. Both platforms in internal-relay/split mode simultaneously
  can create relay loops — validate that a message for a *nonexistent* recipient bounces cleanly rather
  than ping-ponging.
- **SPF has a 10-DNS-lookup limit** — using `include:_spf.google.com` and
  `include:spf.protection.outlook.com` together is fine, but audit the full record so you don't exceed
  it and softfail legitimate mail.
- **Keep DMARC observable during transition** (`p=none`/`quarantine` with `rua` reporting). Only move to
  `p=reject` after Validate/Expand proves both platforms sign and align. Enforcing too early during a
  two-sender period silently drops mail.
- **Require TLS on both relay hops** (the EXO→Google connector and the Google→M365 host) so relayed mail
  stays encrypted in transit.

## Free/busy interop

- **Use dedicated role accounts** (`svc-interop-exo@contoso.com`, `svc-interop-gcal@contoso.com`) —
  never a real person's account. Document them as service identities; exclude the Exchange one from
  blocking Conditional Access and (for basic auth) set the password non-expiring.
- **Default to availability-only**, and raise to event-details deliberately, per policy — event-level
  privacy is respected on both sides, but titles/locations are still data governance cares about.
- **Prefer the Graph-API endpoint over legacy EWS** where your tenant offers it (modern auth,
  no basic-auth password to rotate). If the option is preview/rolling-out, **verify in your tenant**.
- **Protect the endpoint:** the Exchange endpoint must stay reachable on 443 with a valid public-CA
  cert; if you restrict inbound, allowlist Google's Interop egress ranges rather than opening it wide.

## Directory sync

- **GCDS is one-way and simulate-first.** Always **Simulate sync** and review **Proposed changes**
  before a real run — an over-broad search rule can propose mass deletions.
- **Run GCDS on a dedicated host**, not the domain controller; keep it patched and monitored.
- **Represent the other platform's users consistently** — Google **shared contacts** for M365-only
  recipients, Exchange **mail contacts / mail users** for Google-only recipients — and mark them with
  **`Coexistence – Synced`** so they are trivially reportable and removable.
- **One source of truth.** Both platforms provision from the same identity source; never let two
  systems author the same user or the GAL diverges.

## Operate and monitor

- **Weekly coverage report** with `GWCOEX-Report.ps1`; treat any user that loses a pillar as an
  incident, not a curiosity.
- **Remediation is `-WhatIf` by default** — review the plan before `-Apply`. Same for
  `GWCOEX-Set-ScopeTargeting.ps1`.
- **Watch NDR and DMARC-report volume** as the leading indicators that a relay or auth change went
  wrong.

## Plan the exit (decommission at consolidation)

Coexistence should end. Build the off-ramp in from day one:

1. **Confirm all mailboxes have migrated** to the surviving platform (data-migration workstream is
   complete for that user/wave).
2. **Flip MX** fully to the surviving platform and let TTLs settle.
3. **Change the shared domain back to authoritative** on the surviving platform and **disable**
   `Coexistence – EXO→Google Connector` / the Google `Coexistence – Split Delivery` rule.
4. **Turn off Calendar Interop** endpoints and retire `svc-interop-*` role accounts.
5. **Stop GCDS** and remove the **`Coexistence – Synced`** contacts/objects on the retired platform.
6. **Tighten DMARC** to a single-sender enforcing policy; remove the retired platform's SPF include and
   DKIM selector.
7. **Retire the legacy tenant** per the vendor's offboarding process; keep the Phase 1 baseline archived
   for audit.

> The measure of a good coexistence design is a **quiet** transition and a **clean** decommission:
> mail routed, calendars resolved, directory in sync — and nothing left behind when the legacy side
> is switched off.
