# Entra ID Governance — PIM, Access Reviews & Entitlement Management — Government (GCC High)

> **Version 1.0.0** · Category: Entra · Solution code: IGAG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

White-label · Entra ID Solutions · Government (GCC High) edition

Standing admin rights and access that never gets reviewed are how breaches escalate and how audits
fail. Microsoft Entra ID Governance fixes both at once: Privileged Identity Management (PIM) makes
admin roles just-in-time and approval-gated, access reviews recertify who should keep access, and
entitlement management packages access with policies and expiry. The result is privilege that is
least, time-bound, and provable to an auditor — a direct fit for the least-privilege and
periodic-review objectives common to CMMC and NIST 800-171 in GCC High.

This is the **Government (GCC High)** edition: the same governance model, deployed on the **US
sovereign cloud**. The admin portals, sign-in, and Microsoft Graph endpoints are the `*.us` sovereign
URLs (`entra.microsoft.us`, `portal.azure.us`, `login.microsoftonline.us`, `graph.microsoft.us`), and
the scripts target US Gov Graph with `-Environment USGov`. It is written for an administrator with no
prior identity-governance experience, and it calls out where GCC High differs from Commercial so a
government tenant is configured correctly — not with Commercial steps that silently authenticate
against the wrong cloud.

## What you get
- A plain-language Solution Overview of PIM (eligible vs active roles, activation, approval, alerts), access reviews, and entitlement management (catalogs, access packages, policies, expiry) — with an explicit *Commercial vs GCC High — what's different* section.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, the sovereign endpoint table, and the Government licensing SKUs.
- An Implementation Guide of precise, ordered steps in the US Gov Entra admin center, with GCC-High caveats inline where they matter.
- Five PowerShell scripts (US Gov Graph) for governance discovery, privileged-access validation, a standing-privilege and coverage report, safe remediation of standing admin, and a governance-scope group builder.
- A cited GCC High Parity Notes reference, plus Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A governance baseline where privileged directory roles are onboarded to PIM as eligible (not
standing), activation is approval-gated and alerted, access reviews recertify roles, groups, and app
access on a schedule, and entitlement-management access packages grant access with a defined policy
and an expiry date — all on the sovereign plane. Break-glass emergency accounts are deliberately
excluded from PIM so a misconfiguration can never lock every administrator out.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Just-in-time, approval-gated admin, access recertified on a schedule, and entitlements packaged with
expiry — least privilege that is time-bound and provable — configured correctly on GCC High and
proven on a pilot before you scale.


---


# 1. Solution Overview — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

> This is the **Government (GCC High)** edition. It deploys the same Entra ID Governance model as the
> Commercial edition, but on the **US sovereign cloud**: the admin portals, sign-in endpoints, and
> Microsoft Graph endpoints are the `*.us` sovereign URLs, and a few capabilities lag or differ from
> Commercial. Configure a GCC High tenant with these steps — not with Commercial steps that silently
> authenticate against the wrong cloud.

## What Entra ID Governance is
Microsoft Entra ID Governance is the set of Entra identity-governance capabilities that make access
least, time-bound, and provable. Three services do the work: Privileged Identity Management (PIM)
turns admin roles into just-in-time, approval-gated grants; access reviews recertify who should keep
roles, group membership, and application access; and entitlement management packages access into
catalogs and access packages that are granted by policy and expire. Together they replace always-on
admin and never-reviewed access with a governed, auditable model.

This is Entra directory-level governance across the whole tenant. It is distinct from Intune
role-based access control, which governs only who can administer Intune; the two are complementary
and do not overlap.

## How it works
1. Privileged Identity Management makes a directory role (for example `Global Administrator`) eligible rather than active. A person holds no standing power; they activate the role for a limited window when they need it.
2. Activation can require approval, multi-factor authentication, a justification, and a ticket number, and it raises alerts on risky activity. Activation is time-bound and expires automatically.
3. Access reviews ask a reviewer (the resource owner, a manager, or the users themselves) to recertify access on a schedule; anything not approved is removed, so stale access decays automatically.
4. Entitlement management groups related resources (groups, apps, SharePoint sites) into a catalog, then publishes access packages with a policy that governs who may request them, who approves, and when access expires.
5. Break-glass emergency accounts are deliberately excluded from PIM so a PIM misconfiguration can never lock every administrator out of the tenant.
6. Every activation, review decision, and access-package grant is logged, giving an auditor a provable trail of who had access to what, and why.

