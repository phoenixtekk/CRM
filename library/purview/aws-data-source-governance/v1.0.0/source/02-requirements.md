# 2. Requirements Guide — AWS Data-Source Governance (S3/RDS): Microsoft Purview

Verify every requirement before you register an AWS source or run a scan. Each entry gives
Description, Why, How to verify, and How to implement if missing. Category-wide prerequisites (tenant,
roles, toolchain, scope, stakeholders, pilot) are in `global-requirements-purview.md` — this guide
adds the prerequisites specific to **governing AWS S3 and RDS in the Purview Data Map**.

> **Licensing/availability caveat.** Microsoft Purview Data Governance is billed by a consumption /
> pay-as-you-go model on an Azure subscription and is evolving; the **Amazon S3** and **Amazon RDS**
> multicloud connectors, the supported RDS engines, and the exact trust/credential configuration may be
> in preview or may have changed. Where this guide names a capability, an AWS account ID, or a portal
> path, **verify its current availability for your tenant** in Microsoft's documentation and the
> Purview portal before relying on it.

## 2.1 A Microsoft Purview account (Data Map) provisioned on an Azure subscription
Description: A Microsoft Purview account — the Data Map resource — provisioned in an **Azure
subscription** (distinct from the M365 compliance portal). The account exposes the collection
hierarchy, scanning, and the multicloud connectors AWS sources register into.
Why: The Data Map and scans live in this account; without it there is nothing to register AWS sources
into, and the multicloud connectors are surfaced by this account.
How to verify: The account is visible in the Azure portal and its data-plane endpoint
(`https://<account>.purview.azure.com`) resolves; run `DGAWS-Discovery.ps1` to confirm reachability.
How to implement if missing: Provision a Microsoft Purview account under change control on the target
subscription; confirm the consumption billing model and region with your Azure owner.

## 2.2 Amazon S3 / Amazon RDS connector availability confirmed for your tenant
Description: Confirmation that the **Amazon S3** and/or **Amazon RDS** source connectors are available
in your Purview account, and the current supported **RDS engine list** (historically SQL Server and
PostgreSQL — verify).
Why: Multicloud connector availability and the supported engines are evolving/preview; you cannot
register a source type the connector doesn't currently offer in your tenant.
How to verify: In the Purview portal, **Data Map → Sources → Register**, confirm **Amazon S3** and
**Amazon RDS** appear as registerable source types; check Microsoft's current multicloud-connector
documentation for the supported RDS engines.
How to implement if missing: If a connector isn't offered, verify licensing/region and Microsoft's
current availability; scope the pilot to the source type(s) actually available and defer the other.

## 2.3 Least-privilege data-governance roles on the Data Map collection
Description: Role assignments at the right scope — **Collection admin**, **Data source admin**, **Data
curator**, **Data reader** — on the collection the AWS sources will register into. Azure
**Owner/Contributor** on the account only where account-level changes are required.
Why: Purview uses fine-grained, collection-scoped roles; registering a source and running a scan
requires **Data source admin** on that collection, and least-privilege is a governance requirement in
its own right.
How to verify: In the Purview portal, open the collection's **Role assignments**; run
`DGAWS-Discovery.ps1` (reports collections and role coverage, read-only).
How to implement if missing: Assign the least-privilege role at the narrowest collection scope under
change control; reserve account-level Collection admin for a small named group.

## 2.4 An AWS account inventory of the S3 buckets and RDS instances in scope, with owners
Description: A written list of the **AWS resources** to govern — the **S3 buckets** (with region and
whether they are KMS-encrypted) and the **RDS instances/databases** (engine, endpoint, region) — each
with a named **data owner** and **data steward**, and the AWS account ID(s) they live in.
Why: You register, scan, and classify per source; classification and ownership are meaningless without
a known owner per bucket/database, and the region/encryption drive the IAM and KMS permissions the
scan needs.
How to verify: For each in-scope bucket/database you can name the resource, its region, its encryption
state, and its owner; run `DGAWS-Set-Scope.ps1` to record the pilot source set.
How to implement if missing: Inventory the AWS estate with the AWS account owners, and assign a data
owner and steward to every bucket/database before registering it.

