# 2. Requirements Guide — Entra External Identities (B2B) & Cross-Tenant Access

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant, base licensing, admin roles, break-glass
accounts, network access) are in `global-requirements-entra-id-solutions.md` and are not repeated here.

> Licensing and preview items below are flagged **verify** — confirm current availability and the
> feature-to-license mapping in *your* tenant before you rely on them; Microsoft changes these over
> time.

## 2.1 Entra ID P1 (cross-tenant access trust + Conditional Access) — verify
Description: Microsoft Entra ID P1 for the users and administrators involved, to use cross-tenant access **trust settings** and **Conditional Access**.
Why: Trusting a partner's MFA/device claims and enforcing a guest-scoped Conditional Access policy are P1 features. Basic B2B invitation works without P1, but the governance in this solution needs it.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1 (often bundled in M365 E3/E5 or EMS). In Entra, `Protection -> Conditional Access` is available. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1 to the administrators and to any internal users whose collaboration is governed.

## 2.2 Entra ID P2 / Entra ID Governance (access reviews + access packages) — verify
Description: Microsoft Entra ID P2 or Microsoft Entra ID Governance for the guest-lifecycle features — **access reviews** and **entitlement-management access packages**.
Why: Recertifying guests with access reviews and granting governed guest access with access packages are P2 / Governance features.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P2 or Entra ID Governance; in Entra, `Identity governance` shows `Access reviews` and `Entitlement management`. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
Implement: Assign Entra ID P2 (E5/EMS E5) or Entra ID Governance to administrators, sponsors/reviewers, and the internal users who own access packages. (Full governance build-out is the `ENTIGA` solution; this solution uses one package and one review.)

## 2.3 Administrative roles for the operator
Description: A `Global Administrator` or the combination of `Security Administrator` (Conditional Access + cross-tenant access settings) and `Identity Governance Administrator` (access reviews + entitlement management), plus `Guest Inviter` where invitation is delegated.
Why: Cross-tenant access settings and Conditional Access require security-admin rights; access packages and reviews require identity-governance rights; a first-run consent may require `Global Administrator`.
Verify: Entra -> `Roles and administrators`; confirm the operator holds the roles above. Run `ENTB2B-Discovery.ps1`.
Implement: Assign `Security Administrator` and `Identity Governance Administrator` to the operator; reserve `Global Administrator` for the one-time consent.

## 2.4 A named partner tenant (or partner contact) for the pilot
Description: One real partner you actually collaborate with — their tenant's default domain (for example `contoso.com` / `contoso.onmicrosoft.com`) and a pilot guest contact there.
Why: Cross-tenant **organizational** settings, trust, and cross-tenant sync are configured per partner tenant; the pilot proves the model on one partner before you expand.
Verify: You know the partner's tenant domain and have a test guest email at that partner. Run `ENTB2B-Discovery.ps1` to see existing organizational settings.
Implement: Identify one partner tenant and a willing pilot contact; agree which apps/resources the pilot guest needs.

## 2.5 Guest inventory and current cross-tenant baseline
Description: A current inventory of existing guest (`#EXT#`) users — how many, how they arrived, last sign-in — and the current default cross-tenant access policy.
Why: You cannot govern guest sprawl without first seeing it; the default policy may already be more open than you think.
Verify: Entra -> `Users` (filter User type = Guest); Entra -> `External Identities -> Cross-tenant access settings -> Default settings`. Run `ENTB2B-Discovery.ps1` and `ENTB2B-Report.ps1`.
Implement: Export the guest list and classify each guest (keep, expire, remove); record the current default inbound/outbound settings before changing them.

## 2.6 Pilot scope group and sponsor/approver group
Description: A pilot scope group of internal users who will collaborate with the partner, and a sponsor/approver group for the guest access package and review.
Why: Conditional Access, the access package request policy, and the access review target defined groups; approvals need at least two approvers so they are not delayed by one absence.
Verify: Entra -> `Groups`; confirm a pilot scope group and an approver group (2+ members). Run `ENTB2B-Set-CrossTenantAccess.ps1 -WhatIf` (which can report/create the groups it needs) or create them manually.
Implement: Create `B2B Pilot – Guest Scope – Pilot` and `Partner Approvers – B2B – Pilot`; add representative members.

## 2.7 Guest-scoped Conditional Access policy prerequisites (report-only first)
Description: The ability to create a Conditional Access policy scoped to Guest or external users, deployed in **report-only** first, with break-glass accounts excluded.
Why: Enforcing MFA on external sign-ins is the core guest control; report-only proves impact before enforcement, and break-glass exclusion prevents lockout.
Verify: Entra -> `Protection -> Conditional Access`; confirm you can create a policy targeting `Guest or external users`, and that break-glass accounts are excluded from broad policies. Run `ENTB2B-Validate.ps1`.
Implement: Confirm the two break-glass accounts (per global requirement G4) are excluded from broad Conditional Access; plan the new guest policy in report-only.

## 2.8 Microsoft Graph PowerShell SDK
Description: The Microsoft Graph PowerShell SDK on the operator workstation.
Why: The five scripts in this package call Microsoft Graph for discovery, validation, reporting, and the two safe change operations.
Verify: `Get-Module Microsoft.Graph.Authentication -ListAvailable` returns a version; `Connect-MgGraph` connects to `graph.microsoft.com`. Run `ENTB2B-Discovery.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.9 Cross-tenant synchronization prerequisites (optional / where used) — verify
Description: If you will auto-provision guests from a partner, cross-tenant synchronization configured between the two tenants (a configuration on your side and consent on the partner side).
Why: Cross-tenant sync provisions B2B guests automatically instead of one-by-one invitation; it requires both tenants to cooperate and specific configuration.
Verify: Entra -> `Cross-tenant synchronization` (under External Identities / Cross-tenant access settings) is present; the partner has enabled inbound sync. Run `ENTB2B-Discovery.ps1`. *Verify current availability in your tenant.*
Implement: Configure cross-tenant sync only after the invitation-based pilot succeeds and the partner agrees; keep it out of the initial pilot.

---
## Checklist
- [ ] Entra ID P1 assigned (cross-tenant trust + Conditional Access) — `ENTB2B-Discovery.ps1` · *verify*
- [ ] Entra ID P2 / Governance assigned (access reviews + access packages) — `ENTB2B-Discovery.ps1` · *verify*
- [ ] Operator holds Security Administrator + Identity Governance Administrator
- [ ] One named partner tenant + pilot guest contact identified
- [ ] Guest inventory and current default cross-tenant settings captured — `ENTB2B-Report.ps1`
- [ ] Pilot scope group and approver group created (2+ approvers)
- [ ] Break-glass accounts excluded from broad Conditional Access — `ENTB2B-Validate.ps1`
- [ ] Graph PowerShell SDK present; `Connect-MgGraph` connects
- [ ] (Optional) Cross-tenant sync prerequisites confirmed with the partner · *verify*
