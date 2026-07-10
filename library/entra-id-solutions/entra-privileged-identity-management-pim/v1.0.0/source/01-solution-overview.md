# 1. Solution Overview — Entra Privileged Identity Management (PIM)

## The problem PIM solves: standing privilege
A privileged role assignment is *standing* (or "active") when the account holds it all the time —
signed in or not, using it or not. Standing Global Administrators, Privileged Role Administrators,
Security Administrators, and the like are the highest-value targets in the tenant: one stolen or
phished credential yields permanent, unmonitored, tenant-wide control. The fix is not to remove the
people who need admin — it is to remove the *standing* nature of their access, so the power exists only
in the moment it is used, under conditions you control.

## Eligible vs. active assignments
PIM introduces a second kind of assignment.

- An **active** assignment is the classic one — the role is on the account now.
- An **eligible** assignment means the person is *allowed to* hold the role but does not hold it until
  they **activate** it. Activation is an explicit, logged action that grants the role for a bounded
  window (for example up to 8 hours), after which it automatically expires and the account returns to
  having no privilege.

The goal state is: privileged roles are assigned **eligible, not active**. Day to day the admin has no
elevated rights; when they need to do admin work they activate, do the work, and the role expires on
its own.

## The activation policy — the conditions on elevation
Each role in PIM has a **role setting** (activation policy) that governs how eligible users activate
it. The controls that matter:

- **Require MFA on activation** — a fresh multi-factor challenge at the moment of elevation.
- **Require justification** — the activator types a business reason, captured in the audit log.
- **Require approval** — a named approver must approve the activation before the role is granted
  (use this for the most powerful roles, e.g. Global Administrator).
- **Require ticket information** — tie the elevation to a change/incident ticket.
- **Maximum activation duration** — the time-box (e.g. 1–8 hours) after which the role auto-expires.
- **Notifications** — alert admins and the user on eligible assignment, activation, and approval.

## Entra roles vs. Azure resource roles
PIM governs two distinct scopes, and this solution covers both:

- **Microsoft Entra roles** — directory roles like Global Administrator, User Administrator, Exchange
  Administrator. Managed under PIM -> *Microsoft Entra roles*.
- **Azure resource roles** — RBAC roles like Owner, Contributor, User Access Administrator on
  management groups, subscriptions, and resource groups. Managed under PIM -> *Azure resources*. These
  matter because an Azure Owner can be as dangerous as a directory admin.

## Access reviews for privileged roles
Eligibility still drifts — people change teams, projects end, access lingers. A PIM **access review**
periodically asks reviewers (or the users themselves) to confirm each eligible privileged assignment is
still needed; anything not re-attested is removed. This keeps the eligible population honest over time.

## Break-glass (emergency access) accounts
Hardening the identity plane can lock you out — an approval loop with no available approver, an MFA
method that breaks, a policy misfire. **Break-glass accounts** are two cloud-only emergency
Global Administrator accounts that are deliberately **excluded from PIM and from broad Conditional
Access/MFA policies** and kept permanently active, with credentials stored offline and sign-ins
monitored/alerted. They are the safety net that makes it safe to remove everyone else's standing
access. Designing and protecting them is part of this solution, not an afterthought.

## What you can control
- Discovery: every standing (active) privileged role assignment in Entra and in Azure resources.
- Eligibility: convert standing assignments to eligible so no one holds privilege by default.
- Activation policy: MFA, justification, approval, ticketing, and max-duration per role.
- Access reviews: recurring re-attestation of privileged eligibility.
- Break-glass: two protected emergency accounts, excluded and monitored.
- Audit and alerting: every activation logged; alerts for risky patterns (too many admins, activations
  without MFA, stale assignments).

## Benefits
- Security — the number-one payoff: no permanent admins to steal; every elevation is approved,
  time-bound, and logged, collapsing the attacker's window from "forever" to "a few hours, if approved".
- Compliance — demonstrable least-privilege and access-review evidence for auditors.
- Visibility — a real inventory of who *could* be an admin and who *actually* elevated, when, and why.
- Repeatability — a governance pattern (reviews, alerts, reports) you run on a schedule, not once.

## Limitations (be honest with buyers)
- PIM requires **Microsoft Entra ID P2** (or an equivalent bundle such as Microsoft Entra ID
  Governance / certain E5 suites). *Verify current licensing and availability in your tenant.*
- Removing standing access badly can lock admins out — this is why break-glass accounts come first,
  every change is piloted, and the conversion script defaults to a preview (`-WhatIf`).
- PIM governs *who can activate a role and how*; it does not replace Conditional Access, identity
  protection, or a broader zero-trust program — it is the privileged-access pillar of it.

## The standard deployment model
> Discover standing privileged access -> configure activation policy and break-glass ->
> pilot on a cohort of roles/admins (eligible + policy) -> validate activation, approval, and audit ->
> expand to all privileged roles and Azure resource roles, with access reviews and alerts on a
> schedule. Repeatable pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
