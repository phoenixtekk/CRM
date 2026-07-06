# Microsoft 365 ↔ Google Workspace Coexistence (Mail Routing, Free/Busy, Directory Sync)

> **Version 1.0.0** · Category: Google · Solution code: GWCOEX

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 ↔ Google Workspace Coexistence

## The situation

For the months it takes to migrate between **Microsoft 365** and **Google Workspace**, both platforms
run side by side. Users don't care which platform holds their colleague's mailbox — they expect mail
to arrive, calendars to show availability, and the directory to list everyone. Without deliberate
coexistence, the split organization breaks in visible, painful ways: mail bounces (NDRs), meeting
scheduling shows blank calendars, and people can't find each other in the address book.

## What this solution does

It designs and implements **coexistence** — three interop channels that make Microsoft and Google
behave as **one organization** until the migration completes:

1. **Mail routing / split delivery** — the shared domain is set to relay: each platform delivers to its
   own mailboxes and forwards mail for everyone else to the other platform. No NDRs during the split.
2. **Free/busy calendar interop** — Google Calendar Interop plus Exchange availability sharing let
   Outlook and Google Calendar resolve each other's availability **in both directions**.
3. **Directory sync** — one identity source projects users and cross-platform contacts into both
   ecosystems (Google Cloud Directory Sync + Exchange mail contacts), producing a single unified
   address book.

## How it's delivered

The engagement follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model with
explicit pass/fail gates and a documented rollback at every step. Every change — DNS, mail connectors,
calendar endpoints, directory rules — is proven on a small pilot before it touches the fleet, because
mail-flow and DNS changes are high-impact. Five supporting scripts automate readiness discovery,
per-user interop validation, and coverage reporting; the two that make changes default to a safe
preview (`-WhatIf`) mode.

## The outcome

**Microsoft and Google working as one** through the transition — mail routes, calendars resolve, the
directory stays in sync — piloted, validated, and reversible. Because coexistence is a *transition
state*, the solution also builds in a **clean decommission**: once consolidation completes, the legacy
platform is retired in a controlled sequence with nothing left behind.

## Why it matters

Coexistence is the difference between a migration users barely notice and one that generates a flood of
"my email bounced" and "I can't see anyone's calendar" tickets for months. This solution turns the
riskiest window of a platform migration into a **quiet, unified experience** — self-guided, tested, and
at a fraction of the cost of open-ended consulting.


---


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


---


# 2. Requirements — Microsoft 365 ↔ Google Workspace Coexistence

Verify **every** requirement below before starting the implementation runbook (`03-implementation.md`).
Each requirement is stated as **Description → Why required → How to verify → How to implement if
missing**. These are in addition to the Google-category **global requirements**
(`global-requirements-google.md`), which cover the base tenants, DNS control, identity source of
truth, pilot scope, and governance stakeholders.

**Naming used throughout (reuse verbatim):**
- Shared vanity domain: `contoso.com`
- Google role account (used by Exchange to read Google availability): `svc-interop-exo@contoso.com`
- Exchange role account (used by Google to read Exchange availability): `svc-interop-gcal@contoso.com`
- Exchange outbound relay connector: **`Coexistence – EXO→Google Connector`**
- Directory-sync marker OU/group: **`Coexistence – Synced`**
- Pilot group: **`Coexistence – Pilot Members`**

---

## R1 — Administrative access to **both** platforms

- **Description:** A **Google Workspace super-admin** account **and** a Microsoft 365 account with the
  roles the steps name (Exchange admin for mail flow/connectors; Global Admin or the least-privilege
  equivalent for domain, Calendar-endpoint, and directory work).
- **Why required:** Every pillar changes configuration on both sides; you cannot configure split
  delivery, Interop, or directory sync from one platform alone.
- **How to verify:** Sign in to **admin.google.com** as super-admin and to **admin.microsoft.com** /
  **admin.exchange.microsoft.com** with the required role.
- **How to implement if missing:** Obtain the roles from each tenant owner before starting; record
  them in change-control.

## R2 — Shared/verified domain on both platforms

- **Description:** The domain being coexisted (`contoso.com`) is **added and verified** on *both*
  Google Workspace and Microsoft 365.
- **Why required:** Split delivery requires the same SMTP domain to be a recognized (accepted) domain
  on each platform so each can decide "mine, or relay to the other."
- **How to verify:** Google Admin console → **Account → Domains → Manage domains** shows the domain
  verified; Microsoft 365 admin center → **Settings → Domains** shows it verified; Exchange admin
  center → **Mail flow → Accepted domains** lists it.
- **How to implement if missing:** Add and verify the domain (TXT/CNAME) on whichever platform is
  missing it. Do **not** yet change its authoritative/relay type — that is a Configure-phase step.

## R3 — DNS control for MX, SPF, DKIM, DMARC

- **Description:** Ability to edit the authoritative DNS zone for `contoso.com` — specifically **MX**
  (routing primary), **SPF** (authorize both senders), **DKIM** (one selector per platform), and
  **DMARC**.
- **Why required:** MX decides which platform is inbound-primary; SPF/DKIM/DMARC must accommodate two
  sending platforms or legitimate mail will fail authentication and be dropped.
