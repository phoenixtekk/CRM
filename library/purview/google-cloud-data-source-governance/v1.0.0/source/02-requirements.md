# 2. Requirements Guide — Google Cloud Data-Source Governance: Microsoft Purview

Verify every requirement before you register a Google Cloud source or run a scan. Each entry gives
Description, Why, How to verify, and How to implement if missing. Category-wide prerequisites
(tenant, roles, toolchain, scope, stakeholders, pilot) are in `global-requirements-purview.md` — this
guide adds the prerequisites specific to **governing Google BigQuery in the Purview Data Map**.

> **Licensing/availability caveat.** Microsoft Purview Data Governance is billed by a consumption /
> pay-as-you-go model on an Azure subscription and is evolving; the **Google BigQuery** multicloud
> connector, the required GCP IAM roles, and the exact service-account/credential and SHIR/driver
> configuration may be in preview or may have changed. Where this guide names a capability, a GCP
> project ID, an IAM role, or a portal path, **verify its current availability for your tenant** in
> Microsoft's documentation and the Purview portal before relying on it.

## 2.1 A Microsoft Purview account (Data Map) provisioned on an Azure subscription
Description: A Microsoft Purview account — the Data Map resource — provisioned in an **Azure
subscription** (distinct from the M365 compliance portal). The account exposes the collection
hierarchy, scanning, and the multicloud connectors Google Cloud sources register into.
Why: The Data Map and scans live in this account; without it there is nothing to register Google
Cloud sources into, and the multicloud connectors are surfaced by this account.
How to verify: The account is visible in the Azure portal and its data-plane endpoint
(`https://<account>.purview.azure.com`) resolves; run `DGGCP-Discovery.ps1` to confirm reachability.
How to implement if missing: Provision a Microsoft Purview account under change control on the target
subscription; confirm the consumption billing model and region with your Azure owner.

## 2.2 Google BigQuery connector availability confirmed for your tenant
Description: Confirmation that the **Google BigQuery** source connector is available in your Purview
account (and confirmation of any additional Google Cloud source types you intend to use — do not
assume a connector exists).
Why: Multicloud connector availability is evolving/preview; you cannot register a source type the
connector doesn't currently offer in your tenant.
How to verify: In the Purview portal, **Data Map → Sources → Register**, confirm **Google BigQuery**
appears as a registerable source type; check Microsoft's current multicloud-connector documentation.
How to implement if missing: If the connector isn't offered, verify licensing/region and Microsoft's
current availability; scope the pilot to the source type actually available and defer the rest.

