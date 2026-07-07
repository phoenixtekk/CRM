# Exchange Online & Hybrid Mail Flow — Architecture, Connectors & Routing

> **Version 1.0.0** · Category: Messaging · Solution code: EXOMAIL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

In an Exchange/Microsoft 365 **hybrid** environment, mail flow breaks in ways that are hard to trace:
messages leave via the wrong connector, an accepted domain typed incorrectly silently NDRs users still
hosted on-premises, centralized mail transport sends outbound the long way through on-prem, or a pair
of transport rules forms a routing loop. The result is intermittent, mysterious mail loss that costs
hours of investigation and erodes trust in the platform.

This solution converts that mystery into a **named, testable architecture** and a **repeatable
trace-to-root-cause method**. It maps hybrid mail flow end to end — the connector types (inbound/
outbound, on-prem↔EXO hybrid, partner) and when to use each, accepted domains and their routing types
(authoritative vs internal relay), routing topologies, the centralized-mail-transport decision, and
controlled transport rules — then provides a **layered diagnostic** (message trace → message headers →
queues/SMTP logs) that resolves "where did the message go?" in minutes, with evidence.

**Approach.** Delivery follows a pilot-first model — **Assess → Design → Configure → Pilot → Validate →
Expand** — with explicit pass/fail gates and a documented rollback at every step. Nothing changes for
everyone at once: the design is proven on a named pilot scope, validated against clear criteria
(mail routes correctly inbound/outbound/internal-relay, no loops, traces clean), and only then
expanded to production. Every connector, accepted domain, and transport rule is named with a consistent
convention and reused across testing, troubleshooting, and automation.

**Why it is low-risk.** Mail-flow, connector, DNS, and transport-rule changes are high-impact to
production mail, so the solution is engineered to protect it: a read-only baseline before any change, a
pilot gate before expansion, and per-change rollback. The five included PowerShell tools (Exchange
Online PowerShell V3 / Microsoft Graph) are **safe by default** — read-only or `-WhatIf` unless an
explicit apply/commit switch is passed — use modern authentication, and contain **no credentials or
secrets in code**. Vendor detail is taken from Microsoft's public documentation; version-, plan-, and
Government-cloud-dependent behavior is cited or flagged for tenant verification rather than assumed.

**Outcome.** Hybrid mail flow that **routes correctly and is diagnosable**: connectors of the right
type, accepted domains typed to reality, transport rules controlled and loop-free, the centralized-
transport decision made on purpose, and a repeatable method to trace any message to root cause — at a
fraction of the cost of an open-ended consulting engagement.


---


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


---


# Requirements

These are the **solution-specific** prerequisites for designing and troubleshooting Exchange/M365
hybrid mail flow. They build on the shared **Global Requirements — Microsoft 365 / Exchange Messaging
Solutions** (`global-requirements-messaging.md`): a Microsoft 365 tenant with Exchange Online (GR-1),
least-privilege admin roles (GR-2), the EXO V3 + Graph toolchain (GR-3), DNS control for the mail
domains (GR-4), hybrid Exchange/AD/AAD-Connect access for hybrid solutions (GR-5), and a pilot scope
plus change control (GR-6). Verify those first; the items below are additional and specific to
mail-flow architecture, connectors, and routing.

---

## R1. Healthy Exchange hybrid configuration (for hybrid scenarios)

- **Description:** A hybrid deployment configured by a **current** run of the Exchange **Hybrid
  Configuration Wizard (HCW)**, with the HCW-created **hybrid connectors** (`Inbound from on-prem`,
  `Outbound to on-prem`) present and healthy, and a supported on-prem Exchange build/CU.
- **Why required:** Hybrid mail flow depends on HCW-managed connectors, certificates, and organization
  relationships. Hand-editing HCW connectors, or a mismatched/old CU, is a leading cause of hybrid
  mail-flow breakage. Supported CU levels are **version-dependent** — verify against Microsoft's
  current Exchange Server supportability matrix for your build.
- **How to verify:** In on-prem Exchange Management Shell, `Get-HybridConfiguration`; in EXO PowerShell,
  `Get-InboundConnector`, `Get-OutboundConnector` and confirm the hybrid connectors exist with
  `ConnectorType`/`ConnectorSource` = `HybridWizard`. Confirm the on-prem build/CU with
  `Get-ExchangeServer | Format-List Name,AdminDisplayVersion,Edition`.
- **How to implement if missing:** Re-run the current HCW from a supported on-prem Exchange server;
  do **not** create the hybrid connectors by hand. If pure cloud (no on-prem), this requirement is
  N/A — skip the hybrid legs of the implementation.

