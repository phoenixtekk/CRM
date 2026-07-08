# 5. Testing Guide — Regulatory Assessment Framework (Microsoft Purview)

Run these after assigning roles (Step 4), building the crosswalk (Step 3), and creating the group and
pilot regulation with shared-control implementation and automatic testing (Steps 5–7), and again after
each change and before expanding. Every test here is **safe and read-only** or contained to the **pilot
assessment** — Compliance Manager itself changes nothing on the tenant; the point is to prove the
**shared-control coverage, crosswalk, evidence, automatic testing, and role separation** all work before
you build the full framework set. **Adequacy and applicability remain a compliance/legal determination —
these tests validate the mechanism.**

## Test 1 — Role separation is in place (the access guardrail)
**Do:** Run `CMPFRAME-Discovery.ps1`; review the `RAF Roles – Separation Evidence` snapshot of each
Compliance Manager role group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status; readers/
auditors are **read-only**. No administrator is silently also a contributor unless the governance owners
accepted it. **Fail** → correct membership with `CMPFRAME-Set-Scope.ps1` (Implementation Step 4) before
proceeding.

## Test 2 — Licensing supports every in-scope regulation template
**Do:** Run `CMPFRAME-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm **each** regulation template in the framework is available to create.
**Expected:** The **Data Protection Baseline** is present, and each **premium/custom** template for the
regulations you map to shows as available under your entitlement, with enough premium-assessment count
remaining. **Fail** → resolve licensing (Requirement 2.1) before creating that assessment.

## Test 3 — The canonical control set and crosswalk are complete and coherent
**Do:** Run `CMPFRAME-Configuration.ps1` (dry-run) against `RAF Control Set – Canonical` and
`RAF Crosswalk – Register`.
**Expected:** Every canonical control has an owner and maps to at least one regulation; every in-scope
regulation lists its covering shared controls and its remaining **gap**; no control is orphaned and no
regulation is unmapped. **Fail** → complete the set/crosswalk with compliance owners (Steps 2–3).

## Test 4 — The assessment group and pilot regulation exist and are scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `RAF Group – <Program>` and the
`RAF Assessment – <Regulation> – Pilot` within it.
**Expected:** The pilot assessment is in the group, has an owner, and shows a **Compliance Score** and
its improvement actions. **Fail** → recreate/repair the group/assessment (Implementation Step 5).

## Test 5 — Every shared control has an owner, target date, status, and evidence source
**Do:** Run `CMPFRAME-Report.ps1`; review `RAF Action Plan – Shared` / `RAF Evidence – Register` against
the pilot assessment's actions in the portal.
**Expected:** Each shared control has an **owner**, a **target date**, an **implementation status**, and
a **named evidence source**; nothing is unassigned. **Fail** → complete the plan with
`CMPFRAME-Configuration.ps1` and assign in the portal.

## Test 6 — Shared controls score across many regulations (map once, assess many)
**Do:** After the pilot's shared controls are implemented, create a **second** regulation assessment
from a licensed template in the same group (a pilot of expansion) and inspect the mapped/shared controls.
**Expected:** Controls already satisfied by the shared implementation show as **implemented** in the new
assessment via **control mapping** — you did not redo the work; only the second regulation's **gap**
remains. `CMPFRAME-Report.ps1` shows the shared-control leverage (regulations per control). **Fail** →
verify the action is a shared/Microsoft-managed control and its status is set, or fix the custom-template
mapping in the crosswalk.

## Test 7 — Automatic testing reflects the real technical state (true evidence)
**Do:** Confirm automatic testing is enabled (`RAF Automatic Testing – Setting`), then run
`CMPFRAME-Validation.ps1` (read-only) and compare its findings to the auto-tested shared controls'
status.
**Expected:** For a shared control Compliance Manager auto-tests (e.g. **unified audit logging
enabled**), the tool's finding matches the action's **test status** — the score reflects reality, not a
stale value. **Fail** → confirm auto-testing eligibility and the underlying signal; some controls need
manual evidence.

## Test 8 — A not-yet-implemented shared control scores as such (no false pass)
**Do:** Pick a shared control whose technical control is **not** in place; check its status in the portal
and cross-check with `CMPFRAME-Validation.ps1`.
**Expected:** The action shows **Not implemented / not tested** (or Failed) in **every** regulation it
maps to, and the tool confirms the control is absent — the score is **not** inflated anywhere. **Fail** →
correct the status/evidence; do not mark implemented without proof.

## Test 9 — Manual evidence is attached and defensible
**Do:** Open two or three manually-evidenced shared controls in the portal; confirm the uploaded
**evidence**, **owner**, and **test date** are present, and that `RAF Evidence – Register` records the
source.
**Expected:** Each manual control carries proof, an owner, and a date — an auditor-ready record reused
across every mapped regulation. **Fail** → attach the evidence and record it in the register.

## Test 10 — Coverage matrix is accurate and complete
**Do:** Run `CMPFRAME-Report.ps1` for the `RAF Coverage – Matrix`.
**Expected:** The report shows, per regulation, coverage by shared controls vs the remaining gap, the
shared-control leverage, the evidence register, the role-separation snapshot, and the licensing —
matching the portal. It notes that the **authoritative score and export** are the portal's Compliance
Manager export. **Fail** → confirm inputs and re-run.

## Test 11 — Safe automation defaults
**Do:** Run `CMPFRAME-Configuration.ps1` and `CMPFRAME-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `CMPFRAME-Discovery.ps1`, `CMPFRAME-Validation.ps1`, and `CMPFRAME-Report.ps1` are
read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to expand:** Tests 1–2 (guardrails + licensing), 3 (control set + crosswalk), 4–5 (assessment +
ownership), 6 (map-once/assess-many), 7–9 (evidence accuracy), and 10–11 (reporting + safety) all pass
for the pilot → proceed to the full regulation set (Implementation Step 8). Any fail → correct and
re-test. **Whether the resulting score/evidence satisfies an obligation is a compliance/legal decision,
not a technical one.**
