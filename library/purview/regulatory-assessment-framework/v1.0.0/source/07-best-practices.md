# 7. Best Practices — Regulatory Assessment Framework (Microsoft Purview)

- **Map once, assess many — that is the whole point.** Define a **canonical shared-control set**, map it
  to every regulation it satisfies, and let Compliance Manager's control mapping score one implementation
  across all of them. Prioritize **high-point, widely-mapped** shared controls for the most coverage per
  unit of effort, and only do each regulation's **gap** when you add it.
- **Keep the canonical control set tight and real.** A control you cannot evidence does not belong in the
  set. `RAF Control Set – Canonical` should reflect controls the organization actually operates — not an
  aspirational list — so the crosswalk and coverage matrix stay honest.
- **The crosswalk is the asset — maintain it.** `RAF Crosswalk – Register` is what turns silos into a
  framework. Review it whenever a regulation is added or a template is updated; a stale crosswalk quietly
  breaks the map-once/assess-many leverage.
- **Pilot one regulation before building the full set.** Validate one regulation end-to-end — shared
  controls owned, evidenced, and auto-tested — before creating a stack of assessments. One regulation
  proven properly beats ten with unassigned actions and no proof.
- **Assign an owner and a date to every shared control.** A coverage matrix with unowned, undated
  controls is not a plan. Ownership and target dates in `RAF Action Plan – Shared` are what make the
  framework trackable and auditable.
- **Evidence once, reuse across regulations.** Attach documentation, test results, an owner, and a test
  date to each shared control. Because it is shared, that one evidence record satisfies every mapped
  regulation — `RAF Evidence – Register` is the auditor-ready record; don't re-evidence the same control
  per framework.
- **Enable automatic testing — but know its limits.** Turn on automatic testing so eligible shared
  controls self-update from Microsoft 365 signals; but confirm with `CMPFRAME-Validation.ps1` that the
  **underlying control actually exists**, and plan **manual evidence** for controls that can't auto-test.
  Automatic testing is not full coverage.
- **Never mark a shared control implemented without proof.** A false "implemented" inflates the score in
  **every** regulation it maps to and fails the first audit. If the technical control isn't in place, it
  stays Not implemented — `CMPFRAME-Validation.ps1` is your cross-check against wishful status.
- **Compliance Manager measures; it does not enforce.** Implementing a shared control — enabling audit,
  DLP, retention, labels, Conditional Access — is a **separate, high-impact change** owned by that
  feature's solution and **piloted in simulation/test first**. Don't switch controls on tenant-wide from
  the score dashboard.
- **Least privilege and separation.** Keep **Administrators** separate from **Contributors**, and keep
  **Readers/auditors** read-only. Manage membership with `CMPFRAME-Set-Scope.ps1` (`-WhatIf` then
  `-Commit`) and re-snapshot with `CMPFRAME-Discovery.ps1` — membership drifts as people join and leave.
- **Always dry-run automation.** `CMPFRAME-Configuration.ps1` and `CMPFRAME-Set-Scope.ps1` default to
  **`-WhatIf`**. Read every line of the planned change; run `-Commit` only after the output is right. The
  discovery, validation, and report scripts are read-only.
- **Applicability and adequacy belong to compliance/legal.** *Which* regulations apply, *which* controls
  are in/out of scope, and *whether* the evidence satisfies each obligation are **compliance, records,
  privacy, and legal** determinations. The framework provides method, crosswalk, score, and evidence —
  not the verdict.
- **Watch for template and regulation updates.** Microsoft updates assessment templates as regulations
  change; a template update can add controls, move your score, and change the crosswalk mapping. Review
  updates on a cadence and re-baseline affected assessments.
- **Group deliberately.** Keep the framework's regulations in one **assessment group** (`RAF Group –
  <Program>`) so control mapping and the coverage matrix stay coherent; add per-business-unit or
  per-environment groups only when they genuinely differ.
- **Verify licensing and template availability against your tenant.** The baseline is included; premium
  and custom templates are entitlement-gated and the count is seat-dependent; GCC/GCC High may differ.
  Confirm your regulation set fits your premium-assessment entitlement — never assume a template is
  available.
- **The portal is authoritative.** Assessments, groups, evidence upload, and the official score/export
  live in the Purview portal; the scripts assess readiness, roles, licensing, and technical evidence and
  structure the crosswalk/coverage — they support the portal, they don't replace it.
