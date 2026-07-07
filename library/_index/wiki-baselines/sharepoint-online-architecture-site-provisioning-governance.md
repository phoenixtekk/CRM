# SharePoint Online Architecture & Site Provisioning Governance

> **Version 1.0.0** · Category: SharePoint · Solution code: SPOARCH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

**Outcome.** A SharePoint Online estate that stays organized as it grows — sites structured
into a clear hub-and-site architecture, provisioned to a consistent standard, named and tagged
with a controlled taxonomy, and governed through their full lifecycle. Users can find content;
administrators can govern what they can now see; and new sites are correct by construction
rather than cleaned up after the fact.

**The problem.** Left to self-service, SharePoint Online becomes thousands of ungoverned
sites: no consistent structure, no naming, no metadata, no owner-of-record, and no end-of-life
plan. It quietly becomes the largest ungoverned data store in the organization — unnavigable
for users and unauditable for IT, security, and compliance.

**The approach.** This solution designs and implements the information architecture and
provisioning governance as one system: a flat, association-based **hub-and-site structure**; a
small closed set of **site archetypes**, each backed by a reproducible **PnP provisioning
template**; a **request → approve → provision** workflow that applies a naming policy and routes
through a real approval gate; a managed-metadata **taxonomy** (term store, site columns, a
published governed content type); and a defined **site lifecycle** (ownership, inactivity review,
archival hand-off). It ships five PowerShell tools — assessment, provisioning, hub/metadata
apply, compliance reporting, and a scope/health helper — built on the SharePoint Online
Management Shell, PnP PowerShell, and Microsoft Graph.

**Why it is low-risk.** The work follows a pilot-first model — **Assess → Design → Configure →
Pilot → Validate → Expand** — with explicit pass/fail gates at every stage. The automation is
**safe by default**: the provisioning and apply scripts run read-only or in `-WhatIf` dry-run
mode and change nothing until an explicit `-Commit` is passed. The high-impact tenant-wide
change — constraining self-service site creation so the governed pipeline becomes the creation
path — is made only at the Expand stage, under change control, as a **reversible settings change**
(no site data is deleted), with prior values recorded and a documented rollback. Compliance and
legal determinations (retention schedules, records, legal holds) are deferred to those functions;
the solution provides the technical method and the evidence. Plan- and cloud-dependent details
(storage/hub limits, Commercial vs Government cloud URLs) are cited or flagged to verify in the
tenant, never invented. Delivered as self-guided documentation and tested tools, it captures a
consulting-grade architecture at a fraction of the cost of a bespoke engagement.


---


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


---


# Requirements

This solution builds **on** the shared prerequisites in
`global-requirements-sharepoint.md` (the six SharePoint-category requirements: a licensed
M365 tenant with SharePoint Online/OneDrive; least-privilege **SharePoint Administrator**
access; the SPO Management Shell / PnP + Graph toolchain; an IA and identity/group source of
truth; a pilot scope and change control; and security/compliance/records stakeholders).
**Verify those first.** The requirements below are the ones **specific** to architecture and
provisioning governance — do not duplicate the shared six.

---

## 1. PnP PowerShell and a PnP app registration (Entra) for provisioning

- **Description:** The **PnP.PowerShell** module (PowerShell 7 recommended; the module runs on
  5.1 and 7) plus a registered **Entra ID application** that PnP authenticates as. Since
  September 2024 PnP PowerShell no longer ships a default multi-tenant app, so you must
  register your own app (interactive/delegated for hands-on work, or certificate-based
  app-only for unattended provisioning flows).
- **Why required:** The templates are applied and sites provisioned with `Connect-PnPOnline`,
  `Get-PnPSiteTemplate`/`Invoke-PnPSiteTemplate`, and `New-PnPSite`. Unattended provisioning
  (a scheduled or flow-triggered run) needs an app registration with a certificate, not a
  password.
- **How to verify:** `Get-Module PnP.PowerShell -ListAvailable` returns a version; and
  `Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP – Provisioning – Prod" -Tenant <tenant>.onmicrosoft.com`
  has been run once, or an app with the needed Graph/SharePoint permissions exists in Entra.
- **How to implement if missing:** `Install-Module PnP.PowerShell -Scope CurrentUser`. Register
  the app with `Register-PnPEntraIDApp*`, grant and **admin-consent** the delegated
  `Sites.FullControl.All` (and Graph `Group.ReadWrite.All` for group-connected sites) it
  requires, and record the client (application) ID. Name the app `PnP – Provisioning – Prod`.
  For app-only, add a certificate and consent the application permissions. Treat the client
  ID as configuration and the certificate/secret as a secret — never hardcode it in scripts.

## 2. SharePoint tenant settings that permit governed provisioning

- **Description:** Tenant-level SharePoint settings configured so that **governed** provisioning
  is the path and **ungoverned** self-service creation is constrained: the SharePoint admin
  center **"Site creation"** setting (whether users can create sites, and from where) and the
  Microsoft 365 group creation setting (restricting group creation to an approved security
  group).