## R2. Documented current-state routing (MX, connectors, accepted domains)

- **Description:** A captured baseline of the **current** mail-flow topology: MX records for every mail
  domain, all inbound/outbound connectors and their type/source, and every accepted domain with its
  **domain type** (authoritative / internal relay / external relay).
- **Why required:** You cannot safely change routing you have not documented. The domain **type** in
  particular determines whether unknown recipients NDR or relay — the single most common hybrid
  mail-flow surprise.
- **How to verify:** Run the Discovery script (`Invoke-MailFlowDiscovery.ps1`, read-only) or manually:
  `Get-AcceptedDomain | Format-Table Name,DomainName,DomainType,Default`;
  `Get-InboundConnector`, `Get-OutboundConnector`; and resolve public MX for each domain
  (`Resolve-DnsName <domain> -Type MX`).
- **How to implement if missing:** Run the Discovery script and save its report as the baseline before
  making any change; store it with the change record.

## R3. Correct accepted-domain type for each mail domain

- **Description:** Each mail domain must be set to the accepted-domain **type** that matches reality:
  **authoritative** when all recipients are in this Exchange organization; **internal relay** when the
  domain is shared with on-prem or another system during coexistence. The coexistence domain in this
  solution is named `Accepted Domain – Primary – Prod`.
- **Why required:** An authoritative domain NDRs mail for any recipient it does not know — so if some
  mailboxes are still on-prem (or in a partner system) and the domain is authoritative, those users
  silently stop receiving mail. Internal relay forwards unknowns out the outbound connector instead.
- **How to verify:** `Get-AcceptedDomain "<domain>" | Format-List DomainName,DomainType`. Cross-check
  against where mailboxes actually live (EXO vs on-prem).
- **How to implement if missing:** Set the type under change control:
  `Set-AcceptedDomain -Identity "<domain>" -DomainType InternalRelay` (during coexistence), reverting
  to `Authoritative` only after all recipients are migrated. Test in pilot first.

## R4. Connector authentication material (certificates / IPs)

- **Description:** The TLS **certificate subject** (or sending IP ranges) used to identify and secure
  connector traffic between on-prem/partner systems and Exchange Online — for both HCW hybrid
  connectors and any partner connector (`Inbound Connector – Partner – Prod`).
- **Why required:** Inbound connectors validate senders by certificate subject or IP; outbound
  connectors and partner connectors can **require TLS**. Wrong/expired certificate subject or an
  un-listed IP causes rejected or unencrypted mail.
- **How to verify:** For hybrid, HCW manages this — confirm with `Get-InboundConnector | Format-List
  Name,TlsSenderCertificateName,SenderIPAddresses,RequireTls`. For partners, obtain the partner's
  sending domain/cert subject or IP ranges and their required-TLS posture.
- **How to implement if missing:** For hybrid, re-run HCW so it re-provisions certificate/subject
  matching. For partners, collect the cert subject or IPs from the partner and set them on the named
  partner connector under change control.

## R5. Message trace / reporting access and retention awareness

- **Description:** The ability to run **message trace** (real-time and historical) and read message
  headers — via EAC (**Mail flow → Message trace**) and EXO PowerShell (`Get-MessageTraceV2` for
  recent, `Start-HistoricalSearch` for older). Awareness that real-time trace covers roughly the last
  **~10 days** and historical search extends further (retention/window is **version-/service-dependent
  — verify in your tenant**).
- **Why required:** The layered diagnostic starts with message trace; without trace access and an
  understanding of its time window, older incidents can't be investigated the same way.
- **How to verify:** Confirm the admin role includes message-trace rights (e.g. via a
  Compliance/Reporting-capable role); run a small `Get-MessageTraceV2` for a known recent message.
- **How to implement if missing:** Assign the least-privilege role that grants trace/reporting; for
  older messages, plan to use historical search and note its longer processing time.

## R6. On-prem transport visibility (hybrid only): queues and protocol logs

- **Description:** For hybrid, access to the **on-premises** transport server(s) to inspect **queues**
  (`Get-Queue`, `Get-Message`) and **protocol/connectivity logs** — the legs of the path that cloud
  message trace cannot see.
- **Why required:** When trace shows a message handed to on-prem (or received from on-prem), the queue
  and SMTP logs on that server are the only way to see what happened on the on-prem hop.
- **How to verify:** From on-prem Exchange Management Shell, `Get-Queue` returns without error; confirm
  the transport logging paths exist (`Get-TransportService | Format-List *LogPath*`).
