# 1. Solution Overview — Microsoft Fabric & Power BI Governance & Administration

## What this is
A platform-governance solution for Microsoft Fabric and Power BI. It puts controls around the shared
service that self-service analytics runs on, so growth stays deliberate instead of chaotic. You will
set a tenant-settings baseline, build a workspace and access model, put content on a controlled dev to
test to prod lifecycle with deployment pipelines, manage and monitor the capacities that content runs
on, and turn on admin-API-based monitoring so you can see and prove what is happening.

This is platform **administration and governance**. It is not report authoring, not data modeling, and
not data classification. Where classification is in scope — sensitivity labels and DLP for Power BI /
Fabric, and Purview-side reporting — that is delivered by the Microsoft Purview information-protection
solutions and cross-referenced here.

## How the technology works
Microsoft Fabric and Power BI share one administrative fabric on top of your Microsoft 365 / Entra
tenant. The pieces you will govern:

- **Tenant settings** — a single admin surface (the Fabric/Power BI admin portal) that turns
  capabilities on or off for the whole tenant or for named security groups: who can share externally,
  who can export data, who can publish to web, who can certify content, who can create workspaces, and
  which service principals may call the admin APIs. Tenant settings apply to **every user**, so they are
  the highest-leverage and highest-risk control — always scoped to groups and piloted first.
- **Capacities** — the compute that Fabric and Power BI Premium content runs on (Fabric F-SKUs or Power
  BI Premium P-SKUs). Capacities carry workload settings and are the unit of cost. Left unmonitored they
  either throttle (overloaded) or waste money (idle). *Verify the current SKU-to-feature mapping in your
  tenant.*
- **Workspaces** — the containers for content (reports, semantic models, lakehouses, pipelines). Each
  has roles — Admin, Member, Contributor, Viewer — that you assign to security groups, not people.
  Workspaces are assigned to a capacity, which is where governance meets cost.
- **Deployment pipelines** — a built-in dev to test to prod promotion mechanism. You pair three
  workspaces to the three stages and promote content forward with deployment rules, so production is
  never edited directly.
- **Admin and scanner APIs / activity log** — the read surface. The admin REST APIs and the metadata
  scanner return a tenant-wide inventory of workspaces, artifacts, and permissions; the activity log
  (and the admin monitoring / metrics experiences) return who did what. This is how you audit sharing,
  find orphaned or over-shared content, and watch capacity utilization.

## The standard deployment model
Every solution in this catalog follows the same five-step shape so repeat rollouts feel familiar:

1. **Assess** — inventory current tenant settings, capacities, workspaces, and sharing with the
   discovery script; identify sprawl and risky settings; agree the target baseline with the business.
2. **Configure** — author the tenant-settings baseline scoped to groups, build the workspace model and
   access groups, create the deployment pipeline, and set capacity workload/monitoring — all against a
   pilot ring first, nothing tenant-wide yet.
3. **Pilot** — apply the baseline and workspace/pipeline model to the governance pilot ring only; run a
   real content promotion dev to test to prod; watch capacity behavior.
4. **Validate** — run the validation script and the manual checks; confirm each control behaves as
   intended and nothing legitimate broke; get change approval for tenant-wide application.
5. **Expand** — roll the approved baseline tenant-wide under change control, onboard additional
   workloads onto the workspace/pipeline pattern, and put the monitoring report on a schedule.

## Scope
- A tenant-settings governance baseline (sharing, export, publish-to-web, certification, workspace
  creation, service-principal admin-API access), scoped to security groups.
- Capacity management: workload settings, assignment of workspaces to capacities, and utilization / cost
  monitoring.
- A workspace architecture and access model with roles assigned to groups.
- Deployment pipelines (dev to test to prod) for a controlled content lifecycle.
- Admin monitoring via the activity log, the admin monitoring / metrics experiences, and the admin /
  scanner REST APIs.

## Out of scope
- **Report and semantic-model authoring / data modeling** — this is platform governance, not content
  creation.
- **Sensitivity labeling and DLP for Power BI / Fabric, and Purview-side reporting** — delivered by the
  Microsoft Purview information-protection solutions; classification determinations are the compliance
  team's decision.
- **Row-level / object-level security design inside a semantic model** — a content concern, not a
  platform one.
- **Regulatory, records-retention, and legal determinations** — the customer's compliance/legal
  function decides; this guide provides the technical controls.

## Auth and connections used
- The **Fabric/Power BI admin portal** (`https://app.powerbi.com` → Settings → Admin portal) for tenant
  settings, capacities, and monitoring — needs the Fabric Administrator / Power BI Administrator role
  (some settings need Global Administrator).
- **Microsoft Entra security groups** to scope every tenant setting and every workspace role.
- The **MicrosoftPowerBIMgmt** PowerShell module and the Fabric/Power BI **admin & scanner REST APIs**,
  called either as a delegated admin or via a service principal that the "service principals can use
  read-only admin APIs" tenant setting permits, for discovery, validation, and reporting.
