# Intune Administrative Governance — RBAC & Multi-Admin Approval — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: RBACGOVG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Intune Administrative Governance: RBAC & Multi-Admin Approval — Government (GCC High) (Microsoft Intune)

White-label · Intune Solutions · Government (GCC High) edition

When everyone is an Intune Administrator, mistakes and blast radius follow — a bad app assignment or
a destructive script can hit the whole fleet, and a single compromised admin account can do
unlimited damage. Modern governance fixes both with least-privilege RBAC and a second pair of eyes on
risky changes. This solution implements Intune administrative governance: custom roles and scope tags
that limit who can touch what, plus access policies (multi-admin approval) so high-risk actions — such
as app or script deployments — require a second admin to approve before they go live.

This is the **Government (GCC High)** edition. It is authored for the **US sovereign cloud** — every
step uses the `*.us` admin portals (`intune.microsoft.us`, `entra.microsoft.us`,
`portal.office365.us`, `portal.azure.us`) and US Government Microsoft Graph
(`graph.microsoft.us`, `-Environment USGov`), and the Commercial-vs-GCC-High parity gaps are called
out so a government tenant is configured correctly — not with Commercial steps that silently fail to
sign in or reference features (like Copilot-assisted approval) that GCC High does not have.

This is a complete, deploy-it-today package for governing Intune administration, written for an
administrator with no prior RBAC experience.

## What you get
- A plain-language Solution Overview of Intune RBAC (built-in vs custom roles, permissions, scope
  tags, scope groups) and the multi-admin approval / access-policy model — plus an explicit
  *Commercial vs GCC High — what's different* section and a cited parity reference.
- A Requirements Guide with verify / implement-if-missing for every prerequisite on the sovereign
  portals, including a break-glass admin so you never lock yourself out.
- An Implementation Guide of precise, ordered `*.us` portal steps: design roles and scope tags,
  create custom roles and assignments, tag objects, wire the approver group, enable access policies
  for high-risk resource types, then pilot, validate, and expand — with GCC-High caveats inline.
- Five PowerShell scripts (pre-wired for `-Environment USGov`) for governance discovery,
  role-assignment and approval-policy validation, a coverage and over-privilege report, safe
  remediation of over-privileged assignments, and an admin/approver scope-group builder.
- Testing and Troubleshooting guides — including a sovereign-endpoint check — for a confident
  rollout.

## What this delivers
A least-privilege RBAC model — custom roles such as `App Manager – Region A – Prod` bounded by scope
tags such as `Region A – Devices – Prod` — combined with multi-admin approval gates
(`App Deploy Approval – All – Prod`, `Script Deploy Approval – All – Prod`) that require a second
admin to approve high-risk changes, all configured through the correct GCC High portals and proven on
a pilot before broad enforce.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Intune locked down to least privilege on GCC High, with a required second-admin approval on high-risk
changes — so mistakes and blast radius shrink, separation of duties is enforced, and every risky
change has an audit trail — all inside the US Government cloud boundary, deployable by a single
administrator and validated before fleet rollout.


---


# 1. Solution Overview — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

> This is the **Government (GCC High)** edition. It is authored for the **US sovereign cloud**
> (GCC High / DoD, built on Azure Government). Everything you do runs against **`*.us` admin
> portals** and **US Gov Microsoft Graph** (`-Environment USGov`), not the Commercial `*.com`
> portals. The capability is the same idea as Commercial Intune, but the URLs differ and a few
> adjacent features are absent — those gaps are called out inline and in
> `gcc-high-parity-notes.md`.

## What Intune administrative governance is
Intune administrative governance is the practice of controlling *who* can administer Intune, *what*
they can touch, and *which* high-risk changes need a second person to sign off. It combines two
native Intune capabilities:

1. Role-based access control (RBAC) — built-in and custom roles, granular permissions, and scope
   tags that limit each admin to a defined slice of objects and a defined set of actions.
