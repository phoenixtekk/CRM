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

## The standard deployment model
> Onboard privileged roles to PIM as eligible with approval and alerts -> stand up access reviews for
> roles and app access -> build entitlement-management access packages with policy and expiry ->
> validate activation and recertification on a pilot scope -> expand to the tenant.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
