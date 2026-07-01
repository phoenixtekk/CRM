# Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

> **Version 1.0.0** · Category: Migrations · Solution code: GCCHIGH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


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


---


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


---


# 2. Requirements — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Each requirement is structured as **Description / Why / Verify / Implement-if-missing**. **Never assume a prerequisite exists** — verify each one before the program proceeds past the Plan gate. Requirements are numbered R1–R15. R1–R3 are **hard gating prerequisites**: no GCC High provisioning starts until they are satisfied.

> Naming convention used throughout the program (reused verbatim in implementation): every created object is named `<Purpose> – <Scope> – <Stage>`, e.g. `Migration SvcAcct – Exchange – Target`.

---

## R1. GCC High eligibility + Microsoft validation/sponsorship  *(GATING)*

- **Description:** The organization is formally validated by Microsoft as eligible for GCC High (US Gov / DoD / DIB / ITAR / EAR / CMMC / FedRAMP-High driver) and has Microsoft sponsorship for tenant provisioning.
- **Why:** GCC High is eligibility-restricted; without Microsoft validation, no GCC High tenant can be provisioned at all. This is the program's first gate.
- **Verify:** Confirm a completed Microsoft validation / eligibility attestation and a sponsorship/onboarding case reference. Confirm a documented compliance driver (e.g. CMMC level + DFARS 252.204-7012, or ITAR registration).
- **Implement-if-missing:** Engage the AOS-G reseller (R2) to initiate the Microsoft eligibility validation; assemble the eligibility evidence (contracts/clauses citing the driver). Do not proceed until validated.

## R2. Authorized GCC High reseller / AOS-G partner  *(GATING)*

- **Description:** A signed relationship with an **authorized GCC High reseller** under the **AOS-G** (Agreement for Online Services – Government) program.
- **Why:** GCC High licensing and tenant provisioning are **not** available through standard commercial channels. An AOS-G partner is mandatory to procure licenses and stand up the tenant.
- **Verify:** Confirm an executed AOS-G agreement and a named reseller contact. Confirm the reseller can transact the required GCC High SKUs.
- **Implement-if-missing:** Select and contract an authorized AOS-G reseller before any licensing or provisioning. Most eligibility validation (R1) is driven through this partner.

## R3. Provisioned GCC High tenant + licensing  *(GATING)*

- **Description:** A live GCC High tenant (`<org>.onmicrosoft.us`) with the required **Microsoft 365 GCC High** and **Microsoft 365 Government** license SKUs assigned-capacity available for all in-scope users.
- **Why:** The target tenant and licenses must exist before identity, mail, content, or Azure workloads can land. GCC High SKUs are distinct from commercial SKUs.
- **Verify:** Sign in at `https://admin.microsoft.com` for GCC High (resolves to the government admin portal) using a target Global Administrator; confirm tenant exists and the license counts under **Billing → Licenses** cover the user count from Discovery.
- **Implement-if-missing:** Have the AOS-G reseller provision the tenant and allocate licenses sized to the Discovery inventory (add ~10% headroom for shared/resource accounts).

## R4. Azure Government subscription(s)

- **Description:** One or more **Azure Government** subscriptions to host the landing zone (servers, PaaS, AVD).
- **Why:** Azure IaaS/PaaS/AVD workloads must land in **Azure Government** (`portal.azure.us`), which is separate from commercial Azure and from the M365 GCC High tenant billing.
- **Verify:** Sign in at `https://portal.azure.us`; under **Subscriptions** confirm at least one active Azure Government subscription bound to the GCC High Entra tenant.
- **Implement-if-missing:** Procure Azure Government subscription(s) via the AOS-G reseller / Microsoft; associate them to the GCC High Entra directory.

## R5. Global Administrator in source (commercial) AND target (GCC High)

- **Description:** A break-glass-capable Global Administrator account in the **commercial** tenant and one in the **GCC High** tenant.
- **Why:** Cross-cloud migration tooling, consent grants, and DNS/identity cutover all require elevated admin on **both** clouds.
- **Verify:** Source: sign in at `https://entra.microsoft.com` (commercial) → **Roles & admins → Global Administrator** lists the account. Target: sign in at the GCC High Entra portal (`https://entra.microsoft.us`) → same blade.
- **Implement-if-missing:** Create/assign Global Administrator in whichever cloud is missing one; store credentials in the program's privileged-access vault.

## R6. Cross-cloud mail/content migration tooling — Quest On Demand (commercial → GCC High)

- **Description:** A **Quest On Demand Migration** subscription/edition that supports **commercial-source → GCC High-target** for Exchange, SharePoint, OneDrive, and Teams.
- **Why:** Native cross-cloud (commercial → GCC High) mailbox/content moves are not available; a tool that explicitly speaks both clouds' endpoints is required.
- **Verify:** In the Quest On Demand console, confirm the project type / region supports GCC High targets and that the commercial-source connector authenticates. Confirm the license covers the object counts from Discovery.
- **Implement-if-missing:** License Quest On Demand with GCC High target capability sized to Discovery; create the migration project `Cross-Cloud Migration Project – M365 – Target`.

## R7. SharePoint/OneDrive/Teams tooling — ShareGate (GCC High edition)

- **Description:** **ShareGate** licensed with GCC High endpoint support for SharePoint/OneDrive/Teams content fidelity (permissions, versions, metadata).
- **Why:** Provides high-fidelity content migration and an alternative/complement to Quest for large or permission-heavy site sets; must target the `.us` SharePoint endpoints.
- **Verify:** In ShareGate, connect a source commercial site and a target GCC High site (`https://<org>.sharepoint.us`); confirm both connect and a test copy preserves permissions.
- **Implement-if-missing:** License ShareGate (GCC High-capable) and validate both connections before pilot.

## R8. Azure Migrate + Azure Site Recovery (ASR) for servers

- **Description:** **Azure Migrate** project and **Azure Site Recovery** (Recovery Services vault) in Azure Government for VM assessment and replication.
- **Why:** Servers are replicated and failed over (not file-copied); ASR provides block-level replication and test failover into Azure Gov.
- **Verify:** At `https://portal.azure.us` → **Azure Migrate** confirm a project exists; → **Recovery Services vaults** confirm a vault in the target Gov region.
- **Implement-if-missing:** Create migration project `Server Migration Project – IaaS – Target` and vault `Recovery Vault – ASR – Target` in the chosen Azure Gov region/resource group.

## R9. Network connectivity / bandwidth (ExpressRoute or sized internet)

- **Description:** Adequate, sized network egress from the source environment plus, where required, **ExpressRoute (Azure Government)** for server replication.
- **Why:** Multi-TB mailbox/content/VM replication is bandwidth-bound; under-provisioned links cause throttling and missed cutover windows. ASR replication for large estates often needs ExpressRoute.
- **Verify:** Measure available sustained egress; compare against total GB from Discovery and the target window. Confirm any ExpressRoute circuit is provisioned to an **Azure Government** peering location.
- **Implement-if-missing:** Provision/scale bandwidth; order **ExpressRoute for Azure Government** (note: commercial ExpressRoute peering does **not** reach Gov regions).

