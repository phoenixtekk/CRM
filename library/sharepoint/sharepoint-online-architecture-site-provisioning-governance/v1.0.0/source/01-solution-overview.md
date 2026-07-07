# Solution Overview

## What this is

SharePoint Online grows one site at a time. Each team that needs a place to work asks
for a site, gets one, and moves on. Without an architecture and a provisioning process,
that pattern produces thousands of sites created ad hoc — no consistent structure, no
naming convention, no metadata, no owner-of-record, and no plan for what happens when the
site goes quiet. Users cannot find anything, administrators cannot govern what they cannot
see, and the estate silently becomes the largest ungoverned data store in the enterprise.

This solution designs and implements the **information architecture (IA) and provisioning
governance** for SharePoint Online so that every site is consistent, findable, and
governed **from the moment it is created**. It delivers five things that work together:

1. **A hub-and-site structure** — a flat, navigable topology built from SharePoint **hub
   sites** (associations, not nested subsites) that groups related sites and gives them
   shared navigation, branding, and search scope.
2. **Defined site types and templates** — a small, deliberate set of site archetypes
   (team, communication, project, department) each backed by a **PnP provisioning
   template** so that a new site of a given type is identical every time.
3. **A provisioning process** — a **request → approve → provision** workflow that captures
   a request, applies a naming convention, routes for approval, and provisions the correct
   template automatically, replacing self-service "create a site" free-for-all.
4. **Naming and managed-metadata taxonomy** — a naming policy for sites and a **term store**
   (managed metadata) taxonomy (department, document type, region) applied as site columns
   and content types so content is tagged and findable across the estate.
5. **Site lifecycle** — ownership, inactivity review, and archival/retention hand-off so
   sites do not accumulate forever without an owner or a purpose.

The result is a SharePoint estate that **stays organized as it grows**: hubs and sites
structured, provisioned to a standard, named and tagged, and lifecycle-governed.

## How it works

### The reference design

The architecture is deliberately **flat and association-based**. Modern SharePoint does not
use nested subsites; instead each workload gets its **own site collection**, and sites are
related to one another by **hub association**. The reference design has three layers:

- **Hubs** — a small number of top-level hubs that represent the major organizing axis of
  the business (for example a corporate/intranet hub and one hub per division). In this
  solution the production hubs are named `Hub – Corp – Prod` and `Hub – Divisions – Prod`,
  and the pilot hub is `Hub – Pilot – Pilot`. A hub provides shared top navigation, a
  common look, and a rolled-up search scope across every site associated to it. A tenant
  supports up to **2,000 hubs** (verify the current limit for your tenant), but a good
  design uses far fewer — hubs are an organizing tool, not a per-team container.
- **Sites** — individual site collections (team sites, communication sites, project sites)
  each associated to exactly one hub. Each is provisioned from a named template so its
  libraries, columns, content types, navigation, and permissions are consistent.
- **Content** — libraries and lists inside each site, carrying the **site columns** and
  **content types** that surface the managed-metadata taxonomy so documents are tagged with
  department, document type, and region regardless of which site they live in.

### Site types and templates

The solution defines a small, closed set of site archetypes so every site fits a known
pattern. Each archetype is realized as a **PnP provisioning template** (a `.pnp` package or
XML template extracted from a hand-built reference site), named and versioned:

| Archetype | Base template | Provisioning template name | Purpose |
|---|---|---|---|
| Team site (collaboration) | Microsoft 365 group-connected Team site | `Template – Team Site – Prod` | Day-to-day team collaboration, group-backed membership |
| Communication site | Communication site | `Template – Communication Site – Prod` | Broadcast / intranet publishing, wide read audience |
| Project site | Team site | `Template – Project Site – Prod` | Time-boxed project with a defined start/end and archival |
| Department landing | Communication site (hub) | `Template – Department Hub Site – Prod` | Department front door, associated as/under a hub |

Building the template as a PnP template — rather than a raw SharePoint "site template" —
lets the solution capture site columns, content types, list/library schemas, navigation,
theme, and post-provisioning configuration in one reproducible artifact that a script
applies with `Invoke-PnPSiteTemplate`.

### The provisioning process (request → approve → provision)

Self-service site creation is **turned off or constrained** so that new sites flow through
a governed pipeline instead of the "New site" button:

1. **Request** — a requester submits a form backed by a SharePoint list,
   `Site Request – Intake – Prod`, capturing site type, business owner, department (from the
   taxonomy), sensitivity, and justification.
2. **Approve** — a Power Automate approval flow, `Provisioning Flow – Approve → Provision –
   Prod`, routes the request to the governance approver. Approval is a documented gate.
3. **Provision** — on approval, the flow (or a scheduled PnP script) computes the site name
   from the **naming policy**, provisions the correct template, associates the new site to
   its hub, applies the taxonomy columns/content types, sets the owner, and records the site
   in the inventory.