2. Multi-admin approval (access policies) — `operationApprovalPolicies` that require a second admin
   to approve high-risk operations (such as app or script deployments) before they take effect.

Together they replace the "everyone is an Intune Administrator" anti-pattern with least-privilege
roles and a required second pair of eyes on the changes that can break a fleet — the same model in
GCC High as in Commercial, just reached through the sovereign portals.

## Commercial vs GCC High — what's different
This is the most important section for a government tenant. The governance *capability* (RBAC, scope
tags, multi-admin approval / access policies) is part of Intune's **standard MDM feature set**, which
Microsoft lists as available in GCC High and DoD. What changes is **where** you do it and a few
**adjacent** features you cannot rely on:

| Area | Commercial | GCC High (this edition) |
|---|---|---|
| Intune admin center | `https://intune.microsoft.com` or `https://endpoint.microsoft.com` | `https://intune.microsoft.us` (and `https://endpoint.microsoft.us`) |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` |
| Microsoft 365 admin | `https://admin.microsoft.com` | `https://portal.office365.us/adminportal/` |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us` |
| Sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph | `https://graph.microsoft.com` (`-Environment Global`) | `https://graph.microsoft.us` (`-Environment USGov`) |
| RBAC roles, scope tags, role assignments | GA | Standard MDM feature — available in GCC High/DoD [verify for your tenant] |
| Multi-admin approval / access policies (`operationApprovalPolicies`) | GA | Part of the RBAC/MAA fundamentals surface in the shared government instance [verify for GCC High — Microsoft does not enumerate MAA separately in the government service description] |
| Change Review Agent (Security Copilot suggestions inside Multi Admin Approval) | Available | **Not available** — Microsoft Security Copilot is listed as *not yet supported* in GCC High/DoD. Approvals are fully manual. |
| Remote Help (an adjacent admin-assist feature) | Available | **Not yet available** in GCC High/DoD (planned) |

The takeaway: **do not follow Commercial steps verbatim.** They point at `*.com` URLs and, in the
case of Copilot-assisted approval, at a feature that does not exist in your cloud. This edition gives
you the correct sovereign portals, the US Gov Graph endpoint, and the parity gaps so a government
tenant is configured right the first time — not with Commercial steps that silently fail to sign in
or reference features you don't have.

> Note on "GCC" vs "GCC High": Microsoft runs Intune as **one instance** for Commercial *and* GCC
> (state/local government uses the same commercial service), and a **separate government instance**
> for **GCC High and DoD**. This edition is written for **GCC High / DoD** — the sovereign `*.us`
> cloud. If you are actually a *GCC* (not High) tenant, you use the Commercial `*.com` portals; use
> the Commercial edition instead.

## How it works
1. An Intune custom role bundles a precise set of permissions (for example, manage apps but not
   manage devices) into a reusable definition under `roleDefinitions`.
2. A scope tag (under `roleScopeTags`) is a label applied to Intune objects (apps, policies,
   profiles) and to a role assignment, so an admin only sees and manages the objects that carry the
   same tag — a who-touches-what boundary.
3. A role assignment (under `roleAssignments`) binds a role definition to admin members, targets a
   set of managed objects (scope groups), and carries scope tags — defining the admin's effective
   reach.
4. An access policy (under `operationApprovalPolicies`, surfaced in the portal as Multi Admin
   Approval) names a resource type (for example, apps or scripts) and an approver group; any
   create/change/delete of that resource type is held as a request until a different admin in the
   approver group approves it.
5. Approvers review pending requests, approve or reject with a note, and only then does the change
   apply — so no single admin can unilaterally push a high-risk change. In GCC High this review is
   **fully manual** (no Change Review Agent / Copilot suggestions).

## What you can control
- Built-in vs custom roles — start from a built-in role or define a custom role with exactly the
  permissions an admin needs.
- Permissions — granular read/create/update/delete rights per Intune workload.
- Scope tags — partition objects (by site, business unit, platform) so admins manage only their
  slice.
