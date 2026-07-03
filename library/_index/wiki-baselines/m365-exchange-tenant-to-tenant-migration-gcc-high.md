# Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains) — Government (GCC High)

> **Version 1.0.0** · Category: Migrations · Solution code: EXOMIGG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

## The situation

Your organization needs to consolidate Exchange Online mailboxes and a primary email domain from one Microsoft 365 tenant into another **within the US sovereign cloud (GCC High)** — a 1:1-domain move. GCC High is **not** the Commercial service with a different sign-in: it uses different admin portals, different service endpoints, a different licensing channel, and — critically — **different migration support**. Runbooks copied from the Commercial cloud can connect to the wrong cloud or fail silently.

## The one decision that shapes the whole project

**Native (Microsoft-built) cross-tenant mailbox migration cannot cross cloud boundaries.** Microsoft states: *"Cross cloud tenant to tenant migration isn't supported."*

- **Commercial ↔ GCC High** — native migration is **not available**; you must use a **third-party migration tool** (Quest, BitTitan, CloudM, Cloudiway, etc.) or **PST** for the mail data.
- **GCC High → GCC High** (same cloud) — native migration exists but reaches government clouds via **Public Preview**; confirm eligibility with Microsoft before relying on it. A third-party tool is a fully supported alternative.

This solution is authored **tool-agnostic**: it prepares both tenants correctly so whichever engine you use will succeed.

## What this solution provides

A tested, novice-admin-friendly, click-to-implement runbook — plus **five PowerShell scripts** — that:

- Uses the correct **`*.us` GCC High portals and endpoints** throughout (`portal.office365.us`, `admin.exchange.office365.us`, `graph.microsoft.us`, `outlook.office365.us`, `login.microsoftonline.us`).
- Calls out every **Commercial-vs-GCC-High difference** at the step where it matters, with a fully **cited** parity reference.
- Follows a gated **Assess → Configure → Pilot → Validate → Expand** method, so nothing scales until a small pilot is proven.
- Ships **read-only** discovery/validation/reporting scripts and **safe (`-WhatIf`-by-default)** remediation and targeting scripts, all connecting to **US Gov** endpoints.

## Business outcome

The migration is executed **correctly for the sovereign cloud** — right portals, right endpoints, licensing sequence respected, cross-cloud constraint handled up front — and **proven on a pilot before you scale**, protecting mail continuity for a government/DIB organization where a botched cutover is not an option.

## Effort and prerequisites

Self-guided, at a fraction of typical consulting cost. Requires: both tenants in GCC High, appropriate US Gov licensing (G3/G5 GCC High) plus the Cross-Tenant User Data Migration add-on for a native move, Global Administrator / Organization Administrator / Move Mailboxes roles, DNS control for the migrating domain, and reachable `*.us` endpoints. Full detail in the Requirements Guide.

> All GCC High specifics are cited to Microsoft US Government documentation or explicitly flagged "verify for GCC High." Nothing is invented.


---


# Solution Overview — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains) — Government (GCC High)

This is the **Government (GCC High)** edition of the Exchange Online tenant-to-tenant migration solution. It moves Exchange Online mailboxes and the primary email domain from one Microsoft 365 organization to another **within the US sovereign cloud**, using the correct **`*.us` admin portals and endpoints**, with every Commercial-vs-GCC-High difference called out at the point it matters.

If you are running the Commercial edition steps against a GCC High tenant, some of them **silently connect to the wrong cloud or fail outright**. This edition fixes that.

---

## Read this first — the cross-cloud caveat (do not skip)

> **Native (Microsoft-built) cross-tenant mailbox migration cannot cross cloud boundaries.** Microsoft states plainly: *"Cross cloud tenant to tenant migration isn't supported. An example scenario would be moving from Office 365 Worldwide to Office 365 Government Cloud."* (Microsoft Learn, *Cross-tenant mailbox migration*.)

What this means for your project **before you plan anything**:

- **Commercial ↔ GCC High** (either direction): the native cross-tenant mailbox move is **not available**. You must use a **third-party migration tool** (Quest On Demand, BitTitan MigrationWiz, CloudM, Cloudiway, etc.) or a **PST export/import** for the actual mail data.
- **GCC High → GCC High** (both tenants in the same sovereign cloud): Microsoft's **native** cross-tenant mailbox migration exists but reaches government clouds via **Public Preview** and **later than Commercial** — **confirm current eligibility with Microsoft / your account team before relying on it.** (verify for GCC High.) A third-party tool remains a fully supported alternative.
- This solution is therefore authored **tool-agnostic**: it prepares *both* tenants correctly so that **whichever** mail-transfer engine you use — supported native same-cloud move, a third-party tool, or PST — will succeed. **The internals of any third-party migration tool are deferred to that vendor's own GCC High documentation.**

The full support matrix, endpoints, and licensing detail live in **`gcc-high-parity-notes.md`** (all cited).

---

## What this solution delivers

A repeatable, novice-admin-friendly, click-to-implement runbook to:

1. **Assess** both the source and target GCC High tenants (mailbox inventory, licensing, DNS, endpoints, readiness gates) using read-only PowerShell against the **US Gov Graph and EXO endpoints**.
2. **Configure** identity, licensing, admin roles, endpoint allow-listing, and (for a supported native same-cloud move) the cross-tenant `OrganizationRelationship` — all in the **GCC High portals**.
3. **Pilot** a small named batch of mailboxes and prove the method end-to-end before scaling.
4. **Validate** mail flow, mailbox content, permissions, and the DNS/MX cutover with explicit pass/fail gates.
5. **Expand** to the full population in controlled waves, then cut over the primary domain.

Every step names the object it creates or reuses (a pilot group, a migration batch, an org relationship) so later steps build on earlier ones rather than starting over.

---

## The deployment model (Assess → Configure → Pilot → Validate → Expand, with gates)

| Phase | Goal | Exit gate (must pass before next phase) |
|---|---|---|
| **Assess** | Know both tenants: what mailboxes, what licenses, what DNS, what endpoints, what blockers | Discovery report clean; readiness checklist all green or waived in writing |
| **Configure** | Identity, licensing, roles, endpoints, and (if native) org relationship in place | Validation script passes on both tenants; migration engine can authenticate |
| **Pilot** | Move a small named batch and prove the method | Pilot mailboxes fully validated; no unresolved errors |
| **Validate** | Confirm content, mail flow, permissions, and cutover mechanics | All validation checks green; rollback rehearsed |
| **Expand** | Move remaining mailboxes in waves; cut over primary domain | Each wave validated; final MX/Autodiscover cutover confirmed |

Gates are **hard stops**. Do not begin Configure until Assess is clean; do not Expand until the Pilot is validated.

---

## Commercial vs GCC High — what's different

A concise orientation; the fully cited detail is in `gcc-high-parity-notes.md`.

