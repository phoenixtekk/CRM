# Testing & Validation

Each procedure below has an explicit **expected pass/fail**. These are the gates referenced in
`03-implementation.md`. Run them for the pilot cohort first, then for every production wave before it
is allowed to expand. All tools are read-only in their verify/gate modes.

> Where a check depends on a Gemini feature label or a Reports API metric, the **presence and name of
> that signal is version-dependent** — confirm the actual signal exists in your tenant and record it
> in `Feature Enablement Matrix – Workforce – v1`. A missing metric is a "verify in your tenant"
> finding, not automatically a fail.

---

## T0 — Guardrail gate (Gate G0)

**Purpose:** confirm the governance guardrails are live for the scope before/after enablement.
**Run:** `python gemini_guardrail_precheck.py --ou "<wave-ou>"`
**Pass:** the tool reports the expected DLP/data-region/model-usage/admin-security baseline present for
the scope, with no ungoverned gap.
**Fail:** any target OU/group is ungoverned, or a guardrail expected by the governance baseline is
absent → **stop**; do not enable (or, if already enabled, roll back) this scope until governance is
restored.

---

## T1 — License readiness & feasibility

**Purpose:** confirm enough seats exist and the baseline is captured.
**Run:** `python gemini_license_readiness.py --report license-baseline.json`
**Pass:** available seats ≥ the seats required by the remaining waves; baseline written.
**Fail:** projected seat shortfall for a planned wave → resolve licensing before starting that wave.

---

## T2 — Scope correctness (Gate G1)

**Purpose:** features are enabled **only** for the intended OUs/groups.
**Run:** `python gemini_feature_enablement.py --ou "<wave-ou>" --verify-scope`
**Pass:** every enabled capability is applied to exactly the intended OU/group; no unintended users
inherit the setting; the observed configuration matches `Feature Enablement Matrix – Workforce – v1`.
**Fail:** any capability is enabled for a broader scope than intended, or the live config diverges from
the matrix → correct the scope (or roll back) before proceeding.

---

## T3 — Licensing correctness (Gate G2)

**Purpose:** assigned seats match the cohort exactly.
**Run:** `python gemini_license_readiness.py --verify-cohort "<cohort>"`
**Pass:** the set of users with an assigned Gemini/AI license equals the cohort membership — no
over-assignment (wasted seats) and no under-assignment (users who will see no Gemini experience).
**Fail:** a diff between assigned licenses and cohort membership → reconcile assignment before the gate
passes.

---

## T4 — Adoption threshold (Gate G3)

**Purpose:** the cohort's adoption clears the agreed target relative to the baseline.
**Run:** `python gemini_adoption_report.py --cohort "<cohort>" --against adoption-baseline.json --gate <target>`
**Pass:** measured active-usage for the cohort within the window meets or exceeds the agreed adoption
target over the baseline; the tool prints `GATE: PASS`.
**Fail:** adoption below target → do not expand; investigate readiness/training, connector gaps, or a
feature-availability issue, remediate, and re-measure. Persisting failure after remediation is a
signal to pause the wave.

---

## T5 — Configuration snapshot & rollback rehearsal

**Purpose:** confirm the rollback path works before it is needed.
**Run (dry-run):**
```
python gemini_feature_enablement.py --ou "<wave-ou>" --snapshot --out <wave>-config-snapshot.json
python gemini_feature_enablement.py --ou "<wave-ou>" --revert --from <wave>-config-snapshot.json --dry-run
```
**Pass:** the snapshot captures the enabled capabilities and license assignment for the scope, and the
dry-run revert reports the exact set of changes it *would* make to return the scope to pre-wave state.
**Fail:** snapshot incomplete or dry-run revert cannot reconstruct the pre-wave state → fix before
enabling the wave (never enable a scope you cannot cleanly revert).

---

## T6 — End-to-end pilot acceptance

**Purpose:** the pilot is a true dress rehearsal for expansion.
**Method:** with the pilot cohort enabled, trained, and measured, confirm **all** of G0, G1, G2, G3
pass together and a sample of pilot users can perform representative tasks (Gemini in an app, the
Gemini app, a Gem, and NotebookLM Enterprise **where enabled**).
**Pass:** all gates green and representative tasks succeed for the pilot cohort → cleared to expand.
**Fail:** any gate red or representative task blocked → remediate within the pilot before Wave 1;
expansion is blocked on a green pilot.