## 2.5 Amazon S3 trust path — a cross-account IAM role (ARN + external ID), read-only
Description: For S3, an **AWS IAM role** you create that **trusts Microsoft's Purview AWS account**
(the account ID/principal shown in the Purview S3 registration UI — **read it from the portal, do not
assume it**) with a **condition on the external ID** Purview provides, and grants **read-only** access
to the in-scope buckets (for example the AWS-managed `AmazonS3ReadOnlyAccess`, or a bucket-scoped
read policy) plus **KMS decrypt** on the key for any encrypted bucket. The role's **ARN** is
referenced as a Purview credential **by name** — no AWS access key is stored.
Why: Purview scans S3 by **assuming this role**; the external-ID condition prevents the confused-deputy
problem, and read-only + KMS-decrypt is the least privilege a scan needs. A role-based trust avoids
long-lived keys entirely.
How to verify: The IAM role exists with the trust policy (Microsoft's Purview AWS principal + your
external ID) and the read/KMS permissions; the source's **Test connection** in Purview succeeds; the
role ARN is registered as a Purview credential by name.
How to implement if missing: In the Purview S3 registration UI, copy the **Microsoft AWS account /
principal and the external ID**; create the IAM role in AWS with that trust and read-only + KMS
permissions; register its ARN as the credential; run **Test connection**.

## 2.6 Amazon RDS credential via Azure Key Vault — never in code
Description: For RDS, a **database login with read access** to the in-scope databases, whose secret is
stored in an **Azure Key Vault** linked to the Purview account and referenced **by name**. **No
credential is ever placed in a script or document.**
Why: RDS scans authenticate to the database with SQL/DB auth; storing the secret in Key Vault and
referencing it by name is mandatory and is how the provided scripts stay secret-free.
How to verify: A Key Vault is linked to the Purview account and holds the RDS secret; the RDS source's
**Test connection** succeeds using the named credential.
How to implement if missing: Link a Key Vault to the account, create a least-privilege read login on
the RDS database, store its secret in Key Vault, and verify **Test connection** before scanning.

## 2.7 Network path to each source (integration runtime + AWS network/firewall)
Description: A working network path from the scanner to each source: the **Azure (managed) integration
runtime** for publicly reachable S3 and RDS, or a **self-hosted integration runtime (SHIR)** (or
managed VNet runtime — verify) for RDS instances in a **private VPC**; and AWS-side network rules
(security groups, RDS publicly-accessible setting, S3 bucket policy/VPC endpoint) that permit the
scan.
Why: A scan cannot classify what it cannot reach; RDS in a private subnet or an S3 bucket restricted by
policy will fail **Test connection** until the network path and AWS rules allow the scanner.
How to verify: The integration runtime shows **Running/Available** in the portal and **Test
connection** on each source succeeds; `DGAWS-Discovery.ps1` reports registered runtimes.
How to implement if missing: Use the managed runtime for reachable sources; install and register a SHIR
with line of sight to private RDS, adjust the AWS security group / bucket policy to permit the scan,
then re-test.

## 2.8 A classification approach (system + any custom classifications)
Description: A decision on how AWS assets will be classified: rely on the **built-in system
classifications** (credit card, national ID, and the large built-in set) and define any **custom
classification rules** the organization needs (for example an internal customer-ID pattern) via the
scan rule set.
Why: Classification is what turns the raw AWS inventory into a sensitivity-aware map that drives
ownership, access, and downstream protection.
How to verify: System classifications appear on a test scan result; any custom classification rule is
defined and matches sample data.
How to implement if missing: Start with system classifications for the pilot; define custom rules only
where a real internal pattern isn't covered, and validate each against sample data before estate-wide
use.

## 2.9 A pilot scope and change control
Description: A **bounded pilot** — one collection and one or two AWS sources (a couple of S3 buckets
and/or one RDS database) — to prove registration, trust/credential, scanning, and classification
before AWS-wide rollout, plus a change-control window (scans consume resources and touch live AWS
systems and can incur AWS request/egress cost).
Why: Every solution in this category follows Assess → Design → Configure → **Pilot** → Validate →
Expand; scanning is resource-, cost-, and access-sensitive and is always proven on a bounded scope
first.
How to verify: A named pilot collection, its AWS sources, and a change window exist; run
`DGAWS-Set-Scope.ps1` to materialize the pilot scope.
How to implement if missing: Choose one well-understood, high-value bucket set and/or one RDS database
as the pilot; agree the scan window and expected AWS cost with the source owners.

---
## Checklist
- [ ] Purview account (Data Map) provisioned on an Azure subscription — `DGAWS-Discovery.ps1`
- [ ] Amazon S3 / RDS connector availability + supported RDS engines confirmed for the tenant
- [ ] Least-privilege collection roles assigned (Data source admin to register/scan) — `DGAWS-Discovery.ps1`
- [ ] AWS buckets/RDS instances inventoried with owners, region, encryption — `DGAWS-Set-Scope.ps1`
- [ ] S3 cross-account IAM role (ARN + external ID, read-only + KMS decrypt) created; ARN registered by name
- [ ] RDS credential stored in Azure Key Vault, referenced by name (no secrets in code)
- [ ] Network path per source (managed IR or SHIR) + AWS security group/bucket policy — Test connection passes
- [ ] Classification approach agreed (system + any custom)
- [ ] Pilot scope and scan change window (with expected AWS cost) agreed — `DGAWS-Set-Scope.ps1`
