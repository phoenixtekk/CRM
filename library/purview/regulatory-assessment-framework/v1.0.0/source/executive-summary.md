# Executive Summary — Regulatory Assessment Framework (Microsoft Purview)

Most organizations assess each regulation in a **silo** — a separate audit for HIPAA, another for NIST
800-53, another for ISO 27001, another for a state privacy law — each re-testing the *same* underlying
controls as if they were unrelated. The cost is duplicated effort, inconsistent evidence, and a
compliance gap the moment the frameworks drift apart. Microsoft Purview **Compliance Manager** provides
the mechanism to end that: **control mapping**, where one implemented control scores across every
assessment that references it. This solution builds a **Regulatory Assessment Framework** around it —
define a canonical set of **shared controls** once, **cross-walk** each to the regulations it satisfies,
and **assess many** from one owned, evidenced implementation.

This is a complete, deploy-it-today package for standing up a multi-regulation compliance framework,
written for a competent Microsoft 365 / compliance administrator and built to be run **with** the
organization's compliance, records, privacy, and legal functions — who own **which** regulations apply
and **whether** the evidence satisfies them.

## What you get
- A plain-language **Solution Overview** of the framework — the building blocks (**assessments,
  improvement actions, control mapping, assessment groups, evidence**), the **canonical control set +
  crosswalk** model, the role-separation model, and the honest limits (it **measures, it doesn't
  enforce**; premium templates are licensing-gated; the portal is authoritative).
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: per-regulation
  template licensing, the canonical shared-control set, the control-to-regulation crosswalk, the
  separated role groups, named governance owners, the in-scope regulation set and group design,
  shared-control owners and evidence sources, automatic testing, and the pilot regulation.
- An **Implementation Guide** that baselines the score, defines the canonical control set, builds the
  **crosswalk**, assigns roles with least-privilege separation, creates a multi-regulation **assessment
  group** and a **pilot** regulation, implements and evidences the shared controls, enables **automatic
  testing**, validates, reports the **coverage matrix**, then expands to the full regulation set — with
  pass/fail gates and rollback at every step, and any high-impact technical remediation **piloted in
  simulation/test first**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): readiness + role-separation +
  licensing discovery, a crosswalk / shared-control-plan builder, a technical-evidence validator, a
  coverage-matrix report, and a role-membership helper — **read-only or `-WhatIf` by default, no
  secrets**.
- **Testing** and **Best Practices** that prove the crosswalk, shared-control coverage, evidence
  accuracy, and separation before anything expands.

## Why it matters
- **Map once, assess many.** A single well-implemented shared control satisfies requirements across every
  regulation that references it — the fastest, most defensible path to coverage across a whole framework
  set, with the incremental work reduced to each regulation's gap.
- **One evidence record, every framework.** Because controls are shared, owners, test dates, and proof
  are captured **once** and reused across all mapped regulations — consistent, not three different
  versions of the "same" control.
- **Coverage and gaps become visible.** The crosswalk and coverage matrix show, per regulation, exactly
  what shared controls satisfy and what still needs work — no more discovering a gap in an audit.
- **Measurement, not enforcement.** Compliance Manager changes nothing on the tenant; the technical
  changes shared controls depend on are separate, piloted changes — this solution keeps that boundary
  clear and safe.

## The bottom line
Many regulations turned into **one shared-control framework** in Microsoft Purview — mapped once, scored
many, owned, tested, and evidenced — **delivered, validated, and audit-ready.** A fraction of the cost of
a consulting engagement, self-guided and tested.

*Compliance Manager premium/custom templates are licensing-dependent (Microsoft 365 E5 / E5 Compliance /
Premium Assessment Add-On) and the Purview portal evolves; verify capability and template availability
against your own licensing and tenant. Regulatory applicability and whether the evidence satisfies an
obligation are deferred to your compliance, records, privacy, and legal functions.*
