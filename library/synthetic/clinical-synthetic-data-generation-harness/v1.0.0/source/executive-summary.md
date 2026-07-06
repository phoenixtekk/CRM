# Executive Summary

## The outcome

AI and QA teams get **realistic clinical test data on demand** — synthetic patients, encounters,
conditions, medications, labs, and vitals against a chosen target model (**FHIR**, **OMOP**, or a
native schema) — that is **clinically plausible, reproducible, and privacy-conscious**, so they can
build and evaluate safely **without ever touching real Protected Health Information (PHI)**.

## The problem

Realistic clinical data is essential to test AI models and QA pipelines, but real EHR data carries
privacy risk teams cannot responsibly take on into shared, non-production, AI test environments.
Mock data is unrealistic; real data is unsafe. The gap stalls AI and QA work.

## The approach

This solution stands up a **clinical synthetic data generation harness** and hands the team a
self-guided build: five Python tools and step-by-step documentation that follow a disciplined,
pilot-first model — **Assess → Design → Generate → Validate → Expand** — with explicit pass/fail gates
for **plausibility** and **privacy**, and a documented rollback. Generation is **seeded and
reproducible** (same config + seed ⇒ same dataset) and **safe by default** (writes only to an
isolated output directory; no real PHI in the shared harness).

## Why it is safe

- **No real PHI in the shared harness** — only aggregate reference statistics inform generation;
  synthetic records are artificial by construction.
- **Validated before use** — a dataset reaches a consumer only after it passes schema conformance,
  plausibility/coverage, reproducibility, and privacy checks (zero direct identifiers, zero exact
  reference-record matches).
- **Determinations stay with the experts** — the tools produce technical evidence; HIPAA/HITRUST
  de-identification, disclosure-risk acceptance, and IRB/privacy sign-off remain with the
  organization's privacy, compliance, and legal functions.

## The bottom line

Realistic clinical test data, produced in minutes, reproducible for audits and bug reports, and
privacy-conscious by design — delivered as a self-guided, tested build at a fraction of the cost of a
bespoke engagement.
