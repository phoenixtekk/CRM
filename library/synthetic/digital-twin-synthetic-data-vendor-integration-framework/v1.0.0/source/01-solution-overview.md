# Solution Overview

## What this is

Digital-twin and synthetic-data capabilities frequently arrive from **external partners** —
a synthetic-EHR generator, a hospital-twin simulation platform, a scenario/adversarial
data service, or an AI/model framework that consumes synthetic data. Each partner solves a
real problem, but integrating them *well* — consistently across programs, and without
locking the organization into a single vendor — is the hard part.

This solution is the **partner/vendor integration framework** for those capabilities. It
defines four things and gives you five Python tools to operationalize them:

1. **How to evaluate** a digital-twin / synthetic-data vendor against a repeatable scorecard
   (fidelity, privacy posture, interoperability, portability, support, cost).
2. **The integration patterns** for plugging a vendor into your test harness and AI test
   environments — data-in, data-out, and interface/contract patterns — at the architectural
   level, so the *shape* of the integration is standard even when the vendor changes.
3. **The data and interface contracts** — an explicit schema/interface definition the vendor
   output must satisfy and your harness expects — so integrations are testable, not
   hand-wired.
4. **The anti-lock-in / portability criteria** — the concrete signals (open target models,
   exportable artifacts, adapter isolation, exit cost) that keep a partner capability
   replaceable.

It is **not** a build of any specific vendor's product, and it does **not** invent vendor
console internals. Vendors — Synthea-style generators, commercial synthetic-data platforms,
hospital-twin engines, AI/model frameworks — are referenced by **capability and pattern**;
anything version-specific is flagged "verify against your version / the vendor's
documentation."

## How it works

The framework standardizes the boundary between *your* environment and *any* partner
capability, so the vendor becomes a **swappable component behind a stable contract** instead
of a hard dependency woven through your harness.

- **Target model as the lingua franca.** Every integration is expressed against a target
  clinical data model / standard — **FHIR**, **OMOP CDM**, or the source system's own schema
  (see the global requirements). Vendors that emit or accept the target model integrate
  cheaply and stay portable; vendors that only speak a proprietary shape are adapted at a
  single, isolated boundary and scored down on portability.
- **One adapter boundary per direction.** Vendor-specific code is isolated to a thin
  **data-in adapter** (your reference stats / seeds → the vendor) and a **data-out adapter**
  (the vendor's output → your target model + harness). Your harness and AI test environments
  only ever see the target-model contract, never the vendor's native shape.
- **Contracts are executable.** The interface contract (schema + required fields + interface
  conventions) and the adapter conformance rules are checked by the included Python tools, so
  a vendor either conforms or the integration fails a gate — no silent drift.
- **Portability is measured, not assumed.** A lock-in risk assessor turns the anti-lock-in
  criteria into a score and a documented **exit path** for each vendor.

## Target model

Integrations are authored against a defined **target clinical data model / interoperability
standard** — **FHIR R4**, **OMOP CDM**, or the source system's native schema — chosen per the
global requirements (Requirement 2). The framework is model-agnostic: you declare the target
model once in the integration config, and the contracts, adapters, and validation are
expressed relative to it. Where a vendor's native output differs, the data-out adapter maps
it to the target model and the conformance checker proves the mapping is complete.

## The deployment model — Assess → Design → Generate/Build → Validate → Expand

This solution follows the house model for every Synthetic solution, applied to *partner
integration*:

- **Assess** — inventory candidate vendors and the integration need; score each candidate with
  the vendor-evaluation scorecard against your weighted criteria. Produce
  `Vendor Evaluation – Candidate Set – Assess`.
- **Design** — define the target-model **interface contract** and the two adapter boundaries
  (data-in, data-out) for the selected vendor; specify the portability/exit requirements.
  Produce `Integration Contract – <Vendor Capability> – Design`.
- **Generate/Build** — implement the thin adapters and run the vendor to emit synthetic
  output (or execute a twin/scenario) into the **isolated non-production** environment.
  Produce `Vendor Output – Pilot – v1`.
- **Validate** — run the pass/fail gates: contract conformance, adapter conformance,
  fidelity/coverage, privacy/validation, and the portability/lock-in score. Produce
  `Integration Validation – Pilot – v1`. Any failed gate blocks expansion and triggers the
  documented rollback.
- **Expand** — once the pilot passes all gates, extend the same contract + adapter pattern to
  additional domains, programs, or a second vendor — reusing the exact artifact names.

## Benefits

- Partner twin / synthetic-data capabilities are leveraged **consistently across programs**,
  not re-integrated one-off each time.
- Every integration is **contract-defined and testable**, so vendor drift is caught at a gate.
- Vendors stay **portable** — a documented exit path and adapter isolation mean a second or
  replacement vendor touches only the adapter, not the harness.
- **Safe by construction** — no real PHI in the shared harness/twin/AI test environment; the
  isolated environment and privacy gates bound residual disclosure risk.

## Limitations

- The framework gives the **technical method and evidence**; it does **not** make
  regulatory/legal determinations. HIPAA/HITRUST de-identification determinations, IRB /
  privacy-office sign-off, and disclosure-risk acceptance are **deferred to the
  organization's privacy, compliance, and legal functions**.
- Vendor capabilities are integrated at the **pattern level**. Version-specific console steps,
  API surfaces, and licensing terms must be **verified against your version and the vendor's
  documentation** — this solution never invents them.
- Fidelity claims are only as good as the **reference** available (global Requirement 6);
  where real data cannot be used, agreed reference distributions bound what can be asserted.
- The tools are **standard-library-first** engineering aids, not a certified validation suite;
  they produce evidence for human decision-makers, not approvals.