- Scope groups — the admin members and the targeted managed groups on each assignment.
- Access policies (multi-admin approval) — which resource types require approval and which group
  approves them.

Intune supports access policies for these resource types (confirm the current list in your tenant
portal): Apps, Compliance policies, Configuration policies (settings catalog), Device actions (wipe,
retire, delete), Role-based access control, Scripts (Windows), and Tenant Configuration (device
categories). Changes to access policies themselves are always protected and require a second
approver.

## Why this matters (the why lives here, in the Overview)
- Blast radius — when every admin is a full Intune Administrator, one mistake (a bad app
  assignment, a destructive script) can hit the whole fleet. Least-privilege roles and scope tags
  shrink the radius of any single account.
- Insider and compromised-account risk — a stolen or rogue admin credential can do far less when it
  holds a narrow custom role, and high-risk actions still need a second approver. In a government
  tenant this maps directly to separation-of-duties controls auditors expect.
- Separation of duties — multi-admin approval enforces that the person who *requests* a high-risk
  change is not the person who *approves* it.
- Accountability and audit — named roles, scope tags, and approval records make it clear who can do
  what and who approved each risky change; Intune audit logs record every request and approval.
- Sovereign correctness — doing this in the right `*.us` portals with US Gov Graph keeps the whole
  control plane inside the government cloud boundary.

## Limitations (be honest with buyers)
- Multi-admin approval covers specific resource types (such as apps and scripts); it is not a
  blanket approval gate over every Intune action. Confirm the current supported resource types in
  the sovereign portal.
- Scope tags govern visibility/management of taggable Intune objects; not every object type
  supports tagging — verify coverage for the workloads you care about.
- RBAC controls Intune; tenant-wide identity roles live in Entra ID (`entra.microsoft.us`) and are
  governed separately.
- No Copilot-assisted approval — the Change Review Agent is Commercial-only; GCC High approvals are
  manual.
- Over-tightening can lock admins (or yourself) out — always keep a break-glass administrator
  outside the restricted roles and outside the approval gate.
- Where Microsoft's government service description does not explicitly enumerate a sub-feature (MAA
  is documented under Intune fundamentals, not called out separately in the government service
  description), treat it as **[verify for GCC High]** on your tenant before committing to a design.

## The standard deployment model
> Design roles and scope tags, build admin/approver scope groups, create custom roles and
> assignments, apply scope tags to objects, enable access policies for high-risk resource types,
> then pilot one approval before broad enforce — all in the GCC High portals. Repeatable pattern:
> Assess → Configure → Pilot → Validate → Expand.

---
*Sources: Microsoft Learn — "Microsoft Intune Government Service overview"
(learn.microsoft.com/intune/fundamentals/government-service); "Use Multi Admin Approval in Intune"
(learn.microsoft.com/intune/fundamentals/role-based-access-control/multi-admin-approval);
"Network endpoints for US government deployments"; Microsoft Graph national cloud deployments
(learn.microsoft.com/graph/deployments). GCC High portal URLs verified against Microsoft
government-cloud portal references.*


---


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


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Follow these steps in order, in the **Microsoft Intune admin center for US Government**
(`https://intune.microsoft.us`). Entra steps use `https://entra.microsoft.us`.

> GCC High caveat: these are the sovereign portals. If a step below tells you to open a portal, use
> the `*.us` URL — the Commercial `*.com` URL will refuse your government credentials. The
> governance model itself is identical to Commercial; only the URLs and a couple of adjacent
> features differ (see `gcc-high-parity-notes.md`).

> Model: Design least-privilege roles and a scope-tag taxonomy, build admin/approver scope groups,
> create custom roles and assignments, apply scope tags to objects, then enable access policies
> (multi-admin approval) for high-risk resource types. Pilot one approval before broad enforce, and
> keep a break-glass admin so you never lock yourself out.

All artifact names below are used verbatim; reuse them exactly.

## Step 1 — Build the admin and approver scope groups
1. `https://entra.microsoft.us` → Groups → New group → **Security** → `Intune Admins – Region A – Prod`
   (the admins who will hold the custom role). Add members. Create.
