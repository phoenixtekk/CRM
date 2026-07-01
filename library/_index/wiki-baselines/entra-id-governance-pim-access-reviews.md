# Entra ID Governance — PIM, Access Reviews & Entitlement Management

> **Version 1.0.0** · Category: Entra · Solution code: IGA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Phoenixtekk Workplace Marketplace · Entra ID Solutions

Standing admin rights and access that never gets reviewed are how breaches escalate and how audits
fail. Microsoft Entra ID Governance fixes both at once: Privileged Identity Management (PIM) makes
admin roles just-in-time and approval-gated, access reviews recertify who should keep access, and
entitlement management packages access with policies and expiry. The result is privilege that is
least, time-bound, and provable to an auditor.

This is a complete, deploy-it-today package for implementing Entra ID Governance, written for an
administrator with no prior identity-governance experience. It is distinct from Intune role-based
access control: this governs Entra directory roles, group and application access across the tenant.

## What you get
- A plain-language Solution Overview of PIM (eligible vs active roles, activation, approval, alerts), access reviews, and entitlement management (catalogs, access packages, policies, expiry).
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps in the Entra admin center, in the required order.
- Five PowerShell scripts for governance discovery, privileged-access validation, a standing-privilege and coverage report, safe remediation of standing admin, and a governance-scope group builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A governance baseline where privileged directory roles are onboarded to PIM as eligible (not
standing), activation is approval-gated and alerted, access reviews recertify roles, groups, and app
access on a schedule, and entitlement-management access packages grant access with a defined policy
and an expiry date. Break-glass emergency accounts are deliberately excluded from PIM so a
misconfiguration can never lock every administrator out.

## The Phoenixtekk deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Just-in-time, approval-gated admin, access recertified on a schedule, and entitlements packaged with
expiry — least privilege that is time-bound and provable — proven on a pilot before you scale.


---


# 1. Solution Overview — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

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

## What you can control
- PIM role assignment as eligible vs active, activation maximum duration, and permanent-vs-time-bound assignment expiry.
- Activation requirements: approval, approver list, multi-factor authentication, justification, and ticket information.
- Access reviews for directory roles (via PIM), for groups and application assignments, and for access-package assignments — with a recurrence, reviewer, and auto-apply of results.
- Entitlement-management catalogs, access packages, request/approval policies, and access expiry or periodic review.
- PIM alerts (for example, too many Global Administrators, or admins with standing assignments) and their thresholds.

## Benefits
- Least privilege — admins hold roles eligibly and activate only when needed, shrinking standing attack surface.
- Time-bound — activations and access-package grants expire automatically, so access does not accumulate.
- Provable — activations, approvals, and review decisions are logged for audit and compliance.
- Self-service with control — users request access packages; policy decides who approves and when it expires.
- Automatic decay of stale access — access reviews remove what is no longer approved without manual cleanup.

## Limitations (be honest with buyers)
- Entra ID Governance / P2 licensing is required for PIM, access reviews, and entitlement management; confirm licensing before you begin (see requirements).
- PIM governs Entra directory roles, PIM-enabled groups, and Azure resource roles — not Intune RBAC and not on-premises Active Directory admin rights.
- Over-tight approval or too few approvers can delay legitimate activations; approver coverage must be planned.
- Break-glass accounts are intentionally outside PIM and must instead be protected by strong stored credentials, exclusion documentation, and sign-in monitoring.

## The standard Phoenixtekk deployment model
> Onboard privileged roles to PIM as eligible with approval and alerts -> stand up access reviews for
> roles and app access -> build entitlement-management access packages with policy and expiry ->
> validate activation and recertification on a pilot scope -> expand to the tenant. Phoenixtekk
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.


---


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


# 3. Implementation Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Follow these steps in order, in the Microsoft Entra admin center (`https://entra.microsoft.com`),
under `Identity governance`.

> Model: onboard privileged roles to PIM as eligible with approval and alerts, recertify access with
> access reviews, and package access with entitlement management — validated on a pilot scope before
> the tenant. Break-glass accounts stay excluded from PIM throughout.