1. **Cross-cloud native migration is unsupported** (see the caveat above). This is the single biggest planning difference — a Commercial↔GCC High move **cannot** use the native cross-tenant feature at all, and same-cloud GCC High native moves are **preview-gated**.
2. **Different admin portals.** You administer in **`portal.office365.us`** (M365 admin), **`admin.exchange.office365.us`** (Exchange), **`entra.microsoft.us`** (Entra), **`security.microsoft.us`**, **`compliance.microsoft.us`**, **`portal.azure.us`** — never the Commercial `admin.microsoft.com` / `entra.microsoft.com`.
3. **Different endpoints for tooling.** Graph is **`graph.microsoft.us`** (`Connect-MgGraph -Environment USGov`); Exchange Online PowerShell is **`outlook.office365.us`** (`Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`); the login authority is **`login.microsoftonline.us`**. Omitting these makes tools authenticate against Commercial and fail.
4. **Different licensing channel.** Base mailbox licenses are **US Government plans (G3/G5 GCC High)** bought through an **authorized US Gov reseller / AOS-G partner**; the **Cross-Tenant User Data Migration** add-on availability on your Gov agreement must be **verified** before relying on a native move. (verify for GCC High.)
5. **Feature lag / gaps.** Some Commercial conveniences (e.g., Cross-Tenant Identity Mapping, Graph Explorer) are **not available** in GCC High. Assume newer features are absent until Microsoft documents them for US Gov. (verify for GCC High.)
6. **Separate firewall allow-list.** GCC High publishes its **own** endpoint list; you must allow the **`.us`** URLs/IPs, not the Commercial ranges.

**What is the same:** the migration *method and sequence*, the Exchange object model (MailUser/ExchangeGUID/proxy scrubbing), and the cmdlet *names*. Only the *endpoints, portals, licensing channel, and cross-cloud support* change.

---

## What's inside this solution

- **This Solution Overview** and the cited **GCC High Parity Notes**.
- **Requirements Guide** (`02-requirements.md`) — every prerequisite with verify/implement steps, GCC High-specific.
- **Implementation Guide** (`03-implementation.md`) — ordered GCC High steps with inline caveats.
- **Testing** (`05-testing.md`) and **Troubleshooting** (`06-troubleshooting.md`) with pass/fail gates and GCC High gotchas.
- **Best Practices** (`07-best-practices.md`) and **Deliverables Summary** (`08-deliverables-summary.md`).
- **5 PowerShell scripts** — Discovery, Validation, Report (read-only), and Remediation + Set-ScopeTargeting (default `-WhatIf`) — all connecting to **US Gov Graph / EXO** endpoints.

---

## Who this is for

Government tenant administrators, MSPs serving the Defense Industrial Base, and IT teams performing a 1:1-domain Exchange Online consolidation **within GCC High** — who need the sovereign-cloud-correct steps rather than Commercial steps that fail quietly.


---


# Requirements Guide — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

These are the **solution-specific** requirements for a 1:1-domain Exchange Online tenant-to-tenant migration **within GCC High**. They are in addition to the category baseline in `global-requirements-azure-solutions.md` (G1–G6) — satisfy **both** sets before implementation.

Each requirement uses the same structure: **Description / Why required / How to verify (GCC High) / How to implement if missing.**

> Throughout, "source tenant" is the GCC High organization you are migrating **from**; "target tenant" is the GCC High organization you are migrating **to**. All portal URLs are the **`*.us`** GCC High URLs.

---

## R0 — Both tenants are in the **same** sovereign cloud (GCC High)

**Description.** Source and target must both be **Microsoft 365 GCC High** tenants.

**Why required.** Native cross-tenant mailbox migration **cannot cross cloud boundaries** — "Cross cloud tenant to tenant migration isn't supported." (Microsoft Learn, *Cross-tenant mailbox migration*.) A Commercial↔GCC High move must instead use a third-party tool or PST for the mail data (see R7).

**How to verify (GCC High).** In each tenant sign in at **`https://portal.office365.us`** → confirm you reach the **GCC High** M365 admin center (not `admin.microsoft.com`). Confirm each initial domain is `*.onmicrosoft.us`. Run **`EXOMIGG-Discovery.ps1`**, which records the detected cloud/environment for each tenant.

**How to implement if missing.** If the tenants are in different clouds, do **not** attempt a native move — adopt the third-party-tool or PST path (R7). If a tenant is not yet GCC High, provisioning/migrating it into GCC High is a separate prerequisite project via an authorized US Gov reseller.

---

## R1 — Migration method chosen and its support status confirmed

**Description.** A decision, recorded in the change plan, of **which engine moves the mail**: (a) native same-cloud cross-tenant move (GCC High→GCC High only), (b) a third-party migration tool, or (c) PST export/import.

**Why required.** The native path is **Public Preview** for government clouds and reaches GCC High **later than Commercial**; you must confirm it is available and supported for your tenants before depending on it. (verify for GCC High — confirm with Microsoft / your account team.)

**How to verify (GCC High).** Obtain written confirmation from Microsoft support / your account team on native cross-tenant availability for your GCC High tenants, **or** confirm your chosen third-party vendor documents a GCC High / US Gov path. Record the decision.

**How to implement if missing.** If native availability cannot be confirmed, select a third-party tool with an explicit GCC High guide, or plan PST. **Third-party tool setup is deferred to that vendor's GCC High documentation.**

---

## R2 — Administrative roles in both tenants (GCC High portals)

**Description.** Named operator accounts holding the least-privilege roles for a cross-tenant move.

**Why required.** "Two roles are required" for a native move — **Organization Administrator** (one-time setup of the `OrganizationRelationship` / `-MailboxMoveCapability`) and **Move Mailboxes** (executing moves). (Microsoft Learn, *Cross-tenant mailbox migration*.) **Global Administrator** is needed to consent the migration app / cross-tenant config.

**How to verify (GCC High).** In **`https://entra.microsoft.us`** → **Identity → Roles & admins → Roles**, confirm assignments. In **`https://admin.exchange.office365.us`** → **Roles → Admin roles**, confirm the **Organization Management** role group membership and a **Move Mailboxes**-capable role. Prefer **PIM-eligible** (time-bound) assignments.

**How to implement if missing.** Have an existing Global Administrator assign the roles in `entra.microsoft.us`; assign Exchange role groups in `admin.exchange.office365.us`.

---

## R3 — Licensing baseline (US Government plans) + Cross-Tenant User Data Migration add-on

**Description.** Target-tenant Exchange Online licenses for every migrated user (US Gov plans, e.g., **Office 365 G3/G5 GCC High** or **Microsoft 365 G3/G5 GCC High**), plus — **for a native move** — the **Cross-Tenant User Data Migration** per-user add-on.

**Why required.** Users must be licensed in the target for a mailbox to activate. For a **native** move, the Cross-Tenant User Data Migration license is **enforced**: "Migrations fail if this step isn't completed. Microsoft doesn't offer exceptions for this licensing requirement." (Microsoft Learn, *Cross-tenant mailbox migration*.) Third-party/PST paths do not require this add-on.

**How to verify (GCC High).** In **`https://portal.office365.us`** → **Billing → Licenses**, confirm owned quantities and, for native, that the **Cross-Tenant User Data Migration** SKU is present/orderable on your Gov agreement. **(verify for GCC High — confirm the add-on is available on your contract vehicle before relying on native.)**

