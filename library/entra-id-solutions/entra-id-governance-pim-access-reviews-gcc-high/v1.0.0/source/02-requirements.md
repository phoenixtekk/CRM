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
