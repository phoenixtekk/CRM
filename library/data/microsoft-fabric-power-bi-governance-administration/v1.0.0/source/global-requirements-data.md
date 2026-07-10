# Global Requirements — Data (category-level)

These requirements apply to every solution in the Data category (Microsoft Fabric / Power BI and related
analytics-platform administration and governance). Published once at the category level so listings stay
small. Confirm before deploying any Data solution. Each entry: Description / Why / Verify /
Implement-if-missing.

> Analytics platforms sprawl through self-service. Govern at the platform level (tenant settings,
> capacities, workspaces) before locking down individual content, change tenant settings in a controlled
> way (they affect every user), and pilot governance in a ring before enforcing tenant-wide.

## G1. Microsoft 365 / Entra tenant with Fabric/Power BI enabled
Description: A tenant with Microsoft Fabric / Power BI service enabled.
Why: All administration and governance operate against the tenant's Fabric/Power BI service.
Verify: Sign in to `https://app.powerbi.com` / the Fabric portal; the admin portal is reachable.
Implement: Enable Fabric/Power BI and confirm the service is provisioned.

## G2. Fabric / Power BI administrative role
Description: Fabric Administrator / Power BI Administrator (and Global Administrator for some tenant settings).
Why: Tenant settings, capacity management, and the admin APIs require an admin role.
Verify: Entra -> `Roles and administrators`; confirm Fabric Administrator (or Power BI Administrator).
Implement: Assign the Fabric/Power BI Administrator role; reserve Global Administrator for tenant-wide changes.

## G3. Licensing and capacity
Description: The Fabric/Power BI licensing in scope — Power BI Pro/PPU per user and/or Fabric (F-SKU) or Power BI Premium (P-SKU) capacity.
Why: Capacity management, deployment pipelines, and some governance features are capacity/license-gated.
Verify: Admin portal -> capacity settings and `Microsoft 365 admin center -> Billing -> Licenses`. *Verify current SKU/feature mapping in your tenant.*
Implement: Acquire/assign the required licenses and capacity before configuring capacity-gated features.

## G4. Identity, groups, and access model
Description: Entra ID security groups to drive workspace roles and tenant-setting scoping.
Why: Governance is applied to groups, not individuals, so access stays manageable and auditable.
Verify: The intended Entra groups exist. Run the solution's discovery script.
Implement: Create the security groups (see the Entra category solutions) before assigning workspace/access roles.

## G5. Admin API access
Description: Access to the Fabric/Power BI admin and scanner REST APIs (via delegated admin or a service principal enabled for admin APIs).
Why: Inventory, activity logs, and metadata scanning are collected through the admin APIs.
Verify: The admin API is reachable with the operator's token / service principal. *Verify service-principal-for-admin-API tenant setting.*
Implement: Enable the "service principals can use read-only admin APIs" tenant setting and grant the app the needed scope.

## G6. Information protection alignment (where used)
Description: Microsoft Purview sensitivity labels available to Fabric/Power BI where labeling/DLP is in scope.
Why: Data-classification of analytics content is delivered via Purview, not the Fabric admin surface.
Verify: Sensitivity labels are published and enabled for Fabric/Power BI.
Implement: Publish labels (see the Purview information-protection solutions). *Data-classification determinations are the compliance team's decision; this guide covers platform administration.*

## G7. Source control / lifecycle target
Description: A dev/test/prod separation (workspaces and, where used, Git integration) for content lifecycle.
Why: Deployment pipelines and safe promotion need distinct stages.
Verify: Separate dev/test/prod workspaces (or a Git-integrated workspace) exist or can be created.
Implement: Create the staged workspaces and connect Git integration where the solution uses it.

## G8. Change-control for tenant settings + a pilot ring
Description: A change-approval process for tenant-setting changes and a pilot group to validate against.
Why: Tenant settings affect every user; changes are piloted on a ring and approved before tenant-wide.
Verify: A pilot group exists; tenant-setting changes follow an approval step.
Implement: Define the pilot ring and approval step before applying tenant-wide governance. *Tenant-setting business decisions are the customer's.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
