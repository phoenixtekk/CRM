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