## R10. Identity plan — Entra in GCC High

- **Description:** A documented plan for re-establishing identity in the GCC High Entra directory: user/group re-creation, authentication method (cloud-only vs. new on-prem AD Connect to GCC High), conditional access, MFA re-registration, and licensing assignment.
- **Why:** Identity does **not** sync from commercial to GCC High. The plan determines how users authenticate on day one and is foundational to every other workstream.
- **Verify:** Confirm a written identity design naming the auth model and the group `All Migrated Users – Identity – Target`. Confirm whether a **new** Entra Connect/Cloud Sync to the GCC High tenant is required (a fresh sync agent, separate from any commercial sync).
- **Implement-if-missing:** Author the identity design; if hybrid is required, install a **new** provisioning agent targeting GCC High; otherwise plan cloud-only accounts.

## R11. DNS control for domain moves

- **Description:** Administrative control of all public DNS zones for the organization's email/SharePoint domains.
- **Why:** Domain verification in GCC High and MX/autodiscover/SPF/DKIM/DMARC cutover require editing authoritative DNS. A domain can only be verified in one tenant at a time, so the source must release it.
- **Verify:** Confirm registrar/DNS-host admin access for each in-scope domain (`nslookup -type=MX <domain>` shows the current host you control).
- **Implement-if-missing:** Obtain DNS administrative access (or a documented change path with the DNS owner) before cutover planning.

## R12. Migration service accounts (both clouds)

- **Description:** Dedicated, least-privilege **migration service accounts** in source and target, plus any required application consents for the tools.
- **Why:** Tools should authenticate as named service principals (not personal admin accounts) for auditability and throttling isolation; CMMC evidence requires named accounts.
- **Verify:** Confirm accounts `Migration SvcAcct – M365 – Source` and `Migration SvcAcct – M365 – Target` exist with the documented roles (e.g. application impersonation / SharePoint admin) and that tool consent is granted in both tenants.
- **Implement-if-missing:** Create the service accounts, assign scoped roles, grant tool admin consent in each tenant.

## R13. Compliance / ITAR data-handling controls

- **Description:** Documented controls ensuring regulated data (ITAR/EAR/CUI) stays within authorized boundaries **during transit**, including tool data-residency, US-person access, and staging-storage controls.
- **Why:** Moving export-controlled data through a non-authorized region or exposing it to non-US persons is a compliance violation, independent of the destination being GCC High.
- **Verify:** Confirm the migration tool's data path/region is US-sovereign and personnel with access are authorized (US persons where required). Confirm any staging storage is in an authorized boundary.
- **Implement-if-missing:** Configure tools for US-sovereign data handling; restrict migration-team access; document the data-flow for the CMMC/ITAR evidence package.

## R14. Estate inventory (Discovery baseline)

- **Description:** A complete, current inventory of the commercial estate: mailboxes (+ sizes/types), SharePoint sites, OneDrive accounts, Teams, Azure subscriptions, VMs, and App Services.
- **Why:** Sizing licenses (R3), bandwidth (R9), waves, and acceptance gates all derive from this baseline. You cannot plan what you have not inventoried.
- **Verify:** Confirm a Discovery CSV exists (output of `GCCHIGH-Discovery.ps1`) with per-object sizing.
- **Implement-if-missing:** Run `scripts\GCCHIGH-Discovery.ps1` (read-only) against the commercial tenant and Azure to produce `Estate-Inventory – Discovery – Source.csv`.

## R15. Change-control & rollback posture (program-wide)

- **Description:** An approved change-management process with maintenance windows, communications plan, and per-workstream rollback procedures.
- **Why:** Cutovers are outward-facing and disruptive; CMMC and operational safety require approved windows and a defined back-out.
- **Verify:** Confirm an approved change record per planned cutover and a documented rollback for each workstream.
- **Implement-if-missing:** Establish the change/comms process; author rollback runbooks (covered in Best Practices §07). See also the shared `global-requirements-azure-solutions.md`.


---


# Global Requirements — Azure Solutions

These requirements are common to **every** Azure Solutions solution in the standard program model. They are the baseline platform prerequisites that any Azure/Microsoft 365 engagement assumes. Each is structured **Description / Why / Verify / Implement-if-missing**. Solution-specific requirements (see `02-requirements.md`) are layered on top of these.

> Naming convention: every created object is named `<Purpose> – <Scope> – <Stage>` and reused verbatim throughout the engagement.

---

## G1. A Microsoft 365 / Entra tenant

- **Description:** An active Microsoft 365 / Microsoft Entra tenant for the cloud(s) in scope (commercial and/or government).
- **Why:** All identity, licensing, and service configuration is anchored to a tenant; nothing can be configured without one.
- **Verify:** Sign in to the relevant admin center (`https://admin.microsoft.com`) and confirm the tenant resolves and is active under **Settings → Org settings**.
- **Implement-if-missing:** Provision the tenant through the appropriate channel (commercial: standard; government: via an authorized AOS-G reseller).

## G2. Administrative roles (least privilege)

- **Description:** Appropriately scoped admin roles for the work — Global Administrator for tenant-wide changes, and service-specific roles (Exchange, SharePoint, Teams, Azure Owner/Contributor) for day-to-day.
- **Why:** Every configuration and migration action requires a role with sufficient privilege; least-privilege scoping limits blast radius and satisfies audit requirements.
- **Verify:** In Entra → **Roles & admins**, confirm the operating accounts hold the required roles. In Azure → **Subscriptions → Access control (IAM)**, confirm RBAC assignments.
- **Implement-if-missing:** Assign the minimum roles needed; prefer eligible (PIM) activation over standing access where available.

## G3. Licensing baseline

- **Description:** Sufficient Microsoft 365 and/or Azure licensing/credit for all in-scope users and workloads.
- **Why:** Features and capacity (mailboxes, SharePoint storage, AVD, VMs) are gated by license SKUs and subscription quota.
- **Verify:** **Billing → Licenses** for M365; **Subscriptions → Usage + quotas** for Azure. Compare assigned/available against the in-scope object count.
- **Implement-if-missing:** Procure the correct SKUs and request quota increases sized to the workload (add headroom for shared/resource objects).

## G4. Network connectivity to Microsoft 365 / Azure endpoints

- **Description:** Reliable network egress to the required Microsoft 365 and Azure service endpoints (and the sovereign `.us` endpoints for government clouds), with sufficient bandwidth.
- **Why:** All cloud administration and any data movement depends on connectivity to the correct endpoint set; government clouds use distinct endpoints from commercial.
- **Verify:** Confirm reachability to the relevant endpoints (commercial `*.microsoft.com` / government `*.microsoft.us`, `*.azure.us`, `*.office365.us`). Measure sustained bandwidth against the data volume.
- **Implement-if-missing:** Open firewall/proxy allowances for the correct endpoint set; scale bandwidth or add ExpressRoute (matching the cloud — Gov ExpressRoute for Gov regions).