## Step 1 — Confirm break-glass accounts are excluded
1. Entra -> `Users`; confirm two cloud-only break-glass accounts hold a permanent, active `Global Administrator` assignment.
2. Do not onboard these accounts to PIM activation; document their exclusion. Run `IGA-Discovery.ps1` to record the current state before any change.

## Step 2 — Build the governance scope and approver groups
1. Entra -> `Groups -> New group` -> Security -> `IGA Pilot – Governance Scope – Pilot` (a few representative principals). Create.
2. Create `IGA Approvers – Privileged Roles – Pilot` with at least two members. Create.
3. Optionally run `IGA-Set-ScopeTargeting.ps1` to create these groups and set membership consistently.

## Step 3 — Onboard a privileged role to PIM (eligible)
1. Entra -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles`.
2. Open `Assignments -> Add assignments`; choose a role to govern first (start with a non-`Global Administrator` role such as `User Administrator`).
3. Select the pilot admins; set assignment type Eligible (not Active); set a start/end so the eligibility itself is time-bound where appropriate. Assign.
4. Repeat for each privileged role you are governing. Leave break-glass accounts untouched.

## Step 4 — Set role activation policy (approval, MFA, alerts)
1. In PIM -> `Microsoft Entra roles -> Settings`, open the role you onboarded.
2. Set the activation maximum duration (for example 4 hours); require multi-factor authentication on activation; require justification; require ticket information if used.
3. Enable Require approval to activate and set the approver to `IGA Approvers – Privileged Roles – Pilot`. Update.
4. In PIM -> `Alerts`, review and enable alerts (for example too many Global Administrators, and admins with standing assignments) and tune thresholds.

## Step 5 — Create an access review for privileged roles
1. Entra -> `Identity governance -> Access reviews -> New access review`.
2. Review type: `Microsoft Entra roles`; select the roles you onboarded to PIM. Name it `Access Review – Privileged Roles – Pilot`.
3. Reviewer: resource owner or a named reviewer; set recurrence (for example quarterly); enable Auto apply results and set "if reviewers do not respond" to Remove access (or Take recommendations). Create.

## Step 6 — Create an access review for group / application access
1. `Access reviews -> New access review`; review type `Teams + Groups` or `Applications`.
2. Select the group(s) or enterprise app(s) to recertify. Name it `Access Review – App Access – Pilot`.
3. Reviewer: group owner / manager / self-review as appropriate; set recurrence and Auto apply results. Create.

## Step 7 — Create an entitlement-management catalog
1. Entra -> `Identity governance -> Entitlement management -> Catalogs -> New catalog`.
2. Name it `Governance Catalog – App Access – Pilot`; enable it for the pilot scope. Create.
3. Open the catalog -> `Resources -> Add resources` and add the groups, apps, or SharePoint sites that access packages will grant.

## Step 8 — Create an access package with a policy and expiry
1. In the catalog -> `Access packages -> New access package`. Name it `Access Package – App Access – Pilot`.
2. Resource roles: add the group/app role the package grants.
3. Requests policy: who can request (for example members of `IGA Pilot – Governance Scope – Pilot`); require approval and set the approver to the approver group.
4. Lifecycle: set an expiry (for example 90 days) and/or require an access review of assignments. Create.

## Step 9 — Validate on the pilot scope
1. Have a pilot admin activate the onboarded role in PIM and confirm approval + MFA + expiry behave as configured; run `IGA-Validation.ps1`.
2. Have a pilot user request the access package and confirm approval and expiry; confirm the access review issues correctly.
3. Run `IGA-Report.ps1` to confirm standing-privilege is reduced and governance coverage is in place. Complete the Testing Guide.

## Step 10 — Reduce residual standing admin (safe)
1. From the inventory (Step 1 / `IGA-Report.ps1`), identify standing (active) admin assignments that should be eligible instead.
2. Run `IGA-Remediation.ps1` with the default `-WhatIf` to preview converting standing assignments to eligible; re-run without `-WhatIf` once confirmed. Never touch break-glass accounts.

## Step 11 — Expand to production
1. Onboard the remaining privileged roles to PIM (including `Global Administrator`, keeping break-glass excluded) with the same activation policy.
2. Extend access reviews and access packages to the remaining groups, apps, and users.
3. Re-validate each cycle with `IGA-Validation.ps1` and `IGA-Report.ps1`.

---
### Order of operations
`Break-glass check -> Scope/approver groups -> Onboard role (eligible) -> Activation policy + alerts -> Role access review -> App access review -> Catalog -> Access package -> Validate -> Reduce standing admin -> Expand`


---


# 5. Testing Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Run after the pilot scope is configured (Implementation Step 9) and after each governance cycle or
expansion.

## Test 1 — Role is eligible, not standing
Do: Entra -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles -> Assignments`; or run `IGA-Validation.ps1`.
Expected: The onboarded pilot role shows Eligible assignments for pilot admins; no unexpected standing (active) assignments except documented break-glass.

