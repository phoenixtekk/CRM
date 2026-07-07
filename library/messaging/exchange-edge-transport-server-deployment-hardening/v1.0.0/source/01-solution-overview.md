# Solution Overview — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

## What this is

This solution deploys and hardens an **Exchange Edge Transport** server in the perimeter of a
hybrid Exchange organization, and validates that inbound and outbound SMTP flow securely with no
open relay. The Edge Transport role is a purpose-built, minimized Exchange installation that sits
in a perimeter network (screened subnet / DMZ), is **not** joined to the internal Active Directory
forest, and handles internet-facing SMTP plus a first layer of mail hygiene before mail reaches the
internal Mailbox servers.

The work covers the full lifecycle: install the Edge Transport role on a hardened host, create and
import an **Edge Subscription** so EdgeSync one-way replication provisions the connectors and
recipient/config data the Edge needs, configure **Send/Receive connectors** and **accepted
domains**, apply the **anti-spam transport agents** and **connection filtering**, harden the
**OS and TLS** posture (closing the open-relay hole), and prove secure mail flow end to end. Five
PowerShell tools accompany the guide for read-only discovery, safe (`-WhatIf`) configuration, open-
relay/TLS validation, an anti-spam/connection-filter report, and a scope/health helper.

> **Version note — verify for your version.** Exchange Server behavior differs by **version and
> Cumulative Update (CU)** — Exchange Server 2013, 2016, 2019, and the **Subscription Edition (SE)**
> each have their own supported build, prerequisites, and default hygiene agent set. TLS defaults,
> the Extended Protection posture, and supported .NET/OS versions in particular are CU-dependent.
> Before applying any step, **confirm it against Microsoft's documentation for your exact Exchange
> Server version and CU** and against your organization's build. Where this guide states a default,
> treat it as "verify in your version".

## How it works — the reference design

```
   Internet
      │  inbound SMTP (25/TLS)
      ▼
 ┌─────────────────────────────┐   Perimeter network (DMZ / screened subnet)
 │  Edge Transport server      │   • Standalone (workgroup or perimeter domain), NOT internal AD
 │  • Receive connector(s)     │   • AD LDS (ADAM) holds synced config + recipients
 │  • Send connector(s)        │   • Anti-spam agents + Connection Filtering
 │  • Anti-spam / conn filter  │   • TLS enforced; open relay closed
 └─────────────┬───────────────┘
   EdgeSync    │  one-way replication (secure LDAP 50636), internal → Edge
   inbound 25  ▼
 ┌─────────────────────────────┐   Internal network
 │  Mailbox (Transport) server │   • Subscribes the Edge; runs Microsoft Exchange EdgeSync svc
 │  Active Directory / AD DS   │   • Internet send/receive connectors auto-created by EdgeSync
 └─────────────────────────────┘
      │  hybrid connectors (where hybrid)
      ▼
 Exchange Online / EOP  (cloud hygiene complements the Edge)
```

Key mechanics an operator must hold in mind:

- **The Edge is standalone.** It is deployed in a **workgroup or a dedicated perimeter domain**,
  never joined to the internal production AD. It stores its configuration and a read-only copy of
  recipient data in a local **Active Directory Lightweight Directory Services (AD LDS)** instance,
  not in AD DS.
- **EdgeSync provisions it.** You create an **Edge Subscription** file on the Edge, import it on an
  internal **Mailbox server** (the Transport service), and the **Microsoft Exchange EdgeSync**
  service then replicates configuration and recipient/safelist data **one way, internal → Edge**,
  over secure LDAP. EdgeSync **automatically creates** the internet Send connector and the inbound
  Receive connector, so you generally do **not** hand-build those on a subscribed Edge.
- **Hygiene at the perimeter.** The Edge runs the **anti-spam transport agents** (Connection
  Filtering / IP Allow & Block lists, Content Filtering, Sender/Recipient Filtering, Sender ID,
  Sender Reputation, Attachment/Protocol agents where installed). In a hybrid where **Exchange
  Online Protection (EOP)** is the primary hygiene layer, the Edge's job is narrower — perimeter
  connection control, TLS termination, and safe relay — with cloud hygiene doing the heavy lifting.
- **No open relay.** A default, correctly-scoped Edge does **not** relay for anonymous internet
  senders to external domains. The hardening work makes that guarantee explicit and *tested*.

## The deployment model

This solution follows the house model for high-impact messaging changes:

**Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
gates and a documented rollback at every stage. Perimeter mail flow, connectors, DNS (MX), and TLS
are **high-impact to production mail** — a mistake can black-hole inbound mail or expose an open
relay — so every change is staged, validated against a gate, and reversible.

- **Assess** — inventory the current perimeter, existing Edge/transport, connectors, certificates,
  firewall/DNS, and Exchange version/CU.
- **Design** — decide the Edge host topology (workgroup vs perimeter domain), naming, certificate,
  connector scope, and hygiene split with EOP.
- **Configure** — install the role, subscribe (EdgeSync), and apply connector/hygiene/TLS settings
  using the named artifacts.
- **Pilot** — cut a **single test domain / low-risk mail path** over to the new Edge first.
- **Validate** — run the pass/fail gates (EdgeSync healthy, no open relay, TLS enforced, mail flows).
- **Expand** — move production MX / full mail flow only after the pilot gates pass; keep rollback ready.

## Benefits

- **Correct, secure perimeter transport** — EdgeSync healthy, connectors scoped, TLS enforced, and
  the open-relay hole provably closed.
- **First-layer hygiene at the edge** that complements cloud (EOP/Defender for Office 365) hygiene
  rather than duplicating it.
- **Repeatable, tested procedure** with named artifacts, pass/fail gates, and rollback — safe for
  production mail.
- **PowerShell tooling** for read-only discovery, safe configuration, open-relay/TLS validation, and
  ongoing reporting.

## Limitations & scope

- This solution deploys and hardens the **Edge Transport role and its mail flow**; it is **not** a
  full Exchange org build, a migration, or an EOP/Defender policy design (those are separate).
- **Exchange version/CU-specific** build numbers, prerequisites, TLS/Extended Protection defaults,
  and the exact anti-spam agent set are **verify-in-your-version** items — this guide gives the
  procedure and the cmdlets, not a substitute for Microsoft's per-version documentation.
- **Third-party perimeter gateways** (secure email gateways, hygiene appliances) are integrated at
  the pattern level; their consoles are deferred to the vendor's own docs. If a third-party gateway
  is the internet-facing MX, the Edge role may be redundant — that design choice is called out in
  Best Practices.
- **Commercial vs Government (GCC/GCC High/DoD):** the on-prem Edge steps are cloud-independent, but
  the **hybrid/cloud** touch points (EOP, connector endpoints, admin portal URLs such as
  `*.office365.us`) differ on sovereign clouds — flagged where relevant, not assumed Commercial.