- **How to implement if missing:** Obtain on-prem Exchange admin access and confirm transport logging
  is enabled before an incident, so the evidence exists when you need it.

## R7. Government cloud awareness (if applicable)

- **Description:** If the tenant is **GCC High / DoD** (or GCC), awareness that portal URLs and some
  endpoints differ (e.g. admin/Defender/Purview portals on `*.office365.us`) and that certain features
  or connector behaviors may differ or lag Commercial.
- **Why required:** Following Commercial portal paths on a sovereign cloud sends admins to the wrong
  URLs and can misstate feature availability. Per the house Commercial-vs-Government rule, sovereign
  differences are flagged, not assumed away.
- **How to verify:** Confirm the cloud instance of the tenant (Commercial vs GCC/GCC High/DoD) and use
  the matching portal endpoints for that cloud.
- **How to implement if missing:** Substitute the Government portal URLs and **verify each
  feature/endpoint in your own cloud** before relying on a Commercial-documented behavior.


---


# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*


---


# Implementation

Follow the house deployment model — **Assess → Design → Configure → Pilot → Validate → Expand** — with
explicit pass/fail gates and a documented rollback at each production-affecting step. Mail flow,
connectors, accepted domains, DNS, and transport rules are **high-impact to production mail**: change
them pilot-first, never fleet-wide in one move.

Every artifact is named with the convention `<Purpose> – <Scope> – <Stage>` and that exact name is
reused in testing, troubleshooting, and the scripts. Portal paths are Commercial; on GCC/GCC High/DoD
substitute the `*.office365.us` portals and **verify each feature in your own cloud** (R7).

---

## Phase 1 — Assess (read-only baseline)

**Goal:** capture the current mail-flow topology before touching anything.

1. Connect with a least-privilege admin: in EXO PowerShell,
   `Connect-ExchangeOnline -UserPrincipalName <admin-upn>` (modern auth; no stored credentials).
2. Run the Discovery script **read-only**:
   `\.Invoke-MailFlowDiscovery.ps1 -OutputPath .\baseline`. It enumerates accepted domains (+ type),
   inbound/outbound connectors (+ type/source), transport rules, remote domains, the HCW hybrid state,
   and resolves public MX for each domain. Save the report as **`MailFlow Baseline – Tenant – Prod`**.
3. Confirm the accepted-domain **types** match where mailboxes actually live (EXO vs on-prem vs
   partner). Flag any domain that is `Authoritative` but still has recipients elsewhere — that is a
   silent-NDR risk (see R3).
4. Record the current routing topology (cloud-authoritative / on-prem-inbound / CMT) and whether
   **centralized mail transport** is enabled (`Get-OnPremisesOrganization`, HCW state).

**Gate G1 (Assess complete):** baseline report saved; accepted-domain types and current routing
documented; any authoritative-domain-with-external-recipients risk flagged. Do not proceed until G1 is
met.

---

## Phase 2 — Design (on paper, no changes)

**Goal:** decide the target connectors, domain types, routing, transport rules, and the CMT decision.

1. **Accepted domains.** For each mail domain choose the target **type**: `Authoritative` if all
   recipients are (or will be) in EXO; `InternalRelay` during coexistence when the domain is shared
   with on-prem/partner. Name the primary shared domain **`Accepted Domain – Primary – Prod`**.
2. **Connectors.** Decide which connectors you need and their type:
   - Hybrid coexistence → rely on HCW connectors (`Inbound from on-prem`, `Outbound to on-prem`); plan
     to **re-run HCW**, not hand-edit.
   - Partner enforcement (a B2B partner or a hygiene gateway) → plan
     `Inbound Connector – Partner – Prod` and/or `Outbound Connector – Partner – Prod` with the
     partner's cert subject/IPs and required-TLS posture (R4).
3. **Routing topology.** Pick the target shape: cloud-authoritative (MX → EXO/EOP), on-prem-inbound
   (MX → on-prem gateway), or CMT.
4. **Centralized mail transport (CMT) decision.** Enable CMT **only** if on-prem must process outbound
   *cloud* mail (on-prem DLP/encryption/disclaimer gateway, or a required outbound smart host only
   on-prem can reach). Otherwise leave **CMT off** (EXO sends outbound directly). Record the decision
   and its justification.
5. **Transport rules.** List each needed mail-flow rule with condition → action, scope, and priority;
   name them (e.g. `Transport Rule – Partner TLS – Prod`, `Transport Rule – External Tag – Prod`).
   Design out loops: never let two rules redirect to each other, and scope tightly.