## Test 2 — Activation is approval-gated and time-bound
Do: A pilot admin activates the role in PIM (justification + MFA); an approver approves.
Expected: Activation requires approval and MFA, records a justification, grants the role for the configured window, and expires automatically.

## Test 3 — Break-glass excluded
Do: Confirm the two break-glass accounts still hold permanent active `Global Administrator` and are not subject to PIM activation; run `IGA-Validation.ps1`.
Expected: Break-glass accounts sign in without PIM activation; they are flagged as intentionally excluded, not as a violation.

## Test 4 — Privileged-role access review works
Do: Open `Access Review – Privileged Roles – Pilot`; a reviewer records approve/deny decisions; let auto-apply run.
Expected: Denied access is removed on apply; the review is logged with reviewer decisions.

## Test 5 — App/group access review works
Do: Open `Access Review – App Access – Pilot`; a reviewer recertifies membership.
Expected: Unapproved members are removed on apply; decisions are recorded.

## Test 6 — Access package grants with policy and expiry
Do: A pilot user requests `Access Package – App Access – Pilot`; an approver approves.
Expected: Access is granted per the resource role, subject to approval, and carries the configured expiry (or scheduled review).

## Test 7 — Governance coverage report
Do: Run `IGA-Report.ps1`.
Expected: A clear picture of standing vs eligible privileged assignments, roles onboarded to PIM, access reviews in place, and access packages published.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-4 pass; activation is approval-gated and time-bound; break-glass excluded |
| Expand pass | Tests 5-7 pass for the broader scope before onboarding `Global Administrator` tenant-wide |


---


# 6. Troubleshooting Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Use `IGA-Validation.ps1` / `IGA-Discovery.ps1` for current governance state and `IGA-Report.ps1`
for standing-privilege and coverage, `IGA-Remediation.ps1` for safe fixes.

## A. PIM activation problems
| Symptom | Cause | Remediation |
|---|---|---|
| Admin cannot activate a role | No eligible assignment, or activation blocked by policy | Confirm an Eligible assignment exists in PIM; check activation policy (MFA/approval); run `IGA-Validation.ps1` |
| Activation stuck waiting for approval | No available approver, or approver group empty | Confirm the approver group has 2+ members; add coverage with `IGA-Set-ScopeTargeting.ps1` |
| Activation fails MFA | Admin has no strong method registered | Register a multi-factor method for the admin, then retry activation |

## B. Break-glass and lockout risk
- Confirm the two break-glass accounts hold permanent active `Global Administrator` and are excluded from PIM activation and from broad Conditional Access/MFA policies; run `IGA-Discovery.ps1`.
- If PIM/approval is misconfigured tenant-wide, sign in with a break-glass account to restore access, then correct the policy. Never onboard break-glass accounts to PIM.

