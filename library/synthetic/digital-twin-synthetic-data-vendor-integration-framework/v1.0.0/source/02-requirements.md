# Requirements

These are the **solution-specific** prerequisites for the partner/vendor integration
framework. They build on — and do **not** repeat — the six category-wide requirements in
**`global-requirements-synthetic.md`** (a Python data environment; a target clinical data
model/standard; an isolated non-production test environment; privacy/governance stakeholders
and policy; AI/QA use cases and a pilot scope; read-only minimized reference access for
fidelity). Confirm those six first, then verify the following.

> **Boundary reminder.** Vendor capabilities are integrated at the **pattern level**; version-
> specific console/API details are **verified against the vendor's documentation**, never
> invented. Regulatory/legal determinations are **deferred** to privacy/compliance/legal.
> **Never** place real PHI into the shared harness, twin, or AI test environment.

## 1. A candidate vendor set with obtainable evaluation artifacts

- **Description:** A named set of **candidate** digital-twin / synthetic-data vendors (or
  capabilities) in scope for evaluation, and — for each — access to the artifacts needed to
  score them: sample output, a schema/interface description, data-handling documentation, and
  export/portability terms.
- **Why required:** The evaluation scorecard and the portability assessor need real inputs per
  candidate; scoring on marketing claims alone is not defensible.
- **How to verify:** For each candidate you can produce (a) a small sample of its output, (b)
  its documented output schema/interface, and (c) a statement of its export formats and exit
  terms.
- **How to implement if missing:** Request evaluation samples and documentation from each
  vendor (NDA/eval agreements as needed), or use the vendor's published reference material.
  Record what is unavailable — missing evidence is itself a scorecard signal.

## 2. A declared target-model interface contract

- **Description:** The **interface contract** the integration is authored against: the target
  clinical data model (FHIR / OMOP / native — from global Requirement 2), the required
  entities/fields in scope, and the interface conventions (file formats, identifiers,
  encoding, reference/foreign-key rules).
- **Why required:** The contract is the stable boundary between your harness and any vendor;
  the conformance tooling checks vendor output against it. Without a declared contract there
  is nothing to validate portability or conformance against.
- **How to verify:** A machine-readable contract file exists (a small JSON, validated by
  `integration_contract_validator.py`) listing target model, entities, required fields, and
  interface rules.
- **How to implement if missing:** Author the contract from the target model and in-scope
  domains before designing the adapters (Implementation step 2).

## 3. Two isolated adapter boundaries (data-in, data-out)

- **Description:** A place in your architecture to host **exactly two** thin vendor-specific
  adapters — a **data-in** adapter (your seeds/reference stats → vendor inputs) and a
  **data-out** adapter (vendor output → target-model contract). Vendor-specific code lives
  **only** here; the harness and AI test environments consume only the target-model contract.
- **Why required:** Adapter isolation is what keeps a vendor swappable; scattering vendor SDK
  calls through the harness is the primary lock-in failure mode.
- **How to verify:** The harness has a single import path to each adapter and no other module
  references the vendor's native shape or SDK directly.
- **How to implement if missing:** Refactor to route all vendor interaction through the two
  adapter modules before the pilot integration.

## 4. Evaluation criteria with agreed weights and thresholds

- **Description:** The **weighted criteria** the organization will score vendors on (fidelity,
  privacy posture, interoperability, portability, support, cost, and any program-specific
  criteria) with agreed weights and the minimum acceptable thresholds/gates.
- **Why required:** A scorecard is only defensible if the weights and pass thresholds are
  agreed **before** scoring; otherwise selection looks post-hoc.
- **How to verify:** A criteria/weights file exists and is signed off by the technical and
  governance stakeholders (global Requirement 4).
- **How to implement if missing:** Facilitate a short weighting workshop; capture weights and
  thresholds in the config the scorecard tool reads.

## 5. A privacy/validation reference and disclosure-risk threshold for vendor output

- **Description:** The **reference** (read-only, minimized real stats or agreed reference
  distributions — global Requirement 6) and the **disclosure-risk threshold** the organization
  will hold *vendor-produced* synthetic output to, plus the quasi-identifier set to check.
- **Why required:** The privacy/validation gate must judge partner output by the same
  standard as internally generated data; the threshold and quasi-identifiers are governance
  decisions, not tool defaults.
- **How to verify:** The quasi-identifier list, reference source, and the numeric threshold
  are documented and approved.
- **How to implement if missing:** Agree them with privacy/governance before running the
  privacy gate; the tool reports evidence but the **acceptance** is deferred to those
  stakeholders.

## 6. A documented exit/rollback expectation per vendor

- **Description:** For each vendor to be integrated, an agreed expectation of the **exit path**
  (export formats, artifact ownership, contractual portability) and the **rollback** if a gate
  fails (revert to prior vendor/state, quarantine outputs).
- **Why required:** Anti-lock-in is only real if the exit is defined up front; the portability
  assessor scores against it and the deployment model requires a rollback at each gate.
- **How to verify:** An exit/rollback note exists per candidate and is referenced by the
  portability score.
- **How to implement if missing:** Capture the exit terms during evaluation (Requirement 1)
  and the rollback during Design (Implementation step 2).
