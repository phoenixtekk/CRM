# 7. Best Practices — Azure Security Baseline & Governance

- **Audit before you deny, always.** Assign every guardrail in audit first, understand the picture, exempt the legitimate exceptions, then flip the same assignment to deny on an approved gate. This one practice prevents the outage that comes from denying a config real workloads depend on.
- **Assign high in the hierarchy.** Put initiatives and role assignments at the management-group node, not per-subscription — one assignment then covers many subscriptions and new subscriptions inherit the baseline automatically.
- **Name everything and reuse the name.** Use `<Purpose> – <Scope> – <Stage>` for every assignment, custom role, and scope group, and reuse it verbatim across scripts, tests, and rollback so the estate stays auditable.
- **Least privilege by default.** Replace standing Owner with purpose-built custom roles at the narrowest scope; prefer PIM eligible activation over standing access. Owner is for break-glass, not day-to-day.
- **Deny stops new, not existing.** Remember a deny policy only blocks *new* non-compliant resources — remediate pre-existing ones separately with remediation tasks or the remediation script; don't assume deny cleaned up the estate.
- **Exempt, don't weaken.** For a genuine exception, create a scoped, justified, time-boxed exemption — never loosen the policy for everyone to satisfy one resource.
- **Track the secure score every cycle.** Record Defender for Cloud secure score at each stage and chase the top recommendations; a rising score is the evidence the baseline is working.
- **Keep a rollback for every deny/RBAC change.** Setting an effect back to audit or restoring a role assignment is the safety net; write it down before you make the change.
- **Right-size Defender plans.** Foundational CSPM (free) gives secure score and recommendations; turn on enhanced/paid plans only where the workload risk justifies the per-resource cost.
- **Pilot, then expand.** Prove the baseline on a small scope before rolling it estate-wide — the same assign-once, repeat-everywhere pattern that makes governance repeatable.
