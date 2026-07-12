# 7. Best Practices — Entra External Identities (B2B) & Cross-Tenant Access

- Lock down the default, relax per partner. Set the default cross-tenant access policy conservatively (block direct connect, do not trust unknown-tenant MFA/device claims) and add organizational settings only for partners you vet. The default applies to every tenant you have not named — treat it as your safety net.
- Trust MFA/device claims only for vetted partners. Trusting a partner's multi-factor and compliant/hybrid-joined device claims removes re-registration friction without lowering the bar — but only for a partner whose posture you have confirmed. Never enable trust in the default policy.
- Enable B2B direct connect narrowly. Direct connect currently underpins Teams shared channels; enable it per-organization for the partners who need it, not in the default.
- Onboard guests through packaged access, not ad-hoc shares. Use an entitlement-management access package with an approver and an expiry (connected-organization scoped for external requestors) so every guest has an owner and an end date. Reserve one-off invitations for exceptions.
- Enforce a guest-scoped Conditional Access policy, report-only first. Require MFA on external sign-ins with a policy scoped to `Guest or external users`, deployed in report-only until impact is understood, then enforced. Always exclude the two break-glass accounts.
- Keep break-glass accounts out of the guest policy. Break-glass accounts are internal cloud-only administrators; exclude them from the guest-scoped policy and from broad policies so an external-user policy can never lock every admin out.
- Recertify guests on a schedule. Run a recurring access review scoped to guest users, with auto-apply, so stale external access decays without manual cleanup. Use `Take recommendations` for the first cycle, then tighten to `Remove access` once reviewers are reliable.
- Set expiry everywhere. Give access packages a defined expiry or a periodic review; a guest without an end date is guest sprawl waiting to happen.
- Clean up stale guests safely. Report guests who never signed in or are long inactive, preview removal with `-WhatIf`, disable before you delete, and never touch break-glass or internal accounts.
- Restrict who can invite and what guests can see. Delegate invitation to specific roles (or the `Guest Inviter` role) and restrict guest directory access to the minimum, so guest sprawl and directory enumeration are limited by default.
- Introduce cross-tenant sync only after the invitation model is proven. Auto-provisioning guests from a partner is powerful but couples the two tenants; pilot with invitations/packages first, then add sync deliberately (verify current availability).
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, catalogs, packages, CA policies, and reviews so audits and expansion are repeatable.
- Verify licensing and preview before you rely on it. Cross-tenant trust and Conditional Access need P1; access reviews and access packages need P2 / Governance; some self-service and cross-tenant-sync options may be preview or vary by cloud — verify in your tenant.
- Pilot before you expand. Prove the model on one partner and a small guest scope before enforcing tenant-wide and adding partners, and keep a rollback path (report-only, disable-before-delete).

## Where to go next (adjacent catalog areas)
- **Entra ID Governance (`ENTIGA`)** — the full entitlement-management, catalog, access-package, and access-review build-out this solution plugs into. Adopt it to govern *all* access, not just guests.
- **Zero Trust Conditional Access (`ENTZTCA`)** — the Conditional Access baseline (personas, named locations, report-only discipline) that the guest policy here sits on top of.
- **Privileged Identity Management (`ENTPIM`)** — just-in-time, approval-gated admin roles for the internal administrators who run external collaboration.
- **Passwordless / passkey (`ENTPASSKEY`)** and **enterprise-app / service-principal governance** — strengthen internal authentication and app trust around the collaboration you have opened up.
- **Hybrid identity (Entra Connect)** and the **SAML App Factory** — for the on-premises identity and application onboarding that partners' access often depends on.
