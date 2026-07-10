# 8. Deliverables Summary — Entra ID Governance: Access Reviews & Entitlement Management

## What you receive
A complete, self-guided package to deploy **Microsoft Entra ID Governance** — entitlement management
(catalogs, access packages, approval + lifecycle policies), recurring access reviews (groups, apps,
guests), and joiner/mover/leaver lifecycle workflows — so access is requested, approved, time-bound,
reviewed, and revoked automatically, with audit-ready evidence.

### Documentation
- **Executive Summary** — the problem (access sprawl), the solution (three governance pillars), the
  outcome, the boundary, and the licensing gate.
- **Solution Overview** — how entitlement management, access reviews, and lifecycle workflows fit
  together, the building blocks (catalog → package → policy; review definition; workflow → tasks), scope,
  and what's out of scope (PIM is a separate solution).
- **Requirements Guide** — governance-specific prerequisites (Entra ID Governance/P2 licensing, the
  Identity Governance role, resources to govern, pilot group + approvers/reviewers, manager and HR
  lifecycle attributes, guest/external settings, the Graph toolchain), each with Verify / Implement, on
  top of the category global requirements.
- **Implementation Guide** — ordered steps: assess → catalog + resources → access package → employee
  policy → guest policy → three access reviews → joiner + leaver workflows → validate → expand, with
  **every object named** using the `ENTIGA – <Purpose> – <Scope> – <Stage>` convention.
- **Testing & Validation** — the four gates (request/approve/expire, review/remove, guest time-bound,
  lifecycle) as a pass/fail matrix, automated checks, and the evidence to capture for recertification.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (package not requestable,
  approval stuck, auto-apply not removing, guest can't request, workflow not firing).
- **Best Practices** — catalog delegation, time-bound packages, safe auto-apply, leaver deprovisioning,
  guest governance, change safety, and where to go next.

### PowerShell tools (Microsoft Graph) — safe by default
| Script | Purpose | Default mode |
|--------|---------|--------------|
| **`ENTIGA-Discovery.ps1`** | Inventory catalogs, access packages + policies, access review definitions, and lifecycle workflows (baseline posture) | Read-only |
| **`ENTIGA-Validate.ps1`** | Check each named §3 object exists and is wired (package has approval + expiry; reviews auto-apply; workflows enabled/scoped); flag gaps | Read-only |
| **`ENTIGA-Report.ps1`** | Export audit/recertification evidence — access package assignments (who/when/expiry) + recent access review decisions | Read-only |
| **`ENTIGA-GuestReview.ps1`** | Report guest accounts with last sign-in and access; preview stale-guest cleanup | Read / `-WhatIf` |
| **`ENTIGA-Lifecycle.ps1`** | Report workflow run history + which users have `employeeHireDate` / `employeeLeaveDateTime`; preview an on-demand run | Read / `-WhatIf` |

All scripts use `Connect-MgGraph` with **least scopes**, contain **no credentials or secrets**, and any
change/remediation defaults to a **`-WhatIf` preview** gated behind an explicit `-Commit`.

## Outcomes
- Access is **requested and approved**, not assigned by hand — and it **expires**.
- Group, app, and **guest** access is **recertified on a schedule**, with removals that actually apply.
- Joiner/mover/leaver tasks are **automated** — new hires equipped, leavers fully deprovisioned.
- Every grant has a **request, approver, and review decision** on record — audit-ready.
- A **pilot-first**, gated, reversible rollout with a documented rollback for every change.

## Assumptions & boundaries
- **Entra ID Governance / P2 licensing** covers the in-scope users — *verify current SKU coverage*.
- The **resources** to govern (groups/apps/sites) already exist.
- HR **lifecycle attributes** feed scheduled workflows; without them, workflows run **on-demand**.
- **PIM** (privileged role activation) is a **separate adjacent solution**; this governs resource/app
  access.
- **Which** resources, cadences, approvers, and reviewers to use are the customer's governance decisions.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five PowerShell tools in a single ZIP, yours to keep and reuse on every rollout.
