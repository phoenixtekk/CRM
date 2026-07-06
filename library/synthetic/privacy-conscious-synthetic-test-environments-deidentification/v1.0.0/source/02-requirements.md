# Requirements

This solution builds on the six **category-wide** prerequisites in
`global-requirements-synthetic.md` (a Python data environment, a target clinical data model, an
isolated non-production environment, privacy/governance stakeholders and policy, AI/QA use cases and
a pilot scope, and read-only/minimized reference access for fidelity). **Verify those six first** —
they are not repeated here.

Below are the prerequisites **specific to privacy-conscious de-identification and re-ID-risk work**.
Confirm each before running the implementation steps.

---

## S1. A documented field classification for the in-scope dataset

- **Description:** A per-field classification of the in-scope dataset into **direct identifiers**
  (name, MRN, SSN, contact details), **quasi-identifiers** (dates, ZIP/geography, age, sex, admission
  dates — the fields that combine to re-identify), **sensitive attributes** (diagnoses, procedures,
  results the disclosure of which is the harm), and **non-identifying** fields. This becomes the
  artifact **Field Classification – Pilot – v1**.
- **Why required:** Every downstream metric depends on it — quasi-identifiers drive k-anonymity,
  sensitive attributes drive l-diversity, direct identifiers drive suppression. A misclassified field
  silently invalidates the risk assessment.
- **How to verify:** Confirm every column in the pilot extract has exactly one classification and that
  the privacy stakeholder has reviewed the quasi-identifier list (the highest-leverage call).
- **How to implement if missing:** Run the profiling/classification tool (`phi_field_scanner.py`) to
  produce a **draft** classification, then have the privacy stakeholder review and correct it. The
  scanner *suggests*; the human decides.

## S2. An agreed disclosure-risk threshold (the release gate)

- **Description:** The **quantitative threshold** the dataset must meet to be releasable into the test
  environment — e.g. a minimum **k** (equivalence-class size), a minimum **l** (distinct sensitive
  values per class), and/or a maximum acceptable **disclosure-risk** proportion — agreed with privacy
  and recorded as **Risk Threshold – Pilot – v1**.
- **Why required:** "Safe" must be defined as a number *before* generating, or the validation gate is
  subjective. The threshold is a governance decision the method measures against.
- **How to verify:** Confirm the threshold values and their owner are written down and approved.
- **How to implement if missing:** Facilitate the threshold decision with privacy/compliance (the
  solution provides the method to measure against it; it does **not** set the number).

## S3. A governed, read-only, minimized source extract (de-identification route only)

- **Description:** Where the route is **de-identification** (not pure synthesis), a **minimized,
  read-only** extract of the real source — only the in-scope fields, only the pilot cohort — obtained
  and handled under the organization's privacy controls, staged **outside** the shared test
  environment.
- **Why required:** You cannot de-identify data you cannot read; but real data must never enter the
  shared harness in identifiable form. The extract is the *input* to the pipeline, not a test artifact.
- **How to verify:** Confirm the extract is minimized, read-only, access-logged, and staged in the
  privacy-controlled zone — not the AI/QA test environment.
- **How to implement if missing:** Request the minimized extract through the governed data-access
  process; if it cannot be obtained, use the **synthesis route** instead.

## S4. A pseudonymization / key-management decision

- **Description:** A decision on how direct identifiers are handled — **suppressed/dropped** vs.
  **pseudonymized** with a mapping key — and, if a key exists, **where it is held, who controls it,
  and that it never enters the test environment**. Recorded as part of **De-Identification Pipeline –
  Pilot – v1**.
- **Why required:** A re-identification key stored alongside "de-identified" data defeats the entire
  exercise; this must be an explicit, governed decision, not a default.
- **How to verify:** Confirm the handling choice per direct identifier and, if pseudonymized, that the
  key custody is documented and segregated from the test environment.
- **How to implement if missing:** Default to **suppression** unless a governed re-linkage need is
  documented; if pseudonymized, place the key under the privacy function's custody.

## S5. An evidence destination and retention decision

- **Description:** Where the **Privacy Evidence Record** is stored, who can read it, and how long it is
  retained — the audit trail governance will consult on review and on any future challenge.
- **Why required:** The evidence is the deliverable governance signs against; it must be durable,
  attributable, and findable — not a transient file in the test environment.
- **How to verify:** Confirm the evidence store, its access controls, and the retention period.
- **How to implement if missing:** Agree a governed evidence location (the reporting tool writes the
  record; the organization owns where it lands).
