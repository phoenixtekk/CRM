# 5. Testing Guide — Microsoft Purview Compliance Manager Implementation

Run these after assigning roles (Step 2) and building the pilot assessment, action plan, and automatic
testing (Steps 4–6), and again after each change and before expanding. Every test here is **safe and
read-only** or contained to the **pilot assessment** — Compliance Manager itself changes nothing on the
tenant; the point is to prove the **score, ownership, evidence, automatic testing, and role
separation** all work before you build the full framework set. **Adequacy and applicability remain a
compliance/legal determination — these tests validate the mechanism.**

## Test 1 — Role separation is in place (the access guardrail)
**Do:** Run `CMPMGR-Discovery.ps1`; review the `CM Roles – Separation Evidence` snapshot of each
Compliance Manager role group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status; readers/
auditors are **read-only**. No administrator is silently also a contributor unless the governance
owners accepted it. **Fail** → correct membership with `CMPMGR-Set-Scope.ps1` (Implementation Step 2)
before proceeding.

## Test 2 — Licensing supports the in-scope templates
**Do:** Run `CMPMGR-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm each in-scope template is available to create.
**Expected:** The **Data Protection Baseline** is present, and each **premium/custom** template you
plan to use shows as available under your entitlement. **Fail** → resolve licensing (Requirement 2.1)
before creating that assessment.

## Test 3 — The pilot assessment exists and is scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `CM Assessment – Baseline – Pilot`.
**Expected:** The assessment is in the agreed group, has an owner, and shows a **Compliance Score** and
its improvement actions. **Fail** → recreate/repair the assessment (Implementation Step 4).

## Test 4 — Every pilot action has an owner, target date, status, and evidence source
**Do:** Run `CMPMGR-Report.ps1`; review the `CM Action Plan – Pilot` / `CM Evidence – Register` rollup
against the assessment's actions in the portal.
**Expected:** Each improvement action has an **owner**, a **target date**, an **implementation status**,
and a **named evidence source**; nothing is unassigned. **Fail** → complete the plan with
`CMPMGR-Configuration.ps1` and assign in the portal.

## Test 5 — Automatic testing reflects the real technical state (true evidence)
**Do:** Confirm automatic testing is enabled (`CM Automatic Testing – Setting`), then run
`CMPMGR-Validation.ps1` (read-only) and compare its findings to the auto-tested actions' status.
**Expected:** For an action Compliance Manager auto-tests (e.g. **unified audit logging enabled**), the
tool's finding matches the action's **test status** — the score reflects reality, not a stale value.
**Fail** → confirm auto-testing eligibility and the underlying signal; some actions need manual
evidence.

## Test 6 — A not-yet-implemented control scores as such (no false pass)
**Do:** Pick an improvement action whose technical control is **not** in place; check its status in the
portal and cross-check with `CMPMGR-Validation.ps1`.
**Expected:** The action shows **Not implemented / not tested** (or Failed), and the tool confirms the
control is absent — the score is **not** inflated. **Fail** → correct the status/evidence; do not
mark implemented without proof.

## Test 7 — Manual evidence is attached and defensible
**Do:** Open two or three manually-evidenced actions in the portal; confirm the uploaded **evidence**,
**owner**, and **test date** are present, and that `CM Evidence – Register` records the source.
**Expected:** Each manual action carries proof, an owner, and a date — an auditor-ready record.
**Fail** → attach the evidence and record it in the register.

## Test 8 — Control mapping / shared controls behave as expected
**Do:** After the baseline actions are implemented, create a second assessment from a licensed template
(a pilot of expansion) and inspect the shared/mapped controls.
**Expected:** Controls already satisfied by baseline actions show as **implemented** in the new
assessment via **shared/control mapping** — you did not have to redo the work. **Fail** → verify the
action is a shared/Microsoft-managed control and its status is set.

## Test 9 — Posture report is accurate and complete
**Do:** Run `CMPMGR-Report.ps1` for the `CM Score Posture – Report`.
**Expected:** The report rolls up the score, the action-status breakdown, the evidence register, the
role-separation snapshot, and the licensing — matching the portal. It notes that the **authoritative
score and export** are the portal's Compliance Manager export. **Fail** → confirm inputs and re-run.

## Test 10 — Safe automation defaults
**Do:** Run `CMPMGR-Configuration.ps1` and `CMPMGR-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `CMPMGR-Discovery.ps1`, `CMPMGR-Validation.ps1`, and `CMPMGR-Report.ps1` are
read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to expand:** Tests 1–2 (guardrails + licensing), 3–4 (assessment + ownership), 5–7 (evidence
accuracy), 8 (control mapping), and 9–10 (reporting + safety) all pass for the pilot → proceed to the
full assessment set (Implementation Step 8). Any fail → correct and re-test. **Whether the resulting
score/evidence satisfies an obligation is a compliance/legal decision, not a technical one.**