6. **Pilot scope.** Define the pilot: a pilot accepted domain or a small set of pilot recipients and
   controlled test mailboxes (`pilot-tx@…`, `pilot-rx@…`) plus an external test address you control.

**Gate G2 (Design approved):** target domain types, connector list, routing topology, CMT decision,
named transport rules, and pilot scope reviewed and approved under change control. A **rollback plan**
is written for each change (see the Rollback section). Do not configure until G2 is met.

---

## Phase 3 — Configure (in pilot first)

**Goal:** build the designed artifacts, validating with `-WhatIf`/dry-run before applying.

> Safety: the Configuration script defaults to **dry-run/`-WhatIf`**. It only makes changes when you
> pass **`-Commit`** (and it still honors `-WhatIf`). Preview every change first.

### 3a. Accepted-domain type

1. Preview: `Set-AcceptedDomain -Identity "<domain>" -DomainType InternalRelay -WhatIf`.
2. Apply (pilot domain first, under change control): remove `-WhatIf`. This creates/updates the
   **`Accepted Domain – Primary – Prod`** typing.

### 3b. Hybrid connectors (hybrid only)

1. Do **not** hand-create hybrid connectors. If coexistence connectors are missing or unhealthy,
   **re-run the current HCW** from a supported on-prem Exchange server. HCW provisions
   `Inbound from on-prem` and `Outbound to on-prem` with TLS + certificate/subject validation.
2. Confirm after HCW: `Get-InboundConnector`, `Get-OutboundConnector` show the hybrid connectors with
   `ConnectorSource = HybridWizard`.

### 3c. Partner connectors (if in scope)

1. Preview with the Configuration script:
   `\.Set-MailFlowConfiguration.ps1 -PartnerConnector -PartnerDomain <partner.example> -TlsCertName "<subject>" -WhatIf`.
2. Apply with `-Commit` to create:
   - `New-InboundConnector -Name "Inbound Connector – Partner – Prod" -ConnectorType Partner
     -SenderDomains <partner.example> -RequireTls $true -TlsSenderCertificateName "<subject>"`
   - and/or `New-OutboundConnector -Name "Outbound Connector – Partner – Prod" -ConnectorType Partner
     -RecipientDomains <partner.example> -SmartHosts <smarthost> -TlsSettings DomainValidation
     -TlsDomain "<smarthost-subject>"`.
   Use IP restriction instead of cert where the partner authenticates by IP.

### 3d. Centralized mail transport (only if G2 chose CMT)

1. Enable CMT **through HCW** (the "route outbound mail through on-premises" option), not by manual
   connector edits. This is a deliberate, gated change — expect added latency and an on-prem
   dependency for outbound cloud mail.
2. If G2 chose **CMT off** (default), skip this — EXO sends outbound directly.

### 3e. Transport rules

1. Preview each rule: `New-TransportRule -Name "Transport Rule – Partner TLS – Prod" … -WhatIf` (or via
   `Set-MailFlowConfiguration.ps1 -TransportRule … -WhatIf`).
2. Apply with `-Commit`. Set an explicit **priority** and scope tightly (specific senders/recipients/
   domains). Keep rules that *redirect* mail to an absolute minimum and never mutually redirecting.

**Gate G3 (Configured in pilot):** artifacts exist with the exact designed names; `Get-*Connector`,
`Get-AcceptedDomain`, `Get-TransportRule` match the design; no rule forms a loop. Proceed to Validate.

---

## Phase 4 — Pilot & Validate (prove it before expanding)

**Goal:** prove mail routes correctly for the pilot scope, with clean traces and no loops.

Run the validation procedures in `05-testing.md`. In summary:

1. **Inbound:** send external → `pilot-rx@Accepted Domain – Primary – Prod`; confirm delivery and that
   message trace shows the expected inbound connector/path.
2. **Outbound:** send `pilot-tx@…` → an external address you control; confirm delivery and that trace
   shows the expected outbound path (direct, or via on-prem if CMT is on).
3. **Internal-relay:** to a recipient on the shared domain that lives **on-prem**, confirm the message
   relays out `Outbound Connector – OnPrem – Prod` rather than NDR'ing.
4. **Loop check:** confirm no message loops (trace does not show a message bouncing between EXO and
   on-prem, or between two transport rules).
5. **Trace clean:** for each test, message trace status is `Delivered` (or the intended action) with no
   `Failed`/`Pending` surprises, and headers show the expected connector and auth results.

**Gate G4 (Pilot validated):** all five checks pass for the pilot scope; traces clean; no loops. If any
check fails, **roll back** the offending change (below) and redesign. Do not expand until G4 is met.