2. New group → **Security** → `Change Approvers – Apps – Prod` (the second-approver group). Add the
   approvers. Create.
   - GCC High caveat: the approver group **must be a security group**. Distribution lists, Microsoft
     365 groups, and mail-enabled security groups silently fail to resolve approver membership.
3. Optionally build both groups in one pass with `RBACGOVG-Set-ScopeTargeting.ps1` (connects with
   `-Environment USGov`).

## Step 2 — Create the scope tag
1. `https://intune.microsoft.us` → Tenant administration → Roles → Scope tags → Create.
2. Name: `Region A – Devices – Prod`. Next.
3. Assignments → add the groups/objects this tag should be visible to as needed. Create.

## Step 3 — Create the custom roles
1. Intune (`intune.microsoft.us`) → Tenant administration → Roles → All roles → Create → Custom role.
2. Name: `App Manager – Region A – Prod`. Under Permissions, enable only the app-management
   permissions this persona needs (for example Mobile apps: Read/Create/Update/Assign); leave
   device and policy permissions off. Next.
3. Scope (Tags): select `Region A – Devices – Prod`. Next → Create.
4. Create a second custom role `Policy Reader – All – Audit` with read-only permissions across the
   workloads an auditor must view, no write permissions. Create.
   - Tip: to manage MAA access policies with least privilege later, a custom role can carry the
     **Multi Admin Approval** permissions (Create/Read/Update/Delete access policy) instead of using
     the privileged Intune Administrator role.

## Step 4 — Assign the custom role
1. Tenant administration → Roles → All roles → open `App Manager – Region A – Prod` → Assignments →
   Assign.
2. Assignment name: `App Manager Assignment – Region A – Prod`.
3. Admin Groups (members): add `Intune Admins – Region A – Prod`.
4. Scope (Groups): add the managed group(s) this role may administer.
5. Scope (Tags): select `Region A – Devices – Prod`. Next → Create.

## Step 5 — Apply the scope tag to objects
1. For each app/policy/profile this region owns, open the object → Properties → Scope tags → add
   `Region A – Devices – Prod` → Save.
2. This makes the object visible/manageable only to admins whose assignment carries the same tag.
   Run `RBACGOVG-Discovery.ps1` to confirm tag coverage.

## Step 6 — Prepare the approver group for MAA (GCC High requirement)
1. The approver group `Change Approvers – Apps – Prod` must itself be **added to an Intune role
   assignment as a member group**, or Intune periodically removes members from the approver group.
   Add it to a suitable role assignment (for example a read-scoped role that matches what approvers
   need to review).
2. Approvers also need the **resource-specific Read permission** for the policy type they approve
   (for example Read on Mobile apps to approve app changes).
3. Enable **Allow access to unlicensed admins** only if an approver has no Intune license — note
   this setting is **irreversible** once turned on.

## Step 7 — Enable multi-admin approval for high-risk apps
1. `https://intune.microsoft.us` → Tenant administration → Multi Admin Approval → Access policies →
   Create.
2. On *Basics*: Name `App Deploy Approval – All – Prod`.
3. Profile type: select the **Apps** resource type (so app create/change/delete requires approval).
   Each policy supports a single profile type.
4. Approvers → Add groups → `Change Approvers – Apps – Prod`. (Exclude-group configurations are not
   supported.) Review + Create.
5. A **different** admin (with **Approval for Multi Admin Approval** permission) signs in and
   approves the new access policy, then the original admin re-opens it and selects **Complete** to
   activate it.

## Step 8 — Enable multi-admin approval for high-risk scripts
1. Multi Admin Approval → Access policies → Create.
2. Name: `Script Deploy Approval – All – Prod`.
3. Profile type: select the **Scripts** resource type (Windows scripts).
4. Approvers → `Change Approvers – Apps – Prod`. Review + Create, then approve + Complete as in
   Step 7.

