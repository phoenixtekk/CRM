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