## C. Access review issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed access unexpectedly | "If reviewers do not respond" set to Remove access and no decision recorded | Set the no-response action to Take recommendations or No change; re-grant via PIM/access package; re-run the review |
| Review has no reviewer | Manager attribute empty, or owner not set | Populate the `Manager` attribute or assign a named reviewer; recreate the review |
| Decisions not applied | Auto apply results disabled | Enable Auto apply results, or apply the review manually |

## D. Entitlement-management / access-package issues
| Symptom | Cause | Remediation |
|---|---|---|
| User cannot request a package | Requestor not in the request policy scope | Add the user to the scope group (for example the pilot scope) or widen the request policy |
| Request not approved | Approver group empty or approver unavailable | Confirm approver coverage; add members with `IGA-Set-ScopeTargeting.ps1` |
| Access did not expire | No expiry / no review on the package lifecycle | Set an access-package expiry or a periodic review in the package lifecycle settings |

## E. Licensing / feature not visible
- If `Identity governance`, PIM, or access reviews are not visible, confirm Entra ID Governance / P2 licensing is assigned; run `IGA-Discovery.ps1`. Assign P2/Governance to administrators, reviewers, and access-package users.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All'
# Eligible vs active Entra role assignments (PIM)
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All
Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All
# Access reviews and access packages
Get-MgIdentityGovernanceAccessReviewDefinition -All
Get-MgEntitlementManagementAccessPackage -All
```

## G. When to escalate
If roles are correctly eligible, the approver group has coverage, MFA is registered, and activation
or an access review still fails, capture the output of `IGA-Report.ps1` and the PIM audit log for the
affected role and open a Microsoft support case.


---


# 7. Best Practices — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

- Make privileged roles eligible, not standing. Onboarding admin roles to PIM as eligible is the single most important practice — it removes always-on privilege and shrinks the attack surface.
- Keep break-glass accounts out of PIM. Two cloud-only emergency accounts must hold permanent active `Global Administrator` and be excluded from PIM activation, so a PIM misconfiguration can never lock everyone out. Protect them with strong stored credentials and sign-in alerts.
- Gate activation with approval and MFA. Require approval, multi-factor authentication, and justification on activation, and keep the activation window short so access is time-bound.
- Ensure approver coverage. Use an approver group with at least two members so legitimate activations and access-package requests are not delayed by a single unavailable approver.
- Recertify on a schedule. Run recurring access reviews for privileged roles, group membership, and app access, with auto-apply, so stale access decays without manual cleanup.
- Package access, do not assign it ad hoc. Use entitlement-management access packages with a request policy and expiry so grants are governed, self-service, and time-bound.
- Set sensible expiry. Give access packages a defined expiry or a periodic review so access does not accumulate silently.
- Watch PIM alerts. Enable and tune alerts (too many Global Administrators, standing assignments, stale eligibility) and act on them.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, reviews, catalogs, and packages so audits and expansion are repeatable.
- Pilot before you expand. Validate activation, approval, and recertification on a small scope before onboarding `Global Administrator` and the rest of the tenant, and keep a rollback path.


---


# 8. Deliverables Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What Entra ID Governance is: PIM, access reviews, entitlement management, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Entra steps (PIM onboarding, activation policy, reviews, catalog, access package) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IGA-Discovery.ps1` | Reports PIM role eligibility/assignments, access reviews, and entitlement-management packages, and flags break-glass exclusion |
| `IGA-Validation.ps1` | Confirms roles are eligible (not standing), activation policy is gated, and break-glass is excluded |
| `IGA-Report.ps1` | Standing-privilege vs eligible summary and governance-coverage report (Microsoft Graph) |
| `IGA-Remediation.ps1` | Safe remediation (default `-WhatIf`); converts standing admin assignments to eligible |
| `IGA-Set-ScopeTargeting.ps1` | Builds the governance-scope and approver groups used by PIM, reviews, and access packages |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Privileged access made just-in-time and approval-gated, access recertified on a schedule, and
entitlements packaged with expiry — least privilege that is time-bound and provable — proven on a
pilot before you scale.