## G5. Change control & maintenance window

- **Description:** An approved change-management process with scheduled maintenance windows and a stakeholder communications plan.
- **Why:** Cloud changes can be outward-facing and disruptive; controlled windows and comms reduce business impact and satisfy governance/compliance.
- **Verify:** Confirm an approved change record and a scheduled window for each disruptive action.
- **Implement-if-missing:** Stand up a lightweight change/approval process; schedule windows; prepare user comms templates.

## G6. Backup / rollback posture

- **Description:** A defined backup and rollback position for any change — config export, data backup, and a documented back-out procedure before any disruptive action.
- **Why:** Cloud changes are not always reversible by default; a tested rollback is the safety net for cutovers and bulk operations.
- **Verify:** Confirm pre-change config/state is captured and a written rollback exists for each disruptive change.
- **Implement-if-missing:** Export current configuration/state; document and (where feasible) rehearse the rollback before executing the change.


---


# 3. Implementation — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

This is the **program runbook**. It follows the standard program model — **Discover → Assess → Plan → Provision → Pilot → Migrate (per workstream) → Cutover → Validate → Decommission** — and contains a phase-by-phase methodology plus a self-contained runbook for each of the seven workstreams.

> **Endpoint reminder (read first):** GCC High and Azure Government use the **`.us` sovereign endpoints**. Wherever a portal/URL appears below, the **target** uses the government endpoint and the **source (commercial)** uses the standard one:
> - Azure Government portal: `https://portal.azure.us`
> - M365 Government admin: `https://admin.microsoft.com` (resolves to the government admin center when signed in with a GCC High account)
> - Entra (Gov): `https://entra.microsoft.us`
> - Exchange admin (Gov): `https://admin.exchange.microsoft.us`
> - SharePoint admin (Gov): `https://<org>-admin.sharepoint.us`
> - Teams admin (Gov): `https://admin.teams.microsoft.us`
> - Sign-in authority (Gov): `https://login.microsoftonline.us`
> - SharePoint content (Gov): `https://<org>.sharepoint.us`
> - Exchange mail (Gov): `https://outlook.office365.us`

> **Naming convention (mandatory, reused verbatim):** every created object is `<Purpose> – <Scope> – <Stage>`. The canonical object names introduced in each phase are reused later. Stage is `Source` (commercial), `Target` (GCC High), or `Program` (cross-cutting).

---

## Phase 1 — Discover

**Goal:** produce the authoritative estate baseline.

1. Run the read-only discovery script from an admin workstation:
   - `scripts\GCCHIGH-Discovery.ps1` connects to the **commercial** M365 (Exchange Online, SharePoint, Teams) and **commercial** Azure, and exports `Estate-Inventory – Discovery – Source.csv`.
2. Capture, per object: mailbox sizes/types (user/shared/room/resource), SharePoint site count + storage, OneDrive accounts + storage, Teams (with membership and channel counts), Azure subscriptions, VMs (OS, size, disks), and App Services / PaaS resources.
3. Record total **GB per workstream** — this drives bandwidth (R9) and licensing (R3) sizing.
4. Inventory dependencies that do **not** migrate cleanly cross-cloud: app registrations, Power Platform environments, third-party SaaS integrations, conditional-access/Intune config, mail connectors, and public folders.

**Exit gate:** signed-off `Estate-Inventory – Discovery – Source.csv` covering 100% of in-scope objects.

---

## Phase 2 — Assess

**Goal:** turn the inventory into a sized, risk-rated plan input.

1. **Compliance scoping:** confirm the driver (CMMC level, ITAR/EAR, FedRAMP High) and identify export-controlled data sets (R13).
2. **Sizing:** map total GB and object counts to license counts (R3), tool licensing (R6/R7), and bandwidth/ExpressRoute (R9).
3. **Server assessment:** in Azure Migrate (commercial discovery appliance or imported inventory), generate readiness + right-sizing for Azure Government targets.
4. **Complexity rating:** rate each mailbox/site/team/server/app High/Med/Low based on size, permissions complexity, integrations, and compliance sensitivity.

**Exit gate:** an assessment summary with sized targets and a risk rating per object.

---

## Phase 3 — Plan

**Goal:** wave plan + workstream sequencing + named objects.

1. Generate the wave plan from Discovery:
   - `scripts\GCCHIGH-Set-WavePlan.ps1 -InputCsv "Estate-Inventory – Discovery – Source.csv" -OutputCsv "Wave-Plan – Program – Program.csv"` groups users/sites/servers into waves (`Wave 01 … Wave NN`), keeping departments/teams together to limit cross-cloud coexistence pain.
2. **Workstream sequencing (recommended order within each wave):**
   1. **Identity** (must lead — everything authenticates against it),
   2. **Exchange**, **SharePoint/OneDrive**, **Teams** (content workstreams, parallelizable),
   3. **Azure IaaS servers**, **Azure apps/PaaS**, **AVD** (infrastructure, can run in parallel program tracks).
3. **Pilot wave:** designate `Wave 00 – Pilot – Program` (5–25 representative users + 1–2 sites/teams + 1 non-critical server) ahead of production waves.
4. Name every object that will be created (see each workstream below) and record them in the program register.
5. Schedule cutover windows and rollback owners per wave (R15).

**Exit gate:** approved `Wave-Plan – Program – Program.csv`, sequenced workstreams, named objects, scheduled windows.

---

## Phase 4 — Provision (GCC High tenant + Azure Gov landing zone)

**Goal:** stand up the empty target so workloads have somewhere to land. **Prerequisites R1–R4 must be satisfied (eligibility validated, AOS-G reseller, tenant + licenses, Azure Gov subscription).**

### 4.1 Confirm the GCC High tenant
1. Sign in to the GCC High admin center at `https://admin.microsoft.com` with `Migration SvcAcct – M365 – Target` (or a target Global Admin).
2. **Billing → Licenses:** confirm GCC High SKUs cover the Discovery user count.

### 4.2 Build the Azure Government landing zone
At `https://portal.azure.us`, signed in to the GCC High Entra tenant:
1. **Subscriptions:** confirm/assign the Gov subscription `Azure Gov Subscription – Platform – Target`.
2. **Resource groups → Create** the landing-zone resource groups (one per workstream/scope), e.g.:
   - `RG – Networking – Target`
   - `RG – Servers – Target`
   - `RG – PaaS – Target`
   - `RG – AVD – Target`
   - `RG – ASR-Recovery – Target`
3. **Virtual networks → Create** `VNet – LandingZone – Target` with subnets `snet-servers`, `snet-avd`, `snet-paas`, plus a gateway subnet if ExpressRoute is used (R9).
4. **Network security groups:** create `NSG – Servers – Target`, `NSG – AVD – Target`; attach to subnets.
5. If ExpressRoute (Gov) is in scope: **ExpressRoute circuits** → provision to a **Government** peering location and create `VNet Gateway – ExpressRoute – Target`.

