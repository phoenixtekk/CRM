# 2. Requirements Guide — Microsoft Fabric & Power BI Governance & Administration

Verify every requirement before you configure anything. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant with Fabric/Power BI enabled, admin role,
licensing/capacity, identity/groups, admin-API access, Purview alignment, lifecycle target, change
control + pilot ring) are in `global-requirements-data.md` — do not repeat them; this file covers only
what is specific to this solution.

## 2.1 Admin portal access with the Fabric/Power BI Administrator role
Description: The operator can open the Fabric/Power BI admin portal and edit tenant settings.
Why: The entire tenant-settings baseline, capacity settings, and monitoring live behind the admin portal, which requires the admin role (global requirement G2).
Verify: Go to `https://app.powerbi.com` → Settings (gear) → **Admin portal**; the **Tenant settings**, **Capacity settings**, and **Monitoring** pages are visible and editable.
Implement: Assign the Fabric Administrator (or Power BI Administrator) role in Entra → Roles and administrators. Reserve Global Administrator for the few settings that require it.

## 2.2 MicrosoftPowerBIMgmt PowerShell module
Description: The MicrosoftPowerBIMgmt module on the workstation running the scripts.
Why: The discovery, validation, report, tenant-settings, and workspace-provision scripts call the Power BI / Fabric admin REST APIs through this module (`Connect-PowerBIServiceAccount`, `Invoke-PowerBIRestMethod`, `New-PowerBIWorkspace`).
Verify: `Get-Module -ListAvailable MicrosoftPowerBIMgmt` returns a version.
Implement: Run `Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser`.

## 2.3 Security groups for baseline scoping and workspace roles
Description: Entra security groups that will (a) scope tenant settings and (b) receive workspace roles, plus the governance pilot ring.
Why: Governance is applied to groups, not individuals (global G4), so tenant settings and workspace access stay manageable and auditable, and the pilot ring lets you test tenant-scoped settings safely.
Verify: The intended groups exist in Entra → Groups. Run `FABGOV-Discovery.ps1`, which lists the groups it expects.
Implement: Create these security groups before configuring (names used throughout this guide):
- `Governance Pilot Ring – Fabric – Ring1` (the pilot audience for tenant-scoped settings)
- `Fabric Admins – Platform – Prod` (holders of the admin role / admin-portal access)
- `BI Creators – Analytics – Pilot` (users allowed to create workspaces during pilot)
- `BI Content Certifiers – Analytics – Prod` (users allowed to certify content)
- `Fabric Admin API Apps – Platform – Prod` (service principals permitted to call read-only admin APIs)

## 2.4 A capacity to manage and monitor
Description: At least one Fabric (F-SKU) or Power BI Premium (P-SKU) capacity in the tenant.
Why: Capacity management, workload settings, deployment pipelines' production stage, and utilization/cost monitoring all require a capacity (global G3). *Verify the current SKU-to-feature mapping in your tenant — feature gating changes.*
Verify: Admin portal → **Capacity settings**; at least one capacity is listed and Active. Run `FABGOV-Discovery.ps1` to confirm it is returned by the admin API.
Implement: Acquire and provision a Fabric F-SKU (or Power BI Premium P-SKU) capacity, and record its name as `Fabric Capacity – Analytics – Prod`.

## 2.5 Three workspaces (or the right to create them) for the lifecycle
Description: Distinct dev, test, and prod workspaces for at least one pilot workload.
Why: Deployment pipelines pair one workspace to each of the three stages; production must never be edited directly (global G7).
Verify: In the Power BI service you can create workspaces and assign at least one to the capacity.
Implement: The implementation guide creates `Sales BI – Content – Dev`, `Sales BI – Content – Test`, and `Sales BI – Content – Prod`. Confirm you have rights to create them (governed by the "create workspaces" tenant setting).

## 2.6 Service principal enabled for read-only admin APIs (for unattended scripts)
Description: An Entra app registration whose service principal is permitted to call the read-only admin APIs, if you want the discovery/report scripts to run unattended.
Why: Scheduled monitoring (the report script on a schedule) should not depend on a person's interactive sign-in; the scanner and admin read APIs support a service principal when the tenant setting allows it (global G5).
Verify: Admin portal → Tenant settings → **Admin API settings** → "Service principals can access read-only admin APIs" is enabled for `Fabric Admin API Apps – Platform – Prod`, and the app is a member of that group. *Verify the exact setting name in your tenant; the admin-API settings surface changes.*
Implement: Register an Entra app, add its service principal to `Fabric Admin API Apps – Platform – Prod`, and enable the tenant setting for that group. Interactive (delegated) runs do not need this.

## 2.7 A change-approval record for tenant-wide settings
Description: A documented approval step and rollback note for each tenant-setting change (global G8).
Why: Tenant settings affect every user; the pilot proves the setting, but tenant-wide application must be approved and reversible. Business decisions about which settings to enforce are the customer's.
Verify: A change ticket / record template exists that captures the setting, the before value, the after value, the approver, and the rollback.
Implement: Adopt the change-control record before the Expand step; the implementation guide references it at each tenant-wide apply.
