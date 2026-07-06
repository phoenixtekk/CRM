# Solution Overview

## What this is

Synthetic and test data does not escape governance just because it is artificial. In a regulated
healthcare enterprise, an ungoverned pile of "test" datasets — copied, forked, shared into AI
sandboxes, and forgotten — becomes a **shadow data risk**: nobody knows where a given dataset came
from, what it was derived from, who classified it, who approved it for use, or whether it aligns to
the organization's HIPAA/HITRUST and enterprise data-governance obligations.

This solution establishes **synthetic data governance**: the policy, catalog and lineage register,
classification scheme, approval workflow, access model, and control set that make synthetic and
test data **managed, auditable, and aligned** to the regulated-data constraints the organization
already lives under — so the synthetic-data capability can scale without becoming an unmanaged
liability.

It delivers a **governance method plus evidence**, not compliance determinations. The catalog,
classification records, approval decisions, and control-mapping this solution produces are the
technical artifacts and evidence your privacy, compliance, and legal functions consume. Whether a
given synthetic asset meets a HIPAA de-identification standard, whether a residual disclosure risk
is acceptable, and whether a HITRUST control is satisfied are **determinations reserved to those
functions** — this solution never makes them for you.

## The governance model

Six connected components, each of which the implementation stands up in order:

1. **Policy & roles** — a written Synthetic Data Governance Policy that states scope (what counts as
   a governed synthetic/test asset), the roles (data owner, steward, privacy/compliance reviewer,
   consumer), the classification scheme, and the rules for approval, access, retention, and
   disposal. Roles map to your existing RACI where one exists.
2. **Catalog & lineage** — a register of every governed synthetic/test asset, recording where it
   came from (generator, source model, reference statistics used), what it was derived from
   (parent asset), and where it flows (which AI/QA environments consume it). Lineage is the spine:
   an asset with no recorded origin is a finding.
3. **Classification** — every asset carries a classification (e.g. `synthetic-only`,
   `derived-from-real-stats`, `contains-minimized-real`) that drives its handling, access, and the
   controls that apply. Classification is a stewarded, recorded decision — not an attribute the
   generator sets.
4. **Approval workflow** — no governed asset is released to a shared AI/QA environment until it has
   an **approval record**: a stated requester, purpose, classification, the reviewer(s), the
   decision, and the date. Approval is enforced, evidenced, and revocable.
5. **Access model** — least-privilege access to assets by classification and environment, so the
   right consumers reach the right assets and no one silently copies a higher-classification asset
   into a lower-controlled sandbox.
6. **Controls & alignment** — the governance controls (the ones this solution operates) are mapped
   to the organization's declared control set (e.g. selected HIPAA Security Rule safeguards and
   HITRUST CSF control references the compliance team provides), producing an evidence view of
   which governance controls are in place, partial, or absent — for the compliance function to
   interpret.

## How it works (the deployment model)

Like every solution in this category, the work follows a pilot-first
**Assess → Design → Generate/Build → Validate → Expand** model with explicit pass/fail gates and a
documented rollback:

- **Assess** — profile the current state: what synthetic/test assets already exist, which have any
  lineage, what policy and roles exist, and which declared controls are already met. Produce a
  **Synthetic Data Governance – Enterprise – Readiness** baseline.
- **Design** — author the **Synthetic Data Governance Policy – Enterprise – v1**, the classification
  scheme, the role assignments, and the control mapping against the declared control set.
- **Generate/Build** — stand up the **Synthetic Asset Catalog – Enterprise – v1** (a JSON-backed
  register), register the pilot's assets with lineage, classify them, and wire the approval + access
  records.
- **Validate** — run the governance gates on a named pilot service line: is every pilot asset
  cataloged with lineage, classified, and approved before use; is access aligned; are the declared
  controls evidenced? Each gate has an explicit pass/fail.
- **Expand** — only after the pilot passes, extend the catalog, classification, and approval
  workflow to additional service lines and asset types, carrying the same gates forward.

A **rollback** is always defined: if a gate fails, un-approved or misclassified assets are pulled
from shared environments and the release is held until the finding is resolved.

## The target model

This solution governs synthetic/test **assets** regardless of the clinical model they represent
(FHIR bundles, OMOP CDM extracts, or a source system's native schema). The catalog records each
asset's target model as metadata so governance spans a heterogeneous estate. The governance
artifacts themselves are JSON-backed and human-readable, so they integrate with an existing
enterprise data catalog where one exists, or stand alone where one does not.

## Benefits

- **Lineage you can audit** — every governed asset has a recorded origin and derivation; "where did
  this dataset come from?" has an answer.
- **Enforced approval** — assets reach shared AI/QA environments only with an evidenced approval,
  killing the shadow-copy pattern.
- **Alignment evidence** — a clear, current view of which governance controls map to the declared
  HIPAA/HITRUST + enterprise control set are in place, partial, or absent — for compliance to
  interpret.
- **Scales safely** — a repeatable, pilot-proven method so adding service lines and asset types
  does not multiply risk.
- **Self-guided** — exact steps and Python tooling a competent data/platform engineer can run,
  at a fraction of the cost of a bespoke consulting engagement.

## Limitations (read these)

- **Not a compliance determination.** This solution produces governance method and evidence.
  HIPAA/HITRUST de-identification determinations, disclosure-risk acceptance, and IRB/privacy-office
  sign-off are **deferred to your privacy, compliance, and legal functions**.
- **Declared control set is an input.** The control mapping is only as good as the control set your
  compliance team declares; this solution does not decide which controls apply.
- **No real PHI in shared environments.** Governance records describe assets; the assets themselves
  follow the category rule — never real PHI into a shared harness, twin, or AI test environment.
- **Tooling is pattern-level.** Where the solution references an enterprise catalog, generator, or
  AI framework, it does so at the capability level; verify version-specific behavior against your
  vendor's documentation.