- **How to verify:** Confirm write access to the zone; record the **current** MX/SPF/DKIM/DMARC as the
  rollback baseline (`GWCOEX-Discovery.ps1` captures the M365 side; capture the Google/DNS side too).
- **How to implement if missing:** Coordinate with the DNS owner; stage all changes under change
  control with lowered TTLs first (see `07-best-practices.md`).

## R4 — Decided **MX-primary** platform and routing direction

- **Description:** A documented decision on which platform is **MX-primary** during coexistence and
  therefore which platform **relays** unknown recipients to the other (and when, if ever, MX flips).
- **Why required:** Split delivery is asymmetric — exactly one platform receives inbound first and
  relays the remainder. The relay connector and Google routing rule are built for that direction.
- **How to verify:** Confirm the current MX target and the agreed coexistence direction are written
  down and approved.
- **How to implement if missing:** Decide with the migration owners (typical early state: Google
  MX-primary relaying unknowns to M365; late state: the reverse). Record it; the runbook builds to it.

## R5 — Exchange side ready for internal-relay mail flow

- **Description:** On Exchange Online, the ability to set the shared domain's **Accepted Domain** type
  to **Internal relay** and to create an **outbound connector** to Google's smart host.
- **Why required:** Without internal-relay + a connector, Exchange NDRs mail addressed to Google-hosted
  recipients instead of relaying it.
- **How to verify:** Exchange admin center → **Mail flow → Accepted domains** (can you edit the type?)
  and **Mail flow → Connectors** (can you create a connector?). `GWCOEX-Discovery.ps1` reports the
  current accepted-domain types and connectors.
- **How to implement if missing:** Grant the Exchange admin role; confirm no conflicting existing
  connector already claims the domain.

## R6 — Google side ready for split-delivery routing

- **Description:** Access to **Apps → Google Workspace → Gmail → Routing** (and **Hosts**) in the
  Google Admin console to define a **split-delivery** rule that routes unknown recipients to the M365
  host.
- **Why required:** This is the Google-side mirror of internal relay — it forwards mail for
  recipients not hosted in Google to Exchange Online rather than bouncing.
- **How to verify:** Confirm the Gmail **Routing** and **Hosts** pages are accessible; note the M365
  inbound host (`contoso-com.mail.protection.outlook.com`).
- **How to implement if missing:** Assign a role that includes Gmail settings; obtain the domain's
  M365 `*.mail.protection.outlook.com` value from Microsoft 365 admin center → **Settings → Domains**.

## R7 — Free/busy interop prerequisites (both directions)

- **Description:** The building blocks for **Calendar Interop**:
  - a dedicated **Google role account** `svc-interop-exo@contoso.com` (standard user, Calendar enabled,
    no personal calendar use) that Exchange uses to read Google availability;
  - a dedicated **Exchange role account** `svc-interop-gcal@contoso.com` (standard mailbox, password
    non-expiring if basic auth) that Google uses to read Exchange availability;
  - an **Exchange endpoint** reachable by Google — **Microsoft 365 Graph API** endpoint (app
    registration with the required Calendars permission) or the legacy **EWS URL**
    (`https://outlook.office365.com/EWS/Exchange.asmx`) over **port 443** with a public-CA TLS
    certificate.
- **Why required:** Interop is bidirectional and each direction authenticates with its own role
  account; Google must reach the Exchange endpoint to resolve availability.
- **How to verify:** Confirm both role accounts exist and are licensed/enabled; from the internet,
  confirm the Exchange endpoint responds on 443. **Graph-API endpoint availability can be
  preview/rolling-out — verify the endpoint types offered in your tenant.**
- **How to implement if missing:** Create the two role accounts; register the app (Graph) or confirm
  EWS reachability; apply availability sharing (`Set-MailboxCalendarFolder … -SharingPermissionFlags`
  / detail level) on the Exchange side.

## R8 — Directory-sync mechanism and host

- **Description:** A **directory-sync** path from the identity source of truth into **both** platforms:
  **Google Cloud Directory Sync (GCDS)** installed on a supported host with LDAP access to AD (for the
  Google side), and Entra provisioning (Entra Connect / cloud sync, or native Entra) for the Microsoft
  side. A dedicated **Google provisioning admin** (e.g. `svc-gcds@contoso.com`) for GCDS OAuth.
- **Why required:** A unified directory/GAL across platforms depends on the same source projecting
  users, groups, and cross-platform contacts into each ecosystem. GCDS is **one-way** (never writes to
  AD).
- **How to verify:** Confirm the source of truth (per global requirement 4), that GCDS's host can reach
  LDAP (port 389/636), and that the Google provisioning admin can authorize GCDS. `GWCOEX-Discovery.ps1`
  reports the M365/Entra recipient and contact counts.
- **How to implement if missing:** Stand up a GCDS host (separate from the domain controller is
  recommended), create the provisioning admin, and define which OUs/groups sync. Decide how each
  platform represents the *other* platform's recipients (Google **shared contacts** ↔ Exchange
  **mail contacts / mail users**).

## R9 — A pilot scope and change control

- **Description:** A named **pilot group** (**`Coexistence – Pilot Members`**) spanning both platforms
  (some Google-hosted, some M365-hosted users) and a change-control window for mail-flow/DNS/identity
  changes.
