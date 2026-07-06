# 1. Solution Overview — Microsoft 365 ↔ Google Workspace Coexistence

During any multi-month migration between **Microsoft 365** and **Google Workspace**, the two
ecosystems run side by side — and users expect mail, calendars, and the directory to *just work*
across both. This solution designs and implements **coexistence**: the set of mail-routing,
calendar free/busy, and directory-sync controls that make Microsoft and Google behave as one
organization until the migration completes and the legacy side is retired.

It is authored for a **competent administrator** who wants a repeatable, click-to-implement path.
Every connector, endpoint, role account, and organizational unit is **named once and reused
verbatim** across the requirements, implementation, testing, troubleshooting, and the five
supporting scripts, so the design lines up end to end.

The deployment model is the standard **Assess → Configure → Pilot → Validate → Expand** with
explicit pass/fail gates and a documented rollback for every production change — mail flow, DNS,
and identity changes are high-impact and are always piloted before fleet-wide rollout.

---

## The three pillars of coexistence

Coexistence is not one setting; it is three independent interop channels that together make the
split organization feel unified. Each pillar is configured, piloted, and validated on its own.

### Pillar 1 — Mail routing / split delivery

While a domain (e.g. `contoso.com`) is shared between both platforms, inbound mail lands on one
**primary** system (whichever holds the domain's MX record) and is **relayed** to the other for
recipients that don't exist locally. This is *split delivery*.

- **MX-primary platform** — the platform the domain's **MX record** points to receives all inbound
  mail first. Common patterns during a Google-to-M365 migration keep Google as MX-primary early,
  then flip to M365 as mailboxes move.
- **Relay for unknown recipients** — on each platform the shared domain is set to a **non-authoritative
  / internal-relay** mode so that a message for a recipient that isn't hosted locally is forwarded
  to the other platform rather than bounced (NDR).
  - On **Exchange Online**: the shared domain's **Accepted Domain** type is set to **Internal relay**,
    and an **outbound connector** (named **`Coexistence – EXO→Google Connector`**) relays unknown
    recipients to Google's smart host (`aspmx.l.google.com`).
  - On **Google Workspace**: **Routing → Recipient address map / Split delivery** (Admin console →
    **Apps → Google Workspace → Gmail → Routing**) is configured so mail for recipients not hosted
    in Google is routed to the M365 host (the domain's `*.mail.protection.outlook.com` endpoint).
- **Authentication** — **SPF** must authorize *both* sending platforms; **DKIM** is signed
  separately on each; **DMARC** is kept in a monitoring-friendly policy during the transition so a
  misconfigured relay does not cause silent drops.

The result: a sender anywhere reaches the right recipient regardless of which platform hosts that
mailbox on any given day.

### Pillar 2 — Free/busy calendar interop

Users on both platforms must see each other's **availability** when scheduling. This is delivered
by **Google Calendar Interop** (Admin console → **Apps → Google Workspace → Calendar → Calendar
Interop management**) paired with Exchange-side availability sharing:

- **Google → Exchange direction** — Google Calendar queries Exchange availability through an
  **Exchange endpoint** (Microsoft 365 Graph API endpoint, or EWS for legacy) using one or more
  **Exchange role accounts** (named **`svc-interop-gcal@contoso.com`**). Google users then see
  Exchange users' free/busy.
- **Exchange → Google direction** — Exchange queries Google availability through a dedicated
  **Google role account** (named **`svc-interop-exo@contoso.com`**) referenced in Calendar Interop.
  Exchange/Outlook users then see Google users' free/busy.
- **Detail level** — lookups return **availability only** by default; **event details** (title/location)
  can be enabled per direction, and event-level privacy is respected on both sides.

The result: Outlook and Google Calendar both resolve availability for anyone in the org, so meeting
scheduling doesn't break during the split.

### Pillar 3 — Directory sync

A single, consistent **Global Address List / directory** across both platforms lets users find and
address each other. The identity **source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
projects users and groups into *both* ecosystems:

- **Into Google Workspace** — **Google Cloud Directory Sync (GCDS)** performs a **one-way** sync
  from LDAP/Active Directory into Google (users, groups, and shared contacts). GCDS never writes
  back to the source. Mail-enabled contacts for M365-only recipients are provisioned as **shared
  contacts** so they appear in Google's directory.
- **Into Microsoft 365 / Entra** — users are provisioned from the same source (Entra Connect / cloud
  sync from AD, or native Entra where Entra is the source). Google-only recipients are represented in
  Exchange as **mail contacts / mail users** so they appear in the GAL and route correctly.
- **Convention** — objects synced for coexistence carry a recognizable naming/attribute marker (e.g.
  a custom attribute or OU **`Coexistence – Synced`**) so they can be reported on and cleanly removed
  at consolidation.

The result: one directory experience — everyone can look up and address everyone, on either platform.

---

## How the pillars work together

| Pillar | Google side object | Microsoft side object | Makes possible |
|---|---|---|---|
| Mail routing | Split-delivery routing rule | Internal-relay domain + `Coexistence – EXO→Google Connector` | Mail reaches the right mailbox on either platform |
| Free/busy | Calendar Interop + role account `svc-interop-exo@contoso.com` | Exchange endpoint + role account `svc-interop-gcal@contoso.com` | Cross-platform availability in scheduling |
| Directory | GCDS + shared contacts | Entra provisioning + mail contacts | One unified directory / GAL |

Together they produce a **unified experience**: mail routes, calendars resolve, and the directory
stays in sync — for as long as the two platforms coexist.

---

## Scope, boundaries, and lifecycle

- **In scope:** design and configuration of mail routing/split delivery, free/busy interop, and
  directory sync; a pilot-first rollout with gates; validation tooling; and a documented rollback.
- **Out of scope (deferred to vendor docs):** bulk **data migration** (mailbox/Drive/Chat content
  movement) performed by third-party migration tools — coexistence keeps the org working *while*
  that migration runs, but is a separate workstream. Third-party enterprise apps are integrated at
  the pattern level only.
- **Vendor boundary:** the **Google Admin console** and the **Microsoft / Entra** sides are authored
  at click-by-click detail from the vendors' current public documentation. Where a capability is
  preview/rolling-out (e.g. specific Interop endpoint options), it is flagged **"verify in your
  tenant."**
- **Lifecycle:** coexistence is a **transition state**. It is stood up pilot-first, expanded to the
  fleet, operated for the migration window, and then **decommissioned** in a controlled way once
  consolidation retires the legacy platform (see `07-best-practices.md`).

> **Cited sources.** Microsoft Learn — *Manage accepted domains* / *Set up connectors to route mail*
> (internal-relay + smart-host routing to `aspmx.l.google.com`); Google Workspace Admin Help —
> *About Calendar Interop*, *Allow Calendar users to see Exchange availability* (role accounts,
> endpoints, availability vs. event details); Google Workspace Admin Help — *About Google Cloud
> Directory Sync* (one-way LDAP→Google sync). Preview/rolling-out endpoint options are flagged
> "verify in your tenant."