**How to implement if missing.** Purchase US Gov licenses and the add-on through your **authorized US Gov reseller / AOS-G partner** (not the Commercial storefront). Note the license-before-ExchangeGUID caveat: do **not** license the target MailUser before its `ExchangeGUID` is stamped, or a new empty mailbox is provisioned instead. (Microsoft Learn, same.)

---

## R4 — GCC High endpoints reachable and allow-listed (`*.us`)

**Description.** Outbound connectivity from operator workstations (and any migration hosts) to the **GCC High** service endpoints, through corporate proxy/firewall.

**Why required.** GCC High uses a **separate** endpoint list from Commercial; the tooling talks to `login.microsoftonline.us`, `graph.microsoft.us`, `outlook.office365.us`, and the `*.us` portals. Blocked `.us` endpoints cause auth/operation failures.

**How to verify (GCC High).** From an operator workstation confirm you can reach `https://portal.office365.us`, `https://admin.exchange.office365.us`, `https://entra.microsoft.us`, and that `Connect-MgGraph -Environment USGov` and `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` succeed. Reference Microsoft's **Office 365 U.S. Government GCC High endpoints** article.

**How to implement if missing.** Allow-list the GCC High **`.us`** URLs/IP ranges on the proxy/firewall per that article; ensure **TLS 1.2+**. Do **not** rely on the Commercial "Office 365 URLs and IP address ranges" list.

---

## R5 — PowerShell modules installed and Gov-connectable

**Description.** Current **ExchangeOnlineManagement** and **Microsoft.Graph** PowerShell modules on the operator workstation, connectable to the **US Gov** endpoints.

**Why required.** All five scripts in this solution connect via `-Environment USGov` (Graph) and `-ExchangeEnvironmentName O365USGovGCCHigh` (EXO). Old modules may lack these environment values.

