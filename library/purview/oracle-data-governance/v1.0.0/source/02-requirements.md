# 2. Requirements Guide — Oracle Data Governance: Microsoft Purview

Verify every requirement before you register an Oracle source or run a scan. Each entry gives
Description, Why, How to verify, and How to implement if missing. Category-wide prerequisites (tenant,
roles, toolchain, scope, stakeholders, pilot) are in `global-requirements-purview.md` — this guide
adds the prerequisites specific to **governing Oracle databases in the Purview Data Map**.

> **Licensing/availability caveat.** Microsoft Purview Data Governance is billed by a consumption /
> pay-as-you-go model on an Azure subscription and is evolving; the **Oracle** connector, its supported
> Oracle versions, the JDBC-driver requirement, the supported authentication methods, and the exact
> scan configuration may be in preview or may have changed. Where this guide names a capability, a
> version, or a portal path, **verify its current availability for your tenant** in Microsoft's
> documentation and the Purview portal before relying on it.

## 2.1 A Microsoft Purview account (Data Map) provisioned on an Azure subscription
Description: A Microsoft Purview account — the Data Map resource — provisioned in an **Azure
subscription** (distinct from the M365 compliance portal). The account exposes the collection
hierarchy, scanning, and the connectors Oracle sources register into.
Why: The Data Map and scans live in this account; without it there is nothing to register an Oracle
source into.
How to verify: The account is visible in the Azure portal and its data-plane endpoint
(`https://<account>.purview.azure.com`) resolves; run `DGORACLE-Discovery.ps1` to confirm
reachability.
How to implement if missing: Provision a Microsoft Purview account under change control on the target
subscription; confirm the consumption billing model and region with your Azure owner.

## 2.2 Oracle connector availability + supported version confirmed for your tenant
Description: Confirmation that the **Oracle** source connector is available in your Purview account,
and that your Oracle database **version** is within the connector's currently supported range (verify —
historically a broad range up to 19c, but confirm current support).
Why: Connector availability and the supported version range are evolving/preview; you cannot register a
source type or scan a version the connector doesn't currently support in your tenant.
How to verify: In the Purview portal, **Data Map → Sources → Register**, confirm **Oracle** appears as
a registerable source type; check Microsoft's current Oracle-connector documentation for the supported
versions and capabilities (scan, classification, lineage).
How to implement if missing: If the connector isn't offered, verify licensing/region and Microsoft's
current availability; if your Oracle version is unsupported, plan accordingly and scope the pilot to a
supported instance.

