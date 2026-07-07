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
