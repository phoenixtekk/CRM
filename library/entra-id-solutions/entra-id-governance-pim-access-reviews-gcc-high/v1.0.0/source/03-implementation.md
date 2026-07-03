# 3. Implementation Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

Follow these steps in order, in the **Microsoft Entra admin center for US Government**
(**`https://entra.microsoft.us`**), under `Identity governance`.

> **GCC High note.** Do all portal work at `entra.microsoft.us` (not `entra.microsoft.com`) and run
> every script with **`-Environment USGov`** (use `USGovDoD` on the DoD cloud). The navigation paths
> below are the same as Commercial; only the sovereign host differs. Where a step touches a capability
> that lags or differs in GCC High, a caveat is called out inline.

> Model: onboard privileged roles to PIM as eligible with approval and alerts, recertify access with
> access reviews, and package access with entitlement management — validated on a pilot scope before
> the tenant. Break-glass accounts stay excluded from PIM throughout.

## Step 1 — Confirm break-glass accounts are excluded
1. Entra (`entra.microsoft.us`) -> `Users`; confirm two cloud-only break-glass accounts hold a permanent, active `Global Administrator` assignment (typically on the tenant `*.onmicrosoft.us` domain).
2. Do not onboard these accounts to PIM activation; document their exclusion. Run `IGAG-Discovery.ps1` (connects with `-Environment USGov`) to record the current state before any change.

## Step 2 — Build the governance scope and approver groups
1. Entra (`entra.microsoft.us`) -> `Groups -> New group` -> Security -> `IGAG Pilot – Governance Scope – Pilot` (a few representative principals). Create.
2. Create `IGAG Approvers – Privileged Roles – Pilot` with at least two members. Create.
3. Optionally run `IGAG-Set-ScopeTargeting.ps1` to create these groups and set membership consistently (US Gov Graph).

## Step 3 — Onboard a privileged role to PIM (eligible)
1. Entra (`entra.microsoft.us`) -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles`.
2. Open `Assignments -> Add assignments`; choose a role to govern first (start with a non-`Global Administrator` role such as `User Administrator`).
3. Select the pilot admins; set assignment type Eligible (not Active); set a start/end so the eligibility itself is time-bound where appropriate. Assign.
4. Repeat for each privileged role you are governing. Leave break-glass accounts untouched.

> GCC High caveat: PIM for Microsoft Entra roles is Generally Available in US Gov. It governs Entra
> directory roles, PIM-enabled groups, and Azure resource roles only — not Intune RBAC or on-premises
> AD.

## Step 4 — Set role activation policy (approval, MFA, alerts)
1. In PIM -> `Microsoft Entra roles -> Settings`, open the role you onboarded.
2. Set the activation maximum duration (for example 4 hours); require multi-factor authentication on activation; require justification; require ticket information if used.
3. Enable Require approval to activate and set the approver to `IGAG Approvers – Privileged Roles – Pilot`. Update.
4. In PIM -> `Alerts`, review and enable alerts (for example too many Global Administrators, and admins with standing assignments) and tune thresholds.

## Step 5 — Create an access review for privileged roles
1. Entra (`entra.microsoft.us`) -> `Identity governance -> Access reviews -> New access review`.
2. Review type: `Microsoft Entra roles`; select the roles you onboarded to PIM. Name it `Access Review – Privileged Roles – Pilot`.
3. Reviewer: resource owner or a named reviewer; set recurrence (for example quarterly); enable Auto apply results and set "if reviewers do not respond" to Remove access (or Take recommendations). Create.

> GCC High caveat: Access reviews are Generally Available in US Gov. **Machine-learning review
> recommendations** and other capabilities marked Preview in Commercial may arrive later in the
> sovereign clouds — **verify for GCC High** before relying on ML decision helpers; use owner/manager
> reviewers as the dependable default.

## Step 6 — Create an access review for group / application access
1. `Access reviews -> New access review`; review type `Teams + Groups` or `Applications`.
2. Select the group(s) or enterprise app(s) to recertify. Name it `Access Review – App Access – Pilot`.
3. Reviewer: group owner / manager / self-review as appropriate; set recurrence and Auto apply results. Create.

## Step 7 — Create an entitlement-management catalog
1. Entra (`entra.microsoft.us`) -> `Identity governance -> Entitlement management -> Catalogs -> New catalog`.
2. Name it `Governance Catalog – App Access – Pilot`; enable it for the pilot scope. Create.
3. Open the catalog -> `Resources -> Add resources` and add the groups, apps, or SharePoint sites that access packages will grant.

> GCC High caveat: Entitlement management is Generally Available in US Gov. **External / cross-cloud
> collaboration** (connected organizations that span Commercial ↔ US Gov, cross-cloud synchronization)
> behaves differently across clouds and parts remain preview — **verify for GCC High** before adding
> external requestors that cross a cloud boundary. Keep the pilot to in-tenant resources first.

## Step 8 — Create an access package with a policy and expiry
1. In the catalog -> `Access packages -> New access package`. Name it `Access Package – App Access – Pilot`.
2. Resource roles: add the group/app role the package grants.
3. Requests policy: who can request (for example members of `IGAG Pilot – Governance Scope – Pilot`); require approval and set the approver to the approver group.
4. Lifecycle: set an expiry (for example 90 days) and/or require an access review of assignments. Create.

## Step 9 — Validate on the pilot scope
1. Have a pilot admin activate the onboarded role in PIM and confirm approval + MFA + expiry behave as configured; run `IGAG-Validation.ps1`.
2. Have a pilot user request the access package and confirm approval and expiry; confirm the access review issues correctly.
3. Run `IGAG-Report.ps1` to confirm standing-privilege is reduced and governance coverage is in place. Complete the Testing Guide.

## Step 10 — Reduce residual standing admin (safe)
1. From the inventory (Step 1 / `IGAG-Report.ps1`), identify standing (active) admin assignments that should be eligible instead.
2. Run `IGAG-Remediation.ps1` with the default `-WhatIf` to preview converting standing assignments to eligible; re-run without `-WhatIf` once confirmed. Never touch break-glass accounts. (All runs connect to US Gov Graph.)

## Step 11 — Expand to production
1. Onboard the remaining privileged roles to PIM (including `Global Administrator`, keeping break-glass excluded) with the same activation policy.
2. Extend access reviews and access packages to the remaining groups, apps, and users.
3. Re-validate each cycle with `IGAG-Validation.ps1` and `IGAG-Report.ps1`.

---
### Order of operations
`Sovereign sign-in (entra.microsoft.us) -> Break-glass check -> Scope/approver groups -> Onboard role (eligible) -> Activation policy + alerts -> Role access review -> App access review -> Catalog -> Access package -> Validate -> Reduce standing admin -> Expand`
