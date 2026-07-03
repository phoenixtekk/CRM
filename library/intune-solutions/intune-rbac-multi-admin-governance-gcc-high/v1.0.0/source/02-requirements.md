# 2. Requirements Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> GCC High note: every "Verify" and "Implement" step below uses the **sovereign `*.us` portals** and
> **US Gov Graph** (`-Environment USGov`, `https://graph.microsoft.us`). Do not use the Commercial
> `*.com` URLs — GCC High credentials fail against them.

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

## 2.0 GCC High tenant (not GCC, not Commercial)
Description: An Intune GCC High or DoD tenant on Azure Government, with the appropriate US Government
licensing (for example Microsoft 365 G3/G5 Government, or Intune Plan 1 for Government).
Why: This edition's portals and Graph endpoints only work against the government instance; a GCC
(state/local, commercial-instance) or Commercial tenant uses the `*.com` portals instead.
Verify: `https://intune.microsoft.us` loads and you can sign in with your government account;
Microsoft 365 admin at `https://portal.office365.us/adminportal/` shows US Government licensing.
Implement: Procure GCC High / DoD licensing through your government-authorized reseller; if you are
actually a GCC (not High) tenant, use the Commercial edition of this solution.

## 2.1 Intune licensing (Government)
Description: Intune (Plan 1 or via M365 G3/G5 Government / Business Premium equivalent). RBAC and
multi-admin approval are built-in Intune features and part of the standard MDM feature set that
Microsoft lists as available in GCC High/DoD.
Why: Roles, scope tags, and access policies are delivered by Intune.
Verify: `https://portal.office365.us/adminportal/` → Billing → Licenses.
Implement: Assign M365 G3/G5 Government (Intune included) or standalone Intune for Government.

## 2.2 Entra ID groups for admins and approvers
Description: Microsoft Entra **security** groups for admin members and for approvers.
Why: Role assignments target admin groups; access policies target an approver group. Note: the
approver group **must be a security group** — distribution lists, Microsoft 365 groups, and
mail-enabled security groups silently fail to resolve approver membership.
Verify: `https://entra.microsoft.us` → Groups; confirm the groups exist (or run
`RBACGOVG-Discovery.ps1`).
Implement: Entra (`entra.microsoft.us`) → Groups → New group → Security; or build them with
`RBACGOVG-Set-ScopeTargeting.ps1`. Use the names `Intune Admins – Region A – Prod` and
`Change Approvers – Apps – Prod`.

## 2.3 Operator holds an RBAC-capable role
Description: The person configuring governance holds Intune Administrator (or Global Administrator
for the initial setup) in the GCC High tenant.
Why: Creating role definitions, scope tags, and access policies requires elevated rights. Microsoft
recommends a least-privileged custom Intune role for routine access-policy management over the
privileged Intune Administrator role.
Verify: `https://entra.microsoft.us` → Roles and administrators → confirm Intune Administrator.
Implement: Assign Intune Administrator to the operator; reserve Global Administrator for tenant-wide
changes.

## 2.4 A break-glass administrator (do not lock yourself out)
Description: At least one emergency Global Administrator account that is excluded from the restricted
custom roles and from the multi-admin approval gate.
Why: Tight RBAC plus an approval gate can lock out all working admins; a break-glass account is the
recovery path. This is especially important in GCC High where support turnaround can be slower.
Verify: `https://entra.microsoft.us` → Roles and administrators → Global Administrator → confirm a
dedicated, monitored emergency account exists and is excluded from the approver group it would
otherwise gate.
Implement: Create/confirm a cloud-only break-glass Global Administrator with a stored, sealed
credential and exclude it from `Change Approvers – Apps – Prod`.

## 2.5 An admin-role design (least privilege)
Description: A written design of which admins need which permissions and which slice of objects.
Why: Custom roles and scope tags are only as good as the least-privilege design behind them.
Verify: A documented map of admin personas → permissions → scope; run `RBACGOVG-Discovery.ps1` to
inventory current roles and assignments as a baseline.
Implement: Draft the persona-to-role map; define `App Manager – Region A – Prod` and
`Policy Reader – All – Audit` from it.

## 2.6 A scope-tag taxonomy
Description: A consistent set of scope tags (for example by region, business unit, or platform).
Why: Scope tags are the who-touches-what boundary; an inconsistent taxonomy defeats the purpose.
Verify: `https://intune.microsoft.us` → Tenant administration → Roles → Scope tags; run
`RBACGOVG-Discovery.ps1`.
Implement: Define the taxonomy; create `Region A – Devices – Prod` and apply it to that region's
objects.

## 2.7 A list of high-risk resource types to gate
Description: The resource types whose changes should require a second approver (for example apps and
scripts).
Why: Multi-admin approval is configured per resource type; you must decide which to gate.
Verify: `https://intune.microsoft.us` → Tenant administration → Multi Admin Approval → Access
policies; run `RBACGOVG-Validation.ps1`.
Implement: Decide the gated types and create `App Deploy Approval – All – Prod` and
`Script Deploy Approval – All – Prod`.

## 2.8 A change-control process for approvals
Description: An agreed process for who approves, the SLA to respond, and how rejections are
communicated.
Why: An approval gate with no process becomes a bottleneck and is bypassed. Intune does **not** send
notifications when requests are created; approvers must be told out-of-band. There is no
Copilot/Change Review Agent assist in GCC High, so the human SLA matters even more.
Verify: A documented approval SLA and approver roster; the approver group is populated. Remember a
request that isn't completed within **3 days expires** and must be resubmitted.
Implement: Define the SLA; populate `Change Approvers – Apps – Prod`.

## 2.9 Network access to US Gov Microsoft Graph / Intune endpoints
Description: Outbound HTTPS to **US Government** Microsoft Graph and Intune service URLs for the
PowerShell scripts and portal.
Why: The discovery, validation, and report scripts call **US Gov** Microsoft Graph
(`https://graph.microsoft.us`) via `login.microsoftonline.us`. SSL inspection is **not supported** on
`*.manage.microsoft.us`.
Verify: From the admin workstation, reach `https://graph.microsoft.us` and `https://login.microsoftonline.us`.
Implement: Allow the published US Government Intune/Graph URL & IP ranges through proxy/firewall; do
not TLS-inspect `*.manage.microsoft.us`. See Microsoft's "Network endpoints for US government
deployments."

---
## Checklist
- [ ] GCC High / DoD tenant confirmed (not GCC/Commercial)
- [ ] Government Intune licensing assigned
- [ ] Admin + approver Entra **security** groups exist — `RBACGOVG-Discovery.ps1`
- [ ] Operator holds Intune Administrator (least-privilege custom role for routine work)
- [ ] Break-glass Global Administrator exists and is excluded from the gate
- [ ] Least-privilege admin-role design documented
- [ ] Scope-tag taxonomy defined
- [ ] High-risk resource types to gate chosen
- [ ] Approval change-control process and SLA agreed (no Copilot assist in GCC High)
- [ ] Network allows US Gov Microsoft Graph / Intune endpoints (no SSL inspection of `*.manage.microsoft.us`)
