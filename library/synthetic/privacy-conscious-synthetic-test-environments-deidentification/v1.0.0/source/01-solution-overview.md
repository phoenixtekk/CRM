# Solution Overview

## What this solution is

Test environments built from clinical data must be **privacy-safe** — and the organization must be
able to *demonstrate* that they are. This solution establishes **privacy-conscious test
environments** for AI and QA teams by combining three things: a **de-identification (and/or
synthesis) pipeline**, a **re-identification-risk assessment** against a documented threshold, and
the **privacy evidence** that governance needs to review and approve the release of the data.

The result is test data that is **safe by design and defensible on review** — either de-identified
from a governed source or fully synthetic, with disclosure risk assessed under an agreed threshold
and the supporting evidence captured — so AI teams can evaluate models and QA can exercise systems
**without carrying real-PHI exposure into a shared test environment**.

> **Boundary — read this first.** This solution provides the **technical method and the evidence**.
> It does **not** make the **regulatory or legal determination**. Whether a dataset qualifies as
> de-identified under a given regime (e.g. HIPAA Safe Harbor or Expert Determination), whether the
> residual disclosure risk is *acceptable*, and whether an IRB/privacy-office sign-off is required —
> those are decisions for the organization's **privacy, compliance, and legal** functions. The tools
> here compute k-anonymity, l-diversity, disclosure-risk and inference signals and package them into
> an evidence record; a qualified determiner reads that evidence and makes the call. Nothing in this
> solution should be read as a de-identification certification or legal advice.

## How it works

The solution treats "privacy-safe test data" as two complementary routes, chosen per dataset with
the privacy stakeholders:

1. **De-identification route** — start from a **governed, read-only, minimized** source extract and
   transform it (suppress direct identifiers, generalize quasi-identifiers, and reduce disclosure
   risk) until the re-identification-risk assessment passes the agreed threshold. Real source data is
   handled only under the organization's privacy controls and is **never** written into the shared
   test environment in identifiable form.
2. **Synthesis route** — generate **fully artificial** records against a target clinical data model
   (e.g. FHIR / OMOP CDM / the source schema) so no real individual's record is present at all. The
   same risk assessment is still run to check for memorization/leakage (e.g. membership or attribute
   inference) before release.

Both routes converge on the same **evidence record**: the classification of every field, the
transformations applied, the risk metrics computed, the threshold they were measured against, and
the pass/fail result — the artifact governance signs against.

### Target model

Where the solution touches a schema, it works against whatever **clinical data model / standard** the
AI/QA teams have selected as in scope — **FHIR**, **OMOP CDM**, or the source system's native schema.
The scripts are model-agnostic (they operate on tabular exports / column classifications), so the same
pipeline serves whichever target the organization documents in requirements.

## The deployment model — Assess → Design → Generate/Build → Validate → Expand

Every solution in this category follows the same pilot-first model with explicit pass/fail gates and
a documented rollback:

- **Assess** — profile a governed sample; classify each field (direct identifier / quasi-identifier /
  sensitive attribute / non-identifying); agree the **disclosure-risk threshold** and route
  (de-identify vs. synthesize) with the privacy stakeholders.
- **Design** — define the **De-Identification Pipeline – Pilot – v1**: the per-field transformation
  policy (suppression, generalization, date shifting, pseudonymization) and the risk metrics + target
  threshold that will gate release.
- **Generate / Build** — run the pipeline (or the synthesizer) against the pilot scope to produce the
  candidate test dataset in the isolated environment.
- **Validate** — run the **Re-ID Risk Assessment** and the **fidelity/coverage** checks; compare to
  the pass/fail gates; capture the **Privacy Evidence Record**. If a gate fails, **roll back** (do not
  release) and tighten the policy.
- **Expand** — only after the pilot passes and privacy/governance signs the evidence, widen scope to
  further domains or service lines, re-running the same gates each time.

## Benefits

- **Defensible on review** — governance receives a structured evidence record (classification →
  transformation → risk metric → threshold → result), not an assertion.
- **Safe by design** — the isolated environment never receives identifiable real PHI; disclosure risk
  is measured, not assumed.
- **Repeatable** — the pipeline and thresholds are captured as config, so the same discipline applies
  every time scope expands.
- **Separation of duties** — engineering produces method + evidence; the privacy/legal function owns
  the determination. The two are cleanly decoupled.

## Limitations (read honestly)

- **Not a legal determination.** Passing the threshold is a *technical* signal; the regulatory call
  belongs to privacy/compliance/legal.
- **Risk is never zero.** k-anonymity, l-diversity and disclosure-risk metrics reduce and *quantify*
  risk; they do not eliminate it. Residual-risk acceptance is a governance decision.
- **Metrics depend on correct classification.** If a quasi-identifier is misclassified as
  non-identifying, the risk assessment understates exposure — classification review is part of the
  method.
- **Fidelity vs. privacy is a trade-off.** Stronger generalization lowers re-ID risk but reduces
  analytic utility; the pilot exists to find an acceptable point on that curve.
- **Vendor specifics are deferred.** Where a commercial synthesizer or de-identification platform is
  used, verify version-specific behavior against the vendor's documentation; this solution integrates
  such tools at the pattern level.
