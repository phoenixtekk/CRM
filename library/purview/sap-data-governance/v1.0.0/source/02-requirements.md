# 2. Requirements Guide — SAP Data Governance: Microsoft Purview

Verify every requirement before you register an SAP source or run a scan. Each entry gives
Description, Why, How to verify, and How to implement if missing. Category-wide prerequisites (tenant,
roles, toolchain, scope, stakeholders, pilot) are in `global-requirements-purview.md` — this guide
adds the prerequisites specific to **governing SAP in the Purview Data Map**.

> **Licensing/availability caveat.** Microsoft Purview Data Governance is billed by a consumption /
> pay-as-you-go model on an Azure subscription and is evolving; the **SAP** source connectors
> (historically **SAP ECC**, **SAP S/4HANA**, **SAP BW**, **SAP HANA**), the supported SAP versions,
> and the exact driver/runtime/credential configuration may be in preview or may have changed. Where
> this guide names a capability, a driver, or a portal path, **verify its current availability for your
> tenant** in Microsoft's documentation and the Purview portal before relying on it.

## 2.1 A Microsoft Purview account (Data Map) provisioned on an Azure subscription
Description: A Microsoft Purview account — the Data Map resource — provisioned in an **Azure
subscription** (distinct from the M365 compliance portal). The account exposes the collection
hierarchy, scanning, and the connectors SAP sources register into.
Why: The Data Map and scans live in this account; without it there is nothing to register SAP sources
into, and the SAP connectors are surfaced by this account.
How to verify: The account is visible in the Azure portal and its data-plane endpoint
(`https://<account>.purview.azure.com`) resolves; run `DGSAP-Discovery.ps1` to confirm reachability.
How to implement if missing: Provision a Microsoft Purview account under change control on the target
subscription; confirm the consumption billing model and region with your Azure owner.

## 2.2 SAP connector availability confirmed for your tenant (ECC / S/4HANA / BW / HANA)
Description: Confirmation that the SAP source connector you need — **SAP ECC**, **SAP S/4HANA**,
**SAP BW**, or **SAP HANA** — is available in your Purview account, and the current supported **SAP
version list** for that connector.
Why: Connector availability and supported versions are evolving/preview; you cannot register a source
type the connector doesn't currently offer in your tenant.
How to verify: In the Purview portal, **Data Map → Sources → Register**, confirm the SAP source type(s)
appear as registerable; check Microsoft's current connector documentation for the supported SAP
versions.
How to implement if missing: If a connector isn't offered, verify licensing/region and Microsoft's
current availability; scope the pilot to the SAP source type actually available and defer the others.

## 2.3 Least-privilege data-governance roles on the Data Map collection
Description: Role assignments at the right scope — **Collection admin**, **Data source admin**, **Data
curator**, **Data reader** — on the collection the SAP sources will register into. Azure
**Owner/Contributor** on the account only where account-level changes are required.
Why: Purview uses fine-grained, collection-scoped roles; registering a source and running a scan
requires **Data source admin** on that collection, and least-privilege is a governance requirement in
its own right.
How to verify: In the Purview portal, open the collection's **Role assignments**; run
`DGSAP-Discovery.ps1` (reports collections and role coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest collection scope under
change control; reserve account-level Collection admin for a small named group.

## 2.4 An SAP system inventory in scope, with owners
Description: A written list of the **SAP systems** to govern — each system's **type** (ECC / S/4HANA /
BW / HANA), **SID / application-server host / instance number / client** (or HANA host/port/tenant
database), and the tables/objects intent — each with a named **data owner** and **data steward**.
Why: You register, scan, and classify per source; classification and ownership are meaningless without
a known owner per system, and the system details drive the connector and credential configuration.
How to verify: For each in-scope SAP system you can name the type, connection details, and its owner;
run `DGSAP-Set-Scope.ps1` to record the pilot source set.
How to implement if missing: Inventory the SAP landscape with the SAP Basis team, and assign a data
owner and steward to every system before registering it.

## 2.5 A self-hosted integration runtime (SHIR) with line of sight to SAP
Description: A **self-hosted integration runtime** installed on a **Windows machine that has network
line of sight to the SAP system** (the application server for ECC/S4HANA/BW, or the HANA host/port),
registered to the Purview account. SAP is behind the corporate network, so the Azure (managed) runtime
generally cannot reach it — a SHIR is required (**verify** the current runtime requirement for your
connector).
Why: A scan cannot classify what it cannot reach; the SHIR is the bridge from Purview to the on-network
SAP system, and it is where the SAP driver and Java runtime live.
How to verify: The SHIR shows **Running/Available** in the portal; `DGSAP-Discovery.ps1` reports
registered integration runtimes; the SHIR machine can reach the SAP host/port (e.g. RFC gateway
`33NN`, or HANA SQL port `3NN15`).
How to implement if missing: Install and register a SHIR on a hardened Windows host with line of sight
to SAP, size it per Microsoft's guidance, and confirm it shows Running/Available before scanning.