- **Why required:** The model is **Assess → Configure → Pilot → Validate → Expand**; mail-flow and DNS
  changes are high-impact and must be proven on a small, representative set before fleet rollout.
- **How to verify:** Confirm the pilot group exists with members on both platforms and that an approval
  path/window is available.
- **How to implement if missing:** Create **`Coexistence – Pilot Members`**; include at least a few
  users on each platform plus one resource/room and one shared mailbox equivalent; agree the change
  window with the owners.

---

*All prerequisites met? Proceed to `03-implementation.md`. Any gap — especially R3 (DNS), R4 (routing
direction), or R9 (pilot) — is a stop condition: coexistence changes production mail flow and must not
begin until the baseline is captured and the pilot and rollback are in place.*


---


# Global Requirements — Google Workspace & Gemini Solutions

These requirements apply to **every** solution in the **Google** category. They are the common
foundation each Google Workspace / Gemini solution assumes is already in place (or stands up as part
of its own Requirements section). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Google solution).** The **Google Admin console**
> (admin.google.com), **Google Cloud / Cloud Identity**, and the **Microsoft / Entra** sides are
> authored at exact, current click-by-click detail from the vendors' public documentation. **Gemini
> Enterprise** capabilities that are in preview or rolling out are **cited or flagged "verify in your
> tenant"** — never invented. **Third-party migration tools** (e.g. for mail/Drive/Chat data movement)
> and **third-party enterprise apps** (ServiceNow, SAP, Databricks, etc.) are integrated at the
> pattern/architectural level; their internal console steps are deferred to the vendor's own docs.

## 1. Google Workspace / Cloud Identity tenant
- **Description:** A provisioned Google Workspace (or Cloud Identity) tenant with a **super-admin**
  account for configuration, and the appropriate Workspace edition/licensing for the capability in
  scope (e.g. Enterprise Plus for Vault/CAA/DLP, Gemini/AI add-on where required).
- **Why required:** All configuration, policy, and API work is performed against this tenant.
- **How to verify:** Sign in to **admin.google.com** as a super-admin; confirm edition and license
  counts under **Billing / Subscriptions**.
- **How to implement if missing:** Provision the tenant and licenses through Google or an authorized
  reseller before starting.

## 2. Source Microsoft 365 / Entra environment (for migration & coexistence)
- **Description:** For migration/coexistence/identity solutions, administrative access to the source
  **Microsoft 365** tenant and **Microsoft Entra ID** (Global Administrator or the least-privilege
  roles the solution names).
- **Why required:** Migration, directory sync, SSO federation, and coexistence read from and change
  the Microsoft side.
- **How to verify:** Confirm access to the M365 admin center and the Entra admin center with the
  required role.
- **How to implement if missing:** Obtain the role from the M365/Entra tenant owner.

## 3. DNS control for the routed domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF, DKIM, DMARC, TXT, CNAME) for the
  domains being migrated, coexisting, or verified.
- **Why required:** Domain verification, mail routing/coexistence, and authentication all depend on
  DNS changes.
- **How to verify:** Confirm access to the authoritative DNS zone for each domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow changes are high-impact).

## 4. Identity & provisioning source of truth
- **Description:** A defined **identity source of truth** (on-prem AD, Entra ID, or an HR/IGA system)
  and the sync mechanism (e.g. **Google Cloud Directory Sync (GCDS)** or SCIM-based provisioning).
- **Why required:** Consistent users/groups across ecosystems underpin SSO, licensing, and access.
- **How to verify:** Confirm which directory is authoritative and how objects flow into Google.
- **How to implement if missing:** Define the source of truth and provisioning model before configuring
  SSO or migrating.

## 5. A pilot scope (OU / group) and change control
- **Description:** A **pilot organizational unit or group** to validate on before fleet-wide rollout,
  and a **change-control** process for production changes (especially mail flow, DNS, identity, and DLP).
- **Why required:** Every solution follows an **Assess → Configure → Pilot → Validate → Expand** model;
  the pilot proves the design and change control protects production.
- **How to verify:** Confirm a named pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with the
  owners before making production changes.

## 6. Security, compliance & governance stakeholders
- **Description:** Engagement with the **security (CISO), legal/eDiscovery, and data-governance**
  stakeholders whose policies the configuration must satisfy (DLP, retention, Vault/Purview, and any
  regulatory regime such as ITAR/DFARS/Assured Controls where applicable).
- **Why required:** Data governance, eDiscovery, DLP, and regulated-workload settings must align to
  enterprise policy and legal requirements, not just technical defaults.
- **How to verify:** Confirm the applicable policies and named stakeholders/approvers.
- **How to implement if missing:** Identify the owners and obtain the policy/compliance requirements
  before configuring governance controls.

*The deployment model across every Google solution is the same: **Assess → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.*


---


# 3. Implementation — Microsoft 365 ↔ Google Workspace Coexistence

This is the ordered runbook. Execute the phases in order: **Assess → Configure → Pilot → Validate →
Expand**. Do **not** advance a phase until its exit gate (see `05-testing.md`) passes. Every object
is **named once and reused verbatim** in later steps, testing, troubleshooting, and the scripts.

