# Implementation

Follow these steps in order. They implement the house model — **Assess → Configure → Pilot →
Validate → Expand** — pilot-first, with explicit pass/fail gates and a documented rollback for every
production-affecting change. Every artifact is named on first creation with the convention
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in later steps, testing, troubleshooting,
and the scripts.

> **Console-path discipline.** Google Admin console menus and Gemini feature labels change over time,
> and some capabilities are **preview** or edition/region-dependent. Where a step names a control, the
> *navigation intent* is stable; if the exact label or availability differs in your tenant, **verify
> in your tenant** and record the actual path in the `Feature Enablement Matrix – Workforce – v1`.
> Do not enable a capability whose behavior you have not confirmed.

---

## Stage 0 — Assess (read-only)

### 0.1 Confirm licensing position
1. Sign in to **admin.google.com** as a super-admin (or the delegated rollout admin).
2. Go to **Billing → Subscriptions** and record the Gemini/AI subscription, **total seats**, and
   **seats assigned vs. available**.
3. Run the assessment tool to capture this machine-readably and flag shortfalls:
   ```
   python gemini_license_readiness.py --report license-baseline.json
   ```
   This is **read-only**. It records the baseline into `License Assignment – Gemini – v1`.

### 0.2 Confirm governance guardrails are live
1. With the governance owner, confirm the **Gemini Enterprise Secure Adoption & Governance** baseline
   (DLP, data-region, model-usage, admin-security policy) is deployed for the OUs you will enable.
2. Run the read-only pre-check:
   ```
   python gemini_guardrail_precheck.py --ou "/Pilot/Wave0" --dry-run
   ```
3. **Gate G0 (guardrail gate):** if any target scope is ungoverned, **stop** — do not enable Gemini
   there until governance is complete. This gate is re-checked before every wave.

### 0.3 Establish the adoption baseline
1. Confirm the Admin SDK Reports API is reachable for the reporting principal.
2. Capture the pre-rollout usage baseline:
   ```
   python gemini_adoption_report.py --baseline --out adoption-baseline.json
   ```
   Record which Gemini usage metrics the Reports API actually exposes in your tenant (**verify in your
   tenant** — metric availability is version-dependent). The baseline anchors every later trend.

### 0.4 Plan the waves
1. Map users to rollout waves against the OU/group structure:
   ```
   python gemini_rollout_wave_planner.py --plan waves.yaml --dry-run --out wave-plan.json
   ```
2. This produces the ordered cohorts — `Rollout Cohort – Pilot – Wave 0`, `Rollout Cohort – Wave 1`,
   … `Rollout Cohort – Wave N` — each with target OUs/groups, an enablement date, a training package,
   an adoption target, and the seat count required (checked against the license baseline).

**Assess exit criteria:** license baseline captured, Gate G0 passed for the pilot scope, adoption
baseline recorded, wave plan produced and seat-feasible.

---

## Stage 1 — Configure (pilot scope only)

### 1.1 Assign licenses to the pilot cohort
1. Assign Gemini/AI licenses to `Rollout Cohort – Pilot – Wave 0`. In the Admin console this is done
   via **Billing → Subscriptions → (Gemini/AI subscription) → Assign licenses**, scoped to the pilot
   OU/group; automatic licensing by OU may be used where the tenant supports it — **verify in your
   tenant**.
2. Or apply the planned assignment with the helper (dry-run first, then apply):
   ```
   python gemini_feature_enablement.py --ou "/Pilot/Wave0" --assign-licenses --dry-run
   python gemini_feature_enablement.py --ou "/Pilot/Wave0" --assign-licenses --apply
   ```
3. Record assignments in `License Assignment – Gemini – v1`.

### 1.2 Enable and configure Gemini features for the pilot
Configure each capability **scoped to the pilot OU/group only**, and record every decision (including
the exact control path you used and any preview flag) in `Feature Enablement Matrix – Workforce – v1`:

1. **Gemini in Workspace apps** — enable the Gemini side-panel / assistive features in Gmail, Docs,
   Sheets, Slides, Meet, and Drive for the pilot OU. In the Admin console these live under the
   **Generative AI / Gemini** service settings and/or the individual app service settings; the exact
   grouping is version-dependent — **verify in your tenant**.
2. **The Gemini app** — enable access to the standalone Gemini app/experience for the pilot OU where
   your edition provides it.
