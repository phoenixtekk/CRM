# Solution Overview

## What this is

This solution stands up a **synthetic data sub-function** inside a greenfield (or immature)
quality-engineering organization. The problem it solves is an **operating-model** problem, not
merely a tooling one: many teams can run a generator once, but few can turn synthetic data and
simulation into a **repeatable, measured service** that serves AI, QA, and product teams across
programs. This solution supplies the missing structure — the team design (pods/squads), the intake
and prioritization flow, a reference architecture, a maturity model, and a **KPI framework** that
tracks both delivery quality and engineering productivity — and packages five Python tools that
operationalize that model.

The sub-function's mission is simple to state: **produce trustworthy synthetic clinical data and
simulation on demand, safely, and prove it is trustworthy with evidence.** "Trustworthy" means it is
fit for the consuming AI/QA use case (fidelity and coverage) and it is safe to share (privacy), and
"prove it" means every dataset ships with a validation record, not a promise.

Everything here operates on **synthetic (artificial) data in isolated non-production environments**.
**No real Protected Health Information (PHI) is ever placed into a shared synthetic harness, twin, or
AI test environment.** Where real data must inform fidelity, it is used read-only, minimized, and only
under the organization's governing privacy controls (see `02-requirements.md` and the shared
`global-requirements-synthetic.md`).

## The target model

The sub-function is **model-agnostic but standard-anchored.** It generates and validates against a
**target clinical data model** chosen with the consuming teams — typically **FHIR R4**, the **OMOP
CDM**, or the source system's native schema — and it records that choice as a first-class artifact so
fidelity, coverage, and privacy are all measured against a fixed target. The operating model does not
assume one generator: **Synthea**, commercial synthetic-data platforms, and AI/model frameworks are
integrated at the pattern level (an "engine" behind a stable internal interface), so the sub-function
can adopt or swap engines without re-architecting intake, validation, or KPIs. Vendor console
internals are cited to the vendor's documentation or flagged "verify against your version" — never
invented.

## How it works — the operating model

The sub-function runs as a small number of **pods** behind a single **intake queue**:

- **Intake pod** — owns the request queue, triage, scoping, and prioritization. Every request enters
  as a scoped **Intake Request** and leaves as a committed, sized unit of work or a documented
  decline.
- **Generation pod(s)** — build and run the synthetic-data / twin engines against the target model,
  producing named datasets.
- **Validation & governance pod** — runs the fidelity, coverage, and privacy gates, produces the
  validation record, and holds the release decision (technical pass/fail; the privacy/legal
  *determination* is deferred to those functions).
- **Platform/enablement pod** (may be virtual at low maturity) — owns the reference architecture,
  shared libraries, environments, and the five tools.

Work flows through the house deployment model used by every solution in this category:

**Assess → Design → Generate/Build → Validate → Expand**, pilot-first, with explicit pass/fail
(fidelity/privacy) gates and a documented rollback.

- **Assess** — baseline the current capability with the maturity self-assessment; agree sponsorship,
  environment, governance stakeholders, target model, and pilot AI use cases.
- **Design** — define the pods, the intake flow, the reference architecture, the KPI framework, and
  the pilot's pass/fail gates. Produce the **Capability Charter**.
- **Generate/Build** — stand up the environment and engines; run the pilot request end-to-end,
  producing a named dataset (`Synthetic EHR – Pilot – v1`).
- **Validate** — run fidelity, coverage, and privacy gates; produce the validation record; make the
  release decision at the gate.
- **Expand** — onboard more request types, programs, and engines; advance a maturity level; grow the
  KPI baseline into a trend.

## Benefits

- **Repeatable service, not heroics** — a stable intake-to-release flow so any competent engineer can
  run a request the same way, with the same evidence.
- **Measured** — a KPI framework that makes delivery quality (defect escape, validation pass rate,
  rework) and engineering productivity (lead time, throughput, flow efficiency) visible and trended.
- **Safe by construction** — isolation, privacy gates, and safe-by-default tooling mean disclosure
  risk is bounded and evidenced, with the *determination* deferred to privacy/compliance/legal.
- **Scalable** — a maturity model and reference architecture give a clear path from an ad-hoc script
  to a multi-program platform, and engine-agnostic patterns avoid vendor lock-in.

## Limitations

- This is an **operating-model and enablement** solution. It gives you the structure, the gates, and
  five working Python tools; it does **not** ship a production data platform or a specific vendor
  license.
- **Fidelity claims require a reference** (governed real statistics or agreed published
  distributions). Without one, coverage and structural checks still run, but distributional-fidelity
  claims are unfounded — the tools will say so.
- **Regulatory and legal determinations are out of scope** — HIPAA/HITRUST de-identification
  determinations, IRB/privacy-office sign-off, and disclosure-risk acceptance belong to those
  functions. The sub-function supplies method and evidence, not the ruling.
- The KPI framework is only as good as the intake discipline behind it: garbage-in intake produces
  meaningless metrics. The tools assume requests are logged.

## Who operates it

A competent data/platform engineer can run every step and every tool here. Specialist input
(clinical SME for plausibility, privacy officer for disclosure-risk threshold) is called out where the
step needs it.