**How to verify (GCC High).** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph` shows current versions. Run **`EXOMIGG-Validation.ps1`**, which checks module presence and a successful Gov connection to both tenants.

**How to implement if missing.** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and `Install-Module Microsoft.Graph -Scope CurrentUser` (PowerShell 7 recommended). Update with `Update-Module`.

---

## R6 — DNS control for the migrating domain(s)

**Description.** Administrative access to the public DNS zone(s) for the 1:1 domain(s) being moved (MX, Autodiscover, SPF, DKIM, DMARC).

**Why required.** A 1:1-domain move requires **removing** the domain from the source tenant and **verifying** it in the target, then cutting over MX/Autodiscover. Domain verification in the target **fails while the domain is still in use in the source** (expected) — you must control DNS to complete the move.

**How to verify (GCC High).** Confirm you can create/modify TXT/MX/CNAME records at the registrar/DNS host. Capture current records (baseline) with `EXOMIGG-Discovery.ps1` and store them for rollback (G6).

**How to implement if missing.** Obtain DNS delegation/credentials from whoever controls the zone; lower MX TTL (e.g., to 5 minutes) ahead of cutover.

---

## R7 — (If not native) A GCC High-capable third-party tool or PST plan

**Description.** For any Commercial↔GCC High move, and as the supported alternative for GCC High→GCC High, a migration tool that **documents a GCC High / US Gov path**, or a PST export/import plan.

**Why required.** Native cross-cloud is unsupported (R0); a tool or PST is the only way to move the mail data across clouds.

**How to verify (GCC High).** Confirm the vendor lists **GCC High / US Gov** as a supported source/target and that its app registers against **`login.microsoftonline.us`** (US Gov instance). For PST, confirm export capacity and secure handling of CUI/ITAR-scoped data.

**How to implement if missing.** Select a vendor with an explicit GCC High guide (e.g., Quest On Demand, BitTitan MigrationWiz, CloudM, Cloudiway) and follow **their** GCC High onboarding. **Tool internals are out of scope here and deferred to the vendor.**

---

## R8 — Change control, backup, and rollback (G5/G6 applied to this move)

**Description.** Approved change window, communication plan, and a captured pre-change baseline (DNS records, mailbox inventory, permissions) with written rollback steps.

**Why required.** Domain move and MX cutover are disruptive and user-facing. A baseline and rehearsed rollback protect against data loss and prolonged outage.

**How to verify (GCC High).** Confirm an approved change record with window, owner, comms plan, and rollback criteria; confirm `EXOMIGG-Discovery.ps1`/`EXOMIGG-Report.ps1` baselines are stored.

**How to implement if missing.** Raise the change; run the discovery/report scripts to capture the baseline; write the rollback (re-point MX to source, re-add domain to source) into the change record.

---

## Requirements summary

| ID | Requirement | GCC High specific? |
|----|-------------|--------------------|
| R0 | Both tenants in the same GCC High cloud | **Yes** (cross-cloud unsupported) |
| R1 | Migration method chosen + support confirmed | **Yes** (native = preview) |
| R2 | Admin roles (Org Admin, Move Mailboxes, Global Admin) in `*.us` portals | Yes (portals) |
| R3 | US Gov licensing + Cross-Tenant User Data Migration add-on (native) | **Yes** (channel + availability) |
| R4 | GCC High `*.us` endpoints reachable & allow-listed | **Yes** |
| R5 | ExchangeOnlineManagement + Microsoft.Graph, Gov-connectable | Yes (env values) |
| R6 | DNS control for the 1:1 domain(s) | No (same as Commercial) |
| R7 | GCC High-capable third-party tool or PST plan (if not native) | **Yes** |
| R8 | Change control, backup, rollback | No (same as Commercial) |


---


# Global Requirements — Azure Solutions — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

These are the baseline requirements common to **every** solution in the Azure Solutions category. They are generic to the category and are **not** Exchange-specific — the Exchange tenant-to-tenant requirements are listed separately in `02-requirements.md`. Satisfy both sets before beginning implementation.

Each requirement follows the same structure: **Description / Why required / How to verify / How to implement if missing.**

---

## G1 — A Microsoft 365 / Microsoft Entra tenant

**Description.** An active Microsoft cloud tenant (Microsoft Entra ID directory, the identity backbone for all Microsoft 365 and Azure services) for each environment the solution touches.

**Why required.** Every Azure Solutions deliverable operates against one or more Microsoft tenants; the tenant is the root container for identities, licensing, policies, and services.

**How to verify.** Sign in to the **Microsoft Entra admin center** (https://entra.microsoft.com) → **Overview** and confirm the tenant name, tenant ID, and primary domain.

**How to implement if missing.** Provision a Microsoft 365 tenant via https://www.microsoft.com/microsoft-365 (or an Azure subscription via https://portal.azure.com) and record the tenant ID.

---

## G2 — Sufficient administrative roles

**Description.** A named operator account holding the least-privilege administrative roles required by the specific solution (commonly Global Administrator, or a scoped combination such as Exchange Administrator, Security Administrator, Application Administrator, or Privileged Role Administrator).

**Why required.** Configuration, policy, and service changes require directory administrative rights. Using scoped roles where possible limits blast radius.

**How to verify.** In **Microsoft Entra admin center** → **Identity → Roles & admins → Roles**, confirm the operator's role assignments. Prefer **Privileged Identity Management (PIM)** eligible assignments where available.

**How to implement if missing.** Have an existing Global Administrator assign the required role under **Roles & admins → (role) → Add assignments**, ideally as a PIM-eligible (time-bound) assignment.

---

## G3 — Licensing baseline

**Description.** The Microsoft 365 / Entra / Azure licenses and service plans the solution depends on, assigned to the in-scope users or groups.

**Why required.** Most workloads (Exchange Online, Entra ID P1/P2, Defender, Intune, etc.) are gated behind specific service plans; features silently fail or are unavailable without them.

**How to verify.** In the **Microsoft 365 admin center** (https://admin.microsoft.com) → **Billing → Licenses**, confirm owned quantities; in **Users → Active users**, confirm assignment.

**How to implement if missing.** Acquire licenses via **Billing → Purchase services** and assign them directly or via group-based licensing.

---

## G4 — Network connectivity to Microsoft 365 / Azure service endpoints

**Description.** Reliable outbound connectivity from operator workstations and any in-scope systems to the relevant Microsoft 365 and Azure service URLs and IP ranges, through any corporate proxy/firewall.

**Why required.** Admin portals, PowerShell modules, Microsoft Graph, and migration/data services all require access to Microsoft's published endpoints; blocked endpoints cause authentication and operation failures.

**How to verify.** From an operator workstation, confirm you can reach https://admin.microsoft.com, https://entra.microsoft.com, and connect with Exchange Online PowerShell / Microsoft Graph PowerShell without proxy errors. Reference Microsoft's published **Office 365 URLs and IP address ranges**.

**How to implement if missing.** Allow-list the required Microsoft 365/Azure endpoints on the proxy/firewall per Microsoft's published ranges; if using PowerShell, ensure TLS 1.2+ and module access through the proxy.

---

## G5 — Change control and a defined maintenance window

**Description.** An approved change request and a scheduled maintenance/cutover window for any change that affects production identities, mail flow, DNS, or user-facing services.

**Why required.** Azure Solutions changes can affect authentication, mail, and access for the whole organization. Change control provides approval, communication, scheduling, and a rollback decision point.

**How to verify.** Confirm an approved change record exists with a defined window, a named change owner, a communication plan, and documented rollback criteria.

**How to implement if missing.** Raise a change request in the organization's change-management process; schedule the window during low-impact hours and notify stakeholders and the service desk in advance.

---

## G6 — Backup, export, and rollback posture

**Description.** A documented rollback plan and, where applicable, an exported snapshot of pre-change configuration and data (current DNS records, current policy/config exports, data backups) sufficient to recover if the change must be reversed.

**Why required.** Some Azure Solutions actions are disruptive or hard to reverse (DNS cutover, domain moves, policy changes). A captured baseline and a rollback plan protect against data loss and prolonged outage.

**How to verify.** Confirm a pre-change export/backup exists (for this solution: current MX/Autodiscover/SPF/DKIM/DMARC records, mailbox inventory, and permission exports) and that the rollback steps are written down and understood.

**How to implement if missing.** Before making changes, export current DNS records and relevant configuration, run the discovery scripts to capture a data/inventory baseline, and write the rollback procedure into the change record.

---

## Global requirements summary

| ID | Requirement |
|----|-------------|
| G1 | Microsoft 365 / Entra tenant |
| G2 | Sufficient administrative roles (least privilege, PIM where possible) |
| G3 | Licensing baseline for the workload |
| G4 | Network connectivity to Microsoft 365 / Azure endpoints |
| G5 | Change control + defined maintenance window |
| G6 | Backup / export / rollback posture |


---


# Implementation Guide — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Ordered, click-to-implement steps for a 1:1-domain Exchange Online migration **within GCC High**. Every portal path uses the **`*.us`** GCC High URLs. GCC-High-only caveats are called out **inline at the step where they matter**.

> **Before Step 1:** complete the Requirements Guide (`02-requirements.md`, R0–R8) and the category baseline (G1–G6). Confirm **R0** (both tenants GCC High) and **R1** (migration method + support status) — these gate everything below.
>
> **Object naming (reused across steps).** Create and reuse these named objects: a pilot group **`EXOMIGG-Pilot`**, wave groups **`EXOMIGG-Wave1..N`**, a migration endpoint / org relationship named **`EXOMIGG-CrossTenant`**, and a working folder **`EXOMIGG-baseline\`** holding all exports. Later steps refer to these by name.

---

## Phase A — Assess

### Step 1. Establish sovereign-cloud connections

On the operator workstation (PowerShell 7):

```powershell
# Exchange Online — GCC High
Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName admin@source-tenant.onmicrosoft.us
# Microsoft Graph — US Gov
Connect-MgGraph -Environment USGov -Scopes 'User.Read.All','Organization.Read.All','Directory.Read.All'
```

> **GCC High caveat.** Omitting `-ExchangeEnvironmentName O365USGovGCCHigh` or `-Environment USGov` makes the modules authenticate against the **Commercial** cloud (`login.microsoftonline.com`) and fail for a GCC High tenant. `-ExchangeEnvironmentName O365USGovGCCHigh` auto-selects `outlook.office365.us` and the `login.microsoftonline.us/organizations` authority — do **not** also pass `-ConnectionUri`. (Microsoft Learn, *Connect to Exchange Online PowerShell*.)

### Step 2. Run Discovery (read-only) on both tenants

Run **`EXOMIGG-Discovery.ps1`** against the **source**, then the **target**. It captures: detected cloud/environment, mailbox inventory and sizes, licensing, DNS/MX/Autodiscover/SPF/DKIM/DMARC for the migrating domain(s), and admin-role holders — writing them into **`EXOMIGG-baseline\`**.

This baseline satisfies **G6/R8** (rollback) and feeds the readiness gate.

### Step 3. Readiness gate (Assess exit)

Confirm from the Discovery output: both tenants are GCC High (R0); target has enough US Gov licenses (R3); DNS is under your control (R6); endpoints reachable (R4); roles assigned (R2). **Do not proceed to Configure until this is clean or exceptions are waived in writing.**

---

## Phase B — Configure

### Step 4. Assign/confirm admin roles (GCC High portals)

- In **`https://entra.microsoft.us`** → **Identity → Roles & admins → Roles**, confirm **Global Administrator** on the account that will consent the migration configuration.
- In **`https://admin.exchange.office365.us`** → **Roles → Admin roles**, confirm **Organization Management** (for the one-time `OrganizationRelationship`) and a **Move Mailboxes**-capable role for the operator running batches.

> **GCC High caveat.** These are the **`*.us`** portals — the Commercial `entra.microsoft.com` / `admin.exchange.microsoft.com` will not show your GCC High tenant.

### Step 5. Prepare target licensing