**Conventions used below**
- Shared vanity domain: `contoso.com` · M365 inbound host: `contoso-com.mail.protection.outlook.com`
- Google smart host: `aspmx.l.google.com`
- Google role account (Exchange → reads Google availability): `svc-interop-exo@contoso.com`
- Exchange role account (Google → reads Exchange availability): `svc-interop-gcal@contoso.com`
- GCDS provisioning admin: `svc-gcds@contoso.com`
- Exchange outbound relay connector: **`Coexistence – EXO→Google Connector`**
- Google split-delivery host: **`Coexistence – M365 Host`** · routing rule: **`Coexistence – Split Delivery`**
- Directory-sync marker OU/group: **`Coexistence – Synced`** · Pilot group: **`Coexistence – Pilot Members`**

> Replace `contoso.com` and the host values with your real values, but keep the naming **pattern**
> identical so downstream steps and scripts line up.

---

## Phase 1 — Assess

### 1.1 Confirm access to both platforms
1. Sign in to **admin.google.com** (super-admin) and **admin.exchange.microsoft.com** /
   **admin.microsoft.com** (Exchange admin + Global Admin or least-privilege equivalent) — **R1**.

### 1.2 Capture the coexistence-readiness baseline
1. On an operator workstation, install the Exchange Online module:
   `Install-Module ExchangeOnlineManagement -Scope CurrentUser`.
2. Run **`scripts\GWCOEX-Discovery.ps1`** against the M365 tenant. It exports CSVs of: accepted
   domains and their **type** (authoritative vs internal relay), inbound/outbound **connectors**,
   the domain's **MX / SPF / DKIM / DMARC** as seen in DNS, **mail contacts / mail users**
   (Google-side representation), and any existing **Calendar Interop / organization sharing** config.
3. Separately record the current **Google** side (Domains, Gmail Routing/Hosts, Calendar Interop
   management state) and the **DNS** MX/SPF/DKIM/DMARC. Save all of this as the **rollback baseline**.

**Exit gate:** complete readiness baseline captured on both platforms and DNS; MX-primary direction
(**R4**) confirmed and written down. (Test **T1**.)

---

## Phase 2 — Configure

Configure the three pillars. Build each for the **pilot scope first**; expansion is Phase 5.

### 2.1 Mail routing / split delivery

#### 2.1a Exchange side — internal relay + connector to Google
1. In **Exchange admin center → Mail flow → Accepted domains**, open `contoso.com` and set the type
   to **Internal relay**. (This tells Exchange to *relay* unknown recipients instead of NDR.)
2. In **Mail flow → Connectors → Add a connector**, create an **outbound** connector
   **`Coexistence – EXO→Google Connector`**: From **Office 365** → To **Partner organization**; route
   by **domain** `contoso.com`; delivery via **smart host** `aspmx.l.google.com` (or the domain's
   full Google MX target); require **TLS** with a trusted CA subject. Save.
   - You may scope relay to the pilot initially by using a routing subdomain or a transport rule that
     limits the connector to **`Coexistence – Pilot Members`** during Phase 3.
3. Confirm mail for a Google-hosted pilot recipient now relays out of Exchange rather than NDRing
   (validated in Phase 4).

#### 2.1b Google side — split-delivery routing to M365
1. In **Google Admin console → Apps → Google Workspace → Gmail → Hosts**, add a host
   **`Coexistence – M365 Host`** = `contoso-com.mail.protection.outlook.com`, port **25**, require TLS.
2. In **Apps → Google Workspace → Gmail → Routing**, add a **Recipient address map / split-delivery**
   rule **`Coexistence – Split Delivery`**: for envelope recipients **not** hosted in Google, route
   to **`Coexistence – M365 Host`**. Keep the rule scoped to the pilot OU during Phase 3.
3. This is the mirror of internal relay: Google delivers to its own mailboxes and forwards the rest
   to Exchange Online.

#### 2.1c Authentication (DNS)
1. **SPF:** publish a single TXT that authorizes **both** senders, e.g.
   `v=spf1 include:_spf.google.com include:spf.protection.outlook.com -all`.
2. **DKIM:** enable and publish a **separate selector** for each platform (Google: `google` selector;
   M365: the two `selector1/2._domainkey` CNAMEs). Both sign independently.
3. **DMARC:** during the transition keep a monitoring-friendly policy (`p=none` with `rua=` reporting,
   or `quarantine` with a wide `pct`) so a relay misstep is *visible*, not silently dropped. Tighten
   only after Validate.

### 2.2 Free/busy calendar interop

#### 2.2a Create the two role accounts
1. In **Google Admin console → Directory → Users**, create **`svc-interop-exo@contoso.com`** — a
   standard, Calendar-enabled user Exchange will use to read Google availability. Do not use it as a
   person's mailbox.
2. In **Microsoft 365 admin center → Users**, create **`svc-interop-gcal@contoso.com`** — a standard
   licensed mailbox Google will use to read Exchange availability. If the endpoint uses basic auth,
   set the password to **non-expiring** and exclude the account from blocking Conditional Access.

#### 2.2b Google → Exchange (Google users see Exchange availability)
1. In **Google Admin console → Apps → Google Workspace → Calendar → Calendar Interop management**,
   check **"Allow Google Calendar to display Exchange users' availability."**