## Step 9 — Pilot one approval (the pilot gate)
1. As an admin in `Intune Admins – Region A – Prod`, make a small change to a gated resource (for
   example edit a test app assignment). On the **Save + Review** surface, enter a **Business
   justification** and submit. The change is held as a pending request.
2. As a **different** admin in `Change Approvers – Apps – Prod`, go to Tenant administration → Multi
   Admin Approval → **Received requests**, open the Business justification, add Approver notes, and
   **Approve**.
3. Back as the requester, open **My requests** and select **Complete** to apply the change. Confirm
   the change applies only after approval, and that a rejection blocks it.
   - GCC High caveat: there is **no Change Review Agent / Copilot** suggestion column — review is
     fully manual. There are **no notifications**; tell approvers out-of-band. Requests **expire in
     3 days** if not completed.
4. Run `RBACGOVG-Validation.ps1` (`-Environment USGov`) to confirm the policy is active and the role
   assignment is correct.

## Step 10 — Validate and report
1. Run `RBACGOVG-Validation.ps1` → confirms role assignments and approval policies match the design.
2. Run `RBACGOVG-Report.ps1` → governance coverage and any over-privileged assignments.
3. Complete the Testing Guide before expanding.

## Step 11 — Expand to production
1. Roll the scope-tag taxonomy out to the remaining regions/business units; create additional custom
   roles and assignments following the same naming pattern.
2. Add access policies for any other high-risk resource types once the pilot approval is proven.
3. Re-validate each change with `RBACGOVG-Validation.ps1` / `RBACGOVG-Report.ps1`.

> Role-policy deadlock warning: if you create an access policy for the **Role** (RBAC) profile type,
> every role change — including the RBAC assignments MAA itself needs — then requires approval, which
> can deadlock you. Configure and verify all other MAA and RBAC assignments **first**; add a Role
> access policy last. To break a deadlock: Multi Admin Approval → Access policies → delete the Role
> policy, wait 3–5 minutes, complete the RBAC assignment, then re-create the Role policy if desired.

> Rollback note: if an assignment or approval gate is too tight, loosen or remove it using your
> break-glass Global Administrator (excluded from the gate). `RBACGOVG-Remediation.ps1` runs with
> `-WhatIf` by default so you can preview any tightening before it is applied.

---
### Order of operations
`Scope groups → Scope tag → Custom roles → Role assignment → Tag objects → Approver group into a role → App approval policy → Script approval policy → Pilot approval → Validate/report → Expand`


---


# 5. Testing Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Run after the pilot approval is configured (Implementation Step 9) and after each governance change.
All portal steps use `https://intune.microsoft.us`; all scripts connect with `-Environment USGov`.

## Test 1 — Custom roles exist and are scoped
Do: `intune.microsoft.us` → Tenant administration → Roles → All roles → confirm
`App Manager – Region A – Prod` and `Policy Reader – All – Audit`; or run `RBACGOVG-Validation.ps1`.
Expected: Both custom roles exist with only their intended permissions and scope tags.

## Test 2 — Role assignment is correct
Do: Open `App Manager – Region A – Prod` → Assignments → confirm `App Manager Assignment – Region A – Prod`.
Expected: Members = `Intune Admins – Region A – Prod`; scope tag = `Region A – Devices – Prod`; scope
groups as designed.

## Test 3 — Scope tags limit visibility
Do: Sign in to `intune.microsoft.us` as a member of `Intune Admins – Region A – Prod`.
Expected: Only objects carrying `Region A – Devices – Prod` are visible/manageable; objects without
the tag are hidden.

## Test 4 — Least privilege holds
Do: As the app-manager admin, attempt an action outside the role (for example create a device
compliance policy).
Expected: The action is blocked / not available — the role grants app permissions only.

## Test 5 — Access policies exist and target the approver group
Do: Tenant administration → Multi Admin Approval → Access policies → confirm
`App Deploy Approval – All – Prod` and `Script Deploy Approval – All – Prod`; or run
`RBACGOVG-Validation.ps1`.
Expected: Both policies exist, target the correct resource types, and approver = `Change Approvers – Apps – Prod`.

