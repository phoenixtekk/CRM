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
