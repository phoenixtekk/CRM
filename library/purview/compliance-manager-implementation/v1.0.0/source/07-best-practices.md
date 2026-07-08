# 7. Best Practices — Microsoft Purview Compliance Manager Implementation

- **Baseline first, then expand.** Capture the current **Compliance Score** and validate the included
  **Data Protection Baseline** assessment end-to-end before creating a stack of framework-specific
  assessments. One assessment owned and evidenced properly beats ten assessments with unassigned
  actions and no proof.
- **Assign an owner and a date to every improvement action.** A score with unowned, undated actions is
  not a plan. Ownership and target dates in `CM Action Plan – Pilot` are what turn recommendations into
  trackable, auditable work.
- **Evidence is the deliverable.** Attach documentation, test results, an owner, and a test date to
  each action. The number is only defensible with the proof behind it — `CM Evidence – Register` is the
  auditor-ready record.
- **Lean on control mapping.** Implement a shared control once and let it score across every assessment
  that references it (baseline + NIST + ISO + HIPAA…). Prioritize **high-point, widely-mapped** actions
  for the most score per unit of effort, and only do the *gap* when adding a new framework.
- **Enable automatic testing — but know its limits.** Turn on automatic testing so eligible technical
  actions self-update from Microsoft 365 signals; but confirm with `CMPMGR-Validation.ps1` that the
  **underlying control actually exists**, and plan **manual evidence** for actions that can't auto-test.
  Automatic testing is not full coverage.
- **Never mark an action implemented without proof.** A false "implemented" inflates the score and
  fails the first audit. If the technical control isn't in place, the action stays Not implemented —
  `CMPMGR-Validation.ps1` is your cross-check against wishful status.
- **Compliance Manager measures; it does not enforce.** Acting on an improvement action — enabling
  audit, DLP, retention, labels, Conditional Access — is a **separate, high-impact change** owned by
  that feature's solution and **piloted in simulation/test first**. Don't switch controls on tenant-wide
  from the score dashboard.
- **Least privilege and separation.** Keep **Administrators** separate from **Contributors**, and keep
  **Readers/auditors** read-only. Manage membership with `CMPMGR-Set-Scope.ps1` (`-WhatIf` then
  `-Commit`) and re-snapshot with `CMPMGR-Discovery.ps1` — membership drifts as people join and leave.
- **Always dry-run automation.** `CMPMGR-Configuration.ps1` and `CMPMGR-Set-Scope.ps1` default to
  **`-WhatIf`**. Read every line of the planned change; run `-Commit` only after the output is right.
  The discovery, validation, and report scripts are read-only.
- **Applicability and adequacy belong to compliance/legal.** *Which* regulations apply, *which*
  controls are in/out of scope, and *whether* the evidence satisfies the obligation are **compliance,
  records, privacy, and legal** determinations. The tool provides method, score, and evidence — not the
  verdict.
- **Watch for template and regulation updates.** Microsoft updates assessment templates as regulations
  change; a template update can add controls and move your score. Review updates on a cadence and
  re-baseline affected assessments.
- **Group assessments deliberately.** Group by regulation, business unit, or environment so control
  mapping and reporting stay coherent and the score is meaningful per audience.
- **Verify licensing and template availability against your tenant.** The baseline is included; premium
  and custom templates are entitlement-gated and the count is seat-dependent; GCC/GCC High may differ.
  Confirm — never assume a template is available.
- **The portal is authoritative.** Assessments, evidence upload, and the official score/export live in
  the Purview portal; the scripts assess readiness, roles, and technical evidence and structure the
  plan — they support the portal, they don't replace it.
