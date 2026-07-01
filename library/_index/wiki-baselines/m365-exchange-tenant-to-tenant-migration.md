# Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

> **Version 1.0.0** · Category: Migrations · Solution code: EXOMIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

## The situation

Organizations frequently need to consolidate or separate Microsoft 365 environments — after a merger or acquisition, a divestiture, a rebrand, or a move off a managed provider's shared tenant. The hardest and most visible part of that change is **email**: every user's mailbox, every calendar, and the company's primary email domain must move from one Microsoft 365 tenant to another **without** users losing mail, losing their email address, or suffering prolonged downtime.

## The challenge

A Microsoft 365 domain can live in only **one** tenant at a time. The same domain (for example `contoso.com`) cannot be verified in both the old and new tenants simultaneously. That single constraint makes a tenant-to-tenant migration fundamentally a **coordination problem**: mailboxes must be copied while the domain still lives in the old tenant, mail must keep flowing to the right place during the move, and there is one unavoidable cutover moment when the domain is removed from the old tenant and added to the new one. Done badly, this produces lost mail, bounced messages, broken Outlook clients, and an extended outage. Done well, users barely notice.

## The solution

This is a complete, runbook-grade methodology that moves Exchange Online mailboxes — user, shared, and resource — between two Microsoft 365 tenants and then performs a **1:1 domain cutover** so users keep their exact email addresses. It uses **Quest On Demand Migration for Exchange** as the purpose-built migration engine (with native and alternative tooling documented), and a proven eight-phase model: **Assess → Plan → Prepare → Pilot → Migrate → Cutover → Validate → Decommission**.

The package delivers:
- A precise requirements checklist (no prerequisite assumed) and a category baseline.
- An exact, ordered runbook in which every object — projects, waves, service accounts, connectors — is named and reused consistently.
- Five PowerShell automation scripts for discovery, validation, reporting, address/permission remediation, and coexistence setup.
- Test gates for every phase and a formal acceptance gate, plus best-practices and troubleshooting guides.

## How downtime is minimized

Mailbox content is **pre-staged** (bulk-copied) while users keep working in the old tenant, then kept current with scheduled **delta passes**. Mail-flow **coexistence** keeps messages reaching the right mailbox throughout. The only true downtime is the short, scheduled **cutover window** for the domain and DNS change — not the days of bulk copying.

## The outcome

- Users keep their `name@company.com` addresses — no renaming.
- No lost mail, calendars, or contacts — validated by item-count parity and acceptance testing.
- A predictable, low-downtime cutover executed inside a planned change window.
- A fully documented, auditable migration with CSV evidence at every stage.

## Business case

A botched email migration is one of the most damaging IT events an organization can experience — it is highly visible, affects everyone, and erodes confidence immediately. This solution converts a high-risk, one-shot project into a **repeatable, gated, evidence-backed process**, dramatically reducing the risk of data loss and downtime while giving leadership a clear, phase-by-phase view of progress and a defined point of no return. It pays for itself the first time it prevents a single failed cutover.


---


# 1. Solution Overview — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

## What this solution is

This solution is a complete, runbook-grade methodology for migrating **Exchange Online mailboxes** from one Microsoft 365 tenant (the **source** tenant) to a second Microsoft 365 tenant (the **target** tenant), and then performing a **1:1 domain cutover** — the same primary SMTP domain (for example `contoso.com`) is **removed from the source tenant** and **added and verified in the target tenant**, so users keep their exact email addresses after the move.

The scope is deliberately **email-focused**: user mailboxes, shared mailboxes, resource mailboxes (rooms and equipment), calendars, contacts, distribution groups, mail-flow coexistence during the transition, and the domain move itself. SharePoint Online, OneDrive, Microsoft Teams, and broader Azure/Entra workload migration are **out of scope** for this product and are covered by a separate solution.

The primary migration engine documented here is **Quest On Demand Migration for Exchange**, which is the appropriate purpose-built tool for Exchange Online tenant-to-tenant moves (it performs cross-tenant mailbox copy, scheduling, delta synchronization, and coexistence). Native methods and the alternatives **ShareGate** and **BitTitan MigrationWiz** are referenced where relevant so the approach can be adapted to the tooling an organization already owns.

## The source → target 1:1 domain model

A tenant-to-tenant migration is fundamentally different from an on-premises-to-cloud migration because **a domain can exist in only one Microsoft 365 tenant at a time**. The same DNS domain (`contoso.com`) cannot be verified in both the source and target tenants simultaneously. This single constraint drives the entire design:

1. **Mailboxes are copied first** while the primary domain still lives in the source tenant. Target mailboxes are provisioned on a neutral address — either the target tenant's default `target.onmicrosoft.com` routing address or a dedicated **temporary routing/coexistence domain** (for example `contoso-target.onmicrosoft.com` or a registered `contoso-migration.com`).
2. **Coexistence** keeps mail flowing to the right place and (optionally) keeps free/busy calendar lookups working while both tenants hold copies of the users.
3. **At cutover**, after all objects referencing the domain are cleared from the source, the domain is **removed from the source tenant**, then **added and verified in the target tenant**, the **primary SMTP address is stamped** onto the migrated mailboxes, and **MX + Autodiscover DNS** are repointed to the target.

This is what "1:1 domain" means: a one-for-one move of the production vanity domain from source to target, with no permanent renaming of user addresses.

## How it works (end to end)

The migration follows the **standard migration model**, expressed here in eight phases:

| Phase | Goal |
|-------|------|
| **Assess** | Inventory the source tenant; size mailboxes; identify dependencies, shared mailboxes, groups, and forwarding rules. |
| **Plan** | Decide waves, routing domain, coexistence approach, cutover window, and rollback. |
| **Prepare** | Stand up the target tenant, licensing, service accounts, routing domain, and Quest On Demand project. |
| **Pilot** | Migrate a small, representative pilot wave and validate end-to-end before touching production at scale. |
| **Migrate** | Pre-stage mailbox content in waves, then run delta passes to catch changes. |
| **Cutover** | Perform the 1:1 domain move, stamp primary addresses, and repoint MX/Autodiscover. |
| **Validate** | Confirm mail flow, content parity, free/busy, and client reconnection. |
| **Decommission** | Convert/remove source mailboxes, retire connectors, and close out the source tenant footprint. |

This maps to the house "Assess → Configure → Pilot → Validate → Expand" pattern, adapted for a project with an irreversible cutover moment.

## Coexistence during the move

Because the migration runs over days or weeks, the two tenants must coexist:

- **Mail flow coexistence** — Until cutover, the source tenant owns the primary domain and therefore receives inbound mail. A **source→target connector** (named `Coexistence – Source→Target Connector`) and **target→source connector** (named `Coexistence – Target→Source Connector`) plus mail-routing on the routing domain ensure that messages reach the correct mailbox no matter which side the user has been migrated to. Migrated users have a **target address** while inbound public mail still arrives at the **source** domain, so the source forwards/relays to the target via the routing address until cutover.
- **Free/busy and GAL coexistence (optional)** — Quest On Demand can synchronize the Global Address List and broker free/busy calendar lookups so that users in both tenants can still book meetings with each other during the transition. This is recommended for migrations that span more than a few days or where cross-tenant scheduling is business-critical.

## Tooling