- **Why required:** The request→approve→provision pipeline only holds if users cannot simply
  click "New site" (or create an M365 group, which creates a site) outside the process.
- **How to verify:** In the SharePoint admin center → **Settings → Site creation**, review who
  can create sites; and check the Entra/Graph `Set-SPOTenant`/group-creation policy
  (`AllowedMembersToCreateGroups`). `Get-SPOTenant | Select DisableSelfServiceSiteCreation` and
  the group-creation directory setting show current state.
- **How to implement if missing:** Plan the change with the governance stakeholders (it is
  tenant-wide and high-impact). Restrict M365 group creation to an approved group, and set site
  creation to route through the request process. **Do this at Pilot/Expand under change
  control**, not on day one — see the implementation guide's rollback.

## 3. Term store administrator and a taxonomy source of truth

- **Description:** A designated **Term Store Administrator** (assigned in the SharePoint admin
  center → **Content services → Term store**) and a business-supplied source of truth for the
  controlled vocabulary (which departments, document types, and regions are valid values).
- **Why required:** The solution creates the term **structure** (`Term Group – Enterprise
  Metadata – Prod` and its term sets) but the **term values** are the organization's own
  vocabulary and must come from the business/records owners, not be invented.
- **How to verify:** In the term store, confirm at least one **Term store admin** is listed and
  that a business owner has provided (or committed to provide) the term lists.
- **How to implement if missing:** Assign a Term Store Administrator; nominate a taxonomy owner
  in the business who signs off the term sets. Capture the term lists before configuring the
  taxonomy.

## 4. Content type publishing (content type gallery) available

- **Description:** The tenant **content type gallery** (the modern replacement for the classic
  Content Type Hub) so the governed content type can be **published** and syndicated to all
  site collections, rather than defined per-site.
- **Why required:** `Content Type – Governed Document – Prod` and its site columns must exist
  once and appear everywhere; publishing from the gallery is what makes the taxonomy consistent
  across sites the templates create.
- **How to verify:** In the SharePoint admin center → **Content services → Content type
  gallery**, confirm access and that content types can be created/published there.
- **How to implement if missing:** Use the content type gallery in the admin center (available
  in current SharePoint Online — **verify in your tenant**; older tenants may still surface the
  classic Content Type Hub at `/sites/contentTypeHub`). Create the site columns and content type
  there and publish.

## 5. A governance approver and a Power Automate (or scripted) approval path

- **Description:** A named **governance approver** (person or group) who owns the approval gate,
  and a **Power Automate** environment (or an equivalent scripted/ticketing approval) able to
  run an approval flow against the `Site Request – Intake – Prod` list.
- **Why required:** The "approve" step of request→approve→provision is a real, auditable gate.
  Without a named approver and an approval mechanism, provisioning is not governed.
