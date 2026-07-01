# 1. Solution Overview — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

## What this solution is

This is a multi-workstream **program** to migrate an organization's entire **commercial** Microsoft 365 and Azure estate into a **GCC High** (Microsoft 365 Government High / Azure Government) sovereign-cloud tenant. It is a **program playbook**, not a single wizard: it pairs a phased methodology with per-workstream runbooks so a program lead and a team of admins can execute a controlled, auditable cross-cloud migration end to end.

The program covers seven workstreams:

1. **Identity (Entra)** — establish a new Entra ID directory in GCC High and re-create users, groups, and access (identity is **not** synced automatically from the commercial cloud).
2. **Exchange Online mailboxes** — migrate mail, calendar, and contacts cross-cloud.
3. **SharePoint Online / OneDrive** — migrate sites, libraries, and personal storage with permissions.
4. **Microsoft Teams** — migrate teams, channels, files, and (where supported) chat.
5. **Azure IaaS servers** — replicate and fail over virtual machines into Azure Government.
6. **Azure apps / PaaS** — redeploy platform services into Azure Government via IaC.
7. **Azure Virtual Desktop (AVD/VDI)** — rebuild host pools in Azure Government and migrate FSLogix user profiles.

## The single most important reality: GCC High is a SEPARATE cloud

GCC High is **not** a license you switch on inside your existing tenant, and it is **not** an in-place upgrade. It is a **physically and logically separate sovereign cloud** with its own service endpoints (the `.us` domains, e.g. `portal.azure.us`, `login.microsoftonline.us`, `outlook.office365.us`). There is **no in-place move** from commercial to GCC High.

Consequently, this program **provisions a brand-new GCC High tenant** and performs a **tenant-to-tenant / cross-cloud migration** into it. Key implications that shape every phase:

- **Identity is re-established, not migrated in place.** There is no commercial-to-GCC-High Entra Connect sync and no directory "lift". Users, groups, and service principals are re-created in the new GCC High Entra directory; passwords cannot be exported and are reset/re-established.
- **Coexistence is limited cross-cloud.** Native free/busy, cross-tenant mailbox moves, and unified GAL across the two clouds are far more constrained than commercial-to-commercial moves. Plan for **batch cutovers per workstream/wave**, not indefinite coexistence.
- **Tooling must speak the GCC High endpoints.** Generic SaaS migration tools that only target commercial endpoints will not work. Use the **GCC High editions/endpoints** of the chosen tools.
- **Data sovereignty applies in transit.** Content may be export-controlled (ITAR/EAR). The migration path, any staging, and the tooling's data-handling region must keep regulated data within authorized boundaries.
- **Timelines are longer.** Eligibility validation, sponsorship, tenant provisioning, and reseller onboarding add weeks to months before any data moves.

## Eligibility is gated — you must qualify first

GCC High is **eligibility-restricted**. Access is intended for organizations with US Government / Department of Defense, Defense Industrial Base (DIB), ITAR/EAR, **CMMC**, or **FedRAMP High** drivers. Provisioning requires:

- **Microsoft validation/sponsorship** of the organization's eligibility, and
- Procurement through an **authorized GCC High reseller / AOS-G (Agreement for Online Services for Government) partner** — GCC High is not bought through standard commercial channels.

The program treats this validation and reseller engagement as a **gating prerequisite** (see Requirements R1–R3); no provisioning work begins until eligibility is confirmed.

## How it works (the flow)

1. **Discover** the commercial estate: every mailbox, SharePoint site, OneDrive, team, Azure subscription, VM, and PaaS app is inventoried.
2. **Assess** sizing, dependencies, compliance scope, and per-workstream complexity.
3. **Plan** waves and workstream sequencing; name every object that will be created.
4. **Provision** the GCC High tenant and the Azure Government landing zone (subscriptions, resource groups, networking).
5. **Establish identity** in GCC High (Entra users/groups, licensing, conditional access).
6. **Pilot** each workstream with a small representative group.
7. **Migrate** per workstream, wave by wave, using the right cross-cloud tool.
8. **Cut over** mail flow, identity, and DNS to the GCC High tenant.
9. **Validate** each workstream against acceptance gates.
10. **Decommission** the commercial estate under change control once validation passes.

## Tooling

| Workstream | Primary tool(s) | Notes |
|---|---|---|
| Exchange Online | **Quest On Demand Migration** (cross-cloud, incl. commercial → GCC High) | Use the GCC High-capable edition/endpoints; service account on both sides. |
| SharePoint Online / OneDrive | **ShareGate** and/or **Quest On Demand** | ShareGate has GCC High support; preserves permissions/versions. |
| Microsoft Teams | **Quest On Demand** / **ShareGate** | Teams membership, channels, files; chat support varies by tool/edition. |
| Azure IaaS servers | **Azure Migrate** + **Azure Site Recovery (ASR)** | Replicate to Azure Government; test failover before cutover. |
| Azure apps / PaaS | **IaC redeploy** (Bicep/ARM/Terraform) + native | PaaS is redeployed, not "moved"; re-point config/secrets to `.us`. |
| AVD / VDI | **Native rebuild** in Azure Gov + **FSLogix** profile migration | New host pools; migrate profile containers. |
| Identity (Entra) | **Microsoft Graph (USGov)** + native | Re-create directory objects; no cross-cloud sync. |

> **Tooling caveat:** every tool must be the **GCC High / Azure Government** edition or be configured against the sovereign endpoints. Confirm the tool vendor explicitly supports **commercial-source → GCC High-target** before licensing (see Requirements R6–R7).

## Benefits

- **Compliance posture**: a path to CMMC, ITAR/EAR, DFARS 7012, and FedRAMP High alignment in a sovereign cloud.
- **Eligibility to win/keep contracts** that mandate GCC High data residency and US-person access controls.
- **Single, controlled program** instead of seven uncoordinated migrations — shared discovery, waves, and acceptance gates.
- **Auditability**: every created object is named and recorded; every cutover is gated and evidenced — directly usable as CMMC assessment evidence.

## Honest limitations

- **This is not a same-day cutover.** A full estate program runs months; eligibility/sponsorship alone can take weeks.
- **No in-place upgrade and no perfect coexistence.** Expect per-workstream cutovers and a freeze window.
- **Some artifacts do not migrate cleanly cross-cloud**: certain Teams chat history, Power Platform environments, app registrations/secrets, conditional-access/Intune config, and third-party app integrations are **re-created**, not copied.
- **Licensing must be in place first** — GCC High licenses are procured through the AOS-G reseller and are distinct SKUs.
- **PaaS is redeployed**, not migrated byte-for-byte; data within PaaS (databases, storage) is exported/imported separately.
- **Passwords and MFA registrations do not transfer**; users re-register.

## The standard program model

This solution follows the **standard program model** — a phased lifecycle with named objects, explicit acceptance gates, and rollback at every cutover:

**Discover → Assess → Plan → Provision (GCC High tenant + landing zone) → Pilot → Migrate (per workstream) → Cutover → Validate → Decommission.**

Each phase has entry criteria, exit criteria, and named deliverables. No phase begins until the prior phase's gate passes, and no commercial resource is decommissioned until its GCC High counterpart has passed validation.