## Commercial vs GCC High — what's different
The governance model is identical; the **cloud plane it runs on is not**. In GCC High:

- **You sign in and administer at sovereign `*.us` portals**, not the Commercial `*.com` portals. The Commercial portals will not recognize a GCC High account. (See the Requirements Guide for the full endpoint table.)
  - Microsoft Entra admin center: **`https://entra.microsoft.us`** (Commercial: `entra.microsoft.com`).
  - Azure portal: **`https://portal.azure.us`** (Commercial: `portal.azure.com`).
  - Sign-in / authentication: **`https://login.microsoftonline.us`** (Commercial: `login.microsoftonline.com`).
  - Microsoft Graph: **`https://graph.microsoft.us`** for GCC High, **`https://dod-graph.microsoft.us`** for DoD (Commercial: `graph.microsoft.com`). Source: Microsoft Learn, *Microsoft Graph national cloud deployments*.
- **Scripts must target US Gov Graph.** Every `Connect-MgGraph` call in this solution uses **`-Environment USGov`**; without it the SDK authenticates against the Commercial endpoint and fails against a GCC High tenant. All five scripts in this package default to `-Environment USGov`.
- **Licensing uses the Government SKUs.** PIM, access reviews, and entitlement management require **Microsoft Entra ID P2** or **Microsoft Entra ID Governance**. In the US Government clouds the governance capability ships as **"Microsoft Entra ID Governance for Government"** and **"Microsoft Entra ID Governance Add-on for Microsoft Entra ID P2 for Government,"** which Microsoft documents as available in GCC, GCC High, and DoD. Source: Microsoft Learn, *Microsoft Entra ID Governance licensing fundamentals*.
- **Core governance is GA in US Gov.** Microsoft's *Entra feature availability in Azure for US Government* lists **Access reviews, Entitlement management, Privileged Identity Management (PIM), and Lifecycle workflows (in Entra ID Governance)** as available. The core deployment in this solution is fully supported.
- **Some adjacent capabilities lag, are partial, or differ** — call these out and verify against the current sovereign docs before relying on them:
  - **HR-driven provisioning** is listed as **Partial** for US Gov.
  - **My Staff** (delegated user management portal) is listed as **not available** (❌) for US Gov.
  - **Graph Explorer** (the browser tool at `developer.microsoft.com/graph`) is **not supported** for the `graph.microsoft.us`/DoD endpoints — use PowerShell (`-Environment USGov`) rather than Graph Explorer.
  - **Cross-tenant / cross-cloud collaboration** (connected organizations spanning Commercial ↔ US Gov, cross-cloud synchronization) behaves differently across clouds and parts remain **preview**; Microsoft notes cross-cloud sync in GCC High is delivered under the *Entra ID Governance for Government* SKU. **Verify for GCC High** before designing external-guest access packages that cross a cloud boundary.
  - **Preview / ML-assisted features** (for example machine-learning access-review recommendations, catalog access reviews, and other capabilities marked Preview in the licensing table) may reach the sovereign clouds later than Commercial — **verify for GCC High** at the time you deploy rather than assuming Commercial parity.

> Where this document says **"verify for GCC High,"** treat the capability as unconfirmed for the
> sovereign cloud: check the current Microsoft US Gov documentation (or the Microsoft 365 US
> Government service descriptions) before you depend on it. Never assume Commercial parity for a
> preview or external-collaboration feature.

## What you can control
- PIM role assignment as eligible vs active, activation maximum duration, and permanent-vs-time-bound assignment expiry.
- Activation requirements: approval, approver list, multi-factor authentication, justification, and ticket information.
- Access reviews for directory roles (via PIM), for groups and application assignments, and for access-package assignments — with a recurrence, reviewer, and auto-apply of results.
- Entitlement-management catalogs, access packages, request/approval policies, and access expiry or periodic review.
- PIM alerts (for example, too many Global Administrators, or admins with standing assignments) and their thresholds.