---

## Phase 5 — Expand (production rollout)

**Goal:** extend the validated design to all domains/recipients.

1. Apply the validated accepted-domain types and connectors to the remaining production domains,
   **one change per change window**, re-running the relevant validation after each.
2. Update DNS (MX / any connector host records) only when the routing topology change requires it, and
   only after connectors are validated — DNS is high-impact and slow to revert.
3. Re-run the Reporting script (`New-MailFlowHealthReport.ps1`) after each expansion step and archive
   the report with the change record.

**Gate G5 (Expanded):** production mail for all in-scope domains routes correctly (inbound, outbound,
internal-relay), traces are clean, and the health report shows the target connectors/domain types with
no loops or misrouting.

---

## Rollback

Because every change is staged, each is individually reversible:

- **Accepted-domain type:** revert with `Set-AcceptedDomain -Identity "<domain>" -DomainType
  <previous>` (e.g. back to `Authoritative`). Captured in the baseline (R2).
- **Partner connector:** disable then remove: `Set-InboundConnector "Inbound Connector – Partner –
  Prod" -Enabled $false`, then `Remove-InboundConnector` (same for outbound). Never touch
  HCW-sourced connectors this way.
- **Hybrid connectors / CMT:** revert via HCW (re-run and choose the prior CMT setting); do not
  hand-edit HCW connectors.
- **Transport rule:** disable first (`Disable-TransportRule "Transport Rule – … – Prod"`), confirm mail
  flow recovers, then remove if unwanted.
- **DNS/MX:** revert the record to the pre-change value; allow for TTL propagation. Because DNS is
  slowest to revert, change it **last** and only after connectors validate.

Keep the **`MailFlow Baseline – Tenant – Prod`** report from Phase 1 as the source of truth for what
"good" looked like before the change.


---


# Testing & Validation

Each test states a **procedure** and an explicit **pass/fail**. Run them in the pilot scope first
(Gate G4), then re-run the relevant tests after each expansion step (Gate G5). Use the named artifacts
from Implementation: `Accepted Domain – Primary – Prod`, `Inbound Connector – OnPrem – Prod`,
`Outbound Connector – OnPrem – Prod`, `Inbound/Outbound Connector – Partner – Prod`, and the named
transport rules. The Validation script `Test-MailFlowValidation.ps1` automates the checks below where
noted (read-only).

---

## T1. Accepted-domain types are correct

- **Procedure:** `Get-AcceptedDomain | Format-Table Name,DomainName,DomainType,Default`. Cross-check
  each against where recipients live. (Automated: `Test-MailFlowValidation.ps1 -CheckAcceptedDomains`.)
- **Pass:** every domain's `DomainType` matches reality — `InternalRelay` for any domain still shared
  with on-prem/partner; `Authoritative` only where all recipients are in EXO.
- **Fail:** a shared domain is `Authoritative` (silent-NDR risk) or a fully-migrated domain is still
  `InternalRelay` (mail may relay out unnecessarily). Correct per Implementation 3a.

## T2. Connectors exist with the right type/source

- **Procedure:** `Get-InboundConnector | Format-Table Name,ConnectorType,ConnectorSource,RequireTls`;
  same for `Get-OutboundConnector`. (Automated: `Test-MailFlowValidation.ps1 -CheckConnectors`.)
- **Pass:** hybrid connectors show `ConnectorSource = HybridWizard`; partner connectors are named
  `… – Partner – Prod` with `RequireTls = True` (or the intended IP restriction); no unexpected/orphan
  connectors.
- **Fail:** a hybrid connector has been hand-edited (source no longer `HybridWizard`), a partner
  connector lacks required TLS, or an unknown connector exists. Re-run HCW / correct the partner
  connector.

## T3. Inbound mail delivers and traces to the expected path

- **Procedure:** From an external address you control, send to `pilot-rx@<Accepted Domain – Primary –
  Prod>`. Then `Get-MessageTraceV2 -RecipientAddress pilot-rx@<domain> -StartDate … -EndDate …` (or
  EAC → Mail flow → Message trace).
- **Pass:** status `Delivered`; the trace/headers show the expected inbound path (EOP for
  cloud-authoritative, or the on-prem inbound connector for on-prem-inbound topologies).
- **Fail:** `Failed`/NDR, or the message arrived via an unexpected connector. Investigate per
  `06-troubleshooting.md` (trace → headers → queues).

## T4. Outbound mail delivers and traces to the expected path

