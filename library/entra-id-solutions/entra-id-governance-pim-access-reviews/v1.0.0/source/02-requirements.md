# 2. Requirements Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

## 2.1 Entra ID Governance / P2 licensing
Description: Microsoft Entra ID Governance (or Entra ID P2) licensing for the governed users and reviewers.
Why: PIM, access reviews, and entitlement management are licensed features; without P2/Governance they are unavailable.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P2 or Entra ID Governance; in Entra confirm `Identity governance` is available.
Implement: Assign Entra ID P2 or Entra ID Governance to administrators, reviewers, and users who receive access packages.

## 2.2 Administrative roles for the operator
Description: A `Privileged Role Administrator` (and a `Global Administrator` for the one-time consent) to configure PIM and governance.
Why: Onboarding roles to PIM and editing role settings requires `Privileged Role Administrator`; some first-run consents require `Global Administrator`.
Verify: Entra -> `Roles and administrators`; confirm the operator holds `Privileged Role Administrator`; run `IGA-Discovery.ps1`.
Implement: Assign `Privileged Role Administrator` to the operator; reserve `Global Administrator` for tenant-wide first-run changes.

## 2.3 Break-glass emergency accounts excluded from PIM
Description: At least two cloud-only break-glass accounts holding a permanent, active `Global Administrator` role, excluded from PIM activation requirements.
Why: If PIM, approval, or MFA is misconfigured, break-glass accounts still sign in and prevent a full lockout.
Verify: Entra -> `Users`; confirm two cloud-only accounts with standing `Global Administrator`; confirm they are not subject to PIM activation; run `IGA-Discovery.ps1`.
Implement: Create/retain two cloud-only Global Administrator accounts with permanently active assignment, document their exclusion, store credentials securely, and alert on their sign-ins.

## 2.4 Role and access inventory
Description: A current inventory of who holds privileged directory roles and which are standing (active) vs eligible.
Why: You cannot convert standing admin to just-in-time without first knowing what standing access exists.
Verify: Entra -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles -> Assignments`; run `IGA-Discovery.ps1` and `IGA-Report.ps1`.
Implement: Export current role holders and classify each assignment as keep-eligible, keep-active (break-glass), or remove.

## 2.5 Approver groups
Description: A named group (or named approvers) to approve PIM activations and access-package requests.
Why: Approval-gated activation and self-service access packages need defined approvers, with enough coverage to avoid delay.
Verify: Entra -> `Groups`; confirm an approver group exists with more than one member; run `IGA-Set-ScopeTargeting.ps1` to build it if missing.
Implement: Create an approver group (for example `IGA Approvers – Privileged Roles – Pilot`) with at least two members and document coverage.

## 2.6 Reviewer assignment for access reviews
Description: Defined reviewers for each access review — resource owner, manager, or self-review.
Why: An access review with no valid reviewer cannot recertify access and may auto-remove or stall.
Verify: Confirm each planned review has an owner/manager or self-review reviewer identified.
Implement: Identify reviewers per resource; where a manager is used, confirm the `Manager` attribute is populated for the target users.

## 2.7 Pilot scope group
Description: A small pilot group of representative admins/users to validate PIM, reviews, and access packages before tenant-wide rollout.
Why: The identity plane is high risk; a pilot proves activation, approval, and recertification before you expand.
Verify: Entra -> `Groups`; confirm a pilot group exists; run `IGA-Set-ScopeTargeting.ps1`.
Implement: Create a pilot group (for example `IGA Pilot – Governance Scope – Pilot`) and add a few representative principals.

---
## Checklist
- [ ] Entra ID Governance / P2 licensing assigned
- [ ] Operator holds `Privileged Role Administrator`
- [ ] Two break-glass accounts, standing, excluded from PIM — `IGA-Discovery.ps1`
- [ ] Role and access inventory captured — `IGA-Report.ps1`
- [ ] Approver group created with 2+ members
- [ ] Reviewers identified for each planned access review
- [ ] Pilot scope group created — `IGA-Set-ScopeTargeting.ps1`
