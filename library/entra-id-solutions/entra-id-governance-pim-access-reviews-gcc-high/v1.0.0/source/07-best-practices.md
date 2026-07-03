# 7. Best Practices — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

- Administer on the sovereign plane. Do all portal work at `https://entra.microsoft.us` and run every script with `-Environment USGov` (use `USGovDoD` on the DoD cloud). A single Commercial endpoint in a runbook or profile will silently fail against a GCC High tenant.
- Make privileged roles eligible, not standing. Onboarding admin roles to PIM as eligible is the single most important practice — it removes always-on privilege and shrinks the attack surface.
- Keep break-glass accounts out of PIM. Two cloud-only emergency accounts (on the tenant `*.onmicrosoft.us` domain) must hold permanent active `Global Administrator` and be excluded from PIM activation, so a PIM misconfiguration can never lock everyone out. Protect them with strong stored credentials and sign-in alerts.
- Gate activation with approval and MFA. Require approval, multi-factor authentication, and justification on activation, and keep the activation window short so access is time-bound.
- Ensure approver coverage. Use an approver group with at least two members so legitimate activations and access-package requests are not delayed by a single unavailable approver.
- Recertify on a schedule. Run recurring access reviews for privileged roles, group membership, and app access, with auto-apply, so stale access decays without manual cleanup — this maps directly to the least-privilege and periodic-review objectives common to CMMC / NIST 800-171 in GCC High.
- Package access, do not assign it ad hoc. Use entitlement-management access packages with a request policy and expiry so grants are governed, self-service, and time-bound.
- Set sensible expiry. Give access packages a defined expiry or a periodic review so access does not accumulate silently.
- Watch PIM alerts. Enable and tune alerts (too many Global Administrators, standing assignments, stale eligibility) and act on them.
- Do not assume Commercial parity. Preview, ML-assisted, external-collaboration, and cross-cloud features can lag or differ in GCC High — verify each against current Microsoft US Gov documentation before you depend on it (see `gcc-high-parity-notes.md`). Prefer owner/manager reviewers over ML recommendations until confirmed.
- Keep external access in-cloud during the pilot. Because connected-organization and cross-cloud collaboration differ across clouds, start access packages with in-tenant resources and requestors; add cross-cloud external access only after verifying the behavior for GCC High.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, reviews, catalogs, and packages so audits and expansion are repeatable.
- Pilot before you expand. Validate activation, approval, and recertification on a small scope before onboarding `Global Administrator` and the rest of the tenant, and keep a rollback path.
