# Solution Overview

External collaboration in Microsoft Teams is powerful — partners, vendors, and clients can chat, meet,
and co-author inside your teams. Left ungoverned, that same power leaks data to any domain, accumulates
stale guest accounts that never expire, and exposes shared channels no one is watching. This solution
gives a Microsoft 365 collaboration admin an exact, run-to-implement method to **enable external
collaboration while keeping it scoped, reviewed, and on policy**.

## What it is

A governed configuration for the three distinct external-collaboration surfaces in Teams, plus the
lifecycle and sensitivity controls that keep them safe over time:

1. **External access (federation)** — tenant-to-tenant and (optionally) consumer Teams/Skype
   communication. External users are **not** added to your directory; they chat/call from their own
   tenant. Governed with the **federation configuration** (allowed/blocked domains) and per-user
   **external access policies**.
2. **Guest access** — external people are invited **into** your directory as **guest** members of a
   team (an Entra B2B collaboration guest, `userType = Guest`). They appear in the team roster and can
   access channels, files, and apps subject to guest policy. Governed with Teams guest
   configuration, Entra **External collaboration settings** (allow/deny domains), and guest
   **lifecycle** (access reviews + expiration).
3. **Shared channels** — a channel shared with people in **other tenants** via **Entra B2B direct
   connect**, without adding them as guests or switching tenants. Governed with the Teams **channels
   policy** and **cross-tenant access settings** (b2bDirectConnect inbound/outbound).

On top of those three surfaces the solution wires two durable controls:

- **Guest lifecycle** — recurring **Entra access reviews** that recertify or auto-remove guests, and
  **expiration** so access does not live forever (Entra access reviews / lifecycle workflows).
- **Sensitivity** — container **sensitivity labels** (Microsoft Purview) that set a team/group's
  external-sharing and guest posture from the label, so classification drives control.

## How it works (reference design)

```
                    EXTERNAL COLLABORATION SURFACES (governed separately)
  ┌───────────────────────┬───────────────────────┬──────────────────────────┐
  │  External access      │   Guest access        │   Shared channels        │
  │  (federation)         │   (B2B collaboration) │   (B2B direct connect)   │
  ├───────────────────────┼───────────────────────┼──────────────────────────┤
  │ chat/call across      │ external user added   │ channel shared to other  │
  │ tenants; user NOT in  │ INTO your directory   │ tenants; user stays in   │
  │ your directory        │ as a Guest member     │ THEIR tenant             │
  ├───────────────────────┼───────────────────────┼──────────────────────────┤
  │ Federation config     │ Teams guest config    │ Teams channels policy    │
  │ allow/block domains   │ + Entra external      │ + cross-tenant access    │
  │ + external access pol │ collab settings       │ settings (directConnect) │
  └───────────────────────┴───────────────────────┴──────────────────────────┘
        │                          │                          │
        └──────────── Cross-tenant access settings (Entra) ───┘
                                   │
                 ┌─────────────────┴──────────────────┐
                 │ Guest lifecycle: access reviews +   │
                 │ expiration (Entra ID Governance)    │
                 ├─────────────────────────────────────┤
                 │ Sensitivity labels (Purview): label │
                 │ drives external-sharing / guest set │
                 └─────────────────────────────────────┘
```

**Distinction that matters most:** *external access ≠ guest access ≠ shared channels.* They use
different Entra plumbing, different admin surfaces, and different governance. Configuring one does not
govern the others — a tenant with guest access locked down but federation wide-open is still exposed.
This solution treats all three explicitly.

Each artifact this solution creates is **named** with the convention `<Purpose> – <Scope> – <Stage>`
and reused verbatim in configuration, testing, troubleshooting, and the scripts, e.g.:

- `External Access Policy – Pilot` (per-user Teams external access policy)
- `Teams Channels Policy – SharedCh-Pilot` (shared-channel controls)
- `Cross-Tenant Partner – Partner-A – Pilot` (a named partner org in cross-tenant access settings)
- `Guest Access Review – Recert – Pilot` (recurring Entra access review of guests)
- `Sensitivity Label – Ext-Collab – Prod` (container label controlling external sharing)

## Deployment model

The solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
because external access, cross-tenant settings, and guest lifecycle are **tenant-wide, high-impact**
changes:

- **Assess** current posture (what federation/guest/shared-channel settings exist, how many guests,
  how many stale) with the read-only discovery script.
- **Design** the target: which domains are allowed, whether shared channels are on, the review cadence
  and expiration, and which sensitivity labels drive external sharing. Get compliance/governance sign-off.
- **Configure** the settings and policies (default to `-WhatIf`, apply with an explicit `-Commit`).
- **Pilot** on a named policy group / pilot team before org-wide assignment.
- **Validate** against pass/fail gates (external scoped to policy, stale guests reviewed, shared
  channels controlled).
- **Expand** to the org once gates pass — with a documented rollback.

## Benefits

- **External collaboration stays on** — you enable partners without a blanket "block everything".
- **Scoped, not open** — allow/block domains and per-user policies mean only intended orgs connect.
- **Guests don't pile up** — access reviews + expiration recertify or remove them automatically.
- **Shared channels are controlled** — direct-connect is a deliberate, per-partner decision.
- **Classification drives control** — sensitivity labels apply external-sharing posture consistently.
- **Auditable** — every setting is scripted, reported, and validated against a baseline.

## Limitations & boundaries

- **Plan-dependent features are flagged, not assumed.** Recurring **access reviews**, **lifecycle
  workflows**, and some **conditional access for external users** require **Microsoft Entra ID
  Governance** and/or **Entra ID P2** — *verify your licensing in the M365 admin center.* Container
  **sensitivity labels** require the appropriate Purview/Information Protection licensing.
- **Commercial vs Government cloud** portal URLs and some feature availability differ (e.g.
  `*.office365.us` / GCC-High). Where a path is cloud-specific it is flagged **"verify in your
  tenant"** — do not assume the commercial URL.
- **Compliance/legal determinations are deferred.** Which domains are *permitted*, what data
  classification a partner may see, and retention/records outcomes are decisions for your
  security/compliance/records functions. This solution provides the **technical method and evidence**,
  not the policy determination.
- **Third-party/partner-tenant behavior is out of scope** — you control your side of cross-tenant
  access; the partner controls theirs. Shared channels and direct connect require **both** tenants to
  allow the connection.