- **Procedure:** From `pilot-tx@<domain>`, send to an external address you control. Trace by sender.
- **Pass:** `Delivered`; trace shows outbound **direct from EXO** when CMT is off, or **via on-prem**
  when CMT is on — matching the G2 design.
- **Fail:** outbound routes the "wrong way" (via on-prem when CMT should be off, or vice versa), or
  fails. Re-check the CMT decision and outbound connector.

## T5. Internal-relay recipient relays (does not NDR)

- **Procedure:** Send to a recipient on `Accepted Domain – Primary – Prod` whose mailbox is still
  **on-prem**. Trace the message.
- **Pass:** the message **relays out** `Outbound Connector – OnPrem – Prod` (or the HCW outbound
  connector) to on-prem and delivers there.
- **Fail:** the message NDRs at EXO ("recipient not found") — the domain is wrongly `Authoritative`.
  Fix the domain type (Implementation 3a) and retest.

## T6. No routing loops

- **Procedure:** Trace each test message end to end; inspect the `Received:` header chain for repeated
  hops between EXO and on-prem or repeated transport-rule redirects. (Automated heuristic:
  `Test-MailFlowValidation.ps1 -CheckLoops` flags traces with excessive hops/redirects.)
- **Pass:** each message follows a single, forward path; no hop repeats; transport rules do not
  redirect a message back into a rule that redirects it again.
- **Fail:** the header chain shows the same hop twice, or trace shows a message oscillating. Disable the
  offending transport rule / connector (Rollback) and redesign.

## T7. Transport rules fire only as intended

- **Procedure:** Send messages that **should** and **should not** match each named rule (e.g. to/from
  the partner domain for `Transport Rule – Partner TLS – Prod`). Confirm the action via headers (e.g.
  a stamped header, forced TLS, or an external tag) and via
  `Get-MessageTraceDetailV2` / rule match reporting where available.
- **Pass:** the rule's action applies to matching mail only; non-matching mail is untouched; priority
  ordering produces the intended result.
- **Fail:** the rule applies too broadly/narrowly, or a higher-priority rule pre-empts it. Re-scope /
  reorder and retest.

## T8. Headers show expected authentication and connector

- **Procedure:** For a delivered test message, open the full headers (paste into the Message Header
  Analyzer or read `Authentication-Results`, `Received-SPF`, and the `Received:` chain).
- **Pass:** SPF/DKIM/DMARC results are as expected for the domain; the connector used matches the
  design; SCL/spam verdict is sane (not silently marking legitimate pilot mail as spam).
- **Fail:** auth failures the design didn't anticipate, wrong connector in the chain, or an unexpected
  high SCL. Correlate with the routing change and adjust.

## T9. Health report matches the design

- **Procedure:** Run `New-MailFlowHealthReport.ps1 -OutputPath .\report`. Compare against the approved
  G2 design and the Phase 1 baseline.
- **Pass:** reported accepted-domain types, connectors, transport rules, and routing match the design;
  no orphan/unexpected artifacts; hybrid connectors still HCW-sourced.
- **Fail:** drift from the design (an extra connector, a changed domain type, a hand-edited hybrid
  connector). Reconcile before declaring the change complete.

---

**Overall exit criteria:** T1–T9 pass in pilot (Gate G4) and again across production after expansion
(Gate G5): mail routes correctly inbound, outbound, and for internal-relay recipients; no loops;
traces clean; transport rules fire only as intended; and the health report matches the approved design.


---


# Troubleshooting

A symptom → root-cause → fix playbook for Exchange/M365 hybrid mail flow, driven by the layered
diagnostic: **message trace → message headers → queues/SMTP logs**. Start at trace; escalate only when
the prior layer is inconclusive. Use the named artifacts from Implementation and the trace helper
(`Get-MailFlowTraceHelper.ps1`).

## Diagnostic method (apply to every symptom)

1. **Message trace** — where did the message go, and what was the last status? EAC → Mail flow →
   Message trace, or `Get-MessageTraceV2` (recent, ~last 10 days — **verify window in your tenant**) /
   `Start-HistoricalSearch` (older). Note the final `Status` and the connector referenced.
2. **Message headers** — export the full headers and read the `Received:` chain bottom-up (the true
   path), plus `Authentication-Results` (SPF/DKIM/DMARC), `X-Forefront-Antispam-Report`, and SCL. Use
   `Get-MailFlowTraceHelper.ps1 -HeaderFile <file>` or the Message Header Analyzer.
3. **Queues / SMTP logs (on-prem)** — for hybrid legs cloud trace can't see, on the hybrid transport
   server run `Get-Queue`, `Get-Message -Queue <q>`, and review protocol/connectivity logs
   (`Get-TransportService | Format-List *LogPath*`).