- **How to verify:** Confirm the approver (e.g. a `Governance Approvers` group) and that Power
  Automate is available in the tenant (or the org's ITSM tool will hold the approval).
- **How to implement if missing:** Name the approver group; confirm Power Automate licensing/
  environment, or decide the approval will live in the existing ITSM tool and the provisioning
  script runs on ticket closure.

## 6. A reference/build site to author each template from

- **Description:** A hand-built **reference site per archetype** (or a design spec for each) that
  the PnP template is **extracted from** with `Get-PnPSiteTemplate`. You need a place to build
  and validate the ideal team/communication/project site before templatizing it.
- **Why required:** A PnP provisioning template is only as good as the site it is extracted from;
  the templates `Template – Team Site – Prod`, `Template – Communication Site – Prod`,
  `Template – Project Site – Prod`, and `Template – Department Hub Site – Prod` are captured from
  reference sites, not written by hand.
- **How to verify:** Confirm a reference site (or an agreed spec) exists for each archetype in
  the solution's scope.
- **How to implement if missing:** Provision a plain site of each base type in the pilot scope,
  configure it to the design (libraries, columns, content type, navigation, theme), validate it,
  then extract the template from it.


---


# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*


---


# Implementation

Follow these steps in order. They implement the house model **Assess → Design → Configure
→ Pilot → Validate → Expand**, pilot-first, with explicit pass/fail gates and a documented
rollback. Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>`
and the same name is reused in later steps, testing, troubleshooting, and the scripts.

> **High-impact steps** (disabling self-service creation, restricting group creation,
> publishing content types tenant-wide) are called out inline with their rollback. Make them
> under change control at the Pilot/Expand stages, not up front.

Connect once per session with modern auth (no stored credentials):

```powershell
# SharePoint Online Management Shell (tenant admin cmdlets)
Connect-SPOService -Url https://<tenant>-admin.sharepoint.com
# PnP PowerShell (templates, sites, taxonomy) — uses the registered app "PnP – Provisioning – Prod"
Connect-PnPOnline -Url https://<tenant>.sharepoint.com -Interactive -ClientId <app-client-id>
```

> **Government / sovereign clouds:** the admin URL, `-Region`, and Graph endpoint differ
> (e.g. GCC High / DoD). Pass the correct `AzureEnvironment`/`-Region` to `Connect-*` and use
> your tenant's admin host — **verify in your tenant**; do not assume the Commercial URLs.

---

## Stage 1 — Assess (read-only)

### 1.1 Inventory the current estate

Run the discovery script to capture every site collection, hub, template/base type, storage,
sharing capability, and owner into a baseline, and to flag orphaned/owner-less sites:

```powershell
.\Invoke-SPOArchitectureAssessment.ps1 -OutputPath .\out\SPOARCH-Assessment.csv
```

The output is the **assessment baseline**. Nothing is changed. Review it with the governance
stakeholders: how many sites exist, how many are hub-associated, how many have no metadata,
how many are inactive, and where naming is inconsistent.

### 1.2 Gate A — Assessment complete

**Pass:** a complete inventory exists, the current-state pain is quantified (ungoverned sites,
missing owners, no taxonomy), and stakeholders agree the target IA. **Fail:** inventory
incomplete or IA not agreed — do not proceed to design.

---

## Stage 2 — Design

### 2.1 Define the hub-and-site structure

Decide the small set of hubs and document them. For this solution the production hubs are:

- `Hub – Corp – Prod` — corporate/intranet front door and shared services.
- `Hub – Divisions – Prod` — parent hub for divisional/department landing sites.

And the pilot hub used through Stage 4:

- `Hub – Pilot – Pilot` — used to validate the whole pipeline before touching production.

Keep the number of hubs small; hubs organize, they are not per-team containers. Record the hub
list, which sites associate to which hub, and the intended top navigation.

### 2.2 Define site archetypes and their template names

Fix the closed set of archetypes and the PnP template each maps to. Record this table as the
design's **template catalog**:

| Archetype | Base type | Template name |
|---|---|---|
| Team collaboration | M365 group Team site | `Template – Team Site – Prod` |
| Communication / intranet | Communication site | `Template – Communication Site – Prod` |
| Project (time-boxed) | Team site | `Template – Project Site – Prod` |
| Department landing | Communication site | `Template – Department Hub Site – Prod` |

### 2.3 Define the naming policy

Record `Naming Policy – Sites – Prod`:

- Team: `TEAM-<Dept>-<Purpose>` · Communication: `COMM-<Purpose>` · Project: `PROJ-<Code>`.
- URL = the title upper-cased and hyphenated; department is a valid value from
  `Term Set – Department – Prod`. The provisioning flow computes the name — users do not choose
  the URL.

### 2.4 Define the taxonomy and lifecycle rules

- Taxonomy: term group `Term Group – Enterprise Metadata – Prod` with term sets
  `Term Set – Department – Prod`, `Term Set – Document Type – Prod`, `Term Set – Region – Prod`
  (values supplied by the business taxonomy owner — see Requirement 3).
- Lifecycle: `Lifecycle Policy – Inactive Site – Prod` — every site needs a business owner and
  two site owners; group-connected sites use M365 group expiration; `PROJ-*` sites are reviewed
  at project close for archival. **Retention/records schedules are deferred to compliance.**

### 2.5 Gate B — Design approved

**Pass:** hub list, template catalog, naming policy, taxonomy structure, and lifecycle rules are
documented and signed off by the governance stakeholders. **Fail:** any of these undecided —
resolve before configuring.

---

## Stage 3 — Configure (build in the pilot scope)

All configuration is built and validated in the **pilot scope** first. Nothing tenant-wide is
switched yet.

### 3.1 Create the term store taxonomy

As Term Store Administrator (Requirement 3), create the term group and term sets. Interactive:
SharePoint admin center → **Content services → Term store**. Scripted with PnP:

```powershell
New-PnPTermGroup -Name "Term Group – Enterprise Metadata – Prod"
New-PnPTermSet   -TermGroup "Term Group – Enterprise Metadata – Prod" -Name "Term Set – Department – Prod"
New-PnPTermSet   -TermGroup "Term Group – Enterprise Metadata – Prod" -Name "Term Set – Document Type – Prod"
New-PnPTermSet   -TermGroup "Term Group – Enterprise Metadata – Prod" -Name "Term Set – Region – Prod"
# Add the business-supplied values, e.g.:
New-PnPTerm -TermSet "Term Set – Department – Prod" -TermGroup "Term Group – Enterprise Metadata – Prod" -Name "Finance"
```

### 3.2 Create the governed site columns and content type, and publish

In the **content type gallery** (Requirement 4) create managed-metadata site columns bound to
the term sets, gather them into the content type, and publish it:

- Site columns: `Site Column – Department – Prod`, `Site Column – Document Type – Prod`,
  `Site Column – Region – Prod` (each a **Managed Metadata** column bound to its term set).
- Content type: `Content Type – Governed Document – Prod` (parent = Document) containing the
  three columns; then **publish** it from the gallery so it syndicates to site collections.

### 3.3 Build the reference sites and extract the PnP templates

For each archetype, build the reference site (Requirement 6) to the design — libraries, the
governed content type on the default document library, navigation, theme — then **extract** the
PnP template:

```powershell
Connect-PnPOnline -Url https://<tenant>.sharepoint.com/sites/ref-team -Interactive -ClientId <app-client-id>
Get-PnPSiteTemplate -Out ".\templates\Template - Team Site - Prod.pnp" -PersistBrandingFiles
```

Repeat for `Template – Communication Site – Prod`, `Template – Project Site – Prod`, and
`Template – Department Hub Site – Prod`. Store the `.pnp` files as the versioned template
artifacts.

### 3.4 Register the pilot hubs

Create the pilot hub site and register it as a hub:

```powershell
New-PnPSite -Type CommunicationSite -Title "Hub – Pilot – Pilot" -Url https://<tenant>.sharepoint.com/sites/hub-pilot
Register-PnPHubSite -Site https://<tenant>.sharepoint.com/sites/hub-pilot
```

### 3.5 Stand up the request → approve → provision pipeline

1. Create the intake list `Site Request – Intake – Prod` (columns: Site Type from the archetype
   choice, Business Owner, Department from `Term Set – Department – Prod`, Sensitivity,
   Justification, Requested Owners).
2. Build the approval flow `Provisioning Flow – Approve → Provision – Prod` in Power Automate:
   on new item → send approval to the governance approver (Requirement 5) → on approval, call
   the provisioning helper (below) with the request values.
3. The provisioning helper computes the name from `Naming Policy – Sites – Prod`, provisions the
   correct template, associates the hub, applies metadata, and records the site. Use the script
   in dry-run first (see Stage 4).

### 3.6 Gate C — Configuration built

**Pass:** taxonomy created, content type published and visible in a test site, four templates
extracted, pilot hub registered, intake list and approval flow exist. **Fail:** any artifact
missing or the published content type not syndicating — fix before piloting.

---

## Stage 4 — Pilot

### 4.1 Provision a pilot site — dry run first

Always run the provisioning helper with `-WhatIf` before it changes anything. It reports the
computed name, target template, hub, and metadata it *would* apply:

```powershell
.\New-SPOSiteFromTemplate.ps1 -SiteType Team -Department "Finance" -Purpose "Budgeting" `
  -Owners "owner1@contoso.com","owner2@contoso.com" -Hub "Hub – Pilot – Pilot" `
  -TemplatePath ".\templates\Template - Team Site - Prod.pnp" -WhatIf
```

Confirm the computed URL (`TEAM-FIN-Budgeting`), the template, and the hub are correct.

### 4.2 Provision for real

Re-run with `-Commit` to actually create and configure the site:

```powershell
.\New-SPOSiteFromTemplate.ps1 -SiteType Team -Department "Finance" -Purpose "Budgeting" `
  -Owners "owner1@contoso.com","owner2@contoso.com" -Hub "Hub – Pilot – Pilot" `
  -TemplatePath ".\templates\Template - Team Site - Prod.pnp" -Commit
```

### 4.3 Apply hub association, naming, and metadata to an existing pilot site

For a site provisioned outside the helper (or to re-align one), use the hub/metadata helper —
`-WhatIf` by default:

```powershell
.\Set-SPOHubAndMetadata.ps1 -Url https://<tenant>.sharepoint.com/sites/TEAM-FIN-Budgeting `
  -Hub "Hub – Pilot – Pilot" -Department "Finance" -Region "NA" -WhatIf
# then -Commit to apply
```

### 4.4 Run the pilot end-to-end through the pipeline

Submit a request to `Site Request – Intake – Prod`, approve it via `Provisioning Flow – Approve
→ Provision – Prod`, and confirm the site is provisioned to standard. This proves the governed
path, not just the script.

### 4.5 Gate D — Pilot validated

**Pass:** pilot sites provisioned to standard, associated to `Hub – Pilot – Pilot`, the governed
content type and taxonomy columns present, naming compliant, owners set, and the request→approve
→provision flow completed with an audit record. Run `Get-SPOGovernanceComplianceReport.ps1`
scoped to the pilot and confirm it is clean. **Fail:** any gate item red — remediate before
expanding.

---

## Stage 5 — Validate

Run the validation and compliance scripts across the pilot scope and confirm expected results
(see `05-testing.md`): sites provisioned to standard, hubs associated, taxonomy applied, naming
compliant, owners present. Capture the reports as evidence for the change-control record.

---

## Stage 6 — Expand (tenant-wide, high-impact — under change control)

### 6.1 Register the production hubs

```powershell
Register-PnPHubSite -Site https://<tenant>.sharepoint.com/sites/hub-corp       # Hub – Corp – Prod
Register-PnPHubSite -Site https://<tenant>.sharepoint.com/sites/hub-divisions  # Hub – Divisions – Prod
```

### 6.2 Route all new sites through the governed pipeline — **HIGH IMPACT**

Constrain ungoverned creation so the pipeline is the only path:

- Restrict Microsoft 365 **group creation** to an approved group (Entra group-creation policy).
- Set SharePoint **site creation** to route through the request process (SharePoint admin center
  → **Settings → Site creation**), or disable self-service site creation.

```powershell
# Example (verify the exact property/behavior in your tenant before running):
Set-SPOTenant -DisableSelfServiceSiteCreation $true
```

> **Rollback:** these are reversible tenant settings. If the pipeline cannot keep up or a
> business unit is blocked, re-enable the prior creation setting
> (`Set-SPOTenant -DisableSelfServiceSiteCreation $false`) / relax the group-creation policy to
> its previous value, and communicate the interim path. No sites are deleted by these changes —
> only the *creation path* changes — so rollback is a settings reversal, not data recovery.
> Make the change in a maintenance window with the governance stakeholders and keep the prior
> values recorded.

### 6.3 Onboard remaining sites and associate to hubs

Associate existing in-scope sites to the correct production hub with the hub/metadata helper
(`-WhatIf`, then `-Commit`), and backfill metadata where the business supplies it. Do this in
waves, not all at once.

### 6.4 Gate E — Expansion accepted

**Pass:** production hubs registered, governed pipeline is the creation path, existing sites
associated and (where in scope) metadata-backfilled, and the tenant-wide compliance report meets
the agreed threshold. **Fail:** creation still ungoverned or compliance below threshold —
continue remediation before declaring done.

---

## Rollback summary

- **Provisioning helper** defaults to `-WhatIf`; it changes nothing until `-Commit` — a bad dry
  run is discarded by not committing.
- **Hub/metadata helper** is `-WhatIf` by default; hub association and metadata are reversible
  (`Remove-PnPHubSiteAssociation`, clear the column value).
- **Content type publishing** can be unpublished from the gallery; already-syndicated instances
  remain on sites and can be removed per-library if needed.
- **Tenant creation settings** (Step 6.2) are reversible settings changes, recorded before the
  change — see the rollback note there.


---


# Testing & Validation

Run these after each provisioning and before each gate. Each test states the procedure and the
**expected pass/fail** signal. Scope every test to the pilot first (`Hub – Pilot – Pilot`), then
to production. Tests are read-only unless noted.

---

## Test 1 — Assessment baseline is complete

- **Procedure:** `.\Invoke-SPOArchitectureAssessment.ps1 -OutputPath .\out\SPOARCH-Assessment.csv`
  then open the CSV.
- **Pass:** every site collection appears with URL, template/base type, storage, hub association,
  and owner; orphaned/owner-less sites are flagged.
- **Fail:** sites missing from the inventory, or errors connecting — resolve access/scope and
  re-run before Gate A.

## Test 2 — Provisioning dry run computes the correct name and target

- **Procedure:** run `New-SPOSiteFromTemplate.ps1` with `-WhatIf` for a known request (e.g.
  SiteType Team, Department Finance, Purpose Budgeting).
- **Pass:** the dry run reports the computed URL `TEAM-FIN-Budgeting`, the template
  `Template – Team Site – Prod`, the target hub, and the metadata it would apply — and makes **no
  changes** (verify the site does not exist afterwards).
- **Fail:** wrong computed name, wrong template/hub, or the script attempts a change under
  `-WhatIf` — do not run `-Commit`.

## Test 3 — Site is provisioned to standard

- **Procedure:** after `-Commit`, open the new site and inspect it (or use the validation script,
  Test 6).
- **Pass:** the site exists at the naming-compliant URL; the default document library carries
  `Content Type – Governed Document – Prod`; libraries/columns match the template; the theme and
  navigation match the reference.
- **Fail:** missing content type, missing columns, or structure differs from the template —
  re-extract/re-apply the template.

## Test 4 — Hub association is correct

- **Procedure:** `Get-PnPHubSite` / inspect the site’s hub, or run the hub/metadata helper report.
- **Pass:** the site is associated to exactly the intended hub (`Hub – Pilot – Pilot` in pilot;
  `Hub – Corp – Prod` / `Hub – Divisions – Prod` in production) and inherits hub navigation.
- **Fail:** unassociated, or associated to the wrong hub — re-run
  `Set-SPOHubAndMetadata.ps1 -Commit`.

## Test 5 — Taxonomy is applied and usable

- **Procedure:** in the new site’s document library, add a document and set the Department,
  Document Type, and Region columns.
- **Pass:** each column is a managed-metadata picker bound to the correct term set
  (`Term Set – Department – Prod`, etc.) and accepts only valid terms; the values save and are
  searchable.
- **Fail:** columns are free text, unbound, or missing — confirm the content type published from
  the gallery and the columns bind to the term sets.

## Test 6 — Validation script passes for the scope

- **Procedure:** `.\Get-SPOGovernanceComplianceReport.ps1 -Scope Hub -Hub "Hub – Pilot – Pilot" -OutputPath .\out\SPOARCH-Compliance.csv`
- **Pass:** every in-scope site reports **compliant** for: naming policy, hub association, governed
  content type present, taxonomy columns present, and owner set. The summary shows 0 non-compliant.
- **Fail:** any site flagged non-compliant — remediate the specific gap and re-run; do not pass the
  gate with red items.

## Test 7 — Governed pipeline works end-to-end

- **Procedure:** submit an item to `Site Request – Intake – Prod`, approve via `Provisioning Flow –
  Approve → Provision – Prod`, and watch the site provision.
- **Pass:** the request is approved, the site is created to standard, the flow records the
  approver and timestamp, and the requester is notified. No site is created without an approval.
- **Fail:** provisioning fires without approval, or approval does not trigger provisioning —
  fix the flow before relying on the gate.

## Test 8 — Ungoverned creation is blocked (Expand only)

- **Procedure:** after Step 6.2, attempt to create a site / M365 group as a standard user.
- **Pass:** self-service creation is blocked or routed to the request process; only the pipeline
  creates sites.
- **Fail:** a standard user can still create an ungoverned site — recheck the site-creation and
  group-creation settings (**verify the exact setting in your tenant**).

## Test 9 — Lifecycle signals fire

- **Procedure:** review `Lifecycle Policy – Inactive Site – Prod`: confirm group expiration is
  configured for group-connected sites and that owner-less/inactive sites surface in the
  compliance report.
- **Pass:** sites without a business owner or two site owners are flagged; group-connected sites
  have an expiration policy; `PROJ-*` sites appear in the project-close review list.
- **Fail:** no lifecycle signal for owner-less/inactive sites — configure expiration/review and
  the owner check in the provisioning gate.


---


# Troubleshooting

Common failure modes and how to resolve them. Reuse the named artifacts from the implementation
guide when checking. All checks are read-only unless a fix is explicitly a change.

---

## Connect / authentication

### `Connect-PnPOnline` fails with "AADSTS… application not found" or a consent error
- **Cause:** since September 2024 PnP PowerShell has no default multi-tenant app; you must supply
  your own registered app’s **client ID**, and it must be admin-consented.
- **Resolve:** register `PnP – Provisioning – Prod`
  (`Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP – Provisioning – Prod" -Tenant <tenant>.onmicrosoft.com`),
  admin-consent the required delegated permissions, and pass `-ClientId <app-client-id>` on every
  `Connect-PnPOnline`. See Requirement 1.

### `Connect-SPOService` cannot reach the admin center
- **Cause:** wrong admin host, or a **Government/sovereign cloud** where the URL and endpoint
  differ from Commercial.
- **Resolve:** use your tenant’s admin URL (`https://<tenant>-admin.sharepoint.com` for Commercial;
  the GCC High / DoD host differs) and pass the correct `-Region`/environment. **Verify in your
  tenant** — do not assume the Commercial URL.

### Unattended provisioning flow fails at sign-in
- **Cause:** interactive/delegated auth cannot run unattended.
- **Resolve:** use **certificate-based app-only** auth for the flow’s app registration; store the
  certificate in a secure store; never hardcode a secret in the script.

---

## Provisioning

### The provisioning script "did nothing"
- **Cause:** it ran in the **default `-WhatIf` dry-run**; that is by design.
- **Resolve:** review the planned name/template/hub the dry run printed, then re-run with `-Commit`.

### Computed site URL is wrong or rejected
- **Cause:** the department/purpose contained characters stripped by the naming policy, or the URL
  already exists.
- **Resolve:** the policy upper-cases and strips non-alphanumerics (`TEAM-<Dept>-<Purpose>`); pick a
  distinct purpose/code, or delete/rename the colliding site. Confirm the department is a valid
  value from `Term Set – Department – Prod`.

### `Invoke-PnPSiteTemplate` errors or applies partially
- **Cause:** the `.pnp` template references site columns/content types not yet present (e.g. the
  governed content type has not syndicated), or a handler failed mid-apply.
- **Resolve:** confirm `Content Type – Governed Document – Prod` is **published** and has syndicated
  to the site collection (publishing is asynchronous — allow time), then re-run
  `Invoke-PnPSiteTemplate`. PnP template application is idempotent; re-applying completes missing
  handlers.

### `New-PnPSite` for a group Team site fails on alias
- **Cause:** the M365 group **alias** collides, or group creation is restricted to an approved group
  (Requirement 2) that the running identity is not in.
- **Resolve:** choose a unique alias, or run as an identity permitted to create groups. This is
  expected once self-service group creation is constrained — provision through the approved app.

---

## Hubs

### `Add-PnPHubSiteAssociation` fails: hub not found
- **Cause:** the hub is not registered, or the title does not match exactly.
- **Resolve:** `Get-PnPHubSite` and confirm the exact title (`Hub – Pilot – Pilot`,
  `Hub – Corp – Prod`, `Hub – Divisions – Prod`). Register it with `Register-PnPHubSite` if missing.

### Site associated to the wrong hub
- **Resolve:** re-run `Set-SPOHubAndMetadata.ps1 -Commit` with the correct `-Hub`; it removes the
  existing association and adds the correct one. Association is reversible
  (`Remove-PnPHubSiteAssociation`).

### Hub navigation / theme not showing on an associated site
- **Cause:** hub settings propagate asynchronously, or the site overrides navigation.
- **Resolve:** allow propagation time; confirm the site is not using a custom nav that overrides the
  hub. Re-check with `Get-PnPHubSite`.

---

## Taxonomy & content types

### Managed-metadata columns show as free text or are missing
- **Cause:** the governed content type / site columns did not publish or syndicate.
- **Resolve:** confirm `Content Type – Governed Document – Prod` and the columns
  (`Site Column – Department – Prod`, etc.) exist in the **content type gallery** and are
  **published**; wait for syndication; re-apply the template. See Requirement 4.

### Term set exists but has no values / users cannot pick a term
- **Cause:** the structure was created but the **business term values** were not added (they are the
  org’s vocabulary, supplied by the taxonomy owner — Requirement 3).
- **Resolve:** have the Term Store Administrator / taxonomy owner add the terms
  (`New-PnPTerm -TermSet "Term Set – Department – Prod" …`). The solution builds structure, not the
  determination of which terms are valid.

### Content type gallery not available
- **Cause:** older tenant surfacing the classic Content Type Hub instead.
- **Resolve:** use `/sites/contentTypeHub` publishing on that tenant. **Verify in your tenant** which
  surface is present.

---

## Governance pipeline & lifecycle

### Sites are still being created outside the pipeline
- **Cause:** self-service site and/or M365 **group creation** is not yet constrained (this is only
  done at Expand, Step 6.2).
- **Resolve:** restrict group creation to the approved group and set site creation to route through
  the request process under change control. **Rollback is a settings reversal** — no data is lost.
  Verify with Test 8. **Verify the exact setting/behavior in your tenant.**

### The approval flow does not trigger provisioning
- **Cause:** the flow’s connection to the provisioning helper/app failed, or the approver was not
  set.
- **Resolve:** confirm `Provisioning Flow – Approve → Provision – Prod` has a valid connection and
  the governance approver (Requirement 5) is configured; test with a single request end-to-end
  (Test 7).

### Owner-less or inactive sites are not being caught
- **Cause:** `Lifecycle Policy – Inactive Site – Prod` signals (M365 group expiration, owner check)
  are not configured.
- **Resolve:** enable group expiration for group-connected sites and ensure the provisioning gate
  refuses requests without a business owner and two site owners; run
  `Get-SPOGovernanceComplianceReport.ps1` to surface owner-less sites.

---

## Reporting

### Compliance report shows a site inspectable in the browser as "non-compliant" for content type
- **Cause:** the report connects per-site and may hit a transient permission/throttling error while
  reading fields/content types.
- **Resolve:** re-run scoped to the affected site; confirm the running identity has access; if the
  tenant is throttling, run the report in smaller scopes (per hub) rather than tenant-wide at once.

### Assessment or report is slow / times out on a large tenant
- **Cause:** enumerating thousands of site collections and inspecting each is expensive.
- **Resolve:** run `Invoke-SPOArchitectureAssessment.ps1` off-peak; scope
  `Get-SPOGovernanceComplianceReport.ps1` with `-Scope Hub` rather than `Tenant`; expect
  Microsoft 365 throttling on very large estates and retry.


---


# Best Practices

Durable practices for a governed, navigable SharePoint Online estate.

## Architecture

- **Flat, not nested.** Give each workload its own site collection and relate sites by **hub
  association**, never by classic subsites. Subsites inherit permissions and lifecycle in ways
  that become unmanageable at scale.
- **Few hubs, deliberate hubs.** Hubs organize the estate; they are not per-team containers. A
  handful of hubs on a clear organizing axis (corporate, divisions) beats dozens of overlapping
  ones. Reserve a hub change for a real structural change.
- **A closed set of site archetypes.** Every site should fit a known type with a known template.
  Resist one-off "special" sites; if a new pattern is genuinely needed, add it to the catalog as a
  named template rather than hand-building.

## Provisioning

- **Govern at creation, not after.** It is far cheaper to provision a site correctly than to
  remediate an ungoverned one. The request→approve→provision gate is the core control — protect
  it by constraining self-service creation.
- **Templates as versioned artifacts.** Keep each `.pnp` template under source control and version
  it. Extract from a validated reference site; do not hand-edit templates blindly.
- **Dry-run everything.** Provisioning and hub/metadata scripts default to `-WhatIf`; review the
  planned name, template, hub, and metadata before `-Commit`. Make the safe default the habit.
- **Compute names, don’t let users choose URLs.** Encode `Naming Policy – Sites – Prod` in the
  provisioning flow so every URL is consistent and machine-parseable — later reporting and
  lifecycle automation depend on it.

## Taxonomy & metadata

- **Structure is yours; values are the business’s.** Build the term store structure and the
  governed content type once; get the actual term values (departments, document types, regions)
  from the taxonomy owner. Do not invent vocabulary.
- **Publish, don’t duplicate.** Define the governed content type once in the content type gallery
  and publish it. Never redefine the same columns per site — that is how taxonomy drifts.
- **Keep term sets small and stewarded.** A term set nobody maintains rots. Assign a Term Store
  Administrator and a business taxonomy owner, and review term sets on a schedule.

## Lifecycle & governance

- **No site without an owner.** Require a business owner and two site owners at provisioning;
  refuse the request otherwise. Owner-less sites are the root of ungoverned sprawl.
- **Every site has an end-of-life path.** Use M365 group expiration for group-connected sites and
  review `PROJ-*` sites at project close. Archive or hand to retention deliberately.
- **Defer compliance determinations.** Retention schedules, records declarations, sensitivity-label
  policy, and legal holds are set by compliance/records/legal. Build the mechanism and produce the
  evidence; do not make the determination.

## Operations & safety

- **Least privilege.** Use **SharePoint Administrator**, not Global Administrator, for site and
  provisioning work; reserve Global Admin for the rare tenant-wide setting that truly needs it.
- **App registration hygiene.** Provisioning runs as the registered app `PnP – Provisioning –
  Prod`; use certificate-based app-only auth for unattended flows, store the certificate/secret in
  a secure store, and never hardcode credentials in scripts.
- **Change control for tenant-wide changes.** Disabling self-service creation, restricting group
  creation, and publishing content types are high-impact — make them in a window, record prior
  values, and keep the rollback ready.
- **Verify plan- and cloud-dependent behavior.** Storage/hub limits, advanced records/Syntex
  features, and **Commercial vs Government** admin URLs and endpoints differ by tenant — always
  confirm in your own tenant before relying on a specific limit or URL.
- **Report continuously.** Run the compliance report on a schedule, not just at go-live, so drift
  (unassociated sites, missing metadata, owner-less sites) is caught early.


---


# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** (`01-solution-overview.md`) — the IA + provisioning model: hub-and-site
  structure, site archetypes and templates, the request→approve→provision workflow, naming
  policy, managed-metadata taxonomy, lifecycle, benefits, limitations, and the deployment model.
- **Requirements Guide** (`02-requirements.md`) — solution-specific prerequisites (PnP app
  registration, tenant creation settings, term store admin, content type gallery, governance
  approver, reference build sites), each with how to verify and how to implement — building on the
  shared SharePoint global requirements.
- **Implementation Guide** (`03-implementation.md`) — exact ordered steps across Assess → Design →
  Configure → Pilot → Validate → Expand, every hub/site/template/taxonomy artifact named, with
  pass/fail gates and a documented rollback for the high-impact tenant changes.
- **Testing & Validation** (`05-testing.md`) — nine validation procedures, each with an expected
  pass/fail signal.
- **Troubleshooting** (`06-troubleshooting.md`) — common failure modes and resolutions.
- **Best Practices** (`07-best-practices.md`) — durable practices for architecture, provisioning,
  taxonomy, lifecycle, and safe operations.
- **Executive Summary** (`executive-summary.md`) — outcome, approach, and why the work is low-risk.

## PowerShell tools (5)

All are safe by default (read-only or `-WhatIf`), use modern-auth `Connect-*` cmdlets with no
stored credentials, and reuse the named artifacts from the implementation guide.

1. **`Invoke-SPOArchitectureAssessment.ps1`** — *Discovery (read-only).* Inventories every site
   collection, hub, base template, storage, sharing capability, and owner across the tenant and
   flags orphaned/owner-less and un-associated sites — the assessment baseline for Stage 1.

2. **`New-SPOSiteFromTemplate.ps1`** — *Provisioning helper (`-WhatIf` by default, `-Commit` to
   apply).* Computes the site name from `Naming Policy – Sites – Prod`, provisions the correct
   archetype from a PnP template, associates the target hub, applies the taxonomy, and sets owners.
   Dry-runs by default; changes nothing until `-Commit`.

3. **`Set-SPOHubAndMetadata.ps1`** — *Configuration/remediation (`-WhatIf` by default, `-Commit`).*
   Associates an existing site to its hub and applies naming/metadata (department, region) to bring
   a site into compliance with the architecture. Reversible.

4. **`Get-SPOGovernanceComplianceReport.ps1`** — *Reporting (read-only).* Checks in-scope sites for
   naming-policy compliance, hub association, presence of `Content Type – Governed Document – Prod`,
   taxonomy columns, and owners, and writes a per-site + summary compliance report.

5. **`Get-SPOScopeConfig.ps1`** — *Scope/health helper (read-only).* Verifies the toolchain and
   connection (modules, PnP app, admin role, tenant creation settings, term store/content-type
   availability) and resolves the working scope (pilot vs production hubs) before you run the
   other tools.
