# Testing & Validation

These procedures validate both the **operating model** (is the sub-function set up correctly?) and
each **dataset** it produces (is the output fit and safe?). Each test states its **expected pass/fail
signal**. Run the operating-model tests once at standup and on cadence; run the per-dataset tests at
the Validate gate (Gate D) for every request.

> No real PHI in a shared harness/twin/AI test environment. Privacy tests produce **technical
> evidence**; the disclosure-risk **determination** is the privacy officer's.

---

## A. Operating-model validation (run at standup and on review cadence)

### A1. Maturity baseline is captured
- **Procedure:** Run `maturityassess.py` with the agreed dimension scores.
- **Pass:** Produces `Maturity Baseline – Sub-Function – v1` with a level per dimension and an overall
  level; the printed summary matches the recorded charter target.
- **Fail:** Missing dimensions or an unset target level → complete the assessment before Design closes.

### A2. Reference architecture config is valid
- **Procedure:** Run `kpirollup.py --refarch --config <arch>.json` against
  `Reference Architecture – Sub-Function – v1`.
- **Pass:** Exit code 0, **no ERROR findings** — required tiers present, an engine interface defined,
  the isolation/no-real-PHI boundary asserted, and a validation/gate stage present.
- **Fail:** Any ERROR finding (e.g. missing isolation boundary, no gate stage) → fix the architecture;
  Gate B cannot close.

### A3. Intake queue is well-formed and prioritized
- **Procedure:** Run `intakequeue.py --input <queue>.csv` on the current queue.
- **Pass:** All rows parse; each request gets a priority score and rank; capacity-vs-demand summary
  prints. No rows rejected for missing required fields.
- **Fail:** Rejected rows or unscored requests → correct the intake data/schema.

### A4. Pod capacity covers expected demand
- **Procedure:** Run `intakequeue.py --capacity` with pod FTE and expected request mix.
- **Pass:** Modeled utilization for each pod ≤ the agreed ceiling (default 85%); no pod structurally
  over-committed.
- **Fail:** Any pod > ceiling → re-staff or re-scope before committing the charter.

### A5. KPI rollup computes against definitions
- **Procedure:** Run `kpirollup.py` on the pilot's intake + validation records.
- **Pass:** Every KPI in `KPI Framework – Sub-Function – v1` computes to a number with its baseline
  recorded; delivery-quality and productivity sections both populate.
- **Fail:** A KPI cannot compute (missing timestamps/fields) → fix the source data capture in intake.

---

## B. Per-dataset validation (run at Gate D for every dataset)

Applied to the pilot as `Synthetic EHR – Pilot – v1`; applied by name to every later dataset.

### B1. Structural / schema conformance
- **Procedure:** `datasetprofile.py --dataset <data> --mode structure` against the target model.
- **Pass:** All in-scope domains present; required fields typed correctly; referential links
  (patient→encounter→observation) resolve.
- **Fail:** Missing domain or broken link → regenerate (counts as rework).

### B2. Coverage
- **Procedure:** `datasetprofile.py --dataset <data> --mode coverage` against the pilot's coverage
  targets (value sets / categories that must appear).
- **Pass:** Coverage of in-scope categories ≥ the agreed target (default ≥ 90% of required categories
  represented).
- **Fail:** Below target → extend scenarios/generation and re-run.

### B3. Distributional fidelity (requires a reference)
- **Procedure:** `datasetprofile.py --dataset <data> --reference <ref-stats> --mode fidelity`.
- **Pass:** Distributional distance per compared field within tolerance (default: normalized distance
  ≤ 0.10 or as agreed). **If no reference exists, this test is reported as N/A — not passed** — and no
  distributional-fidelity claim is made.
- **Fail:** Distance beyond tolerance → tune the engine/parameters and re-run.

### B4. Privacy — direct-identifier screen
- **Procedure:** `privacycheck.py --dataset <data> --check identifiers`.
- **Pass:** No direct identifiers (names, MRNs, SSNs, contact fields, dates-of-birth in identifying
  form) present in the synthetic output.
- **Fail:** Any direct identifier → **block release**; investigate the engine/config leak.

### B5. Privacy — reference-copy / memorization screen
- **Procedure:** `privacycheck.py --dataset <data> --reference <ref> --check copies`.
- **Pass:** No synthetic record is an exact (or near-exact) copy of a reference record.
- **Fail:** Any exact copy → **block release**; the engine is leaking reference rows.

### B6. Privacy — quasi-identifier / uniqueness risk signal
- **Procedure:** `privacycheck.py --dataset <data> --check uniqueness --k <k>`.
- **Pass:** Share of records that are unique on the quasi-identifier set is **below the agreed
  threshold** (default: k-anonymity with k ≥ agreed value; report the fraction violating it).
- **Fail / escalate:** Above threshold → escalate the evidence to the privacy officer for the
  disclosure-risk **determination**; do not self-clear.

**Gate D result:** all B1–B6 must PASS (or fidelity N/A with explicit acknowledgement) **and** the
privacy officer must accept B4–B6 evidence before `Synthetic EHR – Pilot – v1` is released. Any
privacy fail is a hard block with rollback per `03-implementation.md`.
