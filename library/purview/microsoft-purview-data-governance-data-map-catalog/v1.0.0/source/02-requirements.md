# 2. Requirements Guide — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

Verify every requirement before you register a source or run a scan. Each entry gives Description,
Why, How to verify, and How to implement if missing. Category-wide prerequisites (tenant, roles,
toolchain, scope, stakeholders, pilot) are in `global-requirements-purview.md` — this guide adds the
prerequisites specific to **Data Governance / Data Map / Unified Catalog**.

> **Licensing/availability caveat.** Microsoft Purview Data Governance is billed by a consumption /
> pay-as-you-go model on an Azure subscription and is evolving; some features may be in preview.
> Where this guide names a capability, **verify its current availability and pricing for your tenant**
> in Microsoft's documentation and the Purview portal before relying on it.

## 2.1 A Microsoft Purview account (Data Map) provisioned on an Azure subscription
Description: A Microsoft Purview account — the Data Map / Unified Catalog resource — provisioned in an
**Azure subscription** (this is the data-governance resource, distinct from the M365 compliance
portal). The account exposes the collection hierarchy, scanning, and the catalog.
Why: The Data Map, scans, and Unified Catalog all live in this account; without it there is nothing to
register sources into.
How to verify: The account is visible in the Azure portal and its data-plane endpoint
(`https://<account>.purview.azure.com`) resolves; run `PURVGOV-Discovery.ps1` to confirm reachability.
How to implement if missing: Provision a Microsoft Purview account under change control on the target
subscription; confirm the consumption billing model and region with your Azure owner.

## 2.2 Least-privilege data-governance roles (collections + Unified Catalog)
Description: Role assignments at the right scope — **Collection admin**, **Data source admin**, **Data
curator**, **Data reader** on the Data Map collections, plus **governance domain owner / data product
owner / data steward** in the Unified Catalog. Azure **Owner/Contributor** on the account only where
account-level changes are required.
Why: Purview uses fine-grained, collection-scoped roles; each configuration step requires the matching
role, and least-privilege is a governance requirement in its own right.
How to verify: In the Purview portal, open the collection's **Role assignments** and the Unified
Catalog role pages; run `PURVGOV-Discovery.ps1` (reports collections and role coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest collection/domain scope
under change control; reserve account-level Collection admin for a small named group.

## 2.3 Data sources in scope, inventoried with owners
Description: A written list of the **data sources** to govern (for example Azure SQL, ADLS Gen2, Azure
Blob, Synapse, Power BI, AWS S3, GCP BigQuery/Storage, on-premises SQL Server), each with a named
**data owner** and **data steward**.
Why: You register, scan, and catalog per source; classification and ownership are meaningless without a
known owner per source. Availability of specific connectors (especially multicloud) may be preview —
verify.
How to verify: For each source you can name the system, its location/host, and its owner; run
`PURVGOV-Set-Scope.ps1` to record the pilot source set.
How to implement if missing: Inventory the estate with the data owners, confirm connector availability
for each source type, and assign an owner and steward to every source before registering it.

## 2.4 Source credentials via managed identity / Key Vault — never in code
Description: A credential path for scanning each source: the Purview account's **managed identity**
where the source supports it, otherwise a service principal or account secret stored in an **Azure Key
Vault** linked to the Purview account. **No credential is ever placed in a script or document.**
Why: Scans authenticate to live systems; storing secrets safely (Key Vault + managed identity) is
mandatory and is how the provided scripts stay secret-free.
How to verify: A Key Vault is linked to the Purview account and holds the source secrets, or the
managed identity is granted read on the source; the scan's **Test connection** succeeds.
How to implement if missing: Link a Key Vault to the account, grant the managed identity the least
read role on each source (or store a secret in Key Vault), and verify **Test connection** before
scanning.

## 2.5 Network path to each source (integration runtime)
Description: A working network path from the scanner to each source: the **Azure (managed)
integration runtime** for reachable cloud sources, or a **self-hosted integration runtime (SHIR)**
installed inside the network for on-premises and VNet/firewall-restricted sources.
Why: A scan cannot classify what it cannot reach; on-premises and private-network sources require a
SHIR with line of sight to the source.
How to verify: The integration runtime shows **Running/Available** in the portal and **Test
connection** on the source succeeds; `PURVGOV-Discovery.ps1` reports registered runtimes.
How to implement if missing: Use the managed runtime for public cloud sources; install and register a
SHIR on a host with network access for on-premises/private sources, then re-test the connection.

## 2.6 A classification approach (system + any custom classifications)
Description: A decision on how assets will be classified: rely on the **built-in system
classifications** (credit card, national ID, and the large built-in set) and define any **custom
classifications / classification rules** the organization needs (for example an internal customer-ID
pattern).
Why: Classification is what turns the raw Data Map into a sensitivity-aware inventory that drives
ownership, access, and downstream protection.
How to verify: The system classifications are visible on a test scan result; any custom classification
rule is defined and matches sample data.
How to implement if missing: Start with system classifications for the pilot; define custom
classification rules only where a real internal pattern isn't covered, and validate each against
sample data before estate-wide use.

## 2.7 Governance-domain and data-product intent (Unified Catalog)
Description: An agreed first **governance domain** (a business grouping such as Finance or Customer)
and at least one intended **data product** (a curated, publishable set of assets with an owner and a
use purpose), plus the initial **business glossary** terms / critical data elements for the pilot.
Why: The Unified Catalog is organized by governance domains and data products; without an agreed first
domain and product there is nothing to curate the pilot's scanned assets into.
How to verify: Stakeholders have named the pilot governance domain, one data product, and a short
initial glossary; `PURVGOV-Set-Scope.ps1` records them as the pilot scope.
How to implement if missing: Facilitate a short workshop with the data owners to agree the pilot
domain, one data product, its owner, and 5–10 initial glossary terms.

## 2.8 A pilot scope and change control
Description: A **bounded pilot** — one collection, one governance domain, and one or two sources — to
prove registration, scanning, classification, and catalog curation before estate-wide rollout, plus a
change-control window for scans (scans consume resources and touch live systems).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; scanning is resource- and access-sensitive and is always proven on a bounded scope first.
How to verify: A named pilot collection/domain, its sources, and a change window exist; run
`PURVGOV-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, high-value domain and one or two of its
sources as the pilot; agree the scan window with the source owners.

---
## Checklist
- [ ] Purview account (Data Map) provisioned on an Azure subscription — `PURVGOV-Discovery.ps1`
- [ ] Least-privilege collection + Unified Catalog roles assigned — `PURVGOV-Discovery.ps1`
- [ ] Sources inventoried with owners/stewards — `PURVGOV-Set-Scope.ps1`
- [ ] Credentials via managed identity / Key Vault (no secrets in code)
- [ ] Network path per source (managed IR or SHIR) — Test connection passes
- [ ] Classification approach agreed (system + any custom)
- [ ] Pilot governance domain + data product + initial glossary agreed — `PURVGOV-Set-Scope.ps1`
- [ ] Pilot scope and scan change window agreed