2. Click **Add an Exchange endpoint** and choose the endpoint type your tenant offers —
   **Microsoft 365 (Graph API)** (provide **Tenant ID**, **Application (client) ID**, **client
   secret** from an app registration granted the required Calendars permission) **or** legacy **EWS**
   (`https://outlook.office365.com/EWS/Exchange.asmx` with role account `svc-interop-gcal@contoso.com`).
   *(Graph endpoint availability may be preview/rolling-out — verify in your tenant.)*
3. Optionally enable **Show event details** (title/location) instead of availability-only; event-level
   privacy is respected.

#### 2.2c Exchange → Google (Exchange users see Google availability)
1. Still in **Calendar Interop management**, set the **Google role account**
   **`svc-interop-exo@contoso.com`** that Exchange will authenticate as when reading Google availability.
2. On the Exchange side, configure organization availability sharing so Outlook resolves the Google
   users. Where event-detail visibility is wanted, raise the calendar detail level, e.g.
   `Set-MailboxCalendarFolder <user>:\Calendar -DetailLevel LimitedDetails` for pilot users (default
   is availability-only).
3. Ensure the Exchange endpoint is reachable from Google on **port 443** with a public-CA TLS cert
   (allowlist Google's Interop egress ranges if you block inbound).

### 2.3 Directory sync (unified GAL)

#### 2.3a Google side — GCDS from AD/LDAP
1. In **Google Admin console → Directory → Users**, create the provisioning admin
   **`svc-gcds@contoso.com`** with directory + shared-contacts privileges.
2. Install **GCDS** on a supported host (separate from the domain controller is recommended) with
   LDAP access to AD (389/636).
3. In **GCDS Configuration Manager**:
   - **Google Domain Configuration** → domain `contoso.com`; **Authorize** with `svc-gcds@contoso.com`.
   - **LDAP Configuration** → server type **MS Active Directory**, base DN, and a read account; **Test
     connection**.
   - **User Accounts / Groups / Shared Contacts** → search rules that select the **`Coexistence –
     Synced`** OU/group. Provision **shared contacts** for M365-only recipients so they appear in
     Google's directory.
   - **Sync** → **Clear cache → Simulate sync**; review **Proposed changes**; confirm no unexpected
     deletions, then run once for the pilot.
4. GCDS is **one-way** — it never modifies AD.

#### 2.3b Microsoft side — provision from the same source
1. Ensure users are provisioned into **Entra/Exchange** from the same source of truth (Entra Connect /
   cloud sync from AD, or native Entra).
2. Represent **Google-only** recipients in Exchange as **mail contacts / mail users** (so they appear
   in the GAL and route via 2.1a). Tag coexistence-synced objects with the **`Coexistence – Synced`**
   marker for later cleanup.

**Exit gate:** all three pillars configured and scoped to the pilot; DNS auth (SPF/DKIM/DMARC) in
place. (Test **T2**.)

---

## Phase 3 — Pilot

1. Populate **`Coexistence – Pilot Members`** with representative users on **both** platforms plus one
   resource/room and one shared mailbox equivalent.
2. Confirm the mail relay, split-delivery rule, and Interop endpoint are scoped to the pilot (subdomain,
   transport rule, or OU) so production users are unaffected.
3. Run **`scripts\GWCOEX-Set-ScopeTargeting.ps1`** to (re)point the coexistence scope at
   **`Coexistence – Pilot Members`**. It defaults to **`-WhatIf`** — review the planned scope change,
   then re-run with `-Apply`.

**Exit gate:** coexistence live for the pilot only; production unchanged. (Test **T3**.)

---

## Phase 4 — Validate

Run **`scripts\GWCOEX-Validation.ps1`** for each pilot user; it checks the three pillars per user:
1. **Mail routing** — send a probe from Google→M365 and M365→Google for pilot recipients; confirm
   delivery (no NDR) and correct headers (relayed via the connector / split-delivery host).
2. **Free/busy** — confirm a Google user resolves an Exchange user's availability *and* an Outlook user
   resolves a Google user's availability (both directions).
3. **Directory** — confirm each pilot user appears in the **other** platform's directory/GAL (Google
   shared contact ↔ Exchange mail contact) and resolves when addressed.

Run **`scripts\GWCOEX-Report.ps1`** to produce a **coexistence coverage** report (per user: mail-route
OK, free/busy both-ways OK, directory-present OK) with an overall coverage percentage.

If a check fails, use `06-troubleshooting.md`; if remediation is needed, run
**`scripts\GWCOEX-Remediation.ps1`** (defaults to **`-WhatIf`** — review, then `-Apply`).

**Exit gate:** 100% of pilot users pass all three pillars, both directions. (Test **T4**.)

---

## Phase 5 — Expand

1. Widen each pillar's scope from **`Coexistence – Pilot Members`** to the full fleet:
   - remove the pilot scoping on the **connector / transport rule** and the Google **split-delivery
     rule** (or point them at the whole domain/OU);
   - broaden the **GCDS** search rules to all coexistence OUs and schedule GCDS on its interval;
   - confirm the Interop endpoint covers all users.
2. Re-run **`GWCOEX-Set-ScopeTargeting.ps1 -Scope AllUsers`** (defaults to `-WhatIf`; re-run with
   `-Apply`).
