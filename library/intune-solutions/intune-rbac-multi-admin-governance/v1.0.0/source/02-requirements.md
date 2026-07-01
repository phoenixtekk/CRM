# 2. Requirements Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval)

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

Named artifacts used throughout this solution (create them in section 2.6–2.9 and reuse the names
verbatim):

| Artifact | Name |
|---|---|
| Custom role | `App Manager – Region A – Prod` |
| Custom role | `Policy Reader – All – Audit` |
| Scope tag | `Region A – Devices – Prod` |
| Admin scope group | `Intune Admins – Region A – Prod` |
| Approver scope group | `Change Approvers – Apps – Prod` |
| Role assignment | `App Manager Assignment – Region A – Prod` |
| Access policy | `App Deploy Approval – All – Prod` |
| Access policy | `Script Deploy Approval – All – Prod` |

## 2.1 Intune licensing
Description: Intune (Plan 1 or via M365 E3/E5/Business Premium). RBAC and multi-admin approval are
built-in Intune features.
Why: Roles, scope tags, and access policies are delivered by Intune.
Verify: M365 admin center → Billing → Licenses.
Implement: Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Entra ID groups for admins and approvers
Description: Microsoft Entra security groups for admin members and for approvers.
Why: Role assignments target admin groups; access policies target an approver group.
Verify: Entra → Groups; confirm the groups exist (or run `RBACGOV-Discovery.ps1`).
Implement: Entra → Groups → New group → Security; or build them with
`RBACGOV-Set-ScopeTargeting.ps1`. Use the names `Intune Admins – Region A – Prod` and
`Change Approvers – Apps – Prod`.

## 2.3 Operator holds an RBAC-capable role
Description: The person configuring governance holds Intune Administrator (or Global Administrator
for the initial setup).
Why: Creating role definitions, scope tags, and access policies requires elevated rights.
Verify: Entra → Roles and administrators → confirm Intune Administrator.
Implement: Assign Intune Administrator to the operator; reserve Global Administrator for tenant-wide
changes.

## 2.4 A break-glass administrator (do not lock yourself out)
Description: At least one emergency Global Administrator account that is excluded from the restricted
custom roles and from the multi-admin approval gate.
Why: Tight RBAC plus an approval gate can lock out all working admins; a break-glass account is the
recovery path.
Verify: Entra → Roles and administrators → Global Administrator → confirm a dedicated, monitored
emergency account exists and is excluded from the approver group it would otherwise gate.
Implement: Create/confirm a cloud-only break-glass Global Administrator with a stored, sealed
credential and exclude it from `Change Approvers – Apps – Prod`.

## 2.5 An admin-role design (least privilege)
Description: A written design of which admins need which permissions and which slice of objects.
Why: Custom roles and scope tags are only as good as the least-privilege design behind them.
Verify: A documented map of admin personas → permissions → scope; run `RBACGOV-Discovery.ps1` to
inventory current roles and assignments as a baseline.
Implement: Draft the persona-to-role map; define `App Manager – Region A – Prod` and
`Policy Reader – All – Audit` from it.

## 2.6 A scope-tag taxonomy
Description: A consistent set of scope tags (for example by region, business unit, or platform).
Why: Scope tags are the who-touches-what boundary; an inconsistent taxonomy defeats the purpose.
Verify: Intune → Tenant administration → Roles → Scope tags; run `RBACGOV-Discovery.ps1`.
Implement: Define the taxonomy; create `Region A – Devices – Prod` and apply it to that region's
objects.

## 2.7 A list of high-risk resource types to gate
Description: The resource types whose changes should require a second approver (for example apps and
scripts).
Why: Multi-admin approval is configured per resource type; you must decide which to gate.
Verify: Intune → Tenant administration → Multi admin approval → Access policies; run
`RBACGOV-Validation.ps1`.
Implement: Decide the gated types and create `App Deploy Approval – All – Prod` and
`Script Deploy Approval – All – Prod`.

## 2.8 A change-control process for approvals
Description: An agreed process for who approves, the SLA to respond, and how rejections are
communicated.
Why: An approval gate with no process becomes a bottleneck and is bypassed.
Verify: A documented approval SLA and approver roster; the approver group is populated.
Implement: Define the SLA; populate `Change Approvers – Apps – Prod`.

## 2.9 Network access to Microsoft Graph / Intune endpoints
Description: Outbound HTTPS to Microsoft Graph and Intune service URLs for the PowerShell scripts.
Why: The discovery, validation, and report scripts call Microsoft Graph.
Verify: From the admin workstation, reach `https://graph.microsoft.com`.
Implement: Allow Microsoft Graph / Intune URLs through proxy/firewall.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Admin + approver Entra groups exist — `RBACGOV-Discovery.ps1`
- [ ] Operator holds Intune Administrator
- [ ] Break-glass Global Administrator exists and is excluded from the gate
- [ ] Least-privilege admin-role design documented
- [ ] Scope-tag taxonomy defined
- [ ] High-risk resource types to gate chosen
- [ ] Approval change-control process and SLA agreed
- [ ] Network allows Microsoft Graph / Intune endpoints