## 2.3 Least-privilege data-governance roles on the Data Map collection
Description: Role assignments at the right scope — **Collection admin**, **Data source admin**, **Data
curator**, **Data reader** — on the collection the Google Cloud sources will register into. Azure
**Owner/Contributor** on the account only where account-level changes are required.
Why: Purview uses fine-grained, collection-scoped roles; registering a source and running a scan
requires **Data source admin** on that collection, and least-privilege is a governance requirement in
its own right.
How to verify: In the Purview portal, open the collection's **Role assignments**; run
`DGGCP-Discovery.ps1` (reports collections and role coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest collection scope under
change control; reserve account-level Collection admin for a small named group.

## 2.4 A Google Cloud inventory of the BigQuery projects/datasets in scope, with owners
Description: A written list of the **Google Cloud resources** to govern — the **BigQuery
project(s)**, the **datasets** and **tables/views** within them (with region/location) — each with a
named **data owner** and **data steward**, and the GCP **project ID(s)** they live in.
Why: You register, scan, and classify per source; classification and ownership are meaningless
without a known owner per dataset, and the project/location drive the IAM and network the scan needs.
How to verify: For each in-scope project/dataset you can name the resource, its location, and its
owner; run `DGGCP-Set-Scope.ps1` to record the pilot source set.
How to implement if missing: Inventory the Google Cloud estate with the GCP project owners, and
assign a data owner and steward to every project/dataset before registering it.

## 2.5 A Google Cloud service account with read-only BigQuery access (key stored in Key Vault)
Description: A **Google Cloud service account** in the in-scope project, granted **read-only**
BigQuery access — historically the **BigQuery Data Viewer** and **BigQuery Metadata Viewer** roles
plus the ability to run read jobs (**BigQuery Job User** / read sessions); **verify the current
required IAM roles** for the Purview BigQuery connector. You generate a **service-account key** for
it, and its **private key** is stored in an **Azure Key Vault** linked to the Purview account and
referenced **by name** (for example `DGGCP-Cred-BQ-KV`). **No key material is ever placed in a script
or document.**
Why: Purview authenticates to BigQuery as this service account; read-only IAM is the least privilege
a scan needs, and storing the private key in Key Vault (referenced by name) is how the provided
scripts stay secret-free.
How to verify: The service account exists with the read-only BigQuery roles and the **BigQuery API
enabled** in the project; a Key Vault is linked to the Purview account and holds the private key; the
source's **Test connection** in Purview succeeds using the named credential.
How to implement if missing: Create the service account, grant the read-only BigQuery roles, enable
the BigQuery API, generate the key, store its private key in Key Vault, register it as a Purview
credential by name, and run **Test connection**.

## 2.6 A self-hosted integration runtime (SHIR) with the BigQuery driver prerequisites
Description: A **self-hosted integration runtime (SHIR)** — a machine you control, registered to the
Purview account — with **network line of sight to Google Cloud / BigQuery** and the **BigQuery JDBC
driver prerequisites** installed (historically a **Java Runtime Environment / JDK**; **verify the
current driver and Java version** for your tenant). BigQuery scans execute on this SHIR.
Why: The BigQuery connector runs its scan through a SHIR (not the Azure managed runtime); without a
Running SHIR that can reach BigQuery and has the driver prerequisites, **Test connection** and scans
will fail.
How to verify: The SHIR shows **Running/Available** in the portal, Java/driver prerequisites are
installed on the SHIR host, and **Test connection** on the BigQuery source succeeds;
`DGGCP-Discovery.ps1` reports registered runtimes.
How to implement if missing: Install and register a SHIR with line of sight to BigQuery, install the
required Java/driver prerequisites on the host, confirm it shows Running, then re-test.

## 2.7 A classification approach (system + any custom classifications)
Description: A decision on how Google Cloud assets will be classified: rely on the **built-in system
classifications** (credit card, national ID, and the large built-in set) and define any **custom
classification rules** the organization needs (for example an internal customer-ID pattern) via the
scan rule set.
Why: Classification is what turns the raw BigQuery inventory into a sensitivity-aware map that drives
ownership, access, and downstream protection.
How to verify: System classifications appear on a test scan result; any custom classification rule is
defined and matches sample data.
How to implement if missing: Start with system classifications for the pilot; define custom rules
only where a real internal pattern isn't covered, and validate each against sample data before
estate-wide use.

## 2.8 A pilot scope and change control
Description: A **bounded pilot** — one collection and one Google Cloud source (one BigQuery project /
one or two datasets) — to prove registration, credential, scanning, and classification before
Google-Cloud-wide rollout, plus a change-control window (scans consume resources and touch live
Google Cloud systems and can incur BigQuery query/egress cost).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; scanning is resource-, cost-, and access-sensitive and is always proven on a bounded scope
first.
How to verify: A named pilot collection, its Google Cloud source, and a change window exist; run
`DGGCP-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, high-value dataset set as the pilot; agree
the scan window and expected BigQuery cost with the source owners.

---
## Checklist
- [ ] Purview account (Data Map) provisioned on an Azure subscription — `DGGCP-Discovery.ps1`
- [ ] Google BigQuery connector availability confirmed for the tenant
- [ ] Least-privilege collection roles assigned (Data source admin to register/scan) — `DGGCP-Discovery.ps1`
- [ ] BigQuery projects/datasets inventoried with owners, location — `DGGCP-Set-Scope.ps1`
- [ ] Service account with read-only BigQuery roles + BigQuery API enabled; private key in Key Vault, referenced by name
- [ ] SHIR Running with Java/driver prerequisites and network line of sight to BigQuery — Test connection passes
- [ ] Classification approach agreed (system + any custom)
- [ ] Pilot scope and scan change window (with expected BigQuery cost) agreed — `DGGCP-Set-Scope.ps1`
