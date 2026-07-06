# Implementation

Follow these steps in order to extend synthetic generation to multi-modal clinical data, **pilot-first**,
following **Assess → Design → Generate/Build → Validate → Expand** with explicit pass/fail gates and a
documented rollback. Every artifact is **named** with the `<Purpose> – <Scope> – <Stage>` convention and
that exact name is reused in later steps, testing, and the scripts. All work runs in the **isolated
non-production** environment on **synthetic** data — never real PHI in the shared harness.

The five Python tools referenced below ship with this solution (see `08-deliverables-summary.md`):
`modality_scope_assess.py`, `multimodal_generate.py`, `fidelity_coverage_report.py`,
`crossmodal_consistency_check.py`, and `scope_config_helper.py`. Each is **safe by default** (dry-run
where it writes).

---

## Stage 1 — Assess

### Step 1.1 — Confirm the global prerequisites and boundary
Verify the six global requirements (`global-requirements-synthetic.md`) and the solution-specific
prerequisites (`02-requirements.md`), especially R1 (structured backbone) and the isolated environment.
Record the governing privacy policy and the deferral of regulatory determinations to
privacy/compliance/legal.

### Step 1.2 — Profile the required modalities
Run the assessment tool against your AI/QA use cases to determine which modalities are actually needed
and whether the structured backbone can support them:

```
python modality_scope_assess.py --use-cases use-cases.json
```

Capture the output as **Modality Scope – Pilot – v1** (the scope record). It states, per use case, which
of {structured, notes, vitals} are in scope, the target model, note types, and vitals channels.

**Gate A (Assess):** target model confirmed, isolated environment confirmed, privacy policy recorded,
and at least the structured backbone present. If any fails, stop and remediate per `02-requirements.md`.

---

## Stage 2 — Design

### Step 2.1 — Define the per-patient clinical state contract
From R2, write the **clinical state** schema — the structured record plus the derived facts (e.g.
`febrile`, `hypotensive_episode@h14`, `on_vasopressors`, diagnoses, trajectory) — and the deterministic
mapping from a structured record to those facts. Record this as **Clinical State Contract – Pilot – v1**.

### Step 2.2 — Generate the run configuration
Use the config helper to produce a validated, version-controlled run config that encodes the scope, note
types, vitals channels/cadence/ranges, consistency rules, and gate thresholds:

```
python scope_config_helper.py init --scope "Modality Scope – Pilot – v1" --out multimodal-config.json
python scope_config_helper.py validate --config multimodal-config.json
```

Record the validated config as **Multi-Modal Config – Pilot – v1**. This single config drives generation
and validation so all stages agree.

### Step 2.3 — Finalize note templates, vitals rules, and consistency rules
Confirm R3 (note templates/phrase banks, no real PHI), R4 (vitals channels/cadence/ranges), and R5
(consistency rules + gate thresholds) are captured in the config. Record the combined design as
**Multi-Modal Design – Pilot – v1**.

**Gate B (Design):** clinical state contract written, config validates, and every downstream fact (note
slot, vitals event, consistency rule) traces to a state field. If not, complete the design before
generating.

---

## Stage 3 — Generate/Build (pilot cohort)

### Step 3.1 — Generate the pilot multi-modal set (dry-run first)
Generate structured + notes + vitals for a small **pilot cohort**, all rendered from the shared clinical
state. The tool is **dry-run by default** — preview first, then opt in to write to the isolated harness:

```
# Preview (no files written)
python multimodal_generate.py --config multimodal-config.json --patients 25

# Write to the isolated harness location (explicit opt-in)
python multimodal_generate.py --config multimodal-config.json --patients 25 \
    --out ./harness/pilot --write
```

The output is **Multi-Modal Synthetic Set – Pilot – v1**: for each synthetic patient, a structured
record (target model), one or more notes per the note types, and vitals time-series per channel — every
modality derived from the same state.

**Gate C (Generate):** all in-scope modalities are present for every pilot patient (no patient missing
notes or vitals). Use the coverage portion of the fidelity report (Step 4.1) to confirm.

---

## Stage 4 — Validate (pass/fail gates)

### Step 4.1 — Fidelity & coverage report
Measure modality coverage and fidelity of the pilot set against the reference (global §6):

```
python fidelity_coverage_report.py --set ./harness/pilot --config multimodal-config.json \
    --reference reference-stats.json --report fidelity-coverage.json
```

Record as **Multi-Modal Validation Report – Pilot – v1 (Fidelity/Coverage)**. Gate on: every modality
present per patient (coverage) and fidelity metrics within the configured thresholds.

### Step 4.2 — Cross-modal consistency & synthetic-safety check
Run the consistency validator — it checks that the modalities tell the same story and runs the
no-real-PHI synthetic-safety scan (R5, R6):

```
python crossmodal_consistency_check.py --set ./harness/pilot --config multimodal-config.json \
    --report consistency.json
```

Record as **Multi-Modal Validation Report – Pilot – v1 (Consistency/Safety)**.

**Gate D (Validate) — the release gate.** The pilot set passes only if **all** hold:
1. **Modalities present** — coverage complete (Step 4.1).
2. **Cross-modally consistent** — no unresolved consistency defects (Step 4.2): note diagnoses appear in
   the structured problem list; asserted vitals events have matching signals; units/ranges valid.
3. **Physiologically plausible** — vitals within configured ranges/trends (Step 4.1/4.2).
4. **Synthetic-safety clean** — the no-real-PHI scan reports no hits; reference data handling documented
   read-only/minimized (Step 4.2).

**Rollback:** if Gate D fails, **discard** the failing synthetic set (it is synthetic and isolated) and
regenerate after fixing config/templates/rules. Nothing production or real-PHI is touched, so rollback is
simply deleting the pilot output and re-running Stage 3.

---

## Stage 5 — Expand

Only after **Gate D passes** on the pilot:

### Step 5.1 — Widen the cohort and modalities
Increase the patient count and add note types / vitals channels in the config, then regenerate and
**re-validate at each step** (repeat Stage 4). Name expanded artifacts by scope, e.g. **Multi-Modal
Synthetic Set – Cardiology Cohort – v1**.

### Step 5.2 — Hand off to AI/QA
Release the validated multi-modal set to the AI/QA teams for document-, signal-, and sequence-model
testing, with the validation reports attached as evidence. Keep the config and reports under version
control so any set is reproducible and its gates auditable.