The naming policy is a single named artifact, `Naming Policy – Sites – Prod`, for example:

- Team sites: `TEAM-<Dept>-<Purpose>` (e.g. `TEAM-FIN-Budgeting`)
- Communication sites: `COMM-<Purpose>` (e.g. `COMM-Intranet-News`)
- Project sites: `PROJ-<Code>` (e.g. `PROJ-A1042`)

Encoding the naming policy in the provisioning flow means every URL and title is consistent
and machine-parseable, which makes later reporting and lifecycle automation reliable.

### Managed-metadata taxonomy

A **term store** taxonomy provides the controlled vocabulary that tags content across the
estate. The solution creates one term group and a small set of term sets:

- Term group: `Term Group – Enterprise Metadata – Prod`
- Term sets: `Term Set – Department – Prod`, `Term Set – Document Type – Prod`,
  `Term Set – Region – Prod`

These term sets are surfaced as **site columns** (`Site Column – Department – Prod`, etc.)
gathered into a governed **content type** (`Content Type – Governed Document – Prod`) that is
published from the content type gallery and added to document libraries by the templates. The
**actual term values** (which departments, which document types, which regions) are supplied
by the business — the solution builds the structure and the mechanism, not the org's specific
vocabulary.

### Site lifecycle

Every site has a defined end-of-life path:

- **Ownership** — each site records a business owner and at least two site owners; the
  provisioning process refuses a request without them.
- **Inactivity review** — Microsoft 365 **group expiration** (for group-connected sites)
  and site **access reviews** flag sites with no recent activity; the lifecycle policy is
  named `Lifecycle Policy – Inactive Site – Prod`.
- **Archival / retention** — inactive or completed sites (notably `PROJ-*` project sites)
  are archived or handed to the organization's retention policy. **What must be retained and
  for how long is a compliance/records determination and is deferred to those functions** —
  the solution provides the technical archival method and the evidence, not the schedule.

## Benefits

- **Findable, navigable estate** — hub navigation, consistent structure, and applied
  taxonomy make content discoverable instead of buried.
- **Consistency by construction** — templates mean a site of a given type is identical every
  time; there is no drift between what two teams get.
- **Governed at creation** — the request→approve→provision gate stops ungoverned sprawl at
  the source rather than trying to clean it up later.
- **Auditable** — every site has an owner, a naming-compliant URL, applied metadata, and an
  inventory record; the compliance report proves it.
- **Automatable and repeatable** — the whole model is expressed in PnP templates and
  PowerShell, so it scales and can be re-applied.

## Limitations and boundaries

- **Not a migration.** This solution governs how sites are created and structured; moving
  existing content into the architecture is a separate migration effort (ShareGate /
  Migration Manager at the pattern level; defer to the vendor's docs).
- **Compliance/legal determinations are deferred.** Retention schedules, records
  declarations, sensitivity-label policy definitions, and legal holds are set by the
  organization's compliance, records, and legal functions. The solution provides the
  technical method and evidence.
- **Plan- and cloud-dependent behavior is flagged, not invented.** Storage limits, hub
  limits, advanced records/Syntex capabilities, and **Commercial vs Government cloud** admin
  URLs (for example `*.sharepoint.com` vs `*.sharepoint.us` and `admin.microsoft.com` vs the
  GCC High / DoD portals under `*.office365.us`) differ by tenant and license — always
  **verify in your tenant** before relying on a specific limit or URL.
- **Third-party tooling is referenced at the pattern level.** Provisioning can be driven by
  Power Automate + PnP or a dedicated governance product; this solution builds the native
  PnP/PowerShell path.

## Deployment model

The solution follows the house model — **Assess → Design → Configure → Pilot → Validate →
Expand** — pilot-first, with explicit pass/fail gates and a documented rollback:

- **Assess** — inventory the current estate (sites, hubs, storage, sharing, orphaned sites)
  read-only and evaluate it against the target IA.
- **Design** — define hubs, site archetypes/templates, naming policy, taxonomy, and lifecycle
  rules; get them approved by the governance stakeholders.
- **Configure** — build the reference sites, extract PnP templates, create the term store,
  publish content types, and stand up the request→approve→provision pipeline.
- **Pilot** — run the pipeline for a limited pilot scope (`Hub – Pilot – Pilot` and a handful
  of pilot sites), provisioning with `-WhatIf` first, then for real, and prove the gates.
- **Validate** — confirm sites are provisioned to standard, hubs associated, taxonomy applied,
  and the compliance report is clean for the pilot.
- **Expand** — enable the pipeline for the wider organization, disable/constrain self-service
  creation tenant-wide, and onboard remaining hubs.

Because turning off self-service creation and changing tenant-wide provisioning is
**high-impact**, every production change is made under change control with the rollback
documented in the implementation guide.
