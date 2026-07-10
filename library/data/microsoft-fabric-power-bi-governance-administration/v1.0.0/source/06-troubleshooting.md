# 6. Troubleshooting — Microsoft Fabric & Power BI Governance & Administration

Common failures, their cause, and the fix. Symptom → Cause → Fix.

## Admin portal or scripts

### The Admin portal / Tenant settings page is not visible
- Cause: the signed-in account lacks the Fabric Administrator / Power BI Administrator role (requirement 2.1 / global G2).
- Fix: assign the role in Entra → Roles and administrators, sign out and back in. A few settings additionally require Global Administrator — use a global admin for those.

### `Connect-PowerBIServiceAccount` or `Invoke-PowerBIRestMethod` fails
- Cause: MicrosoftPowerBIMgmt not installed, or the account is not an admin, or you called an `admin/...` endpoint without admin rights.
- Fix: `Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser`; confirm the admin role; ensure the URL uses the `admin/` prefix only when signed in as an admin.

### Scripts return empty capacities/workspaces but no error
- Cause: the token is valid but the account has no admin scope, so the admin API returns an empty set.
- Fix: re-authenticate as a Fabric/Power BI Administrator; for unattended runs, confirm the service principal is in `Fabric Admin API Apps – Platform – Prod` and the "service principals can use read-only admin APIs" tenant setting is enabled (2.6 / global G5).

### Activity-log calls return nothing
- Cause: the requested window exceeds the API limit (activity events are queried per day, up to ~30 days back), the log is not yet populated, or auditing is not enabled.
- Fix: keep `-Days` at 30 or fewer; confirm auditing is on for the tenant; allow time for events to appear (there is ingestion latency).

### `FABGOV-Report.ps1 -ServicePrincipal` fails to connect
- Cause: missing `-TenantId/-AppId/-AppSecret`, an expired secret, or the app is not permitted for admin APIs.
- Fix: supply all three parameters from a secret store; rotate the secret if expired; confirm the app's service principal is enabled for read-only admin APIs.

## Tenant settings

### A tenant-setting change did not take effect for a user
- Cause: the setting is scoped to a security group the user is not in, or Entra group membership has not propagated yet.
- Fix: confirm the user's group membership (`Governance Pilot Ring – Fabric – Ring1` during pilot); allow propagation time; re-check with `FABGOV-Validate.ps1`.

### Legitimate work broke after applying the baseline
- Cause: a control (export, external sharing, workspace creation) was scoped too tightly, catching real users.
- Fix: because you piloted on the ring, only ring users are affected — widen the enabled group or add the user; this is exactly the signal the pilot exists to surface before tenant-wide expansion.

### A setting only offers "entire organization" (no group scope)
- Cause: some tenant settings are not group-scopable (`canSpecifySecurityGroups` is false).
- Fix: treat it as an all-or-nothing decision, get explicit change approval, and record the rollback; the baseline script flags these as "org-wide only".

### Publish to web is still available to a pilot user
- Cause: the setting was saved to the wrong group, or an existing embed code predates the change.
- Fix: re-scope Publish to web to disabled/limited for the ring; review and delete existing embed codes in Admin portal → Embed codes.

## Capacity

### Reports are slow or throttled
- Cause: the capacity (`Fabric Capacity – Analytics – Prod`) is overloaded — too many/too-heavy workloads for its SKU.
- Fix: open the Fabric Capacity Metrics app, identify the top consumers, move non-production workloads off the capacity, or resize the SKU. *Verify current SKU sizing guidance for your workload.*

### A workspace will not assign to the capacity
- Cause: the operator lacks capacity-assignment permission, or the workspace license mode is wrong.
- Fix: ensure `Fabric Admins – Platform – Prod` holds capacity-admin/assignment rights; set the workspace to the correct Premium/Fabric license mode in Workspace settings before assigning.

## Deployment pipelines

### "Deploy to Test/Production" is greyed out or errors
- Cause: a stage is not paired to a workspace, the target stage needs a capacity, or the operator lacks pipeline access.
- Fix: confirm each stage is paired (Dev/Test/Prod → the matching `Sales BI – Content – *`), ensure Test/Prod workspaces are on `Fabric Capacity – Analytics – Prod`, and that only `Fabric Admins – Platform – Prod` (with pipeline access) deploys to Prod.

### Promotion moved more than expected
- Cause: no deployment rules, so data-source/connection differences promoted along with content.
- Fix: set deployment rules on the Production stage to swap data sources; use the compare view before every deploy.

## Access model

### `FABGOV-Validate.ps1` flags "individual user holds roles"
- Cause: a workspace role was assigned to a person instead of a group.
- Fix: remove the user in Manage access and add the correct group (`BI Creators – Analytics – Pilot`, `BI Content Certifiers – Analytics – Prod`, or `Fabric Admins – Platform – Prod`); re-run the validator.

### `Add-PowerBIWorkspaceUser` fails with a group name
- Cause: the cmdlet may require the group's Entra object ID rather than its display name.
- Fix: resolve the group's object ID (Entra → Groups) and pass it as the `-Identifier`; the provision script emits this hint on failure.
