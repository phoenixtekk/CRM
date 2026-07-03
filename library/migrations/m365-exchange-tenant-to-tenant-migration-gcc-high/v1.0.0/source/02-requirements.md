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