3. Re-run **`GWCOEX-Validation.ps1`** on a broad sample and **`GWCOEX-Report.ps1`** for fleet coverage.
4. Only after coverage is proven, tighten **DMARC** to an enforcing policy.

**Exit gate:** fleet coverage report green; DMARC enforced; rollback plan current. (Test **T5**.)

---

## Rollback (any phase)

Because every change is captured in the Phase 1 baseline, rollback is deterministic:
- Revert the **Accepted Domain** type to its prior value and **disable** `Coexistence – EXO→Google
  Connector`.
- Disable the Google **`Coexistence – Split Delivery`** routing rule.
- Uncheck **Calendar Interop** endpoints.
- **Pause GCDS** (do not delete synced objects until consolidation).
- Restore prior **MX/SPF/DKIM/DMARC** DNS if they were changed.

Coexistence is a transition state — see `07-best-practices.md` for the controlled **decommission** at
consolidation.


---


# 5. Testing & Validation — Microsoft 365 ↔ Google Workspace Coexistence

Each phase in `03-implementation.md` has a **pass/fail exit gate**. Do not advance until the gate's
test passes. Tests use the same named objects as the runbook (`Coexistence – Pilot Members`,
`Coexistence – EXO→Google Connector`, `svc-interop-*`, etc.). The scripts automate the per-user checks;
this file defines what "pass" means.

**Test accounts:** at least one **Google-hosted** and one **M365-hosted** pilot user, plus one
resource/room and one shared mailbox equivalent, all in **`Coexistence – Pilot Members`**.

---

## T1 — Assess gate (readiness baseline)

**Goal:** the coexistence-readiness baseline is complete on both platforms and DNS.

| Check | How | Pass |
|---|---|---|
| M365 baseline | `GWCOEX-Discovery.ps1` ran; CSVs present | Accepted-domain types, connectors, contacts, and Interop state exported |
| DNS baseline | Inspect MX/SPF/DKIM/DMARC for `contoso.com` | Current records recorded as rollback baseline |
| Google baseline | Domains, Gmail Routing/Hosts, Calendar Interop management state noted | State recorded |
| Direction decided | Review R4 decision | MX-primary platform + relay direction written down and approved |

**Fail →** capture the missing baseline before any Configure step.

---

## T2 — Configure gate (all three pillars built for pilot)

| Pillar | Check | Pass |
|---|---|---|
| Mail | EXO accepted domain = **Internal relay**; `Coexistence – EXO→Google Connector` exists; Google `Coexistence – Split Delivery` rule + `Coexistence – M365 Host` exist | Both relay paths configured (pilot-scoped) |
| Free/busy | Exchange endpoint added in Calendar Interop; role accounts `svc-interop-exo@contoso.com` and `svc-interop-gcal@contoso.com` set | Both directions configured |
| Directory | GCDS simulate-sync shows expected users/groups/shared contacts; EXO mail contacts for Google-only recipients exist | Directory projection ready both ways |
| Auth | SPF authorizes both senders; DKIM selectors per platform; DMARC monitoring policy | DNS auth in place |

**Fail →** fix the specific pillar in `03-implementation.md` §2.x before piloting.

---

## T3 — Pilot gate (scoped to pilot only)

| Check | How | Pass |
|---|---|---|
| Scope correct | `GWCOEX-Set-ScopeTargeting.ps1` (default `-WhatIf`) plan shows scope = `Coexistence – Pilot Members` | Only pilot users in scope |
| Production untouched | Send a normal message to a non-pilot production user | Delivered exactly as before coexistence |

**Fail →** re-scope before validating; never validate with production in scope.

---

## T4 — Validate gate (pilot passes all pillars, both directions)

Run `GWCOEX-Validation.ps1` per pilot user, then `GWCOEX-Report.ps1`.

| Pillar | Test | Pass |
|---|---|---|
| Mail G→M | Google-hosted user emails an M365-hosted pilot user | Delivered, no NDR; header shows relay/split-delivery path |
| Mail M→G | M365-hosted user emails a Google-hosted pilot user | Delivered, no NDR; relayed via `Coexistence – EXO→Google Connector` |
| Free/busy G→X | Google user views an Exchange user's availability | Busy blocks resolve |
| Free/busy X→G | Outlook user views a Google user's availability | Busy blocks resolve |
| Directory G | Google-only recipient appears in EXO GAL (mail contact) | Resolves when addressed |
| Directory M | M365-only recipient appears in Google directory (shared contact) | Resolves when addressed |

**Pass gate:** **100%** of pilot users green on all six rows. **Fail →** `06-troubleshooting.md`, then
`GWCOEX-Remediation.ps1` (default `-WhatIf`).

---

## T5 — Expand gate (fleet coverage)

| Check | How | Pass |
|---|---|---|
| Scope widened | `GWCOEX-Set-ScopeTargeting.ps1 -Scope AllUsers` plan | Whole fleet in scope |
| Fleet coverage | `GWCOEX-Report.ps1` across a broad sample | Coverage ≥ agreed threshold (target 100%) |
| GCDS scheduled | GCDS running on interval | Automated sync healthy, no unexpected deletes |
| DMARC enforced | DNS shows enforcing DMARC | Enforcement on only after coverage proven |

