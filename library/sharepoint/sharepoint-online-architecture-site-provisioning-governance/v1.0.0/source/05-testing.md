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