- **Primary: Quest On Demand Migration for Exchange** — SaaS migration platform. Connects to both tenants via consented enterprise applications, discovers and maps mailboxes, copies mail/calendar/contacts/tasks, runs scheduled delta syncs, and provides per-wave reporting. It is the recommended engine because it is built specifically for **cross-tenant Exchange** and handles delta passes and coexistence cleanly.
- **Native methods** — Microsoft's **cross-tenant mailbox migration** (MRS-based, using a migration application, organization relationship, and `New-MigrationBatch` with the cross-tenant endpoint) is a license-included option when both tenants meet the prerequisites. It is referenced as the no-third-party-cost path, with the trade-off of more manual orchestration and weaker built-in coexistence/reporting.
- **Alternatives** — **ShareGate** and **BitTitan MigrationWiz** are mature third-party options; the phased methodology, naming conventions, and cutover steps in this solution apply to them with tool-specific substitutions in the migration-engine steps.

## Benefits

- **Users keep their email addresses** — the 1:1 domain move means `firstname.lastname@contoso.com` is identical before and after.
- **Minimal downtime** — pre-staging plus delta passes means the only true "downtime" is the short cutover window for the domain/MX change, not the bulk copy.
- **Predictable, repeatable** — every object is named, every step is ordered, and validation gates prevent advancing on a broken state.
- **Coexistence preserves business continuity** — mail keeps flowing and calendars keep working while the move is in progress.
- **Auditable** — discovery, validation, and reporting scripts produce CSV evidence at every stage.

## Honest limitations

- **A domain cannot be in two tenants at once.** There is an unavoidable cutover moment; the design minimizes — but cannot eliminate — it.
- **Passwords and identity do not migrate by content copy.** Users get new credentials in the target tenant (or identity is provisioned via directory sync / a provisioning process); plan a credential-communication and MFA-re-registration step.
- **MFA and Conditional Access** on the migration service accounts will block automated migration unless those accounts are explicitly excluded for the migration window.
- **Microsoft throttling** caps per-mailbox and per-tenant throughput; large mailboxes and large tenants take real wall-clock time. Pre-staging is essential.
- **Some item types and metadata** (certain rules, some recoverable-items nuances, archive specifics, litigation hold) require explicit handling and verification.
- **Teams chat, SharePoint, OneDrive, and Power Platform are NOT migrated** by this solution.

## Who should run this

A competent Microsoft 365 administrator with Global Administrator access to **both** tenants, control of the **public DNS** for the migrating domain, and a defined change-control window. The remaining documents in this package provide the exact requirements, the ordered runbook, the test gates, best practices, troubleshooting, and the supporting PowerShell automation.


---


# 2. Requirements — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

This section lists every prerequisite for the migration. **Do not assume any of these exist.** Each requirement has four parts: **Description**, **Why required**, **How to verify**, and **How to implement if missing**. Requirements R1–R12 are specific to this Exchange Online tenant-to-tenant solution; the category-wide baseline is in `global-requirements-azure-solutions.md` and must also be satisfied.

Throughout this document the migrating domain is referred to as `contoso.com`, the source tenant default domain as `source.onmicrosoft.com`, and the target tenant default domain as `target.onmicrosoft.com`. Substitute your real values.

---

## R1 — Target Microsoft 365 tenant with Exchange Online licensing for every migrated user

**Description.** A fully provisioned target Microsoft 365 tenant, and an assigned license that includes an **Exchange Online** plan (Exchange Online Plan 1/Plan 2, or a Microsoft 365 Business/Enterprise SKU that bundles it) for **every** user, shared mailbox owner, and resource that will hold a mailbox after migration.

**Why required.** A target mailbox cannot be provisioned or receive migrated content without an Exchange Online service plan enabled on the target account. Shared and resource mailboxes do not need a license up to 50 GB, but their target objects must still exist.

