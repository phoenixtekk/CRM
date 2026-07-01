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
