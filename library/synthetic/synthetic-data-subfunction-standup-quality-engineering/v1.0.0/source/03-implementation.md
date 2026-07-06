# Implementation

This is the ordered standup procedure. It follows the house model **Assess → Design →
Generate/Build → Validate → Expand**, pilot-first, with explicit pass/fail gates and a documented
rollback. Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>` and that
exact name is reused in later stages, testing, troubleshooting, and the tools.

> **Hard boundaries throughout.** No real PHI enters a shared harness/twin/AI test environment. Any
> reference to real data is read-only, minimized, and under the governing privacy controls.
> Regulatory/legal determinations are deferred to privacy/compliance/legal.

## Artifacts you will produce (naming register)

| Artifact | Named instance (pilot) | Produced in |
|---|---|---|
| Capability baseline | `Maturity Baseline – Sub-Function – v1` | Assess |
| Sponsorship & mandate | `Capability Charter – Sub-Function – v1` | Design |
| Pod & RACI design | `Pod Design – Sub-Function – v1` | Design |
| Intake definition | `Intake Scheme – Sub-Function – v1` | Design |
| Reference architecture | `Reference Architecture – Sub-Function – v1` | Design |
| KPI framework | `KPI Framework – Sub-Function – v1` | Design |
| Pilot dataset | `Synthetic EHR – Pilot – v1` | Generate/Build |
| Validation record | `Validation Record – Pilot – v1` | Validate |
| Expansion plan | `Expansion Plan – Sub-Function – v1` | Expand |

---

## Stage 1 — Assess

**Goal:** an honest baseline and a concrete sponsorship ask.

1. **Confirm the six global requirements** (`global-requirements-synthetic.md`) and the six
   solution-specific ones (`02-requirements.md`). Record gaps; do not proceed past Design with S1
   (sponsor) or the isolated environment unresolved.
2. **Run the maturity self-assessment.** Execute `maturityassess.py` with your dimension scores to
   produce **`Maturity Baseline – Sub-Function – v1`** (a JSON + printed summary). This baseline is
   reused as the KPI baseline anchor and the Expand-stage comparison.
3. **Confirm the pilot inputs** with the consuming AI/QA teams: the **target clinical data model**
   (FHIR / OMOP / native), the in-scope domains (patients, encounters, conditions, meds, labs,
   vitals), the pilot AI/QA use case, and the **reference source** for fidelity (governed real stats
   or agreed published distributions).
4. **Make the sponsorship ask** using the baseline: scope, pilot capacity, first pilot value. Obtain a
   named sponsor and funded pilot capacity (S1).

**Gate A (Assess→Design):** sponsor named + funded pilot capacity + isolated non-prod environment
confirmed + target model chosen. If any fail, stop; the standup is not ready.

---

## Stage 2 — Design

**Goal:** the operating model on paper, ready to run.

5. **Author `Capability Charter – Sub-Function – v1`** — mission, scope (what the sub-function does and
   explicitly does *not* do), the sponsor and escalation path, and the deferral of regulatory/legal
   determinations to privacy/compliance/legal.
6. **Design the pods** → **`Pod Design – Sub-Function – v1`**. Define Intake, Generation, Validation &
   Governance, and Platform/enablement pods with owners and committed FTE fractions, plus a RACI for
   the intake-to-release flow. **Model the capacity** with `intakequeue.py --capacity` against expected intake;
   adjust FTE or scope until the model is not structurally over-committed.
7. **Define intake** → **`Intake Scheme – Sub-Function – v1`**. Adopt the intake form fields and the
   prioritization scoring model (value, urgency, effort, risk with agreed weights). This is the schema
   `intakequeue.py` consumes.
8. **Define the reference architecture** → **`Reference Architecture – Sub-Function – v1`**. Specify
   the isolated non-prod tiers, the **engine interface** (Synthea / commercial platform / AI framework
   swappable behind it), storage + access control, the fixed **validation/gate stage**, and the
   data-flow boundary that enforces no-real-PHI-in-shared-harness. Capture it as the config
   `kpirollup.py --refarch` validates.
9. **Define the KPI framework** → **`KPI Framework – Sub-Function – v1`**. Adopt the catalog below;
   give each KPI a definition, target, owner, and baseline slot.

   **Delivery-quality KPIs**
   - *Validation pass rate* — % of datasets passing all gates on first submission.
   - *Defect escape rate* — issues found by consumers ÷ total issues (lower is better).
   - *Rework rate* — % of requests requiring a second generation/validation cycle.
   - *Gate cycle time* — median time in the validation stage.

   **Engineering-productivity KPIs**
   - *Request lead time* — intake-accepted to release (median + p85).
   - *Throughput* — requests released per period.
   - *Flow efficiency* — active time ÷ total lead time.
   - *WIP* — mean requests in progress (watch against pod capacity from step 6).

**Gate B (Design→Build):** charter, pod design, intake scheme, reference architecture (validated by
`kpirollup.py --refarch`), and KPI framework all exist and are agreed. Reference architecture config must
pass `kpirollup.py --refarch` with **no ERROR-level findings**.

---

## Stage 3 — Generate/Build

**Goal:** the environment and engine stood up; one pilot request run end-to-end.

10. **Stand up the isolated environment and engine** per `Reference Architecture – Sub-Function – v1`.
    Install the Python data environment; wire the first engine (e.g. Synthea or a commercial platform)
    behind the engine interface. Verify the environment is not connected to production PHI stores.
11. **Accept the pilot request through intake.** Log it in the queue; confirm `intakequeue.py`
    prioritizes and reports it cleanly.
12. **Profile the target/reference** with `datasetprofile.py` against the agreed reference statistics
    (read-only, minimized) to establish the fidelity comparison baseline for the target domains.
13. **Generate the pilot dataset** → **`Synthetic EHR – Pilot – v1`** against the chosen target model
    and in-scope domains, written **only** to the isolated environment. (If your engine is Synthea or a
    commercial platform, run it per that vendor's documentation; treat its output as the named dataset.)

**Gate C (Build→Validate):** `Synthetic EHR – Pilot – v1` exists in the isolated environment, conforms
structurally to the target model, and contains the in-scope domains. No real PHI present.

---

## Stage 4 — Validate

**Goal:** evidence the dataset is fit and safe; a release decision at the gate.

14. **Run the fidelity/coverage report.** Execute `datasetprofile.py` comparing
    `Synthetic EHR – Pilot – v1` to the reference baseline from step 12; produce the coverage and
    distributional-fidelity section of the validation record.
15. **Run the privacy/validation check.** Execute `privacycheck.py` on the dataset to screen for
    direct-identifier leakage, uniqueness/quasi-identifier risk signals, and exact copies of reference
    rows. This produces **technical evidence and a pass/fail signal only** — the disclosure-risk
    **determination** is deferred to the privacy officer.
16. **Assemble `Validation Record – Pilot – v1`** — the fidelity/coverage results, the privacy screen
    results, the gate decision, and the named reviewers.

**Gate D (the release gate — pass/fail):**
- **Fidelity/coverage:** meets the pilot's agreed thresholds (coverage of in-scope domains ≥ target;
  distributional distance within tolerance where a reference exists).
- **Privacy:** `privacycheck.py` reports **no direct identifiers**, **no exact reference-row copies**,
  and quasi-identifier risk **below the agreed threshold**; privacy officer accepts the evidence.
- **Decision:** PASS → release to the consuming AI/QA use case. FAIL → **rollback**: quarantine
  `Synthetic EHR – Pilot – v1` in the isolated environment, record the failing gate in the validation
  record, and return the request to the Generation pod for a second cycle (counts against *rework
  rate*). Never release on a failed privacy gate.

---

## Stage 5 — Expand

**Goal:** turn the pilot into a scaling, measured service.

17. **Baseline the KPIs.** Compute the first `KPI Framework – Sub-Function – v1` rollup with
    `kpirollup.py` from the intake/validation data of the pilot. This is the trend anchor.
18. **Onboard the next request types and programs** through the same intake and gates; add engines
    behind the engine interface as needed (re-run `kpirollup.py --refarch` on any architecture change).
19. **Re-run the maturity self-assessment** (`maturityassess.py`) on cadence, compare to
    `Maturity Baseline – Sub-Function – v1`, and record the next target in
    **`Expansion Plan – Sub-Function – v1`**.
20. **Review KPIs on cadence** with the sponsor; watch WIP against pod capacity (`intakequeue.py --capacity`) and
    re-scope or re-staff before lead time degrades.

**Steady state:** every request enters through `Intake Scheme – Sub-Function – v1`, produces a named
dataset, ships with a `Validation Record`, and contributes to the KPI trend — a repeatable, measured
service.