**Fail →** do not tighten DMARC or declare done; remediate and re-report.

---

## Regression / ongoing checks

- **Weekly:** `GWCOEX-Report.ps1` for coverage drift; investigate any user that drops a pillar.
- **After any DNS or connector change:** re-run mail-routing rows (T4 Mail G→M / M→G).
- **After GCDS schema/OU changes:** re-run directory rows (T4 Directory G / M).
- **Before consolidation cutover:** full T4 sweep, then follow the decommission steps in
  `07-best-practices.md`.


---


# 6. Troubleshooting — Microsoft 365 ↔ Google Workspace Coexistence

Symptom → likely cause → fix, organized by pillar. Reuse the named objects from
`03-implementation.md`. When a fix requires a change, prefer `GWCOEX-Remediation.ps1` (default
`-WhatIf`) so you can review before applying. Always re-run the matching `05-testing.md` row after a fix.

---

## Mail routing / split delivery

### Mail to a valid recipient on the *other* platform bounces (NDR: recipient not found)
- **Cause:** the shared domain is still **Authoritative** on the receiving platform, so it rejects
  recipients it doesn't host instead of relaying.
- **Fix:** on Exchange, set `contoso.com` Accepted Domain to **Internal relay**; on Google, ensure the
  **`Coexistence – Split Delivery`** routing rule is enabled and targets **`Coexistence – M365 Host`**.
  Verify the outbound path (`Coexistence – EXO→Google Connector` / the Google host) exists and is on.

### Relayed mail loops or bounces with "too many hops"
- **Cause:** *both* platforms are relaying the same domain to each other with no authoritative owner for
  a nonexistent address — the message ping-pongs.
- **Fix:** confirm exactly **one MX-primary** (R4). A message for a truly nonexistent recipient must
  bounce cleanly on the MX-primary; it should not be relayed onward. Re-check the split-delivery scope
  so only *unknown-locally* recipients relay.

### Relayed mail is marked spam or fails authentication at the far platform
- **Cause:** **SPF** doesn't authorize both senders, or **DKIM** isn't signing on the relaying platform.
- **Fix:** publish one SPF TXT with `include:_spf.google.com include:spf.protection.outlook.com`; enable
  a **separate DKIM selector** per platform. Audit SPF for the **10-lookup limit**. Keep **DMARC** at a
  monitoring policy until both align.

### Some pilot users route, others NDR
- **Cause:** the relay/split-delivery rule is scoped to the pilot but the failing user isn't in
  **`Coexistence – Pilot Members`** (or the connector transport rule excludes them).
- **Fix:** confirm scope with `GWCOEX-Set-ScopeTargeting.ps1` (default `-WhatIf`); add the user or widen
  the scope, then re-test.

### Relayed mail is delivered in cleartext / TLS warnings
- **Cause:** the connector or Google host isn't requiring TLS.
- **Fix:** enable **Require TLS** on `Coexistence – EXO→Google Connector` and the Google host
  `Coexistence – M365 Host`.

---

## Free/busy calendar interop

### Google user sees an Exchange user as blank / "no information"
- **Cause:** the **Exchange endpoint** or **`svc-interop-gcal@contoso.com`** role account is
  misconfigured, or the endpoint is unreachable.
- **Fix:** in **Calendar Interop management**, re-check the endpoint (Graph app credentials or the EWS
  URL `https://outlook.office365.com/EWS/Exchange.asmx`) and role account. Confirm the endpoint answers
  on **443** with a valid public-CA cert; if inbound is filtered, allowlist Google's Interop egress
  ranges.

### Outlook user sees a Google user as blank
- **Cause:** the **Google role account `svc-interop-exo@contoso.com`** isn't set in Interop, is
  Calendar-disabled, or the Exchange-side org availability sharing isn't pointed at Google.
- **Fix:** confirm the Google role account is a standard, Calendar-enabled user set in Interop; verify
  the Exchange organization availability/sharing configuration references it.

### Availability resolves but no event titles/locations
- **Cause:** detail level is **availability-only** (the default).
- **Fix:** enable **Show event details** in Interop (Google→Exchange) and raise the Exchange calendar
  detail level (e.g. `Set-MailboxCalendarFolder <user>:\Calendar -DetailLevel LimitedDetails`) where
  policy allows. Event-level privacy is still respected.

### Interop works for some users, not others
- **Cause:** the target user has a conflicting personal Google account on the domain, an Exchange
  mailbox issue, or isn't in scope yet.
- **Fix:** ensure interop-target users have no conflicting personal Google account and a healthy mailbox;
  confirm they're in the current scope.

### Endpoint type "Microsoft 365 (Graph API)" not available
- **Cause:** the Graph-API endpoint option is **preview/rolling-out** in your tenant.
- **Fix:** **verify in your tenant**; if unavailable, use the legacy **EWS** endpoint with modern-auth
  where supported, and revisit when Graph is offered.

---

## Directory sync

### A user on the other platform doesn't appear in the address book/GAL
- **Cause:** the cross-platform representation is missing — no Google **shared contact** for an M365-only
  user, or no Exchange **mail contact / mail user** for a Google-only user.
