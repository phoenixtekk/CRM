# Solution Overview

## What this is

This solution gives an Exchange/Microsoft 365 messaging team a complete, runnable model for
**designing, operating, and troubleshooting mail flow** in an Exchange Online or **Exchange hybrid**
environment. It explains the connector types and when to use each, how accepted domains and domain
types shape routing, the centralized-mail-transport decision, transport (mail-flow) rules, and — when
something breaks — a **layered diagnostic** that moves from message trace to message headers to
queues/SMTP logs to find root cause fast.

Mail flow in a hybrid tenant fails in ways that are hard to see: a message silently routes out the
wrong connector, an accepted-domain type set to the wrong value drops or NDRs mail, centralized
transport sends outbound the "long way" through on-prem, or a pair of transport rules forms a routing
loop. This solution turns those mysteries into a named, testable architecture and a repeatable
trace-to-root-cause method.

It is white-label and vendor-accurate: every Exchange admin center (EAC), Microsoft 365 admin center,
Exchange Online PowerShell (EXO V3), Microsoft Graph, and on-premises Exchange/AD step is taken from
Microsoft's public documentation. Where behavior is version- or plan-dependent (Exchange Server
build/CU, EOP vs Defender for Office 365 plan, Commercial vs Government cloud), it is cited or flagged
**"verify in your tenant/version"** rather than invented.

## How mail flow works (the reference model)

**Accepted domains and domain types.** Exchange Online only accepts and routes mail for domains
configured as **accepted domains**. Each accepted domain has a **type** that governs routing:

- **Authoritative** — the organization owns the domain and *all* mailboxes for it live in this
  Exchange organization. Mail to an unknown recipient is rejected/NDR'd here.
- **Internal relay** — the domain is shared: some recipients are in this organization and some are
  hosted elsewhere (e.g. still on-premises during a migration, or in a partner/subsidiary system).
  Unknown recipients are **relayed** out via a send/outbound connector instead of being NDR'd. This is
  the correct type for a domain that is split between on-prem and Exchange Online during coexistence.
- **External relay** — the organization does not host any recipients for the domain but relays mail
  through to an external system (less common; used for pure pass-through).

Choosing the wrong type is one of the most common causes of "some users get mail, some get NDRs" in a
hybrid tenant. In this solution the primary shared domain is named **`Accepted Domain – Primary –
Prod`** and, during coexistence, set to **Internal relay**.

**Connector types and when to use each.** Connectors define how mail flows *into* and *out of*
Exchange Online with a specific partner system.

| Connector | Direction | Use it when |
|---|---|---|
| **Hybrid connectors** (created by the Hybrid Configuration Wizard, HCW) | Inbound + outbound between on-prem Exchange and EXO | You run Exchange hybrid; HCW builds the `Inbound from on-prem` and `Outbound to on-prem` connectors with TLS + certificate/subject validation. Do **not** hand-edit these; re-run HCW. |
| **Inbound connector** (`OnPremises` type) | On-prem → EXO | Accept mail from your on-prem/Edge servers, validated by certificate subject or sending IP. |
| **Outbound connector** (`OnPremises` type, routing) | EXO → on-prem | Route mail from EXO to on-prem (used for internal-relay recipients and for centralized transport). |
| **Partner inbound connector** | Partner/vendor → EXO | Enforce TLS or restrict by IP/cert for a named partner (e.g. a B2B partner or a mail hygiene gateway). |
| **Partner outbound connector** | EXO → partner smart host | Force mail for a specific domain out through a partner smart host / gateway with required TLS. |

This solution names the coexistence connectors **`Inbound Connector – OnPrem – Prod`** and
**`Outbound Connector – OnPrem – Prod`**, and any partner enforcement connector
**`Inbound Connector – Partner – Prod`** / **`Outbound Connector – Partner – Prod`**.

**Routing topologies.** Three common shapes:

1. **Cloud-authoritative** — MX points to Exchange Online (EOP). Inbound lands in EOP; outbound goes
   directly to the internet from EXO. Simplest; the target end-state for most tenants.