**Exit gate:** target tenant confirmed with licenses; landing-zone resource groups, VNet/subnets, NSGs (and ExpressRoute if applicable) created and named.

---

## Phase 5 — Establish Identity (Entra in GCC High)

**Goal:** users can authenticate in the target before any content lands. Per R10, identity is **re-established**, not synced from commercial.

1. **Verify a routing domain first:** in the GCC High admin center → **Settings → Domains**, the tenant has `<org>.onmicrosoft.us`. (The primary email domain is verified later at cutover — a domain can only live in one tenant at a time.)
2. **Choose the auth model** (per R10): cloud-only accounts, or a **new** Entra Connect / Cloud Sync agent pointed at the GCC High tenant (separate install from any commercial sync).
3. **Create the master group** `All Migrated Users – Identity – Target` (security group) — every migrated account is added here for licensing and conditional access.
4. **Provision users/groups:**
   - Cloud-only: bulk-create from the Discovery CSV (Graph USGov — see `GCCHIGH-Remediation.ps1` helpers) and assign licenses via group-based licensing on `All Migrated Users – Identity – Target`.
   - Hybrid: scope the new sync agent's OUs and let it provision into GCC High.
5. **Conditional access:** create baseline policies `CA – Require MFA – Target` and `CA – Block Legacy Auth – Target` (Entra Gov → **Protection → Conditional Access**). Note: commercial CA policies are **re-created**, not migrated.
6. **MFA:** users re-register MFA in the target (registrations do not transfer).
7. **Create migration service accounts** `Migration SvcAcct – M365 – Source` and `Migration SvcAcct – M365 – Target` (R12) and grant tool consent in both tenants.

**Exit gate:** pilot users can sign in to `https://login.microsoftonline.us`, hold licenses, and satisfy conditional access.

---

## Phase 6 — Pilot

Run **every** in-scope workstream against `Wave 00 – Pilot – Program` end-to-end before any production wave. Each workstream's pilot must pass its acceptance gate (see `05-testing.md`) before production migration of that workstream begins. Capture timings to refine the wave schedule.

---

## Workstream Runbooks (Phase 7 — Migrate)

Each runbook is its own phase, executed per wave. Name every object; use the `.us` endpoints for all target operations.

### WS-A — Exchange Online (Quest cross-cloud)

1. **In Quest On Demand Migration** (R6), create/confirm project `Cross-Cloud Migration Project – M365 – Target`.
2. **Connect endpoints:** add the **commercial** source connector (auth as `Migration SvcAcct – M365 – Source`) and the **GCC High** target connector (auth as `Migration SvcAcct – M365 – Target`). Confirm the project region/edition supports the GCC High target.
3. **Match objects:** map source mailboxes to target users created in Phase 5 (match on UPN/alias). Create the migration collection `Mailbox Wave – Exchange – <Wave NN>`.
4. **Pre-stage (pass 1):** run a full mailbox sync (mail, calendar, contacts) ahead of cutover. Schedule incremental deltas.
5. **Coexistence note:** cross-cloud free/busy and unified GAL are limited — set expectations that full interoperability arrives at wave cutover.
6. **Cutover (per wave):** run the final delta; switch the user's primary mail endpoint; have users reconfigure Outlook/mobile against `https://outlook.office365.us`. MX cutover is handled in Phase 8 (domain cutover).
7. **Re-stamp addresses** if any proxy addresses need fixing post-move (`GCCHIGH-Remediation.ps1 -Mode ReStampAddresses`).

**Named objects:** `Cross-Cloud Migration Project – M365 – Target`, `Mailbox Wave – Exchange – <Wave NN>`.

### WS-B — SharePoint Online / OneDrive (ShareGate / Quest)

1. **Pre-create target sites:** in the GCC High SharePoint admin center (`https://<org>-admin.sharepoint.us`) → **Active sites → Create**, provision target sites mirroring source URLs as `Site – <SourceName> – Target`. Pre-provision OneDrive for target users (Phase 5).
2. **In ShareGate** (R7) or Quest, connect commercial source site and GCC High target site (`https://<org>.sharepoint.us`).
3. **Copy (pass 1):** copy structure, libraries, lists, versions, and **permissions** (map source principals to target Entra principals). Create migration set `Content Wave – SPO/OneDrive – <Wave NN>`.
4. **Incremental:** run delta copies until cutover.
5. **Cutover (per wave):** final delta; set source sites read-only; update any bookmarks/links to the `.us` URLs; re-point Teams files (WS-C) to migrated sites.
6. **Re-permission** any broken inheritance post-move (`GCCHIGH-Remediation.ps1 -Mode RePermission`).

**Named objects:** `Site – <SourceName> – Target`, `Content Wave – SPO/OneDrive – <Wave NN>`.

### WS-C — Microsoft Teams (Quest / ShareGate)