---

## Symptom: some recipients on a shared domain get "recipient not found" NDRs

- **Trace shows:** message reaches EXO and NDRs with `550 5.1.10 / RESOLVER.ADR.RecipNotFound` at the
  cloud hop; recipient's mailbox actually lives on-prem/partner.
- **Root cause:** the accepted domain is **`Authoritative`** but not all recipients are in EXO — EXO
  NDRs unknown recipients instead of relaying them.
- **Fix:** set the domain to **internal relay**: `Set-AcceptedDomain -Identity "<domain>" -DomainType
  InternalRelay` (Implementation 3a). Confirm an outbound connector to on-prem exists so unknowns relay.
  Retest (T5).

## Symptom: outbound mail routes the "long way" (through on-prem) unexpectedly

- **Trace shows:** outbound from EXO handed to `Outbound to on-prem` / the on-prem connector before
  reaching the internet.
- **Root cause:** **centralized mail transport (CMT)** is enabled when it shouldn't be.
- **Fix:** if on-prem does not need to process outbound cloud mail, disable CMT by **re-running HCW**
  and choosing not to route outbound through on-premises. Do not hand-edit HCW connectors. Retest (T4).

## Symptom: mail loops / duplicates / "too many hops" NDR

- **Trace/headers show:** the same `MessageId` appears many times, or the `Received:` chain repeats a
  hop between EXO and on-prem (or a message oscillates between two transport rules).
- **Root cause:** a routing loop — commonly two mutually-redirecting transport rules, an internal-relay
  domain pointing back to a system that relays it back, or an on-prem/EXO connector pair misrouting.
- **Fix:** identify the loop with `Get-MailFlowTraceHelper.ps1` (flags >=25 Received hops / repeat trace
  events) or `Test-MailFlowValidation.ps1 -CheckLoops`. **Disable** the offending transport rule first
  (`Disable-TransportRule`) or the connector, confirm recovery, then redesign the routing (Rollback).
  Retest (T6).

## Symptom: partner mail rejected or delivered without TLS

- **Trace/headers show:** partner mail bounces on connector validation, or arrives without TLS.
- **Root cause:** wrong/expired certificate subject on `Inbound Connector – Partner – Prod`, a sender IP
  not listed, or `RequireTls` not set.
- **Fix:** confirm the partner's current cert subject/IPs (R4); update the connector
  (`Set-InboundConnector "Inbound Connector – Partner – Prod" -TlsSenderCertificateName "<subject>"
  -RequireTls $true`, or set `SenderIPAddresses`). For outbound to a partner smart host, verify
  `TlsSettings`/`TlsDomain` on `Outbound Connector – Partner – Prod`. Retest (T2, T7).

## Symptom: legitimate pilot mail marked as spam / high SCL

- **Headers show:** high `X-MS-Exchange-Organization-SCL`, `dmarc=fail`/`spf=fail` in
  `Authentication-Results`.
- **Root cause:** a routing change altered the sending path so SPF/DKIM/DMARC no longer pass (e.g. mail
  now egresses from an IP not in SPF), or a transport rule set an unexpected SCL.
- **Fix:** correlate the auth result with the new path in the `Received:` chain. If SPF broke because
  mail now leaves via a different connector/host, update the SPF record for that path (DNS, R4/GR-4) —
  change DNS last and under change control. Check no transport rule is setting SCL unintentionally.
  Retest (T8).

## Symptom: HCW hybrid connector "keeps changing back" / breaks after HCW run

- **Symptom:** a manually edited hybrid connector setting reverts, or hybrid mail flow breaks after the
  next HCW run.
- **Root cause:** the connector is **HCW-sourced** (`ConnectorSource = HybridWizard`) and was hand-edited
  — HCW re-provisions/overwrites it.
- **Fix:** never hand-edit HCW connectors. Make the change **through HCW** (re-run it). Validate with
  `Test-MailFlowValidation.ps1 -CheckConnectors` (flags non-HCW-sourced hybrid connectors). Retest (T2).

## Symptom: message "delivered" per trace but user never received it

- **Trace shows:** `Delivered`, but to an unexpected location, or the last cloud event hands off to
  on-prem and trace goes dark.
- **Root cause:** delivery to on-prem (internal-relay) where the on-prem hop failed or delivered to the
  wrong mailbox/folder; cloud trace can't see the on-prem leg.
