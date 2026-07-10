# 2. Requirements Guide — Entra Privileged Identity Management (PIM) — Government (GCC High)

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

> **Government (GCC High) edition.** This edition targets Microsoft's US Government national cloud
> (Azure Government / GCC High) for US public-sector and defense-industrial-base tenants. Portals are
> the GCC High endpoints (`entra.microsoft.us` / `portal.azure.us`) and scripts target the US Gov cloud
> (`Connect-MgGraph -Environment USGov`). **Feature parity in GCC High/DoD can lag commercial** — in
> particular, confirm **Entra ID P2 / PIM availability** in your specific cloud. See
> `gcc-high-parity-notes.md` and, throughout, *verify against current Microsoft Government documentation*.

## 2.1 Microsoft Entra ID P2 licensing
Description: Microsoft Entra ID P2 for every user who will hold an eligible PIM assignment or act as an
approver (P2 is also included in Microsoft Entra ID Governance and certain E5 suites).
Why: PIM — eligible assignments, activation policy, access reviews, and PIM alerts — is a P2 feature. A
P1-only tenant cannot use it.
Verify: GCC High M365 admin center -> `Billing -> Licenses`; confirm Microsoft Entra ID P2 seats and
free count. In the GCC High Entra admin center (`entra.microsoft.us`) -> `Identity governance ->
Privileged Identity Management`, PIM is available.
*Entra ID P2 licensing and PIM availability vary by tenant, cloud, and program — GCC High and DoD (IL5)
government SKUs differ from commercial, and feature availability can lag. **Verify current Entra ID P2 /
PIM availability for your GCC High (or DoD) tenant against current Microsoft Government documentation.***
Implement: Assign Microsoft Entra ID P2 (or a suite that includes it) to the admins and approvers who
will use PIM before onboarding roles.

## 2.2 Administrative roles for the operator
Description: `Privileged Role Administrator` (or `Global Administrator`) to configure PIM — onboard
roles, set activation policy, and create assignments and reviews.
Why: Only these roles can manage role settings and eligible/active assignments in PIM. Reading state
for discovery needs only a read role, but configuration needs Privileged Role Administrator.
Verify: Entra -> `Roles and administrators`; confirm `Privileged Role Administrator` (with a
`Global Administrator` available for the tenant-wide first-time PIM onboarding).
Implement: Assign `Privileged Role Administrator` to the operator; reserve `Global Administrator` for
the one-time onboarding and for emergency use.

## 2.3 Break-glass (emergency access) accounts — MANDATORY FIRST
Description: Two cloud-only emergency Global Administrator accounts (`bg-admin-01@contoso.onmicrosoft.com`,
`bg-admin-02@contoso.onmicrosoft.com`), permanently active, excluded from PIM and from broad
Conditional Access / MFA policies, with sign-in alerts.
Why: PIM removes standing access from everyone else. If an activation, approval, or MFA path breaks,
the break-glass accounts are how you get back in. They are the prerequisite that makes the rest safe.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` Global Administrators exist with strong
stored credentials; a sign-in alert is configured (see global requirement G4). Run `ENTPIMG-Alerting.ps1`.
Implement: Create the two accounts, keep them permanently active (do **not** make them PIM-eligible),
exclude them from broad CA/MFA policies, store credentials offline and split, and alert on any sign-in.

## 2.4 Standing-access baseline (discovery)
Description: A repeatable inventory of every current standing (active) privileged role assignment —
Entra directory roles and Azure resource roles — with the account, role, and scope.
Why: You cannot convert to eligible what you have not inventoried; tenants almost always hold more
standing admins than expected.
Verify: Run `ENTPIMG-Discovery.ps1`; confirm it lists active privileged assignments for Entra roles
(and Azure resource roles where in scope) with account and role.
Implement: Install the Microsoft Graph PowerShell SDK (see 2.7) and run `ENTPIMG-Discovery.ps1`.

## 2.5 Approver groups and pilot cohort
Description: An approver group `PIM Privileged Role Approvers - Tenant - Steady` for approval-gated
roles, and a pilot cohort `PIM Pilot Admins - Pilot - Pilot` of representative admins to onboard first.
Why: Approval requires named approvers; the pilot cohort is how every change is validated before it
reaches all privileged roles.
Verify: Entra -> `Groups`; both groups exist with members. Run `ENTPIMG-Validate.ps1` to confirm
approvers are set on approval-gated roles.
Implement: Create the two groups; add trusted senior admins to the approver group and a handful of
representative admins to the pilot cohort.

## 2.6 Activation policy decision
Description: A documented decision, per privileged role tier, of the activation conditions — which
roles require approval, the max activation duration, and whether ticket information is required.
Why: These are governance choices, not technical defaults. The most powerful roles
(Global Administrator, Privileged Role Administrator) warrant approval + short duration; broadly used
roles may need MFA + justification only.
Verify: A written tiering exists (e.g. Tier-0 roles = approval + 4h; others = MFA + justification + 8h).
Implement: Decide the tiering with the security owner in Implementation Step 3. *Approval, duration,
and ticketing choices are the customer's security/operations decision — this guide provides the
technical controls, not the policy determination.*

## 2.7 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the PIM
and role-management scopes the scripts use.
Why: Discovery, validation, reporting, conversion, and the alerting check read and (for conversion)
write PIM eligibility and policy through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Identity.Governance` returns a version; a test
`Connect-MgGraph -Environment USGov` (US Government cloud) succeeds against `graph.microsoft.us`. For
DoD (IL5) use `-Environment USGovDoD` (`dod-graph.microsoft.us`). *Verify the correct cloud for your tenant.*
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request least privilege —
read: `RoleManagement.Read.All`, `RoleManagementPolicy.Read.AzureADGroup`,
`PrivilegedAccess.Read.AzureAD`, `Directory.Read.All`; and — only for conversion —
`RoleManagement.ReadWrite.Directory`. *Verify current Graph scope names for PIM in your tenant.*

## 2.8 Azure RBAC access for resource-role PIM (if in scope)
Description: For onboarding Azure resource roles, `Owner` or `User Access Administrator` on the target
management group / subscription so PIM can be discovered and configured for Azure resources.
Why: Azure resource-role PIM is managed at the resource scope, separate from directory roles.
Verify: Azure Government portal (`portal.azure.us`) -> the subscription/management group ->
`Access control (IAM)`; confirm the operator's role. PIM for Azure resources appears under
`Identity governance -> PIM -> Azure resources`.
Implement: Grant `User Access Administrator` at the appropriate scope; onboard the subscription to PIM.

---
## Checklist
- [ ] Microsoft Entra ID P2 assigned to PIM users and approvers (*verify availability*)
- [ ] `Privileged Role Administrator` assigned; `Global Administrator` available for onboarding
- [ ] Two break-glass accounts created, excluded from PIM/broad policies, and sign-in alerted — FIRST
- [ ] Standing-access baseline produced — `ENTPIMG-Discovery.ps1`
- [ ] Approver group + pilot cohort created
- [ ] Activation-policy tiering decided and documented
- [ ] Microsoft Graph PowerShell SDK installed and consented
- [ ] Azure RBAC access in place if resource-role PIM is in scope
