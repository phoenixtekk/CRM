# 5. Testing Guide — Microsoft Purview CMMC Compliance Program

Run these after assigning roles (Step 2) and building the pilot assessment, action plan, control map,
and automatic testing (Steps 4–6), and again after each change and before expanding. Every test here is
**safe and read-only** or contained to the **pilot assessment** — Compliance Manager itself changes
nothing on the tenant; the point is to prove the **score, ownership, evidence, control mapping,
automatic testing, and role separation** all work before you build the full CMMC set. **Adequacy,
scoring, and certification remain a compliance/C3PAO determination — these tests validate the
mechanism.**

## Test 1 — Role separation is in place (the access guardrail)
**Do:** Run `CMMC-Discovery.ps1`; review the `CMMC Roles – Separation Evidence` snapshot of each
Compliance Manager role group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status; readers/
auditors (and any external C3PAO reader) are **read-only**. No administrator is silently also a
contributor unless the governance owners accepted it. **Fail** → correct membership with
`CMMC-Set-Scope.ps1` (Implementation Step 2) before proceeding.

## Test 2 — Licensing/cloud supports the CMMC template
**Do:** Run `CMMC-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm the **CMMC Level 2** / **NIST SP 800-171** template is available to create in your cloud.
**Expected:** The template shows as available under your entitlement, in the correct cloud (Commercial
/ GCC / GCC High). **Fail** → resolve licensing/cloud (Requirements 2.1–2.2) before creating the
assessment.

## Test 3 — The pilot assessment exists and is scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `CMMC Assessment – NIST 800-171 –
Pilot`.
**Expected:** The assessment is in the agreed group, has an owner, and shows a **Compliance Score** and
its improvement actions across the NIST 800-171 families. **Fail** → recreate/repair the assessment
(Implementation Step 4).

## Test 4 — Every pilot action is mapped and has an owner, date, status, and evidence source
**Do:** Run `CMMC-Report.ps1`; review the `CMMC Action Plan – Pilot` / `CMMC Control Map – NIST 800-171`
/ `CMMC Evidence – Register` rollup against the assessment's actions in the portal.
**Expected:** Each improvement action maps to a **NIST 800-171 requirement/family** and has an
**owner**, a **target date**, an **implementation status**, and a **named evidence source**; nothing is
unassigned. **Fail** → complete the plan with `CMMC-Configuration.ps1` and assign in the portal.

## Test 5 — Automatic testing reflects the real technical state (true evidence)
**Do:** Confirm automatic testing is enabled (`CMMC Automatic Testing – Setting`), then run
`CMMC-Validation.ps1` (read-only) and compare its findings to the auto-tested actions' status.
**Expected:** For an action Compliance Manager auto-tests (e.g. **unified audit logging enabled** for
the AU family, **MFA/Conditional Access** for AC/IA), the tool's finding matches the action's **test
status** — the score reflects reality, not a stale value. **Fail** → confirm auto-testing eligibility
and the underlying signal; some actions need manual evidence.

## Test 6 — A not-yet-implemented control scores as such (no false pass)
**Do:** Pick an improvement action whose technical control is **not** in place; check its status in the
portal and cross-check with `CMMC-Validation.ps1`.
**Expected:** The action shows **Not implemented / not tested** (or Failed), and the tool confirms the
control is absent — the score is **not** inflated, and the gap is a candidate for the **POA&M**.
**Fail** → correct the status/evidence; do not mark implemented without proof.

## Test 7 — Manual evidence is attached and defensible
**Do:** Open two or three manually-evidenced actions in the portal; confirm the uploaded **evidence**
(policy, procedure, SSP/POA&M reference), **owner**, and **test date** are present, and that
`CMMC Evidence – Register` records the source.
**Expected:** Each manual action carries proof, an owner, and a date — an assessor-ready record.
**Fail** → attach the evidence and record it in the register.

## Test 8 — Control mapping / shared controls behave as expected
**Do:** After the pilot actions are implemented, create the production assessment (or a second framework)
from a licensed template and inspect the shared/mapped controls.
**Expected:** Controls already satisfied by pilot actions show as **implemented** in the new assessment
via **shared/control mapping** — you did not have to redo the work. **Fail** → verify the action is a
shared/Microsoft-managed control and its status is set.

## Test 9 — Posture report is accurate and complete
**Do:** Run `CMMC-Report.ps1` for the `CMMC Score Posture – Report`.
**Expected:** The report rolls up the score, the action-status breakdown, the control-map coverage by
NIST 800-171 family, the evidence register, the role-separation snapshot, and the licensing — matching
the portal. It notes that the **authoritative score and export** are the portal's Compliance Manager
export and that the **SPRS score/certification** are separate determinations. **Fail** → confirm inputs
and re-run.

## Test 10 — Safe automation defaults
**Do:** Run `CMMC-Configuration.ps1` and `CMMC-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `CMMC-Discovery.ps1`, `CMMC-Validation.ps1`, and `CMMC-Report.ps1` are
read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to expand:** Tests 1–2 (guardrails + licensing/cloud), 3–4 (assessment + mapping/ownership),
5–7 (evidence accuracy), 8 (control mapping), and 9–10 (reporting + safety) all pass for the pilot →
proceed to the production assessment (Implementation Step 8). Any fail → correct and re-test. **Whether
the resulting score/evidence satisfies CMMC is a compliance/C3PAO decision, not a technical one.**