1. **Pre-create teams** in the GCC High Teams admin center (`https://admin.teams.microsoft.us`) or let the tool create them; name `Team – <SourceName> – Target`.
2. **Migrate** team membership, channels, tabs, and the underlying SharePoint files (the team's site is migrated by WS-B). Create set `Teams Wave – Teams – <Wave NN>`.
3. **Chat caveat:** 1:1 and some channel chat history support varies by tool/edition — confirm scope; document what is and isn't carried. Migrate what the edition supports; otherwise treat chat as a fresh start at cutover.
4. **Cutover (per wave):** finalize membership; validate channel files resolve to the migrated `.us` SharePoint site; users sign in to Teams against the GCC High tenant.

**Named objects:** `Team – <SourceName> – Target`, `Teams Wave – Teams – <Wave NN>`.

### WS-D — Azure IaaS servers (Azure Migrate + ASR → failover into Azure Gov)

1. **Assess:** in Azure Migrate (`Server Migration Project – IaaS – Target` per R8), confirm readiness/right-sizing for Azure Gov.
2. **Recovery vault:** confirm `Recovery Vault – ASR – Target` in `RG – ASR-Recovery – Target`.
3. **Enable replication:** in the vault → **Site Recovery → Enable replication**, select source VMs, target = Azure Gov region, target RG `RG – Servers – Target`, target VNet `VNet – LandingZone – Target` / `snet-servers`. Create replication group `Replication Group – Servers – <Wave NN>`.
4. **Monitor** replication to 100% synchronized; keep deltas flowing.
5. **Test failover (mandatory):** run an **isolated** test failover into an isolated test subnet; confirm the VM **boots**, the OS is healthy, and apps start. Tear down the test VM. (See `05-testing.md` server gate.)
6. **Planned failover (cutover):** during the window, run a final sync then **planned failover**; commit; attach NICs/NSGs; update internal DNS to the new IPs.
7. **Re-trigger replication** for any failed item with `GCCHIGH-Remediation.ps1 -Mode RetriggerASR`.

**Named objects:** `Server Migration Project – IaaS – Target`, `Recovery Vault – ASR – Target`, `Replication Group – Servers – <Wave NN>`.

### WS-E — Azure apps / PaaS (redeploy / IaC)

1. PaaS is **redeployed**, not block-replicated. Export source IaC or generate it; parameterize for Gov endpoints.
2. **Deploy** into `RG – PaaS – Target` via Bicep/ARM/Terraform (point provider/cloud to **AzureUSGovernment**).
3. **Migrate data** inside PaaS separately: database export/import (e.g. Azure SQL bacpac), storage account copy (AzCopy to `*.blob.core.usgovcloudapi.net`), Key Vault secrets re-created in `KeyVault – AppSecrets – Target` (secrets are re-created, never exported in clear).
4. **Re-point configuration:** connection strings, app settings, and any endpoint URLs to `.us`/Gov equivalents.
5. **Re-create app registrations** in GCC High Entra (registrations and secrets do not migrate); update redirect URIs to `.us`.

**Named objects:** `RG – PaaS – Target`, `KeyVault – AppSecrets – Target`.

### WS-F — AVD / VDI (rebuild host pools in Azure Gov + FSLogix profile migration)

1. **Rebuild host pools natively** in Azure Gov — AVD is not lifted-and-shifted. At `https://portal.azure.us` → **Azure Virtual Desktop → Host pools → Create** `Host Pool – AVD – Target` in `RG – AVD – Target`, with `Workspace – AVD – Target` and `App Group – Desktop – Target`.
2. **Session hosts:** deploy session host VMs from the approved image into `snet-avd`; join to the GCC High identity (Entra-joined or to a Gov-hosted AD).
3. **FSLogix profiles:** provision the profile share `FSLogix Share – Profiles – Target` (Azure Files in Gov or a file server VM). **Migrate FSLogix profile containers** (`.vhdx`) from the source profile share via AzCopy/Robocopy; re-point the FSLogix `VHDLocations` GPO/registry to the target share.
4. **Assign users** from `All Migrated Users – Identity – Target` to `App Group – Desktop – Target`.
5. **Validate** a real user login loads the migrated profile (see `05-testing.md` AVD gate).

**Named objects:** `Host Pool – AVD – Target`, `Workspace – AVD – Target`, `App Group – Desktop – Target`, `FSLogix Share – Profiles – Target`.

---

## Phase 8 — Domain Cutover

**Goal:** point the organization's real domains at the GCC High tenant. Do this per the change window (R15); a domain can only be verified in one tenant at a time.

1. **Release the domain** from the commercial tenant (remove the domain after its users' mail is migrated, or coordinate a same-window release).
2. **Verify the domain** in the GCC High admin center → **Settings → Domains → Add domain** (add the verification TXT to public DNS, R11).
3. **Cut over DNS records** to the GCC High service values:
   - **MX** → GCC High mail routing (`*.mail.protection.office365.us`).
   - **Autodiscover** CNAME → `autodiscover.<region>.outlook.office365.us` equivalent.
   - **SPF/DKIM/DMARC** → re-publish for the GCC High tenant (enable DKIM in the Gov Defender/Exchange portal and publish the CNAMEs).
   - SharePoint/Teams vanity URLs as applicable.
4. **Lower TTLs** ahead of the window; confirm propagation with `nslookup`.

**Exit gate:** mail flows to the GCC High tenant; autodiscover resolves; SPF/DKIM/DMARC pass.

---

## Phase 9 — Validate (per workstream)

Run `scripts\GCCHIGH-Validation.ps1` and the manual gates in `05-testing.md` for each workstream/wave: mail flow, content parity, Teams functionality, server failover boot + app validation, AVD login + profile, identity/DNS. **No commercial resource is decommissioned until its target counterpart passes.** Track progress with `GCCHIGH-Report.ps1`.

**Exit gate:** all workstream acceptance gates PASS for the wave.

---

## Phase 10 — Decommission

**Goal:** retire the commercial estate under change control, only after validation.

1. **Confirm** all waves validated (`GCCHIGH-Report.ps1` shows 100% per workstream).
2. **Soft-retire first:** set commercial mailboxes/sites read-only; disable sign-in for migrated accounts; keep a defined **retention/grace period** for rollback.
3. **Data retention/compliance:** export any legal-hold/retention data per policy before deletion; retain CMMC/ITAR evidence.
4. **Tear down** commercial Azure resources (VMs, PaaS) after their Gov counterparts pass and the grace period elapses.
5. **Decommission the commercial tenant/licenses** last; reclaim/cancel commercial SKUs via the original channel.
6. **Document** the final state and archive the program register for assessment evidence.

**Exit gate:** commercial estate retired; evidence archived; program closed.


---


# 5. Testing & Acceptance — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Testing is organized as numbered tests, each with an explicit **PASS/FAIL gate**, grouped by workstream. Each workstream also has an **acceptance gate** — the combined condition that must be met before that workstream's wave is declared complete and before the corresponding commercial resources may be decommissioned (Phase 10).

> Run `scripts\GCCHIGH-Validation.ps1` to automate the scripted portions; the manual gates below are operator-verified. Record results in `Validation Results – Program – <Wave NN>`.

---

## Group 1 — Identity & Access

**T1.1 — Target sign-in.** A migrated pilot user signs in at `https://login.microsoftonline.us`.
- PASS: authenticates and reaches the GCC High portal. FAIL: any auth error.

**T1.2 — Licensing.** User holds the assigned GCC High license via `All Migrated Users – Identity – Target`.
- PASS: license shows assigned, services enabled. FAIL: unlicensed/partial.

**T1.3 — Conditional access / MFA.** User is prompted by `CA – Require MFA – Target`; legacy auth blocked.
- PASS: MFA enforced, legacy blocked. FAIL: policy not applied.

**Identity acceptance gate:** T1.1–T1.3 PASS for 100% of the wave's users.

---

## Group 2 — Exchange (mail flow)

**T2.1 — Inbound mail.** Send external → migrated mailbox after MX cutover.
- PASS: delivered to GCC High mailbox within SLA, headers show `*.office365.us` routing. FAIL: NDR/misroute/delay.

**T2.2 — Outbound mail.** Migrated mailbox → external recipient.
- PASS: delivered; SPF/DKIM/DMARC pass at recipient. FAIL: auth failure/quarantine.

**T2.3 — Content parity.** Compare folder counts/recent items + calendar + contacts vs. source baseline.
- PASS: counts within tolerance, calendar/contacts present. FAIL: missing items beyond tolerance.

**T2.4 — Client connectivity.** Outlook (desktop + mobile) connects to `https://outlook.office365.us`.
- PASS: autodiscover resolves, profile connects. FAIL: cannot connect.

**Exchange acceptance gate:** T2.1–T2.4 PASS; zero unresolved NDRs for wave users.

---

## Group 3 — SharePoint / OneDrive (content parity)

**T3.1 — Structure parity.** Site/library/list counts match source baseline.
- PASS: parity within tolerance. FAIL: missing structures.

**T3.2 — File parity + integrity.** File counts and sample checksums/versions match.
- PASS: counts match, samples open, versions present. FAIL: missing/corrupt files.

**T3.3 — Permissions.** Sampled permissions resolve to correct target Entra principals.
- PASS: access correct (incl. deny). FAIL: broken/over-broad permissions.

**SharePoint/OneDrive acceptance gate:** T3.1–T3.3 PASS for all sites in the wave.

---

## Group 4 — Teams (functionality)

**T4.1 — Team & membership.** Each `Team – <SourceName> – Target` exists with correct members/owners.
- PASS: membership matches. FAIL: missing members/owners.

**T4.2 — Channel files.** Channel **Files** tab resolves to the migrated `.us` SharePoint site and files open.
- PASS: files present and open. FAIL: broken file location.

**T4.3 — Collaboration.** Post a message, start a call/meeting in a channel.
- PASS: messaging + calling work. FAIL: feature broken.

**T4.4 — Chat scope confirmation.** Confirm migrated chat history matches the documented in-scope set.
- PASS: matches documented scope. FAIL: scope not as documented.

**Teams acceptance gate:** T4.1–T4.4 PASS for all teams in the wave.

---

## Group 5 — Azure IaaS Servers (failover boot + app validation)

**T5.1 — Replication health.** ASR shows each VM in `Replication Group – Servers – <Wave NN>` 100% synchronized, RPO within target.
- PASS: protected, healthy, RPO met. FAIL: critical/stale.

**T5.2 — Test failover boot.** Isolated test failover boots the VM; OS reaches login.
- PASS: VM boots, OS healthy. FAIL: boot failure/BSOD.

**T5.3 — Application validation.** On the failed-over VM, core service/app starts and responds.
- PASS: app functional. FAIL: app down.

**T5.4 — Networking.** Post-planned-failover VM has correct NIC/NSG/IP and internal DNS resolves.
- PASS: reachable per design. FAIL: connectivity broken.

**Server acceptance gate:** T5.1–T5.4 PASS; test failover validated **before** planned failover.

---

## Group 6 — Azure Apps / PaaS

**T6.1 — Service up.** Each redeployed PaaS resource in `RG – PaaS – Target` is running and reachable on its `.us`/Gov endpoint.
- PASS: healthy. FAIL: down/unreachable.

**T6.2 — Data parity.** Migrated database/storage row/object counts match source baseline.
- PASS: parity within tolerance. FAIL: data loss.

**T6.3 — App auth.** Re-created app registration authenticates against GCC High Entra; redirect URIs work.
- PASS: auth succeeds. FAIL: auth/redirect error.

**PaaS acceptance gate:** T6.1–T6.3 PASS for each app.

---

## Group 7 — AVD / VDI (session host login + profile)

**T7.1 — Host pool health.** `Host Pool – AVD – Target` session hosts show **Available**.
- PASS: hosts available. FAIL: unavailable/errors.

**T7.2 — User login.** A wave user signs in to `Workspace – AVD – Target` / `App Group – Desktop – Target`.
- PASS: desktop loads. FAIL: cannot connect.

**T7.3 — FSLogix profile.** The user's migrated FSLogix container mounts (settings/desktop/docs present).
- PASS: profile loads from `FSLogix Share – Profiles – Target`. FAIL: temp profile/failed mount.

**AVD acceptance gate:** T7.1–T7.3 PASS for the wave's AVD users.

---

## Group 8 — Identity & DNS Cutover (program-level)

**T8.1 — Domain ownership.** Each in-scope domain is verified in the GCC High tenant only.
- PASS: verified in GCC High, released from commercial. FAIL: conflict/unverified.

**T8.2 — DNS records.** MX/autodiscover/SPF/DKIM/DMARC resolve to GCC High values.
- PASS: all correct (`nslookup` confirms). FAIL: stale/incorrect.

**DNS acceptance gate:** T8.1–T8.2 PASS before declaring wave cutover complete.

---

## Program-level exit (per wave)

A wave is **complete** only when **every** workstream acceptance gate above is PASS. **No commercial resource may be decommissioned** (Phase 10) until its wave's gates pass and the grace period defined in `07-best-practices.md` has elapsed.


---


# 6. Troubleshooting — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Failure modes and fixes, grouped by area. Most cross-cloud problems trace back to two root causes: **the wrong cloud endpoint** (commercial vs. `.us`) and **assuming something synced that does not sync cross-cloud**.

---

## A. Cross-cloud auth / tenant-connection issues

**Symptom:** Migration tool authenticates to the source but fails on the GCC High target ("invalid client", "AADSTS90002 tenant not found", or silently no objects).
- **Cause:** Tool/connector pointed at commercial endpoints, or the project region is not GCC High.
- **Fix:** Select the tool's **GCC High edition/region**. Confirm the target connector uses `login.microsoftonline.us` and the GCC High tenant ID. In PowerShell use the sovereign switches: `Connect-MgGraph -Environment USGov`, `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`, `Connect-AzAccount -Environment AzureUSGovernment`.

**Symptom:** Consent fails / "admin approval required" loops on the target.
- **Cause:** Tool's app registration not consented in the **GCC High** tenant (consent in commercial does not carry over).
- **Fix:** Grant admin consent separately in the GCC High tenant for the tool's enterprise app; verify `Migration SvcAcct – M365 – Target` holds the required roles (R12).

**Symptom:** Source mailbox/site moves but objects don't match a target user.
- **Cause:** Target identity not pre-created, or UPN/alias mismatch.
- **Fix:** Ensure Phase 5 created the user in `All Migrated Users – Identity – Target`; re-run object matching on UPN/alias; use `GCCHIGH-Remediation.ps1 -Mode ReStampAddresses` to align proxy addresses.

---

## B. GCC High endpoint / `.us` mistakes

**Symptom:** Scripts/portals return commercial data or "not found" when you expected GCC High.
- **Cause:** Using commercial URLs/cmdlet defaults against a GCC High tenant.
- **Fix:** Use the `.us` portals (`portal.azure.us`, `entra.microsoft.us`, `admin.exchange.microsoft.us`, `admin.teams.microsoft.us`, `<org>-admin.sharepoint.us`) and the sovereign cmdlet switches. For SharePoint PowerShell add `-Region ITAR` on `Connect-SPOService`.

**Symptom:** AzCopy/storage copy fails or lands in the wrong region.
- **Cause:** Targeting commercial storage suffix.
- **Fix:** Use the Gov suffix `*.blob.core.usgovcloudapi.net` for Azure Gov storage endpoints.

**Symptom:** ExpressRoute won't connect Gov VNet.
- **Cause:** Commercial ExpressRoute peering cannot reach Gov regions.
- **Fix:** Provision **ExpressRoute for Azure Government** to a Government peering location (R9).

---

## C. Quest / ShareGate GCC High edition pitfalls

**Symptom:** Tool licensed but no GCC High target option appears.
- **Cause:** Wrong tool edition/region (commercial-only).
- **Fix:** Re-provision the **GCC High-capable** Quest On Demand project / ShareGate build (R6/R7); confirm with the vendor it supports **commercial-source → GCC-High-target**.

**Symptom:** Throttling / very slow content throughput.
- **Cause:** Microsoft 365 service throttling under heavy concurrency.
- **Fix:** Reduce concurrency, schedule heavy passes off-hours, let the tool back off, pre-stage early and only delta in the window. Right-size waves (`GCCHIGH-Set-WavePlan.ps1 -MaxGBPerWave`).

**Symptom:** Teams chat history missing after migration.
- **Cause:** Chat fidelity varies by tool/edition; some chat is not migratable cross-cloud.
- **Fix:** Confirm the edition's chat scope; migrate what is supported, communicate fresh-start chat (best practice), and validate against documented scope (T4.4).

**Symptom:** SharePoint permissions broken / over-broad after copy.
- **Cause:** Source principals didn't map to target Entra principals.
- **Fix:** Re-run permission mapping; remediate with `GCCHIGH-Remediation.ps1 -Mode RePermission`; re-validate (T3.3).

---

## D. ASR replication failures + failover boot issues

**Symptom:** Replication health "Critical" or stuck below 100%.
- **Cause:** Bandwidth saturation, source agent issues, or churn exceeding link capacity.
- **Fix:** Check the link vs. churn (R9); stagger VMs across `Replication Group – Servers – <Wave NN>`; re-trigger with `GCCHIGH-Remediation.ps1 -Mode RetriggerASR`. Do not plan failover until health is **Normal** and RPO is met (T5.1).

**Symptom:** Test/planned failover VM doesn't boot or BSODs.
- **Cause:** Missing boot drivers, unsupported config, or incorrect VM size/disk mapping for Azure Gov.
- **Fix:** Use Azure Migrate readiness/right-sizing for the **Gov** target; enable boot diagnostics and inspect the screenshot; correct the target size/disk; re-run an **isolated test failover** (T5.2) before any planned failover.

**Symptom:** Failed-over VM has no network / unreachable.
- **Cause:** NIC/NSG/IP/DNS not attached post-failover.
- **Fix:** Attach the correct NIC in `snet-servers`, apply `NSG – Servers – Target`, set the IP, and update internal DNS (T5.4).

---

## E. AVD profile / FSLogix issues

**Symptom:** User gets a temporary profile / settings missing after AVD login.
- **Cause:** FSLogix container didn't migrate, or `VHDLocations` still points at the source share.
- **Fix:** Confirm the `.vhdx` copied to `FSLogix Share – Profiles – Target`; re-point the FSLogix `VHDLocations` GPO/registry to the target share; confirm host has access; re-test login (T7.3).

**Symptom:** Session hosts show "Unavailable".
- **Cause:** Host agent/registration token issue or identity join failure.
- **Fix:** Re-generate the host pool registration token for `Host Pool – AVD – Target`; confirm session hosts joined the GCC High identity; restart the AVD agent.

**Symptom:** Users can't see the desktop in the Gov client.
- **Cause:** Wrong client/feed URL (commercial) or no app-group assignment.
- **Fix:** Use the **Azure Government** AVD feed; assign users from `All Migrated Users – Identity – Target` to `App Group – Desktop – Target` (T7.2).

---

## F. Identity mismatches

**Symptom:** Users can't sign in to the target after cutover.
- **Cause:** Account not licensed, MFA not registered, or conditional access misconfigured.
- **Fix:** Verify license via `All Migrated Users – Identity – Target`; have users re-register MFA (does not transfer); review `CA – Require MFA – Target` (T1.1–T1.3).

**Symptom:** Expected directory sync from commercial isn't happening.
- **Cause:** There is **no** commercial→GCC High Entra Connect sync.
- **Fix:** Re-establish identity per R10 — cloud-only accounts or a **new** sync agent pointed at GCC High. Do not wait for a sync that cannot exist.

---

## G. Throttling (program-wide)

**Symptom:** Sustained slow throughput, HTTP 429s, ramped-down jobs.
- **Cause:** Microsoft 365 per-tenant/per-user throttling on bulk operations.
- **Fix:** Lower concurrency, distribute across off-hours, honor tool back-off, and size waves so deltas finish in the window despite throttling. More threads make it worse, not better.

---

## H. Domain move blockers

**Symptom:** Can't verify the domain in GCC High — "already in use".
- **Cause:** Domain still verified in the commercial tenant (a domain lives in one tenant at a time).
- **Fix:** Migrate the domain's mailboxes first, then **release** the domain from commercial, then verify in GCC High (Phase 8) and cut over MX/autodiscover/SPF/DKIM/DMARC (R11, T8.1–T8.2).

**Symptom:** Mail mis-routes or NDRs after cutover.
- **Cause:** Stale DNS / TTL, or MX not pointed at the Gov mail endpoint.
- **Fix:** Lower TTLs ahead of the window; point MX at `*.mail.protection.office365.us`; confirm with `nslookup`; re-publish SPF/DKIM/DMARC for the GCC High tenant.

---

## I. Compliance / data-residency gotchas

**Symptom:** Regulated (ITAR/EAR/CUI) data routed through a non-authorized region or exposed to non-US persons during transit.
- **Cause:** Tool data path/region or migration-team access not constrained to the authorized boundary.
- **Fix:** Configure the tool for **US-sovereign** data handling; restrict migration access to authorized (US) persons; keep staging storage in-boundary; document the data-flow for the CMMC/ITAR evidence package (R13). Treat any out-of-boundary transit as an incident, not a performance issue.

**Symptom:** Assessor asks for evidence you didn't capture.
- **Cause:** Program register/named-object list/acceptance results not kept current.
- **Fix:** Maintain the register continuously (best practice §07): named objects, change records, per-gate results, and the data-flow document are the assessment evidence — backfilling after the fact is unreliable.


---


# 7. Best Practices — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Program-grade practices for a cross-cloud GCC High migration. These reduce risk, protect regulated data, and produce the evidence a CMMC/ITAR program requires.

## Program & wave planning

- **Lead with eligibility, not technology.** Confirm Microsoft validation (R1), AOS-G reseller (R2), tenant + licensing (R3), and Azure Gov subscription (R4) before any build. These gate everything and have long lead times.
- **Keep cohorts intact.** Group users, the teams/sites they collaborate on, and their dependent servers into the **same wave**. Splitting collaborators across clouds maximizes the period of painful, limited cross-cloud coexistence.
- **Pilot every workstream.** `Wave 00 – Pilot – Program` runs all seven workstreams end-to-end before any production wave; refine the schedule from real pilot timings.
- **Sequence identity first.** Nothing authenticates until the GCC High Entra directory and licensing are in place.
- **Right-size waves to your bandwidth window.** Cap each wave's GB to what the network (R9) can move and re-sync within the cutover window.

## Communications

- **Set the coexistence expectation up front.** Tell users cross-cloud free/busy, GAL, and Teams interop are **limited** until their wave cuts over — this is inherent to two separate clouds, not a defect.
- **Per-wave comms cadence:** announce → pre-cutover reminder (with the new sign-in URL `https://login.microsoftonline.us`, Outlook/Teams re-config steps, MFA re-registration) → cutover-complete confirmation.
- **Publish the new endpoints.** Users must know the `.us` URLs for Outlook, SharePoint, and Teams.

## Compliance / ITAR handling

- **Keep regulated data in an authorized boundary in transit (R13).** Confirm the migration tool's data path/region is US-sovereign; restrict migration-team access to authorized (US) persons where required; keep any staging storage inside the boundary.
- **Never export secrets in clear.** Key Vault secrets, app-registration secrets, and certificates are **re-created** in the target, not exported.
- **Treat the program register as evidence.** Named objects, change records, acceptance-gate results, and the data-flow document are directly reusable as CMMC/ITAR assessment evidence — keep them complete and dated.

## Identity discipline

- **Re-establish, don't assume sync.** There is no commercial→GCC High Entra Connect; plan cloud-only or a **new** sync agent targeting GCC High.
- **Re-create conditional access and MFA deliberately** — they do not migrate; baseline `CA – Require MFA – Target` and `CA – Block Legacy Auth – Target` before users land.
- **Use named service accounts** (`Migration SvcAcct – M365 – Source/Target`) for all tooling, not personal admin accounts — better throttling isolation and audit trail.

## Content migration (Exchange / SharePoint / Teams)

- **Pre-stage, then delta.** Run full pass-1 syncs well ahead of cutover; only a short final delta runs in the window.
- **Verify the tool's GCC High edition/endpoints** before licensing (R6/R7) — generic commercial-only tools will not target `.us`.
- **Preserve and re-map permissions**; validate sampled ACLs against the correct **target** Entra principals (T3.3).
- **Document Teams chat scope** honestly — what carries depends on tool/edition; communicate any fresh-start chat.

## Throttling

- **Expect Microsoft 365 throttling** on large content/mailbox moves. Stagger concurrency, schedule heavy passes off-hours, and let the tool back off — do not fight throttling with more threads. Size waves so deltas finish inside the window despite throttling.

## Azure servers & ASR

- **Always run a test failover before planned failover (T5.2).** An isolated test failover that boots and validates the app is non-negotiable — it is the only proof the VM will come up in Gov.
- **Replicate to 100% and keep deltas flowing** before the window; commit only after a clean planned failover.
- **Fix internal DNS/IP at cutover**, attach the correct NSGs, and validate connectivity (T5.4) before declaring done.

## PaaS

- **Redeploy via IaC**, parameterized for **AzureUSGovernment**; migrate data (DB/storage) separately and verify counts (T6.2). Re-point all config/endpoints to `.us`.

## AVD / FSLogix

- **Rebuild host pools natively** in Azure Gov; do not attempt to lift session hosts.
- **Migrate FSLogix containers, then re-point `VHDLocations`** to `FSLogix Share – Profiles – Target`. Validate a real login loads the migrated profile (T7.3) — a temp profile means the re-point failed.

## Rollback

- **Define a rollback per workstream and per cutover (R15).** For mail/DNS, keep the source tenant warm and lowered TTLs so MX can be reverted within the window. For servers, do not commit the failover until validated. Keep migrated source data **read-only, not deleted** through the grace period.
- **Grace period before decommission.** Hold the commercial estate read-only for a defined window (e.g. 30–60 days) after a wave passes before tearing it down.

## Decommission discipline

- **Validate before you delete.** No commercial resource is decommissioned until its Gov counterpart passes its acceptance gate and the grace period elapses.
- **Export retention/legal-hold data first**; decommission the commercial tenant/licenses **last** and reclaim SKUs through the original channel.

## Documentation for CMMC

- **Keep `FEATURES`/program-register, named-object list, data-flow, and acceptance results current** as you go — not at the end. A complete, dated record of who moved what, how data stayed in boundary, and how each cutover was validated is the deliverable an assessor expects.


---


# 8. Deliverables Summary — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

This package is a complete, enterprise-grade program kit for migrating a commercial Microsoft 365 + Azure estate into a GCC High sovereign tenant. It contains the documentation playbook, five PowerShell tools, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the program is, the seven workstreams, the GCC-High-is-a-separate-cloud reality, how it works, tooling, benefits, honest limitations, and the standard program model. |
| `02-requirements.md` | R1–R15 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING eligibility, AOS-G reseller, and provisioned-tenant requirements. |
| `global-requirements-azure-solutions.md` | Baseline requirements common to every Azure Solutions engagement (tenant, roles, licensing, network, change control, backup/rollback). |
| `03-implementation.md` | The full program runbook: Discover → Assess → Plan → Provision → Identity → Pilot → seven workstream runbooks → Domain cutover → Validate → Decommission, with named objects and full `.us` navigation paths. |
| `05-testing.md` | Numbered tests with PASS/FAIL gates and a per-workstream acceptance gate (mail flow, content parity, Teams, server failover, AVD/profile, identity/DNS). |
| `06-troubleshooting.md` | Cross-cloud/endpoint, tooling, ASR, AVD/FSLogix, identity, throttling, domain, and compliance failure modes with fixes. |
| `07-best-practices.md` | Program best practices: waves, comms, ITAR handling, pilots, rollback, ASR test failovers, FSLogix, throttling, decommission discipline, CMMC documentation. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a `.SYNOPSIS` header with PURPOSE / HOW TO RUN / EXPECTED RESULTS, and a NEUTRAL white-label `.NOTES`. Cmdlets use the sovereign endpoints where needed (`Connect-AzAccount -Environment AzureUSGovernment`, `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`, Graph `-Environment USGov`).

| Script | What it does |
|---|---|
| `scripts\GCCHIGH-Discovery.ps1` | **Read-only estate inventory.** Connects to the commercial M365 (mailboxes, SharePoint sites, Teams) and Azure (subscriptions, VMs, App Services) and exports a per-object CSV with sizing — the Discovery baseline (R14) that drives licensing, bandwidth, and wave planning. |
| `scripts\GCCHIGH-Validation.ps1` | **Target readiness + per-workstream cutover validation.** Checks the GCC High tenant/licensing, the Azure Gov subscription, sample content parity, and server failover state; emits PASS/FAIL per check for the acceptance gates. |
| `scripts\GCCHIGH-Report.ps1` | **Program/workstream status report.** Reads a status CSV and produces per-workstream % complete, wave progress, and GB moved as a CSV plus a console summary — the program dashboard. |
| `scripts\GCCHIGH-Remediation.ps1` | **Safe remediation helpers.** Re-stamp proxy addresses, re-permission content, and re-trigger ASR replication. Runs read-only / `-WhatIf` by default; requires `-Apply` to make any change. |
| `scripts\GCCHIGH-Set-WavePlan.ps1` | **Wave + workstream planner.** Reads the Discovery CSV and groups users/sites/servers into balanced migration waves, emitting a wave-plan CSV; supports `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `GCCHIGH-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbooks share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Mailbox Wave – Exchange – Wave 03`) so outputs cross-reference cleanly across discovery, planning, validation, and reporting.