- **Fix:** confirm GCDS provisions shared contacts for M365-only recipients and that EXO mail contacts
  exist for Google-only recipients (create via `GWCOEX-Remediation.ps1`, default `-WhatIf`). Confirm the
  user is in the **`Coexistence – Synced`** OU/group.

### GCDS simulate-sync proposes mass deletions
- **Cause:** an over-broad or wrong **search rule / base DN**, so GCDS thinks synced objects should be
  removed.
- **Fix:** **do not run the real sync.** Correct the LDAP search rules / base DN to the intended
  **`Coexistence – Synced`** scope; re-**Simulate** until **Proposed changes** are as expected.

### Directory in Google is stale / out of date
- **Cause:** GCDS isn't scheduled, or its last run failed.
- **Fix:** confirm GCDS is scheduled on its interval and the last run succeeded; check the GCDS logs and
  LDAP connectivity (389/636).

### Duplicate or conflicting entries appear
- **Cause:** two systems are authoring the same user (the GAL diverges).
- **Fix:** enforce a **single source of truth**; ensure only one provisioning path writes each user, and
  that shared contacts/mail contacts are only used for the *other* platform's recipients.

---

## Cross-cutting

### `GWCOEX-*.ps1` fails to connect
- **Cause:** the Graph SDK / Exchange Online module isn't installed, or consent/scopes are missing.
- **Fix:** `Install-Module Microsoft.Graph`, `Install-Module ExchangeOnlineManagement`; sign in with an
  admin that can consent to the required read scopes (see each script's header). Discovery/Validation/
  Report are read-only.

### A remediation applied the wrong change
- **Cause:** `-Apply` was run without reviewing the `-WhatIf` plan.
- **Fix:** revert using the Phase 1 baseline (accepted-domain type, connector state, DNS). Re-run the
  script in default `-WhatIf` mode, review, then `-Apply`.

> After every fix, re-run the corresponding **`05-testing.md`** check and, before declaring resolution,
> re-run `GWCOEX-Report.ps1` to confirm coverage didn't regress elsewhere.


---


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


---


# 8. Deliverables Summary — Microsoft 365 ↔ Google Workspace Coexistence

Everything in this solution, and what to do with it.

## Documents (`source/`)

| Doc | Purpose |
|---|---|
| `01-solution-overview.md` | The coexistence model — the three pillars (mail routing/split delivery, free/busy interop, directory sync), scope, and lifecycle. |
| `02-requirements.md` | Prerequisites (R1–R9) as Description → Why → Verify → Implement — both platforms + admin, DNS/mail-flow, interop role accounts, directory-sync mechanism, pilot. |
| `03-implementation.md` | The ordered runbook: **Assess → Configure → Pilot → Validate → Expand**, with named objects and per-phase exit gates and rollback. |
| `05-testing.md` | Pass/fail gates T1–T5 and ongoing regression checks — mail routes, free/busy both ways, directory in sync. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common coexistence failures (NDRs, relay loops, blank free/busy, missing GAL entries). |
| `07-best-practices.md` | Keeping the transition stable, and the controlled decommission at consolidation. |
| `08-deliverables-summary.md` | This file. |
| `executive-summary.md` | One-page summary for decision-makers. |

## Scripts (`scripts/`)

All Microsoft-side automation uses the **Microsoft Graph PowerShell SDK** (and the Exchange Online
module for mail-flow objects). Discovery, Validation, and Report are **read-only**; Remediation and
Set-ScopeTargeting default to **`-WhatIf`** and require `-Apply` to make changes.

| Script | Role | Read/Write |
|---|---|---|
| `GWCOEX-Discovery.ps1` | Coexistence-readiness discovery — accepted-domain types, connectors, MX/SPF/DKIM/DMARC, cross-platform contacts, Interop state. | Read-only |
| `GWCOEX-Validation.ps1` | Per-user interop validation — mail routing, free/busy both directions, directory presence. | Read-only |
| `GWCOEX-Report.ps1` | Coexistence coverage report — per-user pillar status + overall coverage %. | Read-only |
| `GWCOEX-Remediation.ps1` | Safe remediation of common gaps (relay type, connector, mail contacts). Default `-WhatIf`. | Write (gated) |
| `GWCOEX-Set-ScopeTargeting.ps1` | Point the coexistence scope at the pilot group or all users. Default `-WhatIf`. | Write (gated) |

## How to use it end to end

1. Verify **`02-requirements.md`** (R1–R9). Capture the DNS + Google + M365 baseline.
2. Run **`GWCOEX-Discovery.ps1`** for the M365-side baseline.
3. Follow **`03-implementation.md`** Phase by Phase, honoring each **`05-testing.md`** gate.
4. In Pilot/Validate, run **`GWCOEX-Set-ScopeTargeting.ps1`**, **`GWCOEX-Validation.ps1`**, and
   **`GWCOEX-Report.ps1`**; remediate with **`GWCOEX-Remediation.ps1`** as needed.
5. Expand to the fleet, prove coverage, tighten DMARC.
6. Operate per **`07-best-practices.md`**; at consolidation, run the **decommission** checklist.

## Outcome

Microsoft and Google working as one through the transition — **mail routes, calendars resolve, the
directory stays in sync** — piloted, validated, and rollback-ready, until consolidation retires the
legacy side cleanly.