## Benefits
- Least privilege — admins hold roles eligibly and activate only when needed, shrinking standing attack surface.
- Time-bound — activations and access-package grants expire automatically, so access does not accumulate.
- Provable — activations, approvals, and review decisions are logged for audit and compliance (supports CMMC / NIST 800-171 least-privilege and review objectives common to GCC High tenants).
- Self-service with control — users request access packages; policy decides who approves and when it expires.
- Automatic decay of stale access — access reviews remove what is no longer approved without manual cleanup.
- Sovereign-correct — configured on the `*.us` plane so a government tenant is governed in-cloud, not against Commercial endpoints.

## Limitations (be honest with buyers)
- Entra ID Governance / P2 (Government SKUs) licensing is required for PIM, access reviews, and entitlement management; confirm licensing before you begin (see requirements).
- PIM governs Entra directory roles, PIM-enabled groups, and Azure resource roles — not Intune RBAC and not on-premises Active Directory admin rights.
- Over-tight approval or too few approvers can delay legitimate activations; approver coverage must be planned.
- Break-glass accounts are intentionally outside PIM and must instead be protected by strong stored credentials, exclusion documentation, and sign-in monitoring.
- GCC High parity gaps apply to adjacent/preview/external-collaboration features (see *Commercial vs GCC High* above and `gcc-high-parity-notes.md`) — verify before relying on them.

## The standard deployment model
> Onboard privileged roles to PIM as eligible with approval and alerts -> stand up access reviews for
> roles and app access -> build entitlement-management access packages with policy and expiry ->
> validate activation and recertification on a pilot scope -> expand to the tenant.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 2. Requirements Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

> **GCC High note.** All verification and implementation is done on the **US sovereign cloud**. Use
> the `*.us` portals and endpoints below, and run every script with **`-Environment USGov`**. A
> Commercial portal or endpoint will not recognize a GCC High account.

## 2.0 GCC High tenant and sovereign endpoints
Description: An active Microsoft Entra ID tenant in the **US Government (GCC High or DoD)** cloud, and network access to the sovereign endpoints.
Why: PIM, access reviews, and entitlement management for a GCC High tenant are administered only through the sovereign plane; the Commercial endpoints reject GCC High accounts.
Verify: Sign in to the Microsoft Entra admin center at **`https://entra.microsoft.us`** as an administrator; the tenant resolves and shows `Identity governance`. Run `IGAG-Discovery.ps1` (which connects with `-Environment USGov`).
Implement: If sign-in fails at `entra.microsoft.us`, confirm the account is a GCC High/DoD account and that the following endpoints are reachable through your filtering:

| Purpose | GCC High (US Gov L4) | DoD (US Gov L5) | Commercial (do NOT use for GCC High) |
|---|---|---|---|
| Microsoft Entra admin center | `https://entra.microsoft.us` | `https://entra.microsoft.us` | `https://entra.microsoft.com` |
| Azure portal | `https://portal.azure.us` | `https://portal.azure.us` | `https://portal.azure.com` |
| Sign-in / authentication | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` | `https://login.microsoftonline.com` |
| Microsoft Graph | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` | `https://graph.microsoft.com` |
| Graph PowerShell `-Environment` | `USGov` | `USGovDoD` | `Global` |

Sources: Microsoft Learn, *Microsoft Graph national cloud deployments*; *Microsoft Entra feature availability in Azure for US Government*.

## 2.1 Entra ID Governance / P2 licensing (Government SKUs)
Description: Microsoft Entra ID Governance (or Entra ID P2) licensing for the governed users and reviewers, using the Government products.
Why: PIM, access reviews, and entitlement management are licensed features; without P2/Governance they are unavailable. In the US Government clouds the governance capability ships as the Government SKUs.
Verify: Microsoft 365 admin center (US Gov) -> `Billing -> Licenses`; confirm Entra ID P2 or Entra ID Governance; in Entra (`entra.microsoft.us`) confirm `Identity governance` is available. Run `IGAG-Discovery.ps1`.
Implement: Assign **Microsoft Entra ID P2** (or **G3/G5 Gov** bundles that include the `AAD_PREMIUM_P2` service plan) plus, where used, **Microsoft Entra ID Governance for Government** or the **Microsoft Entra ID Governance Add-on for Microsoft Entra ID P2 for Government** to administrators, reviewers, and users who receive access packages. Microsoft documents these Government products as available in GCC, GCC High, and DoD. Source: Microsoft Learn, *Microsoft Entra ID Governance licensing fundamentals*.