## Test 6 — Approver group is correctly wired (GCC High)
Do: Confirm `Change Approvers – Apps – Prod` is a **security group**, is added to an Intune role
assignment as a member group, and its members hold the resource-specific Read permission.
Expected: Approver membership resolves and persists (Intune does not periodically strip it), and
approvers can open Received requests.

## Test 7 — A gated change requires approval
Do: As an app-manager admin, change a gated app with a Business justification; as a **different**
approver, review under Multi Admin Approval → Received requests and Approve; requester selects
**Complete**.
Expected: The change is held pending until a second admin approves; it does not apply on its own, and
only applies after the requester completes it.

## Test 8 — Rejection blocks the change
Do: Submit another gated change and have the approver reject it with a note.
Expected: The change is not applied; the requester sees the rejection and the Approver notes.

## Test 9 — Governance coverage report
Do: Run `RBACGOVG-Report.ps1`.
Expected: A clear report of roles, scope-tag coverage, assignments, approval-policy coverage, and any
over-privileged assignments flagged.

## Test 10 — Sovereign endpoint check (GCC High)
Do: Run any script and confirm the sign-in prompt is `login.microsoftonline.us` and Graph calls hit
`graph.microsoft.us`; from the admin workstation reach `https://graph.microsoft.us`.
Expected: Authentication and Graph calls stay in the US Government cloud — never `*.com`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–8, 10 pass on the pilot scope; one approval and one rejection behave correctly, all against `*.us` endpoints |
| Broad pass | Tests 1–6, 9, 10 pass across the expanded scope before declaring governance complete |


---


# 6. Troubleshooting Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Use `RBACGOVG-Discovery.ps1` and `RBACGOVG-Validation.ps1` for current state,
`RBACGOVG-Report.ps1` for coverage/over-privilege, and `RBACGOVG-Remediation.ps1` (`-WhatIf` by
default) for safe fixes. All scripts connect to **US Gov Graph** (`-Environment USGov`).

## A. Sign-in / wrong-cloud errors (GCC High specific — check this first)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal rejects your government account / redirect loop | You opened a Commercial `*.com` portal | Use the sovereign `*.us` URL: `intune.microsoft.us`, `entra.microsoft.us`, `portal.office365.us/adminportal/` |
| `Connect-MgGraph` fails auth or returns no data | Missing `-Environment USGov`; module hit `login.microsoftonline.com` | Add `-Environment USGov` (DoD: `-Environment USGovDoD`); confirm it targets `graph.microsoft.us` |
| Graph calls time out behind proxy | US Gov endpoints or `*.manage.microsoft.us` blocked / TLS-inspected | Allow US Government Intune/Graph URLs; **do not SSL-inspect** `*.manage.microsoft.us` |

## B. Admin can see/do too much or too little
| Symptom | Cause | Remediation |
|---|---|---|
| Admin sees objects they should not | Object missing the scope tag, or assignment carries the wrong tag | Apply `Region A – Devices – Prod` to the object; confirm the assignment's scope tag with `RBACGOVG-Validation.ps1` |
| Admin cannot see objects they should manage | Object not tagged, or admin in the wrong group | Tag the object; confirm membership of `Intune Admins – Region A – Prod` |
| Admin can perform actions outside their role | Over-broad custom role or a second, wider assignment | Run `RBACGOVG-Report.ps1` to find over-privilege; tighten with `RBACGOVG-Remediation.ps1` |