**How to verify.**
- In the **Microsoft 365 admin center** (https://admin.microsoft.com) → **Billing → Licenses**, confirm you own enough Exchange-bearing licenses to cover the user count from discovery (see `EXOMIG-Discovery.ps1`).
- Run `EXOMIG-Validation.ps1` in pre-flight mode; it reports whether target users have an Exchange Online plan enabled.

**How to implement if missing.**
- In the **Microsoft 365 admin center** → **Billing → Purchase services**, acquire the required Exchange Online or Microsoft 365 licenses.
- Assign them per-user under **Users → Active users → (user) → Licenses and apps**, or in bulk via group-based licensing under **Microsoft Entra admin center** (https://entra.microsoft.com) → **Identity → Groups**.

---

## R2 — Global Administrator access in BOTH the source and target tenants

**Description.** Standing **Global Administrator** (or the equivalent least-privilege set: Exchange Administrator + an admin able to consent to enterprise applications + Domains management) in **both** tenants for the duration of the project.

**Why required.** You must add/remove/verify domains, create service accounts and connectors, consent the migration application, and run Exchange Online PowerShell against both tenants. The domain move specifically requires domain-management rights on both sides.

**How to verify.**
- In each tenant's **Microsoft Entra admin center** → **Identity → Roles & admins → Roles**, open **Global Administrator** and confirm your migration operator is a member.
- Confirm you can sign in to https://admin.exchange.microsoft.com (Exchange admin center) in both tenants.

**How to implement if missing.**
- Have an existing Global Admin in each tenant assign the role under **Roles & admins → Global Administrator → Add assignments**.
- Prefer creating dedicated, named operator accounts rather than using a person's daily account.

---

## R3 — A dedicated migration service account in each tenant

**Description.** One named, dedicated service account per tenant — `svc-quest-migration@source.onmicrosoft.com` in the source and `svc-quest-migration@target.onmicrosoft.com` in the target — used for migration automation and (where the engine uses it) impersonation/application access.

**Why required.** Using a dedicated account isolates migration activity, allows targeted MFA/Conditional Access exclusions (R8), and keeps an auditable identity for all migration operations. It avoids breaking a human admin's MFA posture.

**How to verify.**
- In each **Microsoft 365 admin center** → **Users → Active users**, confirm `svc-quest-migration` exists, is enabled, and (target side) has any required role/permissions.
- Confirm it can sign in non-interactively for the chosen engine (Quest typically uses app-based consent rather than the password, but a service identity is still required).

**How to implement if missing.**
- In each **Microsoft 365 admin center** → **Users → Active users → Add a user**, create `svc-quest-migration`.
- Grant the minimum roles the engine requires (for Quest On Demand, the consent flow grants app permissions; for native MRS, the migration account needs the **Migration** and **Mail Recipients** management roles and, where used, **ApplicationImpersonation**/RBAC application access).
- Set a strong password and store it in a secrets vault; do **not** put it in scripts.

---

## R4 — Quest On Demand Migration subscription and tenant connections

**Description.** An active **Quest On Demand** subscription with **Migration for Exchange** entitlement, plus both tenants **connected** (consented) to the Quest On Demand workspace.

**Why required.** This is the primary migration engine. Without both tenant connections, Quest cannot discover, map, copy, or delta-sync mailboxes.

**How to verify.**
- In the **Quest On Demand portal** (https://login.quest-on-demand.com) → **Tenants**, confirm both the source and target tenants appear with status **Connected/Consented**.
- In **Migration → Exchange**, confirm the Migration for Exchange module is available.

**How to implement if missing.**
- Procure/activate the Quest On Demand Migration for Exchange subscription.
- In the Quest On Demand portal → **Tenants → Add Tenant**, run the consent flow for the **source** tenant (sign in with a source Global Admin and accept the enterprise-application permissions), then repeat for the **target** tenant.
- If using an alternative engine (native MRS, ShareGate, BitTitan), satisfy that engine's equivalent connection prerequisites instead.

---

## R5 — Ownership of, and DNS control over, the migrating domain (`contoso.com`)

**Description.** Administrative control of the **public DNS zone** for `contoso.com` (at the registrar or DNS host), sufficient to add TXT verification records and to change MX, Autodiscover (CNAME), SPF, DKIM, and DMARC records.

**Why required.** The 1:1 domain move requires adding a **TXT verification record** to prove ownership when the domain is added to the target tenant, and repointing **MX** and **Autodiscover** at cutover. Mail-flow security records (SPF/DKIM/DMARC) must also be updated for the target tenant.

**How to verify.**
- Confirm you can log in to the DNS host for `contoso.com` and edit records.
- Note the current **TTL** values on the MX and Autodiscover records (these will be lowered before cutover — see best practices).

**How to implement if missing.**
- Obtain delegated access to the DNS zone from whoever controls the registrar/DNS host **before** the cutover phase. The migration cannot complete the domain move without it.

---

## R6 — Source tenant administrative access and ability to clear domain references

**Description.** The ability, in the source tenant, to **remove the domain** from all objects (user UPNs/proxy addresses, distribution group addresses, shared/resource mailbox addresses, accepted-domain connectors, app/SharePoint references) so the domain can be removed.

**Why required.** Microsoft 365 will **refuse to remove a domain** while any object still references it. Clearing references is a hard precondition of the cutover.

**How to verify.**
- In the source **Microsoft 365 admin center** → **Settings → Domains → contoso.com**, the portal lists any objects still using the domain. Run the source discovery (`EXOMIG-Discovery.ps1`) to enumerate everything carrying `@contoso.com`.

**How to implement if missing.**
- Plan, as part of the runbook, to re-stamp all source objects onto `source.onmicrosoft.com` (UPN and primary SMTP) and remove `@contoso.com` proxy addresses immediately before the domain removal step. The remediation script assists with re-stamping.

---

## R7 — Network throughput and connectivity to Microsoft 365 / Quest endpoints

**Description.** Reliable network egress to Exchange Online and the migration engine's service endpoints, with enough bandwidth to move the total mailbox volume within the project window.

**Why required.** Quest On Demand copies data tenant-to-tenant through its cloud service; native MRS copies cloud-to-cloud. Throughput governs how long pre-staging takes and whether delta passes keep up.

**How to verify.**
- Sum mailbox sizes from `EXOMIG-Discovery.ps1` to get total GB. Estimate wall-clock time against realistic per-mailbox throughput (Microsoft throttling typically dominates, not raw bandwidth).
- Confirm no proxy/firewall blocks the Quest On Demand or Microsoft 365 service URLs.

**How to implement if missing.**
- Allow-list the required service endpoints on the corporate firewall/proxy.
- Size waves and the schedule to fit the available throughput; start pre-staging early.

---

## R8 — MFA / Conditional Access exclusions for the migration service accounts (migration window only)

**Description.** Temporary, scoped exclusion of `svc-quest-migration` (both tenants) from MFA and any Conditional Access policy that would block non-interactive or service access during the migration window.

**Why required.** Conditional Access and per-user MFA will block the engine's automated authentication, causing throttled or failed mailboxes. The exclusion must be **scoped to the service accounts only** and **removed after the project**.

**How to verify.**
- In each **Microsoft Entra admin center** → **Protection → Conditional Access → Policies**, review each policy's **Users → Exclude** list for `svc-quest-migration`.
- In **Protection → Authentication methods / per-user MFA**, confirm the service account's state matches the engine's needs.

**How to implement if missing.**
- Add `svc-quest-migration` to the **Exclude** list of the relevant Conditional Access policies (do **not** disable the policies tenant-wide).
- Document the change in change-control and add a **decommission task** to reverse it after cutover.

---

## R9 — A temporary routing / coexistence domain

**Description.** A neutral routing target used to receive migrated mail before cutover — either the target tenant's built-in `target.onmicrosoft.com`, or a dedicated registered domain such as `contoso-target.onmicrosoft.com` / `contoso-migration.com`, added as an **accepted domain** where needed.

**Why required.** Because `contoso.com` stays in the source tenant until cutover, migrated mailboxes need an address that resolves in the target tenant so coexistence mail flow can deliver to them.

**How to verify.**
- In the target **Exchange admin center** → **Mail flow → Accepted domains**, confirm the routing domain is present (the `*.onmicrosoft.com` domain always exists by default).

**How to implement if missing.**
- Use the default `target.onmicrosoft.com` (no setup needed), or register and add a dedicated routing domain via **Microsoft 365 admin center → Settings → Domains → Add domain** and configure it as an accepted domain. `EXOMIG-Set-Coexistence.ps1` can add the accepted domain.

---

## R10 — Target mailbox provisioning (or identity sync) and mail-routing readiness

**Description.** A defined method to create the target mailbox objects with the correct routing address before content copy — either manual/scripted provisioning, the migration engine's auto-provisioning, or directory synchronization/identity provisioning if a hybrid identity model is used.

**Why required.** Content cannot be copied to a mailbox that does not exist. The target object must carry a routing address (R9) so coexistence works.

**How to verify.**
- Run `EXOMIG-Validation.ps1`; it checks that each mapped target user has a provisioned mailbox.

**How to implement if missing.**
- Let Quest On Demand provision target mailboxes during the project, or pre-create them via the **Microsoft 365 admin center** / Microsoft Graph / Exchange Online PowerShell, ensuring each carries `user@target.onmicrosoft.com` (or the dedicated routing domain) as a routable address.

---

## R11 — Source-to-target inventory and mapping

**Description.** A complete mapping file: source UPN / primary SMTP / aliases / mailbox type → the corresponding target UPN / routing address. Includes users, shared mailboxes, resource (room/equipment) mailboxes, and group memberships.

**Why required.** The migration engine and the re-stamping/permission scripts are driven by this mapping. Errors here cause mail to land in the wrong mailbox or addresses to be stamped incorrectly at cutover.

**How to verify.**
- Generate the source inventory with `EXOMIG-Discovery.ps1` (exports mailboxes, sizes, types, aliases, accepted domains, groups to CSV) and confirm every source object has a target row.

**How to implement if missing.**
- Build the mapping CSV from the discovery export. Reconcile shared/resource mailboxes and groups explicitly — they are frequently missed.

---

## R12 — Mailbox permission and delegation inventory (FullAccess / SendAs / SendOnBehalf / forwarding)

**Description.** A record of all mailbox-to-mailbox permissions (FullAccess, SendAs, Send-on-Behalf), calendar delegation, and forwarding rules in the source tenant.

**Why required.** Cross-tenant migration does **not** automatically reproduce inter-mailbox permissions or delegation in the target; these must be re-applied. Forwarding rules can also cause mail loops during coexistence if not reviewed.

**How to verify.**
- `EXOMIG-Discovery.ps1` exports permissions and delegation alongside the mailbox inventory; review the permissions CSV.

**How to implement if missing.**
- Capture permissions during discovery and re-apply them in the target after migration using `EXOMIG-Remediation.ps1` (driven by the permissions CSV, `-Apply` to commit).

---

## Requirements summary

| ID | Requirement | Gating phase |
|----|-------------|--------------|
| R1 | Target tenant + Exchange Online licensing for all users | Prepare |
| R2 | Global Admin in both tenants | Assess |
| R3 | Dedicated migration service account per tenant (`svc-quest-migration`) | Prepare |
| R4 | Quest On Demand subscription + both tenants connected | Prepare |
| R5 | DNS control of the migrating domain | Cutover |
| R6 | Source admin access + ability to clear domain references | Cutover |
| R7 | Network throughput to M365/Quest endpoints | Migrate |
| R8 | MFA/Conditional Access exclusions for service accounts | Prepare |
| R9 | Temporary routing/coexistence domain | Prepare |
| R10 | Target mailbox provisioning / identity sync | Prepare |
| R11 | Source→target inventory and mapping | Assess/Plan |
| R12 | Mailbox permission / delegation inventory | Assess/Plan |

All of the above are in addition to the category baseline in `global-requirements-azure-solutions.md`.


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


# 3. Implementation — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

This is the ordered runbook for the full migration. Execute the phases in order: **Assess → Plan → Prepare → Pilot → Migrate → Cutover → Validate → Decommission**. Do not advance a phase until its exit gate (see `05-testing.md`) passes. Every object you create is named with the convention `<Purpose> – <Scope> – <Stage>`; reuse the exact names verbatim in later steps, testing, troubleshooting, and the scripts.

**Conventions used below**
- Source vanity domain: `contoso.com` · Source default: `source.onmicrosoft.com`
- Target default / routing domain: `target.onmicrosoft.com`
- Migration service accounts: `svc-quest-migration@source.onmicrosoft.com`, `svc-quest-migration@target.onmicrosoft.com`
- Quest On Demand project: **`EXO T2T – Contoso – Migration Project`**
- Pilot wave: **`EXO T2T – Pilot Wave`** · Bulk waves: **`EXO T2T – Wave 1`**, **`EXO T2T – Wave 2`**, … 
- Coexistence connectors: **`Coexistence – Source→Target Connector`**, **`Coexistence – Target→Source Connector`**
- Mail-enabled security group for pilot: **`EXO T2T – Pilot Members`**

> Replace `contoso.com` / `*.onmicrosoft.com` and the wave list with your real values, but keep the naming **pattern** identical so downstream steps and scripts line up.

---

## Phase 1 — Assess

### 1.1 Confirm access to both tenants
1. Sign in to the **source** Exchange admin center (https://admin.exchange.microsoft.com) and the **source** Microsoft 365 admin center (https://admin.microsoft.com); confirm Global Admin (R2).
2. Repeat for the **target** tenant.

### 1.2 Run source discovery
1. On an operator workstation, install the Exchange Online PowerShell module: `Install-Module ExchangeOnlineManagement`.
2. Run **`scripts\EXOMIG-Discovery.ps1`** against the source tenant. It exports CSVs of: all mailboxes (user/shared/room/equipment), sizes, item counts, aliases, accepted domains, distribution groups, Microsoft 365 groups, and mailbox permissions/delegation.
3. Save the exports as the **assessment baseline** (also serves G6 backup posture).

### 1.3 Build the source→target mapping (R11) and permission inventory (R12)
1. From the discovery CSVs, build the mapping file `mapping.csv` with columns: `SourceUPN, SourcePrimarySMTP, MailboxType, TargetUPN, TargetRoutingAddress, FinalPrimarySMTP, Wave`.
2. Build `permissions.csv` from the permissions export: `TargetMailbox, Trustee, AccessRight` (FullAccess / SendAs / SendOnBehalf).
3. Reconcile shared mailboxes, room/equipment mailboxes, distribution groups, and forwarding rules explicitly.

**Exit gate:** complete inventory; every source object has a target mapping row. (Test T1.)

---

## Phase 2 — Plan

### 2.1 Decide waves
1. Group users into waves by department/dependency so people who collaborate move together. Assign each row in `mapping.csv` a `Wave` value: `EXO T2T – Pilot Wave`, `EXO T2T – Wave 1`, etc.
2. Keep the pilot wave small (5–15 representative mailboxes, including at least one shared and one resource mailbox).

### 2.2 Decide routing domain and coexistence model
1. Choose the routing domain (R9): default `target.onmicrosoft.com` or a dedicated routing domain.
2. Decide whether to enable GAL sync + free/busy coexistence (recommended for multi-week projects).

### 2.3 Plan the cutover and rollback
1. Choose the cutover window (low-mail-volume hours) and lower DNS TTLs in advance (see `07-best-practices.md`).
2. Capture current DNS (MX, Autodiscover CNAME, SPF, DKIM, DMARC) and write the rollback plan (G6).

**Exit gate:** approved plan, wave list, routing decision, cutover window, rollback plan. (Test T2.)

---

## Phase 3 — Prepare

### 3.1 Prepare the target tenant and licensing
1. In the **target** Microsoft 365 admin center → **Billing → Licenses**, confirm Exchange Online licensing for all migrated users (R1).
2. Assign licenses to target users (per-user under **Users → Active users → (user) → Licenses and apps**, or group-based via **Microsoft Entra admin center → Identity → Groups**).

### 3.2 Add the routing/coexistence domain (if using a dedicated one)
1. In the **target** Microsoft 365 admin center → **Settings → Domains → Add domain**, add the routing domain and complete TXT verification; or simply use the built-in `target.onmicrosoft.com`.
2. In the **target** Exchange admin center → **Mail flow → Accepted domains**, confirm it is present (or add it with `EXOMIG-Set-Coexistence.ps1 -AddRoutingDomain`).

### 3.3 Create the migration service accounts (R3)
1. In the **source** Microsoft 365 admin center → **Users → Active users → Add a user**, create **`svc-quest-migration@source.onmicrosoft.com`**.
2. In the **target** Microsoft 365 admin center → **Users → Active users → Add a user**, create **`svc-quest-migration@target.onmicrosoft.com`**.
3. Grant each the minimum roles the engine requires (Quest uses app consent; native MRS needs the **Migration**/**Mail Recipients** roles and application access).

### 3.4 Exclude the service accounts from MFA / Conditional Access (R8)
1. In each **Microsoft Entra admin center** → **Protection → Conditional Access → Policies**, edit each blocking policy → **Users → Exclude** → add `svc-quest-migration`. Do **not** disable policies tenant-wide.
2. Record the exclusion in change-control and add a reversal task to Decommission.

### 3.5 Connect both tenants in Quest On Demand and create the project
1. In the **Quest On Demand portal** (https://login.quest-on-demand.com) → **Tenants → Add Tenant**, run the consent flow for the **source** tenant (source Global Admin signs in and accepts), then repeat for the **target** tenant. Confirm both show **Connected** (R4).
2. In **Migration → Exchange → New Project**, create **`EXO T2T – Contoso – Migration Project`**, selecting source and target tenants.
3. Inside the project, create the pilot wave object **`EXO T2T – Pilot Wave`** (and, later, `EXO T2T – Wave 1`, etc.).

### 3.6 Configure coexistence mail-flow connectors
1. Create the source→target relay: in the **source** Exchange admin center → **Mail flow → Connectors → Add a connector** (From: Office 365 → To: Partner organization), name it **`Coexistence – Source→Target Connector`**, routing mail for migrated users to the target routing domain.
2. Create the reverse: in the **target** Exchange admin center → **Mail flow → Connectors**, name it **`Coexistence – Target→Source Connector`**.
3. Alternatively run **`scripts\EXOMIG-Set-Coexistence.ps1`** (use `-WhatIf` first) to create both connectors and the accepted domain.
4. (Optional) In Quest On Demand, enable **GAL synchronization** and **free/busy coexistence** for the project.

**Exit gate:** target licensed; routing domain present; service accounts created and CA-excluded; both tenants connected in Quest; project + pilot wave created; coexistence connectors created. (Test T3.)

---

## Phase 4 — Pilot

### 4.1 Provision and map pilot targets
1. Ensure the pilot users' target mailboxes exist (R10) carrying a routing address (`user@target.onmicrosoft.com`). Let Quest auto-provision or pre-create them.
2. In the project, add the pilot users to **`EXO T2T – Pilot Wave`** using `mapping.csv` (filter `Wave = EXO T2T – Pilot Wave`).
3. Add pilot members to the mail-enabled security group **`EXO T2T – Pilot Members`** for comms/testing.

### 4.2 Pre-flight validation
1. Run **`scripts\EXOMIG-Validation.ps1`** in pre-flight mode against the pilot mappings: confirms target licensing, accepted/verified domains, and provisioned mailboxes.

### 4.3 Migrate the pilot wave
1. In Quest On Demand → project → **`EXO T2T – Pilot Wave`**, start the **migration (copy)** task.
2. When the initial copy completes, run a **delta pass** to catch changes.

### 4.4 Validate the pilot
1. Run **`scripts\EXOMIG-Validation.ps1`** in post-migration mode for a sample of pilot users: item-count parity (source vs target) for mail/calendar/contacts.
2. Manually verify in the target: a pilot user can open Outlook on the web (https://outlook.office.com) and see migrated mail, calendar, and contacts.
3. Verify coexistence mail flow both directions using `EXO T2T – Pilot Members` (send source→pilot and pilot→source).

**Exit gate:** pilot content parity, coexistence mail flow both ways, free/busy (if enabled). No data loss. (Test T4.)

---

## Phase 5 — Migrate (bulk, in waves)

### 5.1 Pre-stage each wave
1. For each wave (`EXO T2T – Wave 1`, `EXO T2T – Wave 2`, …), add its mapped users in Quest On Demand and start the **initial copy** well ahead of cutover. Pre-staging copies the bulk of data while users keep working in the source.

### 5.2 Run delta passes
1. On a schedule (e.g. nightly), run **delta passes** for each pre-staged wave so the target stays current with source changes.
2. Track progress with **`scripts\EXOMIG-Report.ps1`** (per-wave counts, completed/failed, GB moved).

### 5.3 Re-apply permissions and delegation
1. After each wave's mailboxes are migrated, re-apply FullAccess/SendAs/SendOnBehalf in the target using **`scripts\EXOMIG-Remediation.ps1`** driven by `permissions.csv` (run with default `-WhatIf`, then `-Apply`).

**Exit gate:** all waves pre-staged; delta passes current (small, fast deltas); permissions re-applied; report shows near-100% complete, zero unresolved failures. (Test T5.)

---

## Phase 6 — Cutover (the 1:1 domain move)

> This is the irreversible moment. Perform in the change window, after a final delta. Lower DNS TTLs at least 24–48h in advance (best practices).

### 6.1 Final delta pass
1. Run a **final delta** for all waves so the target is fully caught up immediately before the domain moves.

### 6.2 Clear references and remove the domain from the source tenant (R6)
1. In the **source** tenant, re-stamp every object that uses `@contoso.com` onto `source.onmicrosoft.com`:
   - User UPNs and primary SMTP → `source.onmicrosoft.com`; remove `@contoso.com` proxy addresses.
   - Distribution groups, shared/resource mailboxes → remove `@contoso.com` addresses.
   - Review/remove any source connectors, transport rules, or app references using the domain.
2. In the **source** Microsoft 365 admin center → **Settings → Domains → contoso.com → Remove domain**. Microsoft will block removal if any reference remains — resolve each blocker it lists, then retry.

### 6.3 Add and verify the domain in the target tenant
1. In the **target** Microsoft 365 admin center → **Settings → Domains → Add domain**, enter `contoso.com`.
2. Add the provided **TXT verification record** at the DNS host (R5), wait for propagation, and click **Verify**. (Domain verification can only succeed once the source has released the domain — step 6.2 must complete first.)

### 6.4 Stamp primary SMTP addresses in the target
1. With `contoso.com` now verified in the target, stamp each migrated mailbox's **primary SMTP** to its final `@contoso.com` address using **`scripts\EXOMIG-Remediation.ps1 -Apply`** driven by `mapping.csv` (`FinalPrimarySMTP`).
2. Confirm `@contoso.com` is the **primary** and the routing address remains as a secondary alias.

### 6.5 Cut over MX and Autodiscover DNS
1. At the DNS host for `contoso.com`:
   - Repoint the **MX** record to the target tenant's Exchange Online endpoint (`contoso-com.mail.protection.outlook.com`).
   - Repoint **Autodiscover** CNAME to `autodiscover.outlook.com`.
   - Update **SPF** to the target's `include:spf.protection.outlook.com`, publish target **DKIM** CNAMEs (enable DKIM in the target Defender/Exchange portal), and review **DMARC**.
2. In the target Exchange admin center → **Settings → Domains**, follow the recommended DNS records for the now-verified `contoso.com`.

### 6.6 Tidy coexistence
1. Once mail is flowing directly to the target, disable/remove the coexistence connectors **`Coexistence – Source→Target Connector`** and **`Coexistence – Target→Source Connector`** when no longer needed.

**Exit gate:** domain removed from source, verified in target; primary SMTP stamped; MX/Autodiscover/SPF/DKIM repointed; mail delivering to target. (Test T6.)

---

## Phase 7 — Validate

1. Confirm inbound external mail to `user@contoso.com` lands in the **target** mailbox.
2. Confirm outbound mail from the target shows `@contoso.com` as the sender and passes SPF/DKIM/DMARC at external recipients.
3. Confirm Outlook (desktop and mobile) reconnects via Autodiscord to the target mailbox; reprofile any clients that don't auto-reconnect.
4. Run **`scripts\EXOMIG-Validation.ps1`** post-migration for a broad sample: item-count parity, addresses correct, permissions present.
5. Confirm free/busy and delegation work within the target tenant.

**Exit gate:** all acceptance tests in `05-testing.md` PASS. (Test T7, acceptance gate.)

---

## Phase 8 — Decommission

1. **Convert/remove source mailboxes** — once validation is signed off and a retention/grace period has passed, convert source user mailboxes to shared (for short-term reference) or remove them; offboard source licenses.
2. **Remove coexistence objects** — delete the coexistence connectors and any routing-domain artifacts no longer needed.
3. **Reverse the MFA / Conditional Access exclusions (R8)** — remove `svc-quest-migration` from the CA exclude lists in both tenants.
4. **Disable/remove the migration service accounts** — `svc-quest-migration` in both tenants, after final reporting.
5. **Disconnect tenants in Quest On Demand** if the project is closed; revoke the consented enterprise application if not needed.
6. **Archive evidence** — keep the discovery, validation, and report CSVs as the project record.

**Exit gate:** source footprint retired, temporary exclusions reversed, service accounts removed, evidence archived. (Test T8.)

---

## Object name register (reuse verbatim)

| Object | Name |
|--------|------|
| Quest On Demand project | `EXO T2T – Contoso – Migration Project` |
| Pilot wave | `EXO T2T – Pilot Wave` |
| Bulk waves | `EXO T2T – Wave 1`, `EXO T2T – Wave 2`, … |
| Source service account | `svc-quest-migration@source.onmicrosoft.com` |
| Target service account | `svc-quest-migration@target.onmicrosoft.com` |
| Source→target connector | `Coexistence – Source→Target Connector` |
| Target→source connector | `Coexistence – Target→Source Connector` |
| Pilot mail-enabled security group | `EXO T2T – Pilot Members` |


---


# 5. Testing — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

Each test below is a **phase exit gate**. Run the test, record the result, and only advance when the gate is **PASS**. Tests reference the named objects from `03-implementation.md` verbatim. The final **Acceptance Gate** (T7) must pass before the project is declared complete.

---

## T1 — Assessment completeness gate (exit Assess)

**Purpose.** Confirm the source is fully inventoried and mapped.

**Steps.**
1. Run `scripts\EXOMIG-Discovery.ps1` against the source tenant.
2. Confirm `mapping.csv` (R11) has a target row for every source mailbox, shared mailbox, room/equipment mailbox, and group.
3. Confirm `permissions.csv` (R12) lists FullAccess/SendAs/SendOnBehalf.

**PASS:** every source object has a mapping row; permission inventory exists.
**FAIL:** any source object lacks a mapped target, or permission export is incomplete → return to Assess.

---

## T2 — Plan approval gate (exit Plan)

**Steps.**
1. Confirm waves are assigned (`Wave` column populated; `EXO T2T – Pilot Wave` defined).
2. Confirm routing domain chosen (R9) and coexistence model decided.
3. Confirm cutover window, lowered-TTL plan, and written rollback plan exist (G5/G6).

**PASS:** approved plan with waves, routing decision, cutover window, rollback plan.
**FAIL:** any missing → return to Plan.

---

## T3 — Preparation readiness gate (exit Prepare)

**Steps.**
1. `EXOMIG-Validation.ps1` pre-flight: target users have Exchange Online plans (R1).
2. Confirm routing/coexistence domain is an accepted domain in the target.
3. Confirm `svc-quest-migration` exists in both tenants and is excluded from blocking Conditional Access policies (R8).
4. In Quest On Demand, confirm both tenants show **Connected** and `EXO T2T – Contoso – Migration Project` + `EXO T2T – Pilot Wave` exist (R4).
5. Confirm `Coexistence – Source→Target Connector` and `Coexistence – Target→Source Connector` exist.

**PASS:** all five confirmed.
**FAIL:** any missing → return to Prepare.

---

## T4 — Pilot validation gate (exit Pilot)

**Steps.**
1. After migrating + delta of `EXO T2T – Pilot Wave`, run `EXOMIG-Validation.ps1` post-migration for sample pilot users: **item-count parity** for mail, calendar, contacts (source vs target).
2. A pilot user opens https://outlook.office.com on the target and confirms migrated mail/calendar/contacts are present and correct.
3. Send a test message **source → pilot user** and **pilot user → source**; confirm both deliver (coexistence mail flow).
4. If free/busy coexistence is enabled, a source user looks up a pilot user's free/busy and vice versa.

**PASS:** parity within expected tolerance (no missing folders/items), mail flows both ways, free/busy works (if enabled), **no data loss**.
**FAIL:** content gaps, one-way or no mail flow, broken free/busy → diagnose (see `06-troubleshooting.md`), remediate, re-test before any bulk migration.

---

## T5 — Bulk migration readiness gate (exit Migrate)

**Steps.**
1. `EXOMIG-Report.ps1` shows every wave pre-staged and delta passes current (deltas small and fast).
2. Confirm permissions re-applied via `EXOMIG-Remediation.ps1` (spot-check FullAccess/SendAs in the target).
3. Report shows near-100% completed with **zero unresolved failed mailboxes**.

**PASS:** all waves staged, deltas current, permissions applied, no unresolved failures.
**FAIL:** stuck/failed mailboxes or stale deltas → remediate before scheduling cutover.

---

## T6 — Cutover verification gate (exit Cutover)

**Steps.**
1. Confirm a **final delta** ran immediately before cutover.
2. Confirm `contoso.com` is **removed** from the source (Settings → Domains no longer lists it) and **verified** in the target (Settings → Domains shows Healthy).
3. Confirm primary SMTP stamped: spot-check migrated mailboxes show `@contoso.com` as **primary** (`EXOMIG-Validation.ps1`).
4. Confirm DNS: `nslookup -type=mx contoso.com` resolves to the target endpoint; Autodiscover CNAME → `autodiscover.outlook.com`; SPF includes `spf.protection.outlook.com`; target DKIM published.
5. Send an external test message to `user@contoso.com`; confirm it lands in the **target** mailbox.

**PASS:** domain moved + verified, primary addresses stamped, MX/Autodiscover/SPF/DKIM correct, external mail delivers to target.
**FAIL:** domain won't remove/verify, wrong MX, or mail not delivering → `06-troubleshooting.md`.

---

## T7 — Acceptance Gate (exit Validate — project sign-off)

All of the following must be **PASS** to declare the migration complete:

| # | Acceptance criterion | PASS condition |
|---|----------------------|----------------|
| 1 | Mail flow both ways | External in to `@contoso.com` lands in target; outbound from target sends as `@contoso.com`. |
| 2 | Pilot/sample content parity | Item-count parity (mail/calendar/contacts) within tolerance for sampled users; no missing folders. |
| 3 | Free/busy | Cross-mailbox free/busy works within the target tenant. |
| 4 | Domain verified in target | `contoso.com` shows Healthy in target Settings → Domains; absent from source. |
| 5 | MX / Autodiscover correct | MX → target endpoint; Autodiscover → `autodiscover.outlook.com`; clients reconnect. |
| 6 | Delta caught up | Final delta complete; no pending changes; report shows complete. |
| 7 | No data loss | Validation parity + user spot-checks confirm no lost mail/calendar/contacts. |
| 8 | Outbound authentication | Outbound from target passes SPF/DKIM/DMARC at external recipients. |

**PASS:** all eight criteria met → proceed to Decommission.
**FAIL:** any criterion unmet → do not decommission; remediate first.

---

## T8 — Decommission completeness gate (exit Decommission)

**Steps.**
1. Source mailboxes converted/removed per plan; source licenses reclaimed.
2. Coexistence connectors removed; routing-domain artifacts cleaned.
3. `svc-quest-migration` removed from CA exclude lists in both tenants (R8 reversed).
4. Migration service accounts disabled/removed.
5. Discovery/validation/report CSVs archived.

**PASS:** all five confirmed.
**FAIL:** any temporary exclusion or service account still active → complete cleanup.


---


# 6. Troubleshooting — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

Use this guide top-down: start with the symptom, work through the ordered checks, and stop when the issue resolves. References to named objects (e.g. `Coexistence – Source→Target Connector`, `svc-quest-migration`) match `03-implementation.md` verbatim.

---

## 1. Tenant connection / authentication failures (Quest On Demand or PowerShell)

**Symptoms:** Quest On Demand shows a tenant as **Not connected / consent expired**; Exchange Online PowerShell sign-in fails; migration tasks immediately error with auth/permission messages.

**Diagnose, in order:**
1. **Service account state.** In each tenant's **Microsoft 365 admin center → Users → Active users**, confirm `svc-quest-migration` is **enabled** and the password is current.
2. **MFA / Conditional Access (most common cause).** In **Microsoft Entra admin center → Protection → Conditional Access → Policies**, confirm `svc-quest-migration` is in the **Exclude** list of every blocking policy (R8). A newly added or changed CA policy can silently re-block the account. Check **Sign-in logs** (Entra → Monitoring) for the account and read the failure reason.
3. **Consent / enterprise app.** In the Quest On Demand portal → **Tenants**, re-run the consent flow for the affected tenant (sign in as a Global Admin and re-accept). For native MRS, confirm the migration application and `New-MigrationEndpoint` are still valid.
4. **Roles.** Confirm the account still holds the roles the engine needs (Migration / Mail Recipients / application access for native; the consented app permissions for Quest).

**Resolve:** correct the CA exclusion or re-consent, then retry. Never disable CA tenant-wide — scope the exclusion to the service account.

---

## 2. Throttling / slow throughput

**Symptoms:** copy/delta passes crawl; mailboxes sit "in progress" for a long time; engine logs mention throttling or transient errors.

**Diagnose:**
1. **Expect throttling — it's by design.** Microsoft caps per-mailbox and per-tenant migration throughput; you cannot remove the cap. Compare elapsed time against realistic throughput, not raw bandwidth.
2. **Concurrency.** Reduce the number of concurrent mailboxes per wave if the engine is hitting tenant-level limits.
3. **Large mailboxes clustered.** Check whether several multi-GB mailboxes are in the same pass; spread them across waves.
4. **Competing load.** Avoid running discovery, migration, and reporting at peak simultaneously against the same tenant.
5. **Network path.** Confirm the proxy/firewall isn't rate-limiting or intermittently blocking the engine/Microsoft endpoints (R7).

**Resolve:** lower concurrency, re-balance large mailboxes across waves, and lean on **early pre-staging + scheduled deltas** so throughput pressure doesn't fall in the cutover window.

---

## 3. Stuck or failed mailboxes

**Symptoms:** `EXOMIG-Report.ps1` shows mailboxes in **Failed** (or perpetually **InProgress**).

**Diagnose:**
1. **Read the engine error per mailbox** (Quest task detail, or `Get-MigrationUserStatistics` for native). The message usually names the cause.
2. **Target not provisioned / unlicensed** — run `EXOMIG-Validation.ps1` pre-flight; a missing or unlicensed target mailbox (R1/R10) fails the copy.
3. **Corrupt / oversized items** — a small number of bad items can stall a mailbox; raise the engine's bad-item / large-item tolerance and retry that mailbox.
4. **Mapping error** — confirm the `mapping.csv` row points to the correct `TargetUPN`/routing address (R11).
5. **Auth blip** — if failures cluster in time, re-check section 1 (CA/MFA on `svc-quest-migration`).

**Resolve:** fix the specific cause, then **retry just the failed mailboxes** (do not re-run the whole wave). Re-run `EXOMIG-Report.ps1` until **zero unresolved failures** (Test T5 gate).

---

## 4. Domain won't remove from the source tenant (lingering references)

**Symptoms:** **Settings → Domains → contoso.com → Remove** in the source fails with "this domain is being used by …".

**Diagnose — Microsoft blocks removal while ANY object references the domain:**
1. **Re-run source discovery** (`EXOMIG-Discovery.ps1`) and search every export for `@contoso.com`.
2. Check, specifically:
   - **User UPNs and proxy addresses** still on `@contoso.com` (re-stamp to `source.onmicrosoft.com`).
   - **Distribution groups** and **Microsoft 365 groups** with `@contoso.com` addresses.
   - **Shared / room / equipment mailboxes** with `@contoso.com` addresses.
   - **Connectors, transport rules**, and **email address policies** referencing the domain.
   - **Guest / external** objects or app registrations using the domain.
3. The portal's domain page lists offending object **types**; clear each one.

**Resolve:** re-stamp/remove all `@contoso.com` references onto `source.onmicrosoft.com` (step 6.2 of the runbook), wait a few minutes for replication, then retry **Remove domain**. This is the single most common cutover blocker — budget time for it.

---

## 5. Domain verification fails in the target tenant

**Symptoms:** **Settings → Domains → Add domain → contoso.com** won't verify, or stays "Pending/Verifying".

**Diagnose, in order:**
1. **Source hasn't released the domain yet.** A domain can be in only one tenant at a time — verification in the target **cannot** succeed until **section 4** is done and the domain is fully removed from the source. Confirm it's gone from the source first.
2. **TXT record wrong or not propagated.** Confirm the exact **TXT verification value** from the target portal is published at the apex of `contoso.com` at the DNS host (R5). Check with `nslookup -type=txt contoso.com`.
3. **TTL / propagation delay.** If TTLs were high, wait for propagation; this is why TTLs are lowered in advance (best practices).
4. **Typo / wrong zone** — verify you edited the correct, authoritative DNS zone.

**Resolve:** ensure source release is complete, publish the correct TXT, wait for propagation, then click **Verify** again.

---

## 6. Mail-flow gaps during coexistence

**Symptoms:** mail to migrated users bounces or doesn't arrive; mail loops; NDRs reference the routing domain.

**Diagnose:**
1. **Connectors exist and are enabled** — confirm `Coexistence – Source→Target Connector` (source) and `Coexistence – Target→Source Connector` (target) are present and **Enabled** (`Get-OutboundConnector`).
2. **Routing address present** — migrated target mailboxes must carry the routing address (e.g. `user@target.onmicrosoft.com`); `EXOMIG-Validation.ps1` flags missing routing addresses.
3. **Smart host / recipient domain** — confirm each connector's `SmartHosts` and `RecipientDomains` point at the **other** tenant's MX endpoint and routing domain.
4. **Forwarding rules causing loops** — review user forwarding rules carried over from source; remove rules that bounce mail back and forth.
5. **Accepted domain type** — the routing domain should be an accepted domain of the correct type (Internal Relay) on the target.

**Resolve:** correct the connector definition (re-run `EXOMIG-Set-Coexistence.ps1`), add the missing routing address, and remove loop-inducing forwards. Use **message trace** (Exchange admin center → **Mail flow → Message trace**) in both tenants to follow a stuck message end-to-end.

---

## 7. Autodiscover / Outlook won't reconnect after cutover

**Symptoms:** after the domain move, Outlook desktop/mobile keeps prompting for credentials, shows "disconnected", or still points at the old tenant.

**Diagnose:**
1. **Autodiscover DNS** — confirm the Autodiscover CNAME for `contoso.com` points to `autodiscover.outlook.com` and has propagated (`nslookup -type=cname autodiscover.contoso.com`). High TTLs delay this — hence lowering TTL beforehand.
2. **MX correct** — `nslookup -type=mx contoso.com` should resolve to the **target** endpoint.
3. **Cached profile** — Outlook may cling to the old profile. Have the user restart Outlook; if it persists, **recreate the Outlook profile** pointing at the target mailbox.
4. **Credentials** — users authenticate against the **target** tenant now; confirm they have target credentials and have completed MFA registration there.
5. **Mobile** — on Outlook mobile, remove and re-add the account.

**Resolve:** fix DNS first, then reprofile clients that don't auto-reconnect. A small number of manual reprofiles is normal at cutover.

---

## 8. Free/busy not working (cross-mailbox or during coexistence)

**Symptoms:** users see hashmarks instead of availability; "No information" when scheduling.

**Diagnose:**
1. **During coexistence** — free/busy across tenants only works if **GAL sync + free/busy coexistence** was enabled in the Quest On Demand project. If it wasn't, cross-tenant availability is expected to be unavailable until cutover.
2. **After cutover (within the target tenant)** — availability should work natively. If not:
   - Confirm both users' mailboxes are fully migrated and licensed in the target.
   - Confirm the primary SMTP was stamped correctly (`EXOMIG-Validation.ps1`); a mismatched primary address breaks availability lookups.
   - Check **delegation/calendar permissions** were re-applied (`EXOMIG-Remediation.ps1`) — delegate free/busy depends on them.
3. **Test directly** — in Outlook on the web (https://outlook.office.com) on the target, open the scheduling assistant for two migrated users.

**Resolve:** for coexistence gaps, enable free/busy coexistence in the engine; for post-cutover gaps, fix licensing/primary-SMTP/delegation, then re-test in the scheduling assistant.

---

## Quick reference — symptom to section

| Symptom | Section |
|---------|---------|
| Engine/tenant auth fails | 1 |
| Migration slow | 2 |
| Individual mailboxes fail/stuck | 3 |
| Can't remove domain from source | 4 |
| Can't verify domain in target | 5 |
| Mail bounces/loops mid-migration | 6 |
| Outlook won't reconnect after cutover | 7 |
| Free/busy broken | 8 |


---


# 7. Best Practices — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

These practices reflect the standard migration model and reduce risk, downtime, and rework. Apply them throughout the eight phases.

## Pre-stage, then delta
- **Always pre-stage the bulk copy** days or weeks before cutover while users keep working in the source. The initial full copy is the slow part; do it early.
- **Run scheduled delta passes** (e.g. nightly) so the target stays current. A short final delta in the cutover window keeps true downtime minimal.
- Treat the size of the **final delta** as a health signal — a large final delta means delta passes weren't keeping up.

## Respect Microsoft throttling
- Microsoft 365 throttles per-mailbox and per-tenant migration throughput; you **cannot** force unlimited speed. Plan wall-clock time around realistic throughput, not raw bandwidth.
- Spread large mailboxes across waves; don't schedule every multi-GB mailbox in the same pass.
- Avoid running discovery, migration, and reporting all at peak simultaneously against the same tenant.

## Wave sizing and grouping
- Keep the **`EXO T2T – Pilot Wave`** small (5–15 mailboxes) but representative — include a shared mailbox and a room/equipment mailbox.
- Group production waves by **collaboration boundary** (department/team) so people who email and share calendars daily migrate together; this minimizes cross-tenant coexistence friction.
- Size waves to what your throughput and support team can validate in the available window.

## DNS discipline (lower TTL before cutover)
- **Lower the TTL** on the MX and Autodiscover records to 300 seconds (5 min) at least **24–48 hours before** the cutover window, so the cutover propagates quickly.
- Capture the **current DNS** (MX, Autodiscover, SPF, DKIM, DMARC) before changing anything (rollback baseline, G6).
- After cutover, restore normal TTLs once stable.

## Identity, passwords, and MFA
- Mailbox content copy does **not** move passwords/identity. Plan how users get target credentials (provisioning + secure communication) and budget time for **MFA re-registration** in the target tenant.
- Exclude **`svc-quest-migration`** from MFA/Conditional Access for the migration window **only**, scoped to those accounts — never disable policies tenant-wide — and **reverse it during Decommission**.

## Coexistence
- Stand up **`Coexistence – Source→Target Connector`** and **`Coexistence – Target→Source Connector`** before migrating production users so mail reaches migrated and not-yet-migrated users correctly.
- Enable **GAL sync + free/busy coexistence** for any project spanning more than a few days or where cross-tenant scheduling matters.
- Review **forwarding rules** before coexistence to avoid mail loops.

## Permissions and delegation
- Inter-mailbox permissions (FullAccess/SendAs/SendOnBehalf) and calendar delegation do **not** migrate automatically — capture them in discovery (`permissions.csv`) and re-apply with `EXOMIG-Remediation.ps1` after each wave.
- Re-test shared mailbox and delegate access after stamping addresses.

## Communications plan
- Publish a schedule to users: what changes, when their wave moves, what to expect at cutover (possible re-auth in Outlook, mobile re-add), and where to get help.
- Use **`EXO T2T – Pilot Members`** for the pilot comms and feedback loop; refine the message before bulk waves.
- Notify the service desk before each wave and especially before cutover.

## Validation and evidence
- Gate every phase on the tests in `05-testing.md`; never advance on a broken state.
- Keep the CSV outputs of discovery, validation, and reporting as the audit trail.
- Confirm **outbound authentication** (SPF/DKIM/DMARC) from the target after cutover — a common post-cutover deliverability gap.

## Rollback posture
- Before cutover, have a written rollback: if the domain move or DNS cutover fails, you can re-point DNS to the source and (because the domain hasn't yet been re-stamped on source objects irreversibly during the staging period) keep the source operational.
- The point of **least reversibility** is removing the domain from the source; do it only after a successful final delta and with the rollback decision explicitly made.

## Tooling choice
- Use **Quest On Demand Migration for Exchange** as the primary engine for its delta and coexistence handling. If using **native MRS**, ShareGate, or BitTitan instead, keep the same phases, naming, and gates — substitute only the engine-specific steps.


---


# 8. Deliverables Summary — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

This package is a complete, runbook-grade migration kit for moving Exchange Online mailboxes between Microsoft 365 tenants and performing a 1:1 domain cutover. It contains the following deliverables.

## Documentation

| Document | Purpose |
|----------|---------|
| `01-solution-overview.md` | What the solution is, the source→target 1:1 domain model, how it works, coexistence, tooling, benefits, and honest limitations. |
| `02-requirements.md` | Requirements R1–R12, each with Description / Why / How to verify / How to implement if missing. |
| `global-requirements-azure-solutions.md` | Category-wide baseline (G1–G6) common to every Azure Solutions deliverable. |
| `03-implementation.md` | The exact ordered runbook across all eight phases, with every created object named. |
| `05-testing.md` | Numbered phase-exit tests with PASS/FAIL gates and the final Acceptance Gate. |
| `06-troubleshooting.md` | Top-down diagnosis for the common failure modes. |
| `07-best-practices.md` | Migration best practices (pre-stage + delta, throttling, comms, DNS TTL, rollback, etc.). |
| `08-deliverables-summary.md` | This document. |
| `executive-summary.md` | One-page business case and outcome. |

## PowerShell scripts

All scripts carry a header block with `.SYNOPSIS`, PURPOSE / HOW TO RUN / EXPECTED RESULTS, and a neutral `.NOTES` line. Read-only by default where they could change state; changes require an explicit `-Apply` switch and support `-WhatIf`.

| Script | What it does |
|--------|--------------|
| `scripts\EXOMIG-Discovery.ps1` | Inventories the **source** tenant: mailboxes (user/shared/room/equipment), sizes, item counts, aliases, accepted domains, distribution and Microsoft 365 groups, and mailbox permissions/delegation. Exports CSVs. **Read-only.** |
| `scripts\EXOMIG-Validation.ps1` | Pre-flight and post-migration validation: target licensing present, accepted/verified domains, mailbox provisioned, and item-count parity (source vs target) for a sample user. Prints a PASS/FAIL summary. **Read-only.** |
| `scripts\EXOMIG-Report.ps1` | Migration status/throughput report: per-wave counts, completed/failed, GB moved — read from a status CSV (exported from the engine) or live from the tenant. Exports a CSV + prints a summary. **Read-only.** |
| `scripts\EXOMIG-Remediation.ps1` | Safe remediation: re-stamps the target **primary SMTP** from `mapping.csv` and re-grants **FullAccess/SendAs** from `permissions.csv`. Defaults to `-WhatIf`; changes require `-Apply`. |
| `scripts\EXOMIG-Set-Coexistence.ps1` | Creates the mail-flow coexistence connectors (`Coexistence – Source→Target Connector`, `Coexistence – Target→Source Connector`) and, optionally, the routing-domain accepted domain, via Exchange Online PowerShell. Supports `-WhatIf`. |

## Visual asset

| Asset | Purpose |
|-------|---------|
| `EXOMIG-hero.png` | Hero image for the solution listing. |

## How the deliverables fit together

1. Run **`EXOMIG-Discovery.ps1`** to build the inventory and the `mapping.csv` / `permissions.csv` that drive everything else.
2. Use **`02-requirements.md`** + **`global-requirements-azure-solutions.md`** to confirm prerequisites; verify with **`EXOMIG-Validation.ps1`** pre-flight.
3. Follow **`03-implementation.md`** phase by phase, creating the named objects and using **`EXOMIG-Set-Coexistence.ps1`** for connectors.
4. Track progress with **`EXOMIG-Report.ps1`**; re-apply addresses/permissions with **`EXOMIG-Remediation.ps1`**.
5. Gate every phase with **`05-testing.md`**; resolve issues with **`06-troubleshooting.md`**; apply **`07-best-practices.md`** throughout.
