# 1. Solution Overview — Intune Administrative Governance (RBAC & Multi-Admin Approval)

## What Intune administrative governance is
Intune administrative governance is the practice of controlling *who* can administer Intune, *what*
they can touch, and *which* high-risk changes need a second person to sign off. It combines two
native Intune capabilities:

1. Role-based access control (RBAC) — built-in and custom roles, granular permissions, and scope
   tags that limit each admin to a defined slice of objects and a defined set of actions.
2. Multi-admin approval (access policies) — `operationApprovalPolicies` that require a second admin
   to approve high-risk operations (such as app or script deployments) before they take effect.

Together they replace the "everyone is an Intune Administrator" anti-pattern with least-privilege
roles and a required second pair of eyes on the changes that can break a fleet.

## How it works
1. An Intune custom role bundles a precise set of permissions (for example, manage apps but not
   manage devices) into a reusable definition under `roleDefinitions`.
2. A scope tag (under `roleScopeTags`) is a label applied to Intune objects (apps, policies,
   profiles) and to a role assignment, so an admin only sees and manages the objects that carry the
   same tag — a who-touches-what boundary.
3. A role assignment (under `roleAssignments`) binds a role definition to admin members, targets a
   set of managed objects (scope groups), and carries scope tags — defining the admin's effective
   reach.
4. An access policy (under `operationApprovalPolicies`, surfaced in the portal as Multi admin
   approval) names a resource type (for example, apps or scripts) and an approver group; any
   create/change/delete of that resource type is held as a request until a different admin in the
   approver group approves it.
5. Approvers review pending requests, approve or reject with a note, and only then does the change
   apply — so no single admin can unilaterally push a high-risk change.

## What you can control
- Built-in vs custom roles — start from a built-in role or define a custom role with exactly the
  permissions an admin needs.
- Permissions — granular read/create/update/delete rights per Intune workload.
- Scope tags — partition objects (by site, business unit, platform) so admins manage only their
  slice.
- Scope groups — the admin members and the targeted managed groups on each assignment.
- Access policies (multi-admin approval) — which resource types require approval and which group
  approves them.

## Why this matters (the why lives here, in the Overview)
- Blast radius — when every admin is a full Intune Administrator, one mistake (a bad app
  assignment, a destructive script) can hit the whole fleet. Least-privilege roles and scope tags
  shrink the radius of any single account.
- Insider and compromised-account risk — a stolen or rogue admin credential can do far less when it
  holds a narrow custom role, and high-risk actions still need a second approver.
- Separation of duties — multi-admin approval enforces that the person who *requests* a high-risk
  change is not the person who *approves* it — a control auditors expect.
- Accountability and audit — named roles, scope tags, and approval records make it clear who can do
  what and who approved each risky change.

## Limitations (be honest with buyers)
- Multi-admin approval covers specific resource types (such as apps and scripts); it is not a
  blanket approval gate over every Intune action. Confirm the current supported resource types in
  the portal.
- Scope tags govern visibility/management of taggable Intune objects; not every object type
  supports tagging — verify coverage for the workloads you care about.
- RBAC controls Intune; tenant-wide identity roles live in Entra ID and are governed separately.
- Over-tightening can lock admins (or yourself) out — always keep a break-glass administrator
  outside the restricted roles and outside the approval gate.

## The standard Phoenixtekk deployment model
> Design roles and scope tags, build admin/approver scope groups, create custom roles and
> assignments, apply scope tags to objects, enable access policies for high-risk resource types,
> then pilot one approval before broad enforce. Phoenixtekk pattern:
> Assess → Configure → Pilot → Validate → Expand.