3. **Gems** (custom saved assistants/personas) — enable and, if desired, seed a small set of
   org-relevant starter Gems for the pilot. Availability and the admin control for Gems are
   evolving — **verify in your tenant** whether it is generally available or preview for your edition.
4. **NotebookLM Enterprise** — enable **only where available** for your edition/region. This is
   frequently **preview or edition-gated**; if it is not clearly available and governed for your
   tenant, mark it *Deferred* in the matrix and **do not enable it** in the pilot. **Verify in your
   tenant.**
5. For each capability enabled, note whether it is **GA or preview** and attach the "verify in your
   tenant" flag in the matrix where the control path or availability was not certain.

### 1.3 Prepare readiness for the pilot
1. Attach the pilot training package to `Rollout Cohort – Pilot – Wave 0` (quick-start, example
   prompts, Gems/NotebookLM usage where enabled, role-specific use cases).
2. Snapshot the intended configuration for validation and rollback:
   ```
   python gemini_feature_enablement.py --ou "/Pilot/Wave0" --snapshot --out pilot-config-snapshot.json
   ```

**Rollback (Stage 1):** to revert the pilot, disable the enabled features for the pilot OU/group and
unassign the licenses:
```
python gemini_feature_enablement.py --ou "/Pilot/Wave0" --revert --from pilot-config-snapshot.json --dry-run
python gemini_feature_enablement.py --ou "/Pilot/Wave0" --revert --from pilot-config-snapshot.json --apply
```
Feature settings and license assignment revert independently — reverting a setting does not release a
seat; unassign licenses explicitly to free seats.

---

## Stage 2 — Pilot

1. Announce enablement to `Rollout Cohort – Pilot – Wave 0` and deliver the training package.
2. Run the pilot for the fixed window agreed with the sponsor.
3. Collect usage over the window:
   ```
   python gemini_adoption_report.py --cohort "Pilot-Wave0" --since <pilot-start> --out pilot-adoption.json
   ```
4. Collect qualitative feedback (blockers, missing use cases, connector gaps to hand to the separate
   connector solution).

---

## Stage 3 — Validate (the gates)

Run the consolidated validation before expanding. All gates must pass; see `05-testing.md` for exact
expected results.

- **Gate G1 — scope correctness:** features are enabled **only** for the intended OUs/groups (no
  bleed to unintended users).
  ```
  python gemini_feature_enablement.py --ou "/Pilot/Wave0" --verify-scope
  ```
- **Gate G2 — licensing correctness:** assigned seats match the cohort; no over- or under-assignment.
  ```
  python gemini_license_readiness.py --verify-cohort "Pilot-Wave0"
  ```
- **Gate G0 (re-check) — guardrails respected:** governance guardrails still hold for the enabled
  scope.
  ```
  python gemini_guardrail_precheck.py --ou "/Pilot/Wave0"
  ```
- **Gate G3 — adoption threshold:** pilot adoption clears the agreed target vs. baseline.
  ```
  python gemini_adoption_report.py --cohort "Pilot-Wave0" --against adoption-baseline.json --gate <target>
  ```

**Validate exit criteria:** G0, G1, G2, G3 all pass. If any fails, remediate or roll back the pilot
(Stage 1 rollback) before proceeding — do **not** expand on a failed gate.

---

## Stage 4 — Expand (wave by wave)

For each production wave `Rollout Cohort – Wave N` in the wave plan, repeat the loop:

1. **Guardrail pre-check (G0):** `python gemini_guardrail_precheck.py --ou "<wave-ou>"` — must pass
   before enabling.
2. **Assign licenses** for the wave (dry-run then apply), checking seat availability against
   `License Assignment – Gemini – v1`.
3. **Enable features** for the wave, matching the validated pilot configuration recorded in
   `Feature Enablement Matrix – Workforce – v1` (dry-run then apply; snapshot for rollback first).
4. **Train** the wave with the readiness package.
5. **Measure** with `gemini_adoption_report.py --cohort "Wave-N"` and run the same G1/G2/G3 gates for
   the wave.
6. **Rollback (per wave):** identical to the Stage 1 rollback, scoped to the wave OU/group, using that
   wave's config snapshot. A regressing wave is reverted without touching prior waves.

Proceed to the next wave only after the current wave passes its gates. Continue until the full
workforce is enabled, trained, and measured, and the adoption trend is reported to the sponsor against
the baseline.