2. **On-prem inbound (MX on-prem)** — MX points at an on-prem gateway/Edge; on-prem relays to EXO over
   the inbound connector. Used when an on-prem hygiene appliance must see mail first.
3. **Centralized mail transport (CMT)** — outbound (and optionally inbound) from EXO is routed back
   through on-prem Exchange so on-prem controls the final hop to the internet.

**Centralized mail transport decision.** CMT is an HCW option. Enable it only when on-prem must apply
outbound processing to *cloud* mail — e.g. an on-prem data-loss-prevention/encryption gateway,
disclaimers, or a required outbound smart host that only on-prem can reach. The cost is latency, an
extra dependency on on-prem availability, and more complex tracing. Default is **CMT off** (EXO sends
outbound directly); this solution treats enabling CMT as a deliberate, gated design decision.

**Transport (mail-flow) rules.** Mail-flow rules (`Get-/New-/Set-TransportRule`) apply conditions →
actions to messages in transit (add disclaimers, redirect, block, force TLS, set headers/SCL). They
are powerful and a frequent source of loops and silent redirects, so this solution requires each rule
to be **named**, scoped, priority-ordered, and pilot-tested before production. Example names:
`Transport Rule – Partner TLS – Prod`, `Transport Rule – External Tag – Prod`.

**The layered mail-flow diagnostic.** When mail misbehaves, work outermost-in:

1. **Message trace** (EAC → Mail flow → Message trace, or `Get-MessageTraceV2` / historical search) —
   where did the message go, and what was the last event/status?
2. **Message headers** (paste into the Message Header Analyzer, or read the `Received:` chain and
   `X-` anti-spam/forefront headers) — hop-by-hop path, which connector, SCL/spam verdict, auth
   results (SPF/DKIM/DMARC).
3. **Queues / SMTP logs** (on the **on-prem** side: `Get-Queue`, protocol/connectivity logs on the
   hybrid transport server) — for the on-prem legs that trace can't see into.

Each layer answers a different question; escalating only when the prior layer is inconclusive keeps
diagnosis fast and evidence-based.

## Benefits

- **Mail routes correctly** — connectors of the right type, accepted domains typed correctly, and a
  routing topology you can draw and defend.
- **No mystery loss** — a repeatable trace → headers → queues method that resolves "where did the
  message go?" in minutes, with evidence.
- **Controlled transport rules** — every rule named, scoped, and pilot-tested; loops and silent
  redirects designed out.
- **Deliberate CMT** — the centralized-transport decision is made on purpose, not inherited by
  accident.
- **Automation, safe by default** — five EXO V3 / Graph PowerShell tools that discover, validate,
  report, and (only when told) configure — read-only or `-WhatIf` unless you pass an explicit
  apply/commit switch, with no credentials in code.

## Limitations and scope

- Covers **mail-flow architecture, connectors, accepted domains, routing, transport rules, and
  troubleshooting**. Deep email-authentication hardening (SPF/DKIM/DMARC policy design), anti-spam/
  anti-phish policy tuning, and archiving/retention are adjacent solutions — this one touches auth
  results and hygiene headers only insofar as they explain routing/verdicts.
- **On-prem Exchange internals** (installing Exchange, CU upgrades, Edge subscription setup) are
  assumed in place per the hybrid requirement; this solution configures and validates the *mail-flow*
  side of hybrid, not the base install.
- **Third-party hygiene/gateway/archiving products** are integrated at the **pattern** level
  (connector + TLS + routing); their own consoles are deferred to the vendor's documentation.
- Portal URLs and some feature availability differ on **Government clouds (GCC/GCC High/DoD)** — those
  differences are flagged where they matter; verify endpoints in your own cloud.

## Deployment model

This solution follows the house model for high-impact messaging changes:

**Assess → Design → Configure → Pilot → Validate → Expand**

Mail flow, connectors, DNS, and transport-rule changes are **high-impact to production mail**, so every
change is pilot-first, gated by explicit pass/fail criteria, and paired with a documented rollback.
You never change the production routing path for everyone at once; you prove it on a named pilot scope
(a pilot accepted domain, pilot recipients, and controlled test mail flow) first, validate against the
gates, then expand.