## C. Multi-admin approval not gating changes
| Symptom | Cause | Remediation |
|---|---|---|
| Gated change applies without approval | Access policy missing or wrong resource type, or not yet **Completed** | Confirm `App Deploy Approval – All – Prod` / `Script Deploy Approval – All – Prod` exist, target the right type, and were finalized with **Complete** — `RBACGOVG-Validation.ps1` |
| No approvers can act | Approver group empty, not a security group, or not added to a role | Populate `Change Approvers – Apps – Prod`; ensure it is a **security group** added to an Intune role assignment as a member group |
| Approver membership keeps disappearing | Approver group not added to any Intune role assignment (Intune strips it periodically) | Add the approver group to a role assignment as a member group |
| Requester can self-approve | Requester is also in the approver group | An admin cannot approve their own request; a **different** approver must act — keep requesters and approvers distinct |
| Multi Admin Approval node not present | MAA not surfaced on this tenant | Run `RBACGOVG-Discovery.ps1`; if `operationApprovalPolicies` errors or the node is absent, treat MAA as **[verify for GCC High]** and open a Microsoft support case |

## D. GCC-High-specific gotchas
- **No Change Review Agent / Copilot column.** Security Copilot is not available in GCC High/DoD, so
  the MAA node has no Agent Response suggestions — approvals are fully manual. This is expected, not a
  bug.
- **No notifications.** Intune never emails on new/changed requests; if an approval seems ignored,
  the approver simply wasn't told — escalate out-of-band per your SLA.
- **Requests expire in 3 days.** A "stuck" request that passed 3 days is **Expired** and must be
  resubmitted.
- **"Allow access to unlicensed admins" is irreversible.** If an approver lost access after you
  toggled licensing, review the unlicensed-admin limits; you cannot turn the setting back off.

## E. Locked out (no one can make changes)
- Symptom: every admin is blocked by the approval gate or by an over-tight role, or a **Role**-type
  access policy deadlocked RBAC.
- Remediation: sign in with the break-glass Global Administrator (excluded from the gate) at
  `intune.microsoft.us`. For a Role-policy deadlock: Tenant administration → Multi Admin Approval →
  Access policies → delete the **Role** policy, wait 3–5 minutes, complete the RBAC assignment
  (add the approver group), then re-create the Role policy if desired. This is why the break-glass
  account in requirement 2.4 is mandatory.

## F. Pending approval requests stuck
- Approvers not responding within the SLA → escalate per the change-control process (requirement
  2.8); confirm the approver group is populated and someone with **Approval for Multi Admin
  Approval** permission is available. Remember there are no notifications and a 3-day expiry.

## G. Scripts cannot read governance data
- The discovery/validation/report scripts need **US Gov** Microsoft Graph access and the right read
  scopes (for example `DeviceManagementRBAC.Read.All`, `DeviceManagementConfiguration.Read.All`).
  Confirm the operator consented to the requested scopes, that `-Environment USGov` is in effect, and
  that the workstation can reach `https://graph.microsoft.us`.

## H. Diagnostics quick reference (US Gov)
```powershell
Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementRBAC.Read.All' -NoWelcome
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value | Select-Object displayName, isBuiltIn
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleScopeTags').value | Select-Object displayName, id
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value | Select-Object displayName, policyType
```
If `operationApprovalPolicies` returns an error on your GCC High tenant, MAA may not be surfaced —
capture the error and open a Microsoft support case.

## I. When to escalate
If roles, scope tags, and access policies match the design (confirmed by `RBACGOVG-Validation.ps1`),
the approver group is a security group added to a role and populated, and the break-glass path works,
but approvals still do not behave as expected, capture the `RBACGOVG-Report.ps1` output and open a
Microsoft support case referencing your GCC High / DoD tenant.


---


# 7. Best Practices — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

- Always use the sovereign portals. Do every step in `https://intune.microsoft.us` /
  `https://entra.microsoft.us` and connect PowerShell with `-Environment USGov`
  (`https://graph.microsoft.us`). Commercial `*.com` URLs reject government credentials.
- Least privilege by default. Start every admin from a narrow custom role (for example
  `App Manager – Region A – Prod`), not the full Intune Administrator role; grant only the
  permissions the persona actually uses. Use a custom role carrying the Multi Admin Approval
  permissions for routine access-policy work instead of the privileged Intune Administrator role.