## 2.2 Administrative roles for the operator
Description: A `Privileged Role Administrator` (and a `Global Administrator` for the one-time consent) to configure PIM and governance.
Why: Onboarding roles to PIM and editing role settings requires `Privileged Role Administrator`; some first-run consents require `Global Administrator`.
Verify: Entra (`entra.microsoft.us`) -> `Roles and administrators`; confirm the operator holds `Privileged Role Administrator`; run `IGAG-Discovery.ps1`.
Implement: Assign `Privileged Role Administrator` to the operator; reserve `Global Administrator` for tenant-wide first-run changes.

## 2.3 Break-glass emergency accounts excluded from PIM
Description: At least two cloud-only break-glass accounts holding a permanent, active `Global Administrator` role, excluded from PIM activation requirements.
Why: If PIM, approval, or MFA is misconfigured, break-glass accounts still sign in and prevent a full lockout.
Verify: Entra (`entra.microsoft.us`) -> `Users`; confirm two cloud-only accounts with standing `Global Administrator`; confirm they are not subject to PIM activation; run `IGAG-Discovery.ps1`.
Implement: Create/retain two cloud-only Global Administrator accounts (on the tenant's `*.onmicrosoft.us` domain) with permanently active assignment, document their exclusion, store credentials securely, and alert on their sign-ins.

## 2.4 Role and access inventory
Description: A current inventory of who holds privileged directory roles and which are standing (active) vs eligible.
Why: You cannot convert standing admin to just-in-time without first knowing what standing access exists.
Verify: Entra (`entra.microsoft.us`) -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles -> Assignments`; run `IGAG-Discovery.ps1` and `IGAG-Report.ps1`.
Implement: Export current role holders and classify each assignment as keep-eligible, keep-active (break-glass), or remove.

## 2.5 Approver groups
Description: A named group (or named approvers) to approve PIM activations and access-package requests.
Why: Approval-gated activation and self-service access packages need defined approvers, with enough coverage to avoid delay.
Verify: Entra (`entra.microsoft.us`) -> `Groups`; confirm an approver group exists with more than one member; run `IGAG-Set-ScopeTargeting.ps1` to build it if missing.
Implement: Create an approver group (for example `IGAG Approvers – Privileged Roles – Pilot`) with at least two members and document coverage.

## 2.6 Reviewer assignment for access reviews
Description: Defined reviewers for each access review — resource owner, manager, or self-review.
Why: An access review with no valid reviewer cannot recertify access and may auto-remove or stall.
Verify: Confirm each planned review has an owner/manager or self-review reviewer identified.
Implement: Identify reviewers per resource; where a manager is used, confirm the `Manager` attribute is populated for the target users.

## 2.7 Pilot scope group
Description: A small pilot group of representative admins/users to validate PIM, reviews, and access packages before tenant-wide rollout.
Why: The identity plane is high risk; a pilot proves activation, approval, and recertification before you expand.
Verify: Entra (`entra.microsoft.us`) -> `Groups`; confirm a pilot group exists; run `IGAG-Set-ScopeTargeting.ps1`.
Implement: Create a pilot group (for example `IGAG Pilot – Governance Scope – Pilot`) and add a few representative principals.

## 2.8 Microsoft Graph PowerShell SDK with US Gov targeting
Description: The Microsoft Graph PowerShell SDK on the operator workstation, used with `-Environment USGov` (or `USGovDoD` for DoD).
Why: The scripts in this package call US Gov Graph; without `-Environment USGov` the SDK authenticates against the Commercial endpoint and fails on a GCC High tenant.
Verify: `Get-Module Microsoft.Graph.Authentication -ListAvailable` returns a version; `Connect-MgGraph -Environment USGov` connects to `graph.microsoft.us`. Run `IGAG-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; connect with `-Environment USGov`. Optional convenience: `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` in the operator profile.

---
## Checklist
- [ ] GCC High/DoD tenant reachable at `entra.microsoft.us`; sovereign endpoints allowed — `IGAG-Discovery.ps1`
- [ ] Entra ID Governance / P2 (Government SKUs) licensing assigned
- [ ] Operator holds `Privileged Role Administrator`
- [ ] Two break-glass accounts, standing, excluded from PIM — `IGAG-Discovery.ps1`
- [ ] Role and access inventory captured — `IGAG-Report.ps1`
- [ ] Approver group created with 2+ members
- [ ] Reviewers identified for each planned access review
- [ ] Pilot scope group created — `IGAG-Set-ScopeTargeting.ps1`
- [ ] Graph PowerShell SDK present; `-Environment USGov` connects


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


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


---


# 5. Testing Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

Run after the pilot scope is configured (Implementation Step 9) and after each governance cycle or
expansion. Do portal checks at **`https://entra.microsoft.us`**; every script connects to US Gov
Graph with **`-Environment USGov`**.

## Test 0 — Sovereign endpoint confirmed
Do: Run `IGAG-Validation.ps1` and confirm it connects to `graph.microsoft.us` (GCC High) without redirecting to the Commercial endpoint; sign in to `entra.microsoft.us` in the portal.
Expected: The script authenticates against US Gov Graph and returns governance state; the portal resolves the tenant. A redirect/"wrong environment" error means `-Environment USGov` was missing.

## Test 1 — Role is eligible, not standing
Do: Entra (`entra.microsoft.us`) -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles -> Assignments`; or run `IGAG-Validation.ps1`.
Expected: The onboarded pilot role shows Eligible assignments for pilot admins; no unexpected standing (active) assignments except documented break-glass.

## Test 2 — Activation is approval-gated and time-bound
Do: A pilot admin activates the role in PIM (justification + MFA); an approver approves.
Expected: Activation requires approval and MFA, records a justification, grants the role for the configured window, and expires automatically.

## Test 3 — Break-glass excluded
Do: Confirm the two break-glass accounts still hold permanent active `Global Administrator` and are not subject to PIM activation; run `IGAG-Validation.ps1 -BreakGlassUpns ...`.
Expected: Break-glass accounts sign in without PIM activation; they are flagged as intentionally excluded, not as a violation.

## Test 4 — Privileged-role access review works
Do: Open `Access Review – Privileged Roles – Pilot`; a reviewer records approve/deny decisions; let auto-apply run.
Expected: Denied access is removed on apply; the review is logged with reviewer decisions.

## Test 5 — App/group access review works
Do: Open `Access Review – App Access – Pilot`; a reviewer recertifies membership.
Expected: Unapproved members are removed on apply; decisions are recorded.

## Test 6 — Access package grants with policy and expiry
Do: A pilot user requests `Access Package – App Access – Pilot`; an approver approves.
Expected: Access is granted per the resource role, subject to approval, and carries the configured expiry (or scheduled review). (Keep the pilot to in-tenant requestors; see the GCC High cross-cloud caveat.)

## Test 7 — Governance coverage report
Do: Run `IGAG-Report.ps1`.
Expected: A clear picture of standing vs eligible privileged assignments, roles onboarded to PIM, access reviews in place, and access packages published — all read from US Gov Graph.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Test 0 confirms sovereign connectivity; Tests 1-4 pass; activation is approval-gated and time-bound; break-glass excluded |
| Expand pass | Tests 5-7 pass for the broader scope before onboarding `Global Administrator` tenant-wide |


---


# 6. Troubleshooting Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

Use `IGAG-Validation.ps1` / `IGAG-Discovery.ps1` for current governance state and `IGAG-Report.ps1`
for standing-privilege and coverage, `IGAG-Remediation.ps1` for safe fixes. All scripts connect to
US Gov Graph with **`-Environment USGov`** (use `USGovDoD` on the DoD cloud); do portal work at
**`https://entra.microsoft.us`**.

## A. Sovereign endpoint / connection problems (GCC High-specific — check first)
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` redirects or throws a "wrong environment"/AADSTS error | `-Environment USGov` was omitted, so the SDK targeted the Commercial endpoint | Reconnect with `-Environment USGov` (or `USGovDoD` for DoD); set `$PSDefaultParameterValues['Connect-MgGraph:Environment']='USGov'` in the profile |
| GCC High account not recognized at the portal | Signed in at a Commercial `*.com` portal | Use `entra.microsoft.us` / `portal.azure.us`; sign-in is `login.microsoftonline.us` |
| Graph Explorer will not open the tenant | Graph Explorer is not supported for `graph.microsoft.us` / `dod-graph.microsoft.us` | Use PowerShell (`-Environment USGov`) instead of Graph Explorer |
| Scripts return empty/forbidden results | Consent granted in the wrong cloud, or missing scopes | Re-consent in the GCC High tenant; confirm the read-only scopes each script requests |

## B. PIM activation problems
| Symptom | Cause | Remediation |
|---|---|---|
| Admin cannot activate a role | No eligible assignment, or activation blocked by policy | Confirm an Eligible assignment exists in PIM; check activation policy (MFA/approval); run `IGAG-Validation.ps1` |
| Activation stuck waiting for approval | No available approver, or approver group empty | Confirm the approver group has 2+ members; add coverage with `IGAG-Set-ScopeTargeting.ps1` |
| Activation fails MFA | Admin has no strong method registered | Register a multi-factor method for the admin, then retry activation |

## C. Break-glass and lockout risk
- Confirm the two break-glass accounts hold permanent active `Global Administrator` and are excluded from PIM activation and from broad Conditional Access/MFA policies; run `IGAG-Discovery.ps1`.
- If PIM/approval is misconfigured tenant-wide, sign in with a break-glass account (at `login.microsoftonline.us`) to restore access, then correct the policy. Never onboard break-glass accounts to PIM.

## D. Access review issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed access unexpectedly | "If reviewers do not respond" set to Remove access and no decision recorded | Set the no-response action to Take recommendations or No change; re-grant via PIM/access package; re-run the review |
| Review has no reviewer | Manager attribute empty, or owner not set | Populate the `Manager` attribute or assign a named reviewer; recreate the review |
| Decisions not applied | Auto apply results disabled | Enable Auto apply results, or apply the review manually |
| ML review recommendations not offered | ML decision helpers may lag in GCC High (Preview in Commercial) | Verify for GCC High; use owner/manager reviewers as the dependable default |

## E. Entitlement-management / access-package issues
| Symptom | Cause | Remediation |
|---|---|---|
| User cannot request a package | Requestor not in the request policy scope | Add the user to the scope group (for example the pilot scope) or widen the request policy |
| Request not approved | Approver group empty or approver unavailable | Confirm approver coverage; add members with `IGAG-Set-ScopeTargeting.ps1` |
| Access did not expire | No expiry / no review on the package lifecycle | Set an access-package expiry or a periodic review in the package lifecycle settings |
| External / cross-cloud requestor cannot be added | Connected-organization / cross-cloud collaboration differs across clouds and parts are preview in GCC High | Verify for GCC High; keep the pilot to in-tenant requestors; add cross-cloud external access only after confirming behavior |

## F. Licensing / feature not visible
- If `Identity governance`, PIM, or access reviews are not visible, confirm the **Government** Entra ID Governance / P2 SKUs are assigned; run `IGAG-Discovery.ps1`. Assign **Microsoft Entra ID P2** and, where used, **Microsoft Entra ID Governance for Government** or the **Add-on for Entra ID P2 for Government** to administrators, reviewers, and access-package users.
- If a capability is present in Commercial docs but missing in your GCC High tenant, check the GCC High parity notes — it may be Partial, unavailable, or preview-only in the sovereign cloud (verify for GCC High).

## G. Diagnostics quick reference
```powershell
# GCC High: always specify the US Gov environment (USGovDoD for DoD)
Connect-MgGraph -Environment USGov -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All'
# Eligible vs active Entra role assignments (PIM)
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleInstances'
# Access reviews and access packages
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages'
```

## H. When to escalate
If roles are correctly eligible, the approver group has coverage, MFA is registered, connectivity is
confirmed on `graph.microsoft.us` (Test 0), and activation or an access review still fails, capture the
output of `IGAG-Report.ps1` and the PIM audit log for the affected role and open a Microsoft support
case for the GCC High tenant.


---


# 7. Best Practices — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

- Administer on the sovereign plane. Do all portal work at `https://entra.microsoft.us` and run every script with `-Environment USGov` (use `USGovDoD` on the DoD cloud). A single Commercial endpoint in a runbook or profile will silently fail against a GCC High tenant.
- Make privileged roles eligible, not standing. Onboarding admin roles to PIM as eligible is the single most important practice — it removes always-on privilege and shrinks the attack surface.
- Keep break-glass accounts out of PIM. Two cloud-only emergency accounts (on the tenant `*.onmicrosoft.us` domain) must hold permanent active `Global Administrator` and be excluded from PIM activation, so a PIM misconfiguration can never lock everyone out. Protect them with strong stored credentials and sign-in alerts.
- Gate activation with approval and MFA. Require approval, multi-factor authentication, and justification on activation, and keep the activation window short so access is time-bound.
- Ensure approver coverage. Use an approver group with at least two members so legitimate activations and access-package requests are not delayed by a single unavailable approver.
- Recertify on a schedule. Run recurring access reviews for privileged roles, group membership, and app access, with auto-apply, so stale access decays without manual cleanup — this maps directly to the least-privilege and periodic-review objectives common to CMMC / NIST 800-171 in GCC High.
- Package access, do not assign it ad hoc. Use entitlement-management access packages with a request policy and expiry so grants are governed, self-service, and time-bound.
- Set sensible expiry. Give access packages a defined expiry or a periodic review so access does not accumulate silently.
- Watch PIM alerts. Enable and tune alerts (too many Global Administrators, standing assignments, stale eligibility) and act on them.
- Do not assume Commercial parity. Preview, ML-assisted, external-collaboration, and cross-cloud features can lag or differ in GCC High — verify each against current Microsoft US Gov documentation before you depend on it (see `gcc-high-parity-notes.md`). Prefer owner/manager reviewers over ML recommendations until confirmed.
- Keep external access in-cloud during the pilot. Because connected-organization and cross-cloud collaboration differ across clouds, start access packages with in-tenant resources and requestors; add cross-cloud external access only after verifying the behavior for GCC High.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, reviews, catalogs, and packages so audits and expansion are repeatable.
- Pilot before you expand. Validate activation, approval, and recertification on a small scope before onboarding `Global Administrator` and the rest of the tenant, and keep a rollback path.


---


# 8. Deliverables Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box (GCC High edition) |
| 1. Solution Overview | What Entra ID Governance is on GCC High: PIM, access reviews, entitlement management, benefits, limitations, and a *Commercial vs GCC High — what's different* section |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, including the sovereign endpoint table and Government licensing SKUs |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps in the US Gov Entra admin center (`entra.microsoft.us`) with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-connectivity test |
| 6. Troubleshooting Guide | Field issues and remediation, with GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations, sovereign-aware |
| GCC High Parity Notes | Cited Commercial-vs-GCC-High feature parity reference |

## PowerShell scripts (US Gov Graph, `-Environment USGov`)
| Script | What it does |
|---|---|
| `IGAG-Discovery.ps1` | Reports PIM role eligibility/assignments, access reviews, and entitlement-management packages, and flags break-glass exclusion (read-only) |
| `IGAG-Validation.ps1` | Confirms roles are eligible (not standing), activation policy is gated, and break-glass is excluded (read-only) |
| `IGAG-Report.ps1` | Standing-privilege vs eligible summary and governance-coverage report (read-only) |
| `IGAG-Remediation.ps1` | Safe remediation (default `-WhatIf`); converts standing admin assignments to eligible |
| `IGAG-Set-ScopeTargeting.ps1` | Builds the governance-scope and approver groups used by PIM, reviews, and access packages |

All scripts connect to the US Government Graph endpoint with `-Environment USGov` (use `USGovDoD` on
the DoD cloud). Discovery, Validation, and Report are read-only; Remediation and Set-ScopeTargeting
change state (Remediation defaults to `-WhatIf`).

## What the buyer receives
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Privileged access made just-in-time and approval-gated, access recertified on a schedule, and
entitlements packaged with expiry — least privilege that is time-bound and provable — configured
correctly on the **US sovereign cloud** and proven on a pilot before you scale.