In **`https://portal.office365.us`** → **Billing → Licenses**, confirm US Gov mailbox licenses for every migrated user. **For a native move**, confirm the **Cross-Tenant User Data Migration** add-on is present.

> **GCC High caveat.** Buy through your **authorized US Gov reseller / AOS-G partner**. **verify for GCC High:** confirm the Cross-Tenant User Data Migration add-on is orderable on your Gov agreement **before** relying on a native move; if not, use the third-party/PST path (Step 7B). **Do not license the target MailUser before its `ExchangeGUID` is stamped** — doing so provisions a new empty mailbox instead of accepting the move. (Microsoft Learn, *Cross-tenant mailbox migration*.)

### Step 6. Allow-list endpoints and validate connectivity

Ensure the proxy/firewall allows the **GCC High `.us`** endpoints (R4). Then run **`EXOMIGG-Validation.ps1`** against both tenants — it verifies module versions, a successful Gov connection, role presence, license counts, and endpoint reachability, and reports **pass/fail** per check.

### Step 7. Configure the migration engine

Choose **one** path per the decision in R1:

**7A — Native same-cloud move (GCC High → GCC High only, if confirmed available).**
- In the **target** tenant, set up the cross-tenant `OrganizationRelationship` named **`EXOMIGG-CrossTenant`** and its **`-MailboxMoveCapability`** (Organization Administrator only). Register/consent the migration application in **both** tenants against **`login.microsoftonline.us`**.
- Build the target-side **MailUser** objects (mail-enabled users) carrying the source **ExchangeGUID** and proxy addresses, so the move converts them to mailboxes rather than creating new ones.
- Use **`EXOMIGG-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to build the pilot/wave target groups from a mapping CSV.

> **GCC High caveat.** Every app registration, consent, and endpoint here is the **`.us`** instance. **verify for GCC High:** the native cross-tenant feature is **Public Preview** in government clouds — confirm eligibility for your tenants before enabling. Newer conveniences like **Cross-Tenant Identity Mapping** should be assumed **unavailable** in GCC High until Microsoft documents otherwise. (Microsoft Learn, *national cloud deployments*.)

**7B — Third-party tool or PST (required for cross-cloud; supported alternative for same-cloud).**
- Register the vendor's application against the **US Gov instance** (`login.microsoftonline.us`) in both tenants and select the vendor's **GCC High** service. Provide the mailbox-mapping CSV (map using the `*.onmicrosoft.us` initial domains).
- **Tool internals — batch configuration, throttling, delta passes — are deferred to that vendor's GCC High documentation.**

### Step 8. Configure gate (Configure exit)

`EXOMIGG-Validation.ps1` passes on **both** tenants and the chosen engine can authenticate. Only then proceed to Pilot.

---

## Phase C — Pilot

### Step 9. Prepare the pilot domain/DNS (non-disruptive prep)

In **`https://portal.office365.us`** (target) → **Settings → Domains**, **add** the migrating domain and create the verification **TXT** record in DNS.

> **Expected behavior (same as Commercial):** verification **fails while the domain is still in use in the source tenant**. Adding it now lets DNS propagate (up to 72h). Final verification happens at cutover.

Lower the domain's **MX TTL** (e.g., to 5 minutes) ahead of any cutover.

### Step 10. Migrate the pilot batch

Populate **`EXOMIGG-Pilot`** with a small set of low-risk, named test mailboxes. Run the move for just this group using the engine from Step 7 (native `New-MigrationBatch`/`New-MoveRequest`, or the vendor tool). Monitor to completion.

### Step 11. Validate the pilot (Pilot exit gate)

Run **`EXOMIGG-Report.ps1`** for the pilot mailboxes and perform the checks in `05-testing.md`: content present, folder counts match, permissions/delegation intact, mail flow to/from works. **Do not expand until every pilot mailbox passes and there are no unresolved errors.**

---

## Phase D — Validate & Expand

### Step 12. Build waves

Use **`EXOMIGG-Set-ScopeTargeting.ps1`** (default `-WhatIf`; re-run with `-Execute`/`-Confirm` only after reviewing the WhatIf output) to assign the remaining mailboxes to **`EXOMIGG-Wave1..N`** from the mapping CSV. Keep waves sized to your validated throughput.

### Step 13. Migrate waves with validation between each

For each wave: run the move, then **`EXOMIGG-Report.ps1`** + the `05-testing.md` checks. Treat each wave's validation as a gate before the next.

### Step 14. Source-side domain release and target verification (cutover prep)

On cutover day, in the **source** tenant remove the migrating domain from all objects (reset default addresses to `*.onmicrosoft.us`, strip proxy addresses, set default domain to the initial domain). Then complete **domain verification in the target** (`portal.office365.us` → Domains).

> **GCC High caveat.** All of this is in the **`*.us`** portals. The domain cannot verify in the target until fully released from the source — expect a short window after release before target verification succeeds.

### Step 15. MX / Autodiscover cutover

Point the domain's **MX** and **Autodiscover CNAME** to the **target** GCC High tenant. When the (lowered) TTL expires, mail flows to the migrated mailboxes. Recreate transport rules, connectors, and allow/block lists in the target. Verify mail flow both directions.

### Step 16. Post-migration cleanup and closeout

Clear Outlook Auto-Complete (nickname cache) or add legacy DN as an X.500 proxy to avoid NDRs. Run a final **`EXOMIGG-Report.ps1`** across all migrated mailboxes and archive it with the change record. Confirm rollback baseline is retained for the agreed period.

---

## Rollback (if a gate fails)