- Always keep a break-glass admin. Maintain a cloud-only Global Administrator excluded from the
  custom roles and from the approver group, so a too-tight policy can never lock everyone out —
  doubly important in GCC High where support turnaround is slower.
- Use security groups for approvers. The approver group **must** be a security group and **must** be
  added to an Intune role assignment as a member group, or Intune periodically strips its members.
  Distribution lists, M365 groups, and mail-enabled security groups silently fail.
- Design the scope-tag taxonomy first. A consistent tag scheme (region/business unit/platform) is
  the who-touches-what boundary; apply tags to objects as you create them, not as an afterthought.
- Separate request from approval. Configure access policies so the admin who makes a high-risk change
  is never the one who approves it — an admin cannot approve their own request even if in the
  approver group. This is the whole point of multi-admin approval.
- Gate the changes that actually hurt. Start with the highest-blast-radius resource types (apps,
  scripts) via `App Deploy Approval – All – Prod` and `Script Deploy Approval – All – Prod`; add more
  only as the process matures.
- Add a Role-type access policy last. A Role/RBAC access policy gates all role changes and can
  deadlock the very RBAC assignments MAA needs. Configure and verify all other MAA/RBAC first.
- Plan approvals as a human process — there is no Copilot. GCC High has **no Change Review Agent /
  Security Copilot** assist and Intune sends **no notifications**; agree an approval SLA, keep an
  approver roster, and notify approvers out-of-band. Remember requests **expire in 3 days**.
- Pilot one approval before broad enforce. Prove an approval and a rejection on a test change before
  enforcing the gate across the fleet (the pilot gate).
- Name everything consistently. Use `<Purpose> – <Scope> – <Stage>` for every role, tag, group,
  assignment, and policy so the model is self-documenting and auditable.
- Review for over-privilege regularly. Run `RBACGOVG-Report.ps1` on a schedule to catch assignments
  that drifted broader than the design.
- Remediate safely. `RBACGOVG-Remediation.ps1` defaults to `-WhatIf`; preview every tightening before
  applying, and apply during a change window.
- Verify sub-features on your tenant. Where Microsoft's government service description does not
  enumerate a sub-feature separately, treat it as **[verify for GCC High]** before committing a
  design, and record what you confirmed for your audit trail.
- Document the governance model. Record roles, tags, assignments, gated resource types, the approver
  roster, and the portal/endpoint set (sovereign) for audits and repeatability.


---


# 8. Deliverables Summary — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (GCC High edition) |
| 1. Solution Overview | What Intune RBAC + multi-admin approval is, the model, benefits, limitations, the why, and a *Commercial vs GCC High — what's different* section |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the sovereign portals |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps on `*.us` portals with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-endpoint check |
| 6. Troubleshooting Guide | Field issues and remediation, including GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for a government tenant |
| GCC High Parity Notes | Cited Commercial-vs-GCC-High feature parity reference |

## PowerShell scripts (all connect with `-Environment USGov` → `graph.microsoft.us`)
| Script | What it does |
|---|---|
| `RBACGOVG-Discovery.ps1` | Inventories role definitions, scope tags, role assignments, and access policies (read-only) |
| `RBACGOVG-Validation.ps1` | Validates role assignments and approval policies against the design (read-only) |
| `RBACGOVG-Report.ps1` | Governance-coverage and over-privilege report (read-only) |
| `RBACGOVG-Remediation.ps1` | Safely tightens over-privileged assignments; defaults to `-WhatIf` |
| `RBACGOVG-Set-ScopeTargeting.ps1` | Builds the admin/approver scope groups |

## What the buyer receives
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP, pre-wired for US Gov Graph (`-Environment USGov`).
- A repeatable process following the standard model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Intune locked down to least privilege on a **GCC High** tenant — custom roles and scope tags limiting
who can touch what, and a required second-admin approval on high-risk changes — configured through the
correct sovereign `*.us` portals and US Gov Graph, with Commercial-vs-GCC-High parity gaps handled,
and proven on a pilot before you scale.