## 2.6 The SAP driver and Java runtime on the SHIR machine (your SAP entitlement)
Description: The **SAP-provided driver** placed on the SHIR machine: for **ECC/S4HANA/BW**, the **SAP
JCo** libraries (`sapjco3.jar` + `sapjco3.dll`, 64-bit) plus a supported **64-bit Java runtime
(JRE/JDK)** with `JAVA_HOME`/path configured; for **SAP HANA**, the **SAP HANA JDBC driver
(`ngdbc.jar`)**. These are downloaded from the **SAP Support Portal under your SAP license (an
S-user)** — they are SAP's deliverables under your entitlement.
Why: Purview's SAP scanner loads these drivers to talk to SAP; without the correct driver + Java
version on the SHIR, the scan cannot connect. **Verify** the exact driver and Java versions Microsoft's
current connector documentation requires — they change.
How to verify: `sapjco3.jar`/`sapjco3.dll` (or `ngdbc.jar`) are present in the location Microsoft's
docs specify, the Java runtime version matches, and the SAP source's **Test connection** succeeds;
`DGSAP-Test-Readiness.ps1` records a driver-placement checklist item.
How to implement if missing: Download the driver from the SAP Support Portal with your S-user, install
the required Java runtime on the SHIR machine, place the files per Microsoft's docs, and re-test. The
solution does not (and cannot) ship SAP's drivers — obtain them under your SAP license.

## 2.7 A least-privilege SAP read login, secret in Azure Key Vault — never in code
Description: An **SAP service/read user** with the **least-privilege authorizations** the scan needs —
for ECC/S4HANA/BW, authorization to execute the RFC function modules the scanner calls (authorization
object **`S_RFC`**) and read the **data-dictionary metadata** it enumerates; for HANA, a database user
with **read** on the schemas in scope. The user's password is stored in an **Azure Key Vault** linked
to the Purview account and referenced **by name**. **No credential is ever placed in a script or
document.**
Why: SAP scans authenticate as this user; storing the secret in Key Vault and referencing it by name
is mandatory and is how the provided scripts stay secret-free. Least privilege keeps a governance
scanner from carrying more SAP authority than reading metadata requires.
How to verify: The SAP user exists with a scoped authorization role, a Key Vault is linked to the
Purview account and holds the SAP secret, and the SAP source's **Test connection** succeeds using the
named credential.
How to implement if missing: With the SAP security team, create a service user and a **least-privilege
authorization role** (the `S_RFC` function-module set and metadata-table read the scanner requires —
**verify the exact authorizations against Microsoft's current connector documentation**); store the
secret in Key Vault; create a Purview credential referencing it by name; verify **Test connection**.

## 2.8 A classification approach (system + any custom classifications)
Description: A decision on how SAP assets will be classified: rely on the **built-in system
classifications** (credit card, national ID, and the large built-in set) and define any **custom
classification rules** the organization needs (for example an internal customer- or vendor-ID pattern)
via the scan rule set.
Why: Classification is what turns the raw SAP metadata inventory into a sensitivity-aware map that
drives ownership, access, and downstream protection.
How to verify: System classifications appear on a test scan result; any custom classification rule is
defined and matches sample data.
How to implement if missing: Start with system classifications for the pilot; define custom rules only
where a real internal pattern isn't covered, and validate each against sample data before estate-wide
use.

## 2.9 A pilot scope and change control
Description: A **bounded pilot** — one collection and one SAP system/client with a scoped table/object
set — to prove registration, driver/credential/network, scanning, and classification before SAP-wide
rollout, plus a change-control window (scans consume SHIR/SAP resources and read a live SAP system).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; scanning is resource- and access-sensitive and is always proven on a bounded scope first.
How to verify: A named pilot collection, its SAP source, and a change window exist; run
`DGSAP-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, non-production-critical SAP system (or a
low-impact client) as the pilot; agree the scan window and expected SAP load with the SAP Basis team.

---
## Checklist
- [ ] Purview account (Data Map) provisioned on an Azure subscription — `DGSAP-Discovery.ps1`
- [ ] SAP connector availability + supported SAP versions confirmed for the tenant (ECC/S4HANA/BW/HANA)
- [ ] Least-privilege collection roles assigned (Data source admin to register/scan) — `DGSAP-Discovery.ps1`
- [ ] SAP systems inventoried with type, connection details, and owners — `DGSAP-Set-Scope.ps1`
- [ ] SHIR installed with line of sight to SAP, Running/Available — `DGSAP-Discovery.ps1`
- [ ] SAP driver (JCo `sapjco3.*` / HANA `ngdbc.jar`) + Java runtime placed on the SHIR (your SAP license)
- [ ] Least-privilege SAP read user created; secret in Azure Key Vault, referenced by name (no secrets in code)
- [ ] Classification approach agreed (system + any custom)
- [ ] Pilot scope and scan change window agreed — `DGSAP-Set-Scope.ps1`