Re-point **MX/Autodiscover to the source** tenant (records captured in `EXOMIGG-baseline\`), re-add the domain to the source if it was released, and re-enable source mailboxes. Because moves are staged in waves behind gates, rollback scope is limited to the current wave.

---

## Endpoint quick-reference (this engagement)

| Purpose | GCC High value |
|---|---|
| M365 admin center | `https://portal.office365.us` |
| Exchange admin center | `https://admin.exchange.office365.us` |
| Entra admin center | `https://entra.microsoft.us` |
| Defender / Purview | `https://security.microsoft.us` / `https://compliance.microsoft.us` |
| EXO PowerShell | `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` |
| Graph PowerShell | `Connect-MgGraph -Environment USGov` |
| Login authority | `https://login.microsoftonline.us` |

Full cited detail: `gcc-high-parity-notes.md`.


---


# Testing & Validation — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Each phase in the Implementation Guide ends with a **gate**. This document defines the pass/fail checks for those gates. Run the read-only scripts (`EXOMIGG-Validation.ps1`, `EXOMIGG-Report.ps1`) plus the manual checks below. **A gate passes only when every check is PASS or explicitly waived in writing.**

> All connections use the GCC High endpoints (`-ExchangeEnvironmentName O365USGovGCCHigh`, `-Environment USGov`). A "connected to wrong cloud" failure (see `06-troubleshooting.md`) invalidates the entire test run.

---

## Gate 0 — Environment sanity (before Assess)

| # | Check | How | PASS |
|---|-------|-----|------|
| 0.1 | Correct cloud | `EXOMIGG-Discovery.ps1` reports environment per tenant | Both show **GCC High / USGov**, initial domains `*.onmicrosoft.us` |
| 0.2 | Modules current | `EXOMIGG-Validation.ps1` | ExchangeOnlineManagement + Microsoft.Graph present and Gov-connectable |
| 0.3 | Endpoints reachable | `EXOMIGG-Validation.ps1` | `login.microsoftonline.us`, `graph.microsoft.us`, `outlook.office365.us` reachable |

**FAIL 0.1** = you are pointed at Commercial; fix connection parameters before anything else.

---

## Gate 1 — Assess exit (readiness)

| # | Check | How | PASS |
|---|-------|-----|------|
| 1.1 | Both tenants GCC High (R0) | Discovery | Confirmed same sovereign cloud |
| 1.2 | Migration method + support (R1) | Change record | Native availability confirmed **or** third-party/PST path selected |
| 1.3 | Target licensing (R3) | Discovery / `portal.office365.us` | Enough US Gov mailbox licenses; native add-on present/orderable (verify for GCC High) |
| 1.4 | Roles (R2) | Discovery | Org Admin + Move Mailboxes + Global Admin assigned |
| 1.5 | DNS control (R6) | Manual | Can edit MX/TXT/CNAME for the domain |
| 1.6 | Baseline captured (R8/G6) | `EXOMIGG-baseline\` | DNS, mailbox inventory, permissions exported |

---

## Gate 2 — Configure exit

| # | Check | How | PASS |
|---|-------|-----|------|
| 2.1 | Validation clean, both tenants | `EXOMIGG-Validation.ps1` | All checks PASS on source **and** target |
| 2.2 | Engine authenticates | Native: org relationship set; Tool: vendor connectivity test | Chosen engine connects to **both** GCC High tenants via `login.microsoftonline.us` |
| 2.3 | Target MailUsers correct (native) | `EXOMIGG-Report.ps1` | Target MailUsers carry source **ExchangeGUID** + proxies; **not** prematurely licensed |
| 2.4 | Domain pre-added | `portal.office365.us` → Domains | Domain added to target; TXT created (verification pending is expected) |

---

## Gate 3 — Pilot exit (the critical gate)

Run for every mailbox in **`EXOMIGG-Pilot`**:

| # | Check | How | PASS |
|---|-------|-----|------|
| 3.1 | Move completed | Batch status / `EXOMIGG-Report.ps1` | Status Completed, no errors |
| 3.2 | Content present | Open OWA in target (`outlook.office365.us`) | Inbox, Sent, Calendar, Contacts present |
| 3.3 | Folder counts | `EXOMIGG-Report.ps1` item counts source vs target | Counts match within expected delta |
| 3.4 | Permissions/delegation | `Get-MailboxPermission` / `Get-RecipientPermission` | Delegates, SendAs, SendOnBehalf intact |
| 3.5 | Mail flow | Send/receive test to a pilot mailbox | Inbound + outbound succeed |
| 3.6 | Free/busy & calendar | Meeting invite test | Calendar and free/busy resolve |

**Any FAIL here stops expansion.** Diagnose in `06-troubleshooting.md`, remediate (`EXOMIGG-Remediation.ps1`, default `-WhatIf`), re-test.

---

## Gate 4 — Per-wave validation (Expand)

Repeat Gate 3 checks for each **`EXOMIGG-WaveN`** after its move. Do not start the next wave until the current wave is fully PASS.

---

## Gate 5 — Cutover validation

| # | Check | How | PASS |
|---|-------|-----|------|
| 5.1 | Domain released (source) | `Get-MsolUser -DomainName <domain>` equiv. / Discovery | No objects still bind the domain in source |
| 5.2 | Domain verified (target) | `portal.office365.us` → Domains | Domain shows **Verified** in target |
| 5.3 | MX cutover | `nslookup -type=mx <domain>` / MxToolbox | MX points to target GCC High |
| 5.4 | Autodiscover | Outlook profile rebuild | Autodiscover resolves to target |
| 5.5 | Mail flow both ways post-cutover | Test messages | External inbound + outbound OK |
| 5.6 | Transport rules/connectors | Target EAC | Rules/connectors/allow-block recreated |

---

## Gate 6 — Closeout

| # | Check | How | PASS |
|---|-------|-----|------|
| 6.1 | Final report archived | `EXOMIGG-Report.ps1` (all mailboxes) | Stored with change record |
| 6.2 | NDR mitigation | Auto-Complete cleared / X.500 added | No reply NDRs on migrated threads |
| 6.3 | Rollback baseline retained | `EXOMIGG-baseline\` | Retained per policy |

---

## Notes on GCC High testing

- **Validate with PowerShell, not Graph Explorer** — Graph Explorer is **not supported** in GCC High. (Microsoft Learn, *national cloud deployments*.)
- **OWA URL is `outlook.office365.us`**, not `outlook.office.com`.
- If any test tool "can't find the tenant," it is almost always pointed at the **Commercial** endpoint — recheck `-Environment USGov` / `-ExchangeEnvironmentName O365USGovGCCHigh`.


---


# Troubleshooting — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Diagnosis for the failures you actually hit during a GCC High move. Symptoms are grouped; each has cause, GCC-High context, and fix. Run the read-only scripts (`EXOMIGG-Validation.ps1`, `EXOMIGG-Report.ps1`) to confirm state before and after any change.

---

## 1. "Tenant not found" / login redirects to the wrong place / auth fails

**Symptom.** `Connect-MgGraph` or `Connect-ExchangeOnline` errors, redirects to `login.microsoftonline.com`, or reports the tenant doesn't exist even though it does.

**Cause.** The tool is authenticating against the **Commercial** cloud. This is the single most common GCC High problem.

**Fix.**
- Exchange: `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (do **not** also pass `-ConnectionUri`).
- Graph: `Connect-MgGraph -Environment USGov`.
- Confirm the sign-in URL is **`login.microsoftonline.us`** and portals are **`*.us`**.
- Update modules if the environment value is unrecognized (R5). (Microsoft Learn, *Connect to Exchange Online PowerShell*; *national cloud deployments*.)

---

## 2. Native cross-tenant migration option is missing or blocked

**Symptom.** The native cross-tenant move can't be configured, or an org-relationship `-MailboxMoveCapability` step fails.

**Cause.** Either a **cross-cloud** attempt (unsupported) or a **preview-availability** gap in GCC High.

**Fix.**
- If either tenant is **Commercial**: native is **not supported** across clouds — switch to a **third-party tool or PST** (R7). *"Cross cloud tenant to tenant migration isn't supported."*
- If both are **GCC High**: native cross-tenant is **Public Preview** in government clouds — **confirm eligibility with Microsoft / your account team** before proceeding. Use a third-party tool if preview access isn't available. (verify for GCC High.)
- Ensure the org relationship is created by an **Organization Administrator** — "Only the organization administrator can alter the `-MailboxMoveCapability` setting." (Microsoft Learn.)

---

## 3. `CrossTenantMigrationWithoutLicensePermanentException`

**Symptom.** A native move fails with: *"No license was found for the source recipient … or the target recipient. A Cross-tenant User Data Migration license is required."*

**Cause.** Missing the **Cross-Tenant User Data Migration** add-on. It is enforced — "Migrations fail if this step isn't completed. Microsoft doesn't offer exceptions."

**Fix.** Assign the add-on to the migrating user (source or target object). In GCC High, purchase it through your **authorized US Gov reseller / AOS-G partner**; **verify it is orderable on your Gov agreement** — if not, use a third-party/PST path (which doesn't require it). (Microsoft Learn, *Cross-tenant mailbox migration*.)

---

## 4. Target gets a new empty mailbox instead of the migrated one

**Symptom.** After the move (or after licensing), the target user has an empty mailbox rather than the source content.

**Cause.** A license (Exchange plan) was applied to the target MailUser **before** its `ExchangeGUID` was stamped, provisioning a new mailbox; or the target MailUser had a **mismatched previous ExchangeGUID**.

**Fix.**
- Do **not** license the target MailUser before `ExchangeGUID` + proxies are set; assign licenses during the 30-day grace window after the move.
- Clear a mismatched GUID: `Set-User <identity> -PermanentlyClearPreviousMailboxInfo`, then re-stamp the source `ExchangeGUID`. `EXOMIGG-Remediation.ps1` performs this (default `-WhatIf`). (Microsoft Learn.)

---

## 5. Proxy addresses disappear after licensing

**Symptom.** External/secondary SMTP addresses (e.g., an unverified domain) vanish from a MailUser after an Exchange plan is applied.

**Cause.** **Proxy-address scrubbing** — when an Exchange service plan is applied, Entra ID removes SMTP addresses on domains the local tenant hasn't verified (anti-spoofing).

**Fix.** Expected behavior. To retain external branding, strip the license until after the move, or verify the domain first. Plan address handling accordingly. (Microsoft Learn.)

---

## 6. Domain won't verify in the target tenant

**Symptom.** Adding the migrating domain in the target (`portal.office365.us` → Domains) fails verification.

**Cause.** The domain is still in use in the **source** tenant (expected until release), or DNS TXT hasn't propagated.

**Fix.**
- Before cutover, **verification failing is normal** — pre-adding just lets DNS propagate (up to 72h).
- At cutover, fully **release** the domain from the source (reset default/proxy addresses to `*.onmicrosoft.us`, set default domain to initial), then verify in target. Use `Get-Recipient`/Discovery to find lingering objects still binding the domain.

---

## 7. Mail flow broken after MX cutover

**Symptom.** Inbound mail bounces or doesn't arrive after pointing MX to the target.

**Cause.** TTL not expired, MX/Autodiscord pointing to wrong tenant, or transport rules/connectors not recreated in target.

**Fix.**
- Verify MX with `nslookup -type=mx <domain>` / MxToolbox; wait out the (lowered) TTL.
- Recreate transport rules, connectors, and allow/block lists in the **target** EAC (`admin.exchange.office365.us`).
- If needed, roll back: re-point MX/Autodiscover to source from the `EXOMIGG-baseline\` records.

---

## 8. Reply NDRs on migrated threads

**Symptom.** Users get NDRs replying to pre-migration emails.

**Cause.** Outlook Auto-Complete (nickname cache) holds old legacy DN routing.

**Fix.** Clear the Auto-Complete list, or add the old legacy DN as an **X.500** proxy address on migrated users.

---

## 9. Scripts/portals work in Commercial but "can't find" things in GCC High

**Symptom.** A step from a Commercial guide references a portal/feature that doesn't exist for you.

**Cause.** GCC High **feature lag/absence** and different URLs. Graph Explorer, Cross-Tenant Identity Mapping, and some newer conveniences are **not available** in GCC High.

**Fix.** Map every Commercial reference through **`gcc-high-parity-notes.md`**. Validate Graph via **PowerShell**, not Graph Explorer. Assume a newer Commercial feature is absent until Microsoft documents it for US Gov. (verify for GCC High; Microsoft Learn, *national cloud deployments*.)

---

## 10. Endpoints blocked by proxy/firewall

**Symptom.** Timeouts reaching `graph.microsoft.us`, `outlook.office365.us`, or the `*.us` portals.

**Cause.** Firewall allow-lists Commercial ranges only; GCC High uses a **separate** endpoint list.

**Fix.** Allow-list the **GCC High `.us`** URLs/IPs from Microsoft's *Office 365 U.S. Government GCC High endpoints* article; ensure **TLS 1.2+**. Re-check monthly (GCC High publishes changes 30 days ahead).

---

## Escalation

If a native move remains blocked after the above and both tenants are confirmed GCC High, open a Microsoft support case referencing **cross-tenant mailbox migration in GCC High (Public Preview)** and confirm current availability for your tenants. For cross-cloud moves, do not escalate for native support — it does not exist; proceed with a third-party tool or PST.

---

## Sources

- Microsoft Learn — *Cross-tenant mailbox migration* (`learn.microsoft.com/microsoft-365/enterprise/cross-tenant-mailbox-migration`).
- Microsoft Learn — *How to migrate mailboxes … to another* (`learn.microsoft.com/exchange/mailbox-migration/migrate-mailboxes-across-tenants`).
- Microsoft Learn — *Connect to Exchange Online PowerShell* (`learn.microsoft.com/powershell/exchange/connect-to-exchange-online-powershell`).
- Microsoft Learn — *Microsoft Graph national cloud deployments* (`learn.microsoft.com/graph/deployments`).
- Microsoft Learn — *Microsoft 365 U.S. Government GCC High endpoints*.


---


# Best Practices — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Field-tested guidance for running a 1:1-domain Exchange Online migration **within GCC High**. These complement the ordered steps in `03-implementation.md`; they do not replace them.

---

## 1. Decide the migration engine before anything else

- **Confirm the cloud boundary first.** If either tenant is Commercial, native cross-tenant migration is **off the table** — commit to a third-party tool or PST immediately and stop planning around native. (Microsoft Learn: cross-cloud not supported.)
- For **GCC High → GCC High**, treat native cross-tenant migration as **Public Preview** and **confirm eligibility in writing** with Microsoft / your account team before you design around it. Keep a third-party tool as a fallback so the project is not blocked by preview availability. (verify for GCC High.)

## 2. Always pin the sovereign cloud in every tool and script

- Bake `-ExchangeEnvironmentName O365USGovGCCHigh` and `-Environment USGov` into every connection — never rely on defaults. The most common GCC High failure is a script silently authenticating against Commercial.
- Use the **`*.us` portals** exclusively (`portal.office365.us`, `admin.exchange.office365.us`, `entra.microsoft.us`, `security.microsoft.us`, `compliance.microsoft.us`, `portal.azure.us`). Bookmark them to avoid muscle-memory Commercial URLs.
- Register **every** migration/vendor app against **`login.microsoftonline.us`** and the vendor's **US Gov** service instance.

## 3. Respect the licensing sequence (native)

- Purchase US Gov licenses and the **Cross-Tenant User Data Migration** add-on through an **authorized US Gov reseller / AOS-G partner** — and **verify the add-on is orderable on your agreement before relying on native**. (verify for GCC High.)
- **Never license the target MailUser before its `ExchangeGUID` is stamped** — that provisions a new empty mailbox and breaks the move. Assign licenses during the 30-day grace period after the move, or only once the ExchangeGUID and proxies are correct. (Microsoft Learn.)
- Expect **proxy-address scrubbing**: unverified SMTP domains are removed when an Exchange plan is applied. Plan address/branding accordingly.

## 4. Gate every phase — never skip the pilot

- Treat the **Pilot exit** as the hard gate: no expansion until every pilot mailbox passes content, permissions, and mail-flow checks.
- Migrate in **named waves** (`EXOMIGG-Wave1..N`), validating between each. Size waves to your **validated** throughput, not an optimistic estimate.
- Keep the phase gates from `05-testing.md` as documented, signed-off checkpoints in the change record.

## 5. Protect data and stay compliant (GCC High context)

- GCC High hosts **CUI/ITAR/DFARS-scoped** data. Keep migration hosts, PST files, mapping CSVs, and reports **inside** the authorized boundary; do not export CUI to Commercial workstations or storage.
- Prefer **certificate-based / app-only** auth for unattended scripts over stored passwords; use **PIM-eligible** (time-bound) admin roles.
- Never place tenant secrets, tokens, or full mailbox exports in shared or public locations. Redact identifiers in any report shared outside the boundary.

## 6. DNS and cutover discipline

- **Lower MX TTL early** (e.g., 5 minutes) so cutover is fast and reversible.
- **Pre-add** the domain to the target and create the TXT record days ahead — verification failing while the domain is still in the source is **expected**, not an error.
- Have the **rollback** (re-point MX/Autodiscover to source, re-add domain to source) written and rehearsed before cutover day.

## 7. Communications and endpoints

- Notify users the **OWA URL is `outlook.office365.us`** and that Outlook profiles may need rebuilding; clear Auto-Complete to avoid NDRs.
- Allow-list the **GCC High endpoint list** (`.us`) on proxies/firewalls, and re-check monthly — GCC High publishes changes 30 days ahead on its **own** endpoint article, separate from Commercial.

## 8. Don't assume Commercial features exist

- Assume newer Commercial conveniences (e.g., **Cross-Tenant Identity Mapping**, **Graph Explorer**) are **absent** in GCC High until Microsoft documents them for US Gov. Validate Graph with PowerShell, not the web explorer. (verify for GCC High.)
- When a Commercial runbook references a portal or feature, **map it through `gcc-high-parity-notes.md`** before following it.

## 9. Keep the three surfaces coherent

- The wiki page, the repo source, and the store deliverable (PDF/scripts) should always agree. When a live GCC High correction is made, sync it back into `source/` and republish so the runbook stays accurate.


---


# Deliverables Summary — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Everything included in this Government (GCC High) edition, and how the pieces fit together.

---

## Documents (`source/`)

| File | Purpose |
|---|---|
| `01-solution-overview.md` | What the solution does, the deployment model, and **Commercial vs GCC High — what's different** (with the cross-cloud-unsupported caveat up front). |
| `02-requirements.md` | Prerequisites R0–R8 (each with GCC High verify/implement steps), plus the category baseline G1–G6. |
| `03-implementation.md` | Ordered Assess→Configure→Pilot→Validate→Expand steps using the `*.us` portals, with GCC-High caveats inline. |
| `05-testing.md` | Pass/fail gates for every phase (Gate 0–6). |
| `06-troubleshooting.md` | GCC-High-specific failure diagnosis (wrong-cloud, licensing, ExchangeGUID, DNS, endpoints). |
| `07-best-practices.md` | Field guidance for running the move safely inside the sovereign boundary. |
| `gcc-high-parity-notes.md` | **Cited** Commercial→GCC High map: endpoints, portals, licensing, roles, support status. |
| `executive-summary.md` | One-page brief for decision-makers. |
| `global-requirements-azure-solutions.md` | Category baseline (G1–G6). |

---

## Scripts (`scripts/`)

All connect to **US Gov Graph / EXO** endpoints (`-Environment USGov`, `-ExchangeEnvironmentName O365USGovGCCHigh`). Read-only scripts make **no** changes. Change-capable scripts default to **`-WhatIf`**.

| Script | Type | What it does |
|---|---|---|
| `EXOMIGG-Discovery.ps1` | **Read-only** | Inventories both tenants: cloud/environment, mailboxes/sizes, licensing, DNS (MX/Autodiscover/SPF/DKIM/DMARC), roles. Writes the `EXOMIGG-baseline\`. |
| `EXOMIGG-Validation.ps1` | **Read-only** | Verifies modules, Gov connectivity, roles, license counts, endpoint reachability; reports pass/fail per check. |
| `EXOMIGG-Report.ps1` | **Read-only** | Per-mailbox migration status, item/folder counts, permissions — for pilot/wave validation and closeout. |
| `EXOMIGG-Remediation.ps1` | **Change (default `-WhatIf`)** | Safe fixes for common blockers (e.g., clear stale ExchangeGUID, reset default addresses, re-stamp proxies). Requires explicit `-Execute` to act. |
| `EXOMIGG-Set-ScopeTargeting.ps1` | **Change (default `-WhatIf`)** | Builds pilot/wave target groups (`EXOMIGG-Pilot`, `EXOMIGG-Wave1..N`) from a mapping CSV. Requires explicit `-Execute` to act. |

---

## How the deliverables work together

1. **Assess** — run `EXOMIGG-Discovery.ps1` (+ `EXOMIGG-Validation.ps1`) to capture the baseline and pass Gate 1.
2. **Configure** — assign roles/licensing in the `*.us` portals, set up the engine (native org relationship or vendor tool), re-run `EXOMIGG-Validation.ps1` to pass Gate 2.
3. **Pilot** — build `EXOMIGG-Pilot` with `EXOMIGG-Set-ScopeTargeting.ps1`, move it, validate with `EXOMIGG-Report.ps1` to pass Gate 3.
4. **Expand** — build waves, move, validate each with `EXOMIGG-Report.ps1` (Gate 4), then cut over DNS (Gate 5) and close out (Gate 6).
5. `EXOMIGG-Remediation.ps1` (`-WhatIf` first) resolves blockers surfaced by validation/testing at any point.

---

## Scope boundaries

- **In scope:** tenant preparation, identity/licensing/endpoint configuration, DNS cutover, pilot/wave orchestration, and validation for a **1:1-domain Exchange Online move within GCC High**.
- **Out of scope / deferred:** the **internals of any third-party migration tool** (deferred to that vendor's GCC High documentation); DoD (L5) endpoints (this edition targets GCC High L4); SharePoint/OneDrive/Teams data migration (Exchange-focused).
- **Hard constraint:** native cross-cloud (Commercial↔GCC High) mailbox migration is **not supported** — use a third-party tool or PST for cross-cloud mail data.