- **Fix:** escalate to the **third layer** — on the on-prem hybrid transport server, `Get-Queue` /
  `Get-Message` and the protocol logs to follow the on-prem hop. Confirm the recipient object/routing on
  on-prem. This is exactly the leg the layered method exists for.

## Symptom: message trace returns nothing for an older incident

- **Root cause:** real-time trace only covers roughly the last ~10 days (**window is service-dependent —
  verify in your tenant**).
- **Fix:** use **historical search** (`Start-HistoricalSearch` / EAC historical search) for older mail;
  expect longer processing time. Going forward, capture traces/headers at incident time.

---

**Escalation rule:** if trace is `Delivered`/clean and headers look correct but the user still reports
loss, the problem is almost always on the **on-prem leg** (queues/SMTP logs) or in the recipient's
mailbox rules/forwarding — not in cloud routing. Keep the `MailFlow Baseline – Tenant – Prod` report
handy to compare current config against a known-good state.


---


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


---


# Deliverables Summary

This solution delivers a complete, run-to-implement package for designing, operating, and
troubleshooting Exchange/Microsoft 365 hybrid mail flow.

## Documentation

- **Solution Overview** — the hybrid mail-flow reference model: accepted domains and domain types
  (authoritative / internal relay / external relay), connector types (inbound/outbound, on-prem↔EXO
  hybrid, partner) and when to use each, routing topologies, the centralized-mail-transport decision,
  transport rules, and the layered trace → headers → queues diagnostic.
- **Requirements Guide** — solution-specific prerequisites (healthy HCW hybrid config, documented
  current-state routing, correct accepted-domain types, connector auth material, message-trace access,
  on-prem transport visibility, Government-cloud awareness) each with how to verify/implement, built on
  the shared Messaging global requirements.
- **Implementation Guide** — exact ordered steps following Assess → Design → Configure → Pilot →
  Validate → Expand, with every artifact named (`Accepted Domain – Primary – Prod`, `Inbound/Outbound
  Connector – OnPrem/Partner – Prod`, `Transport Rule – … – Prod`), explicit pass/fail gates
  (G1–G5), and a documented rollback.
- **Testing & Validation** — nine PASS/FAIL procedures (T1–T9) covering domain types, connectors,
  inbound/outbound/internal-relay delivery, loop detection, transport-rule scoping, header/auth checks,
  and a health-report reconciliation.
- **Troubleshooting** — common mail-flow failure modes and their resolutions, organized as a
  symptom → root-cause → fix playbook driven by the layered diagnostic.
- **Best Practices** — durable practices for resilient, diagnosable hybrid mail flow.
- **Executive Summary** — outcome, approach, and why the change is low-risk.

## PowerShell scripts (Exchange Online PowerShell V3 / Microsoft Graph — safe by default)

1. **`Invoke-MailFlowDiscovery.ps1`** — *Discovery (read-only).* Enumerates accepted domains (+ type),
   inbound/outbound connectors (+ type/source), transport rules, remote domains, hybrid state, and
   resolves public MX; flags authoritative domains as silent-NDR risks to review. Produces the
   `MailFlow Baseline – Tenant – Prod` report.
2. **`Set-MailFlowConfiguration.ps1`** — *Configuration/Remediation (`-WhatIf` by default; `-Commit` to
   apply).* Sets an accepted domain's type, creates named partner inbound/outbound connectors with
   required TLS, or creates a named, scoped transport rule. Exports a rollback baseline before any
   change. Never hand-edits HCW connectors.
3. **`Test-MailFlowValidation.ps1`** — *Validation (read-only).* Runs the T1–T8 checks — domain types
   defined, hybrid connectors still HCW-sourced, partner connectors enforce TLS, recent trace delivered,
   and a routing-loop heuristic — printing PASS/FAIL per check.
4. **`New-MailFlowHealthReport.ps1`** — *Reporting (read-only).* Consolidates accepted domains,
   connectors, transport rules, and an optional trace summary into an HTML + CSV report, with drift
   warnings (authoritative shared domains, non-HCW hybrid connectors, partner connectors without TLS).
5. **`Get-MailFlowTraceHelper.ps1`** — *Scope/diagnostic helper (read-only).* Runs a message trace,
   pulls per-hop trace detail, and parses a saved header block (Received chain, SCL, SPF/DKIM/DMARC) to
   drive the layered diagnostic; points to on-prem `Get-Queue`/SMTP logs for the legs cloud trace can't
   see.

All scripts use modern authentication (`Connect-ExchangeOnline` / `Connect-MgGraph`), contain **no
hardcoded credentials or secrets**, and are read-only or `-WhatIf` unless an explicit apply/commit
switch is passed.