## 2.3 Least-privilege data-governance roles on the Data Map collection
Description: Role assignments at the right scope — **Collection admin**, **Data source admin**, **Data
curator**, **Data reader** — on the collection the Oracle source will register into. Azure
**Owner/Contributor** on the account only where account-level changes are required.
Why: Purview uses fine-grained, collection-scoped roles; registering a source and running a scan
requires **Data source admin** on that collection, and least-privilege is a governance requirement in
its own right.
How to verify: In the Purview portal, open the collection's **Role assignments**; run
`DGORACLE-Discovery.ps1` (reports collections and role coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest collection scope under
change control; reserve account-level Collection admin for a small named group.

## 2.4 An inventory of the Oracle databases/schemas in scope, with owners
Description: A written list of the **Oracle sources** to govern — the **host/service name (or SID)**,
**listener port**, **version**, and the **schemas** in scope on each — each with a named **data owner**
and **data steward**.
Why: You register, scan, and classify per source; classification and ownership are meaningless without
a known owner per database/schema, and the host/service/port drive the connection and network path the
scan needs.
How to verify: For each in-scope database you can name the host/service, port, version, in-scope
schemas, and its owner; run `DGORACLE-Set-Scope.ps1` to record the pilot source set.
How to implement if missing: Inventory the Oracle estate with the DBAs, and assign a data owner and
steward to every database/schema before registering it.

## 2.5 A least-privilege, read-only Oracle database login for scanning
Description: An Oracle database login the scanner authenticates as, granted **least privilege and
read-only**: `CREATE SESSION` plus `SELECT` on the in-scope schemas/objects and on the data-dictionary
views the scanner reads (verify the exact grant list — for example the `ALL_*` catalog views — in
Microsoft's current Oracle-connector documentation). It is **not** a DBA/SYS account.
Why: The scan authenticates with Basic authentication and needs read access to enumerate schemas,
tables, columns, and sample data for classification — but no more. A least-privilege read login is the
least the scan needs and the least the source owner should grant.
How to verify: The login exists with `CREATE SESSION` and the required `SELECT` grants; the Oracle
source's **Test connection** in Purview succeeds using it.
How to implement if missing: With the DBA, create a dedicated read-only login (for example
`PURVIEW_SCAN`), grant `CREATE SESSION` and the required `SELECT` privileges, and confirm it can query
the in-scope objects and catalog views.

## 2.6 The Oracle credential stored in Azure Key Vault — never in code
Description: The scanning login's **password stored in an Azure Key Vault** that is **linked to the
Purview account**, exposed as a Purview credential (Basic authentication) referenced **by name**. **No
credential is ever placed in a script or document.**
Why: Oracle scans authenticate with Basic auth; storing the secret in Key Vault and referencing it by
name is the mandatory secure pattern and is how the provided scripts stay secret-free.
How to verify: A Key Vault is linked to the Purview account and holds the Oracle secret; the Oracle
source's **Test connection** succeeds using the named credential.
How to implement if missing: Link a Key Vault to the account, store the login's password as a secret,
create a Purview credential (Basic auth) that references the Key Vault secret by name, and verify
**Test connection**.

## 2.7 A self-hosted integration runtime (SHIR) + network path + JDBC driver
Description: A working scan path to the Oracle listener: a **self-hosted integration runtime (SHIR)**
installed on a machine with **network line of sight** to the Oracle host on the listener port
(default `1521`), the SHIR registered to the Purview account and showing **Running/Available**, and the
**Oracle JDBC driver** present on the SHIR machine where Microsoft's current docs specify (**verify
whether your SHIR version bundles the driver or requires a manual install**). A managed VNet runtime may
be an option for cloud-reachable instances — verify.
Why: A scan cannot classify what it cannot reach; Oracle behind a firewall requires the SHIR, and the
scanner needs the JDBC driver to talk to Oracle. Missing runtime, network, or driver is the most common
cause of a failed **Test connection**.
How to verify: The SHIR shows **Running/Available** in the portal, the firewall permits the SHIR host
to reach the listener port, the JDBC driver is present, and **Test connection** on the source succeeds;
`DGORACLE-Discovery.ps1` reports registered runtimes.
How to implement if missing: Install and register a SHIR with line of sight to the Oracle listener,
open the firewall to the listener port from the SHIR host only, install the Oracle JDBC driver per
Microsoft's current docs, then re-test.

## 2.8 A classification approach (system + any custom classifications)
Description: A decision on how Oracle assets will be classified: rely on the **built-in system
classifications** (credit card, national ID, and the large built-in set) and define any **custom
classification rules** the organization needs (for example an internal customer-ID or account-number
pattern) via the scan rule set.
Why: Classification is what turns the raw Oracle inventory into a sensitivity-aware map that drives
ownership, access, and downstream protection.
How to verify: System classifications appear on a test scan result; any custom classification rule is
defined and matches sample data.
How to implement if missing: Start with system classifications for the pilot; define custom rules only
where a real internal pattern isn't covered, and validate each against sample data before estate-wide
use.

## 2.9 A pilot scope and change control
Description: A **bounded pilot** — one collection and one Oracle source scoped to a **few schemas** — to
prove registration, credential, network/driver, scanning, and classification before Oracle-wide
rollout, plus a change-control window (scans consume SHIR and database resources and read live data).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; scanning is resource- and access-sensitive and is always proven on a bounded scope first.
How to verify: A named pilot collection, its Oracle source and in-scope schemas, and a change window
exist; run `DGORACLE-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, high-value database and a few schemas as the
pilot; agree the scan window and expected load with the DBA and source owner.

---
## Checklist
- [ ] Purview account (Data Map) provisioned on an Azure subscription — `DGORACLE-Discovery.ps1`
- [ ] Oracle connector availability + supported version confirmed for the tenant
- [ ] Least-privilege collection roles assigned (Data source admin to register/scan) — `DGORACLE-Discovery.ps1`
- [ ] Oracle databases/schemas inventoried with owners, host/service, port, version — `DGORACLE-Set-Scope.ps1`
- [ ] Least-privilege read-only Oracle login created (CREATE SESSION + required SELECT grants)
- [ ] Oracle credential stored in Azure Key Vault, referenced by name (no secrets in code)
- [ ] SHIR installed/registered (Running), network path to listener open, JDBC driver present — Test connection passes
- [ ] Classification approach agreed (system + any custom)
- [ ] Pilot scope (one database, a few schemas) and scan change window agreed — `DGORACLE-Set-Scope.ps1`
