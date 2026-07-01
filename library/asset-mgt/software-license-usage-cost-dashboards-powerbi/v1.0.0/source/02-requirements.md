# 2. Requirements Guide — Software License Usage Reporting & Cost Dashboards (Power BI)

Verify every requirement before building. Each entry: Description · Why · Verify · Implement-if-missing.
Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 Power BI Desktop
Description: A current Power BI Desktop install on the SAM analyst's workstation.
Why: The dataset, model, and dashboard pages are authored in Power BI Desktop before publishing.
Verify: Power BI Desktop opens and Help shows a current version; it can create a blank report.
Implement: Install Power BI Desktop from the Microsoft Store or the standalone installer.

## 2.2 Power BI service workspace
Description: A Power BI service workspace to publish the dataset and report into, plus rights to set scheduled refresh.
Why: Scheduled refresh and distribution to leadership/procurement happen in the service, not Desktop.
Verify: Sign in at `https://app.powerbi.com` and confirm you can open or create a workspace.
Implement: Provision a Power BI (Pro or Premium Per User) license and create the workspace `License Reporting – Software Assets – Workspace`.

## 2.3 Excel with Power Query
Description: A current Excel with Power Query (Get & Transform) for staging and quick reconciliation.
Why: License/contract exports are often cleaned and reconciled in Excel Power Query before modeling.
Verify: In Excel, Data > Get Data is present (Power Query).
Implement: Install a current Microsoft 365 Excel; Power Query is built in.

## 2.4 Access to license entitlement data
Description: A reachable source of entitlement counts, products, unit cost, and renewal dates (global G3).
Why: The deployment, cost-per-seat, and expirations KPIs are all calculated against entitlements.
Verify: You can open the entitlement source and read the count and renewal date for a sample product; run `LICRPT-Discovery.ps1` to confirm M365 license counts.
Implement: Stand up the entitlement record (per global G3) and export current quantities, unit costs, and renewal dates.

## 2.5 Access to usage / deployment data
Description: A reachable source of actual usage and deployment — M365/SaaS activity reports and discovery inventory (global G4).
Why: Active usage and reharvesting KPIs need real consumption, not just assignment.
Verify: You can export a usage or installed-software report for a sample of users/devices; run `LICRPT-Discovery.ps1` to confirm M365 usage reports are reachable.
Implement: Enable M365 usage reporting and Intune/Configuration Manager (or discovery-tool) inventory per global G4.

## 2.6 Microsoft Graph PowerShell (for the scripts)
Description: The Microsoft Graph PowerShell SDK on the workstation running the scripts.
Why: The discovery, validation, report, and scheduled-export scripts read license and usage data through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version.
Implement: Run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.7 Read scopes for license & usage data
Description: Delegated/least-privilege read scopes for organization licensing and usage reports.
Why: Reading subscribed SKUs and usage detail requires consent to specific Graph scopes.
Verify: `Connect-MgGraph` succeeds with `Organization.Read.All`, `Reports.Read.All`, and `User.Read.All`.
Implement: Have an administrator consent the read scopes (least privilege; no write scopes are needed).

## 2.8 On-premises data gateway (only if a source is on-prem)
Description: An on-premises data gateway when a data source (a file share, an on-prem SQL/SAM database) is not cloud-reachable.
Why: Scheduled refresh in the service can only reach on-prem sources through a gateway.
Verify: In the service, Settings > Manage gateways shows a registered, online gateway covering the source.
Implement: Install and register the standard on-premises data gateway; bind the dataset's source to it.

## 2.9 A reporting/distribution destination
Description: A defined audience and channel for the published report (an Entra group + the workspace/app).
Why: Distribution targets a named leadership/procurement group, not individuals.
Verify: The group `License Reporting – Leadership & Procurement – Audience` exists and members are correct.
Implement: Create the audience group (or build it with `LICRPT-Set-ScopeTargeting.ps1`) and grant it report access.

---
## Checklist
- [ ] Power BI Desktop installed
- [ ] Power BI service workspace `License Reporting – Software Assets – Workspace` created
- [ ] Excel with Power Query available
- [ ] License entitlement data reachable — `LICRPT-Discovery.ps1`
- [ ] Usage / deployment data reachable — `LICRPT-Discovery.ps1`
- [ ] Microsoft Graph PowerShell SDK installed
- [ ] Read scopes consented (`Organization.Read.All`, `Reports.Read.All`, `User.Read.All`)
- [ ] On-premises data gateway (only if a source is on-prem)
- [ ] Audience group `License Reporting – Leadership & Procurement – Audience` created
