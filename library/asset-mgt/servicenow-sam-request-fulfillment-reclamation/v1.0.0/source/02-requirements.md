# 2. Requirements Guide — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

Verify every requirement before configuring. Each entry: Description, Why, Verify, Implement-if-missing.
Category-wide prerequisites are in `global-requirements-asset-mgt.md`. ServiceNow-specific module
configuration (plugin activation, store apps, console layout) is deferred to ServiceNow's official
documentation — verify presence here, follow ServiceNow's docs to enable.

## 2.1 ServiceNow instance with SAM / ITAM
Description: A ServiceNow instance with the Software Asset Management (and ITAM/CMDB) capability
available and licensed.
Why: The whole workflow — catalog, entitlements, reconciliation, reclamation — runs on the SAM module.
Verify: Sign in to the instance as an admin; confirm the SAM application and its entitlement and
reconciliation areas are present.
Implement: Activate/license the SAM application per ServiceNow's documentation; do not invent plugin
names — follow the vendor's activation steps for your instance version.

## 2.2 Administrative / SAM roles
Description: An account with the SAM administrator role (or equivalent) plus catalog and flow authoring
rights.
Why: Building catalog items, workflows, and reclamation rules requires elevated SAM and platform roles.
Verify: Confirm the account can open the SAM admin area, the Service Catalog designer, and Flow Designer.
Implement: Assign the least-privilege SAM/ITAM admin role plus `catalog_admin` and flow-designer access
per ServiceNow's role documentation.

## 2.3 Entitlement data loaded
Description: Software entitlement records (purchased licenses, quantities, products, and renewal dates)
maintained in the SAM module.
Why: The entitlement check and fulfillment steps consume a known, authoritative entitlement count; with
no entitlements, fulfillment cannot validate availability.
Verify: Locate the entitlement quantity and renewal date for a representative product; run
`SNOWSAM-Discovery.ps1` to read entitlement records via the Table API.
Implement: Import purchase orders / true-up statements into the SAM entitlement records (ServiceNow
import sets or the SAM content service), per ServiceNow's documentation.

## 2.4 Software model / catalog content
Description: Software models (the products you license) defined and mappable to catalog items.
Why: A catalog item must reference a real software model so a request maps to an entitlement.
Verify: Confirm the products in pilot scope exist as software models; run `SNOWSAM-Validation.ps1`.
Implement: Create/normalize the software models for in-scope products (SAM content service or manual),
per ServiceNow's documentation.

## 2.5 Discovery / usage data integration
Description: A source of what is actually installed or used — Discovery/CMDB, an SCCM/Intune integration,
or SaaS sign-in/usage telemetry — feeding the SAM reconciliation.
Why: Reclamation of unused licenses requires a usage signal; reconciliation needs install data to match
entitlements to deployments.
Verify: Export an installed-software or last-used report for a sample of devices/users; run
`SNOWSAM-Discovery.ps1` to confirm install/usage records are present.
Implement: Enable Discovery or the relevant integration and confirm install/usage data lands in the
reconciliation tables, per ServiceNow's documentation.

## 2.6 Approval owners and groups
Description: Named owners for the approval and fulfillment groups — `Approval Group – Restricted Software
– Triage` and `Fulfillment Group – Software – Fulfillment`.
Why: Restricted requests need an approver, and fulfillment needs an owner; an unstaffed step stalls the
queue.
Verify: Confirm the groups exist with members and that a test request routes to a real person.
Implement: Create the groups, assign members, and set group managers per the named convention.

## 2.7 Reporting / KPI surface
Description: Access to ServiceNow reporting (or Performance Analytics) plus an external reporting
toolchain (Excel / Power BI) for the KPI set.
Why: Request throughput, time-to-fulfill, and reclamation yield are delivered as `KPI Set – Request &
Reclamation – Reporting`.
Verify: You can build a report/dashboard over the request and entitlement tables; the scripts can export
CSV for external analysis.
Implement: Enable reporting/Performance Analytics access; install Power BI Desktop / current Excel for
external dashboards.

## 2.8 Pilot scope defined
Description: One representative product family chosen as `Pilot Scope – First Product Family – Pilot`.
Why: The workflow is validated on a controlled scope before fleet-wide rollout.
Verify: A pilot product family and its entitlement/usage data owners are identified.
Implement: Choose a high-value, well-understood product family with good usage data as the first pass.

---
## Checklist
- [ ] ServiceNow instance with SAM/ITAM available
- [ ] SAM admin + catalog + flow authoring roles
- [ ] Entitlement data loaded — `SNOWSAM-Discovery.ps1`
- [ ] Software models / catalog content for pilot products — `SNOWSAM-Validation.ps1`
- [ ] Discovery / usage data integrated for reclamation
- [ ] Approval and fulfillment groups staffed
- [ ] Reporting / KPI surface available
- [ ] `Pilot Scope – First Product Family – Pilot` chosen
