# 1. Solution Overview — Remote Help for the Enterprise Help Desk (Operations, Unattended Access & Adoption)

## What this solution is
This is the **operations and adoption layer** that sits **on top of an existing Remote Help
deployment**. It does **not** install, enable, or re-teach the base Remote Help service or its
security model — that is the job of the separate **Remote Help** solution (slug `remote-help`),
which is the **prerequisite** for this package. This solution assumes Remote Help is already
enabled in the tenant, the Remote Help app is deployed to devices, and the base security model
(Entra authentication, RBAC, compliance visibility, audit) is in place.

> **Prerequisite (read this first):** This solution **assumes Remote Help is deployed per the
> "Remote Help" solution** (`remote-help`). If Remote Help is not yet enabled and the app not yet
> deployed, run that solution first. Everything below builds the *help-desk practice* around a
> working Remote Help deployment; it never repeats install/enable/security-model setup.

Once the app is in place, an enterprise still has to turn "installed" into a **running help-desk
capability**: who can help whom, when unattended access is appropriate and how it is governed, how
a session fits the ticket and escalation workflow, how usage and outcomes are measured, and how end
users learn to trust and request help. That operating model is what this solution delivers.

## What this adds vs. the base Remote Help product
| Base **Remote Help** product (prerequisite) | **This** operations/adoption product |
|---|---|
| Enable Remote Help in the tenant | *(assumed already done)* |
| Deploy the Remote Help app via Intune | *(assumed already done)* |
| The security model (Entra auth, RBAC, compliance, audit) | *(assumed already in place)* |
| — | **Role & scope design** — map help-desk **tiers** to RBAC roles + scope so agents help exactly the right users, and no more |
| — | **Attended vs unattended access** — when unattended is appropriate, how it is governed and consented, and its guardrails |
| — | **Help-desk workflow** — fit a session into ticket intake, verification, escalation tiers, and session logging/handoff |
| — | **Measurement** — usage, session outcomes, and adoption KPIs + reporting |
| — | **Adoption** — end-user comms, how to request help, trust/consent expectations, agent enablement |

## The operating model
1. **Tier the help desk.** Define the support tiers (for example **Tier 1 – Service Desk**,
   **Tier 2 – Desktop Support**, **Tier 3 – Escalation Engineering**) and decide what each tier is
   allowed to do in a Remote Help session (view only, full control, elevation).
2. **Map each tier to an RBAC role + scope.** Each tier gets its own Remote Help RBAC role
   (capability) and its own scope (the users it may help), so an agent can help exactly the right
   population and no more.
3. **Govern unattended access.** Decide where unattended assistance is appropriate (for example
   unattended kiosks, shared devices, or servers with no user present to consent), restrict it to a
   dedicated tier, and put guardrails around it. *(Unattended-access availability and behavior in
   Remote Help — whether it is offered, on which platforms, its exact settings and consent model —
   must be **verified against current Microsoft documentation**; this solution governs the practice,
   it does not assert the capability.)*
4. **Wire the session into the ticket workflow.** Every session starts from a ticket, verifies the
   caller, is escalated across tiers when needed, and is logged back to the ticket on completion.
5. **Measure and report.** Track session volume, outcomes, escalation and consent rates, unattended
   sessions, and adoption; report the KPIs that prove the capability is working.
6. **Drive adoption.** Tell end users how to request help and what to expect (consent, audit), and
   enable agents so the tool is actually used.

## Benefits
- **Right-scoped support** — agents help the users they should, with the capability they should have.
- **Governed unattended access** — a deliberate, guard-railed practice instead of an open door.
- **Faster, traceable resolution** — sessions live inside the ticket and escalation flow.
- **Provable value** — KPIs and reporting show utilization, outcomes, and adoption.
- **Real adoption** — end users trust it and agents use it, so the investment pays off.

## Limitations (be honest with buyers)
- **Requires Remote Help already deployed** (the `remote-help` solution) — this package does not
  install or enable it.
- **Unattended-access specifics are Microsoft-governed** — availability, supported platforms, exact
  settings, and consent behavior change over time and must be verified against current Microsoft
  documentation before you rely on them.
- **RBAC role names, permission names, and portal navigation** in Intune change over time — this
  guide names objects consistently but you must confirm current labels in your tenant.
- **Ticketing integration is process-level** — this solution defines how a session maps to a ticket;
  it does not build a code integration to any specific ITSM product.

## The standard deployment model
> **Design the tiers & role/scope model → configure roles, scope, and unattended governance →
> pilot with one tier and a small user scope → validate scope, unattended, logging, and KPIs →
> expand across tiers and run the adoption campaign.** Repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**
