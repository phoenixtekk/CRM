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
