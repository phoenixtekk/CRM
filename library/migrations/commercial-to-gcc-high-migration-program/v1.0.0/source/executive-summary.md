# Executive Summary — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

## The situation

Organizations in the US Defense Industrial Base and other regulated sectors increasingly face contractual mandates — **CMMC**, **ITAR/EAR**, **DFARS 252.204-7012**, and **FedRAMP High** — that require their data to live in a US sovereign cloud with controlled, US-person access. A standard **commercial** Microsoft 365 and Azure tenant does not meet these requirements. The destination is **GCC High** (Microsoft 365 Government High / Azure Government).

The critical, often-misunderstood reality: **GCC High is a separate cloud.** There is no in-place upgrade and no switch to flip. Moving requires provisioning a **new GCC High tenant** and performing a **cross-cloud tenant-to-tenant migration** of the entire estate — identity, email, files, collaboration, servers, applications, and virtual desktops.

## The solution

This program delivers a controlled, auditable cross-cloud migration across **seven workstreams** — **Identity (Entra), Exchange Online, SharePoint/OneDrive, Microsoft Teams, Azure IaaS servers, Azure apps/PaaS, and Azure Virtual Desktop** — using a phased methodology with named objects, explicit acceptance gates, and rollback at every cutover.

It follows the **standard program model**: **Discover → Assess → Plan → Provision the GCC High tenant + Azure Gov landing zone → Pilot → Migrate per workstream → Cutover → Validate → Decommission.** Proven cross-cloud tooling is used per workstream (Quest On Demand and ShareGate for mail/content/Teams; Azure Migrate + Azure Site Recovery for servers; native rebuild + FSLogix migration for AVD), each configured for the GCC High `.us` sovereign endpoints.

## The outcome

- **Compliance posture achieved** — a sovereign-cloud estate aligned to CMMC, ITAR/EAR, DFARS, and FedRAMP High drivers, with a documented evidence trail assessors can use directly.
- **Contracts protected** — eligibility to win and retain work that mandates GCC High data residency and US-person access controls.
- **Controlled, low-surprise execution** — one coordinated program instead of seven uncoordinated migrations: shared discovery, wave planning, pilots, and per-workstream acceptance gates, with regulated data kept inside an authorized boundary throughout transit.
- **No data left behind, nothing deleted prematurely** — every commercial resource is retired only after its GCC High counterpart passes validation and a defined grace period elapses.

## What leadership must know

- **Eligibility gates the timeline.** GCC High requires Microsoft validation/sponsorship and procurement through an authorized AOS-G reseller — weeks to months before any data moves. The program treats this as the first hard gate.
- **Plan for months, not days.** A full estate migration is a phased program; coexistence between the two clouds is deliberately limited, so users cut over wave by wave.
- **Some artifacts are re-created, not copied** — identity, passwords/MFA, conditional access, app registrations/secrets, and certain Teams chat are re-established in the new cloud by design.

## Investment

A flagship migration program kit: a complete phased playbook, per-workstream runbooks with exact `.us` navigation, five operational PowerShell tools (discovery, validation, reporting, remediation, wave planning), and the testing/acceptance and troubleshooting references that de-risk a high-stakes sovereign-cloud move.
