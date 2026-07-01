# 7. Best Practices — Intune Administrative Governance (RBAC & Multi-Admin Approval)

- Least privilege by default. Start every admin from a narrow custom role (for example
  `App Manager – Region A – Prod`), not the full Intune Administrator role; grant only the
  permissions the persona actually uses.
- Always keep a break-glass admin. Maintain a cloud-only Global Administrator excluded from the
  custom roles and from the approver group, so a too-tight policy can never lock everyone out.
- Design the scope-tag taxonomy first. A consistent tag scheme (region/business unit/platform) is
  the who-touches-what boundary; apply tags to objects as you create them, not as an afterthought.
- Separate request from approval. Configure access policies so the admin who makes a high-risk change
  is never the one who approves it — that is the whole point of multi-admin approval.
- Gate the changes that actually hurt. Start with the highest-blast-radius resource types (apps,
  scripts) via `App Deploy Approval – All – Prod` and `Script Deploy Approval – All – Prod`; add more
  only as the process matures.
- Pilot one approval before broad enforce. Prove an approval and a rejection on a test change before
  enforcing the gate across the fleet (the pilot gate).
- Set an approval SLA. An approval gate with no response-time commitment becomes a bottleneck; agree
  who approves and how fast.
- Name everything consistently. Use `<Purpose> – <Scope> – <Stage>` for every role, tag, group,
  assignment, and policy so the model is self-documenting and auditable.
- Review for over-privilege regularly. Run `RBACGOV-Report.ps1` on a schedule to catch assignments
  that drifted broader than the design.
- Remediate safely. `RBACGOV-Remediation.ps1` defaults to `-WhatIf`; preview every tightening before
  applying, and apply during a change window.
- Document the governance model. Record roles, tags, assignments, gated resource types, and the
  approver roster for audits and repeatability.
