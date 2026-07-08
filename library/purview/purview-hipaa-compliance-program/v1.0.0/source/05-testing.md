# 5. Testing Guide — Microsoft Purview HIPAA Compliance Program

Run these after assigning roles (Step 2) and building the pilot assessment, action plan, and automatic
testing (Steps 4–6), and again after each change and before expanding. Every test here is **safe and
read-only** or contained to the **pilot assessment** — Compliance Manager itself changes nothing on the
tenant; the point is to prove the **score, safeguard mapping, ownership, evidence, automatic testing, and
role separation** all work before you build the full HIPAA program. **Adequacy, applicability, and the
risk-analysis outcome remain compliance/privacy/legal determinations — these tests validate the
mechanism.**

## Test 1 — Role separation is in place (the access guardrail)
**Do:** Run `CMPHIPAA-Discovery.ps1`; review the `HIPAA Roles – Separation Evidence` snapshot of each
Compliance Manager role group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status; the HIPAA
Security/Privacy Officer and auditors are **read-only**. No administrator is silently also a contributor
unless the owners accepted it. **Fail** → correct membership with `CMPHIPAA-Set-Scope.ps1` (Implementation
Step 2) before proceeding.

## Test 2 — Licensing supports the HIPAA (and HITRUST) template
**Do:** Run `CMPHIPAA-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm the **HIPAA/HITECH** template (and **HITRUST CSF** where scoped) is available to create.
**Expected:** The HIPAA/HITECH template shows as available under your entitlement; HITRUST CSF likewise
where scoped. **Fail** → resolve licensing (Requirement 2.1) before creating that assessment.

## Test 3 — The pilot assessment exists and is scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `HIPAA Assessment – HITECH – Pilot`.
**Expected:** The assessment is in the agreed group, has an owner, and shows a **Compliance Score** and
its improvement actions grouped by safeguard. **Fail** → recreate/repair the assessment (Implementation
Step 4).

## Test 4 — Every pilot action has an owner, target date, status, mapped safeguard, and evidence source
**Do:** Run `CMPHIPAA-Report.ps1`; review the `HIPAA Action Plan – Pilot` / `HIPAA Evidence – Register` /
`HIPAA Control Map – Safeguards` rollup against the assessment's actions in the portal.
**Expected:** Each improvement action has an **owner**, a **target date**, an **implementation status**, a
**mapped HIPAA safeguard**, and a **named evidence source**; nothing is unassigned or unmapped. **Fail** →
complete the plan with `CMPHIPAA-Configuration.ps1` and assign in the portal.

## Test 5 — Automatic testing reflects the real technical safeguard state (true evidence)
**Do:** Confirm automatic testing is enabled (`HIPAA Automatic Testing – Setting`), then run
`CMPHIPAA-Validation.ps1` (read-only) and compare its findings to the auto-tested actions' status.
**Expected:** For a safeguard Compliance Manager auto-tests (e.g. **§164.312(b) audit controls** →
unified audit logging enabled), the tool's finding matches the action's **test status** — the score
reflects reality, not a stale value. **Fail** → confirm auto-testing eligibility and the underlying
signal; some safeguards need manual evidence.

## Test 6 — A not-yet-implemented safeguard scores as such (no false pass)
**Do:** Pick a mapped action whose technical control is **not** in place (e.g. no DLP for ePHI yet); check
its status in the portal and cross-check with `CMPHIPAA-Validation.ps1`.
**Expected:** The action shows **Not implemented / not tested** (or Failed), and the tool confirms the
control is absent — the HIPAA score is **not** inflated. **Fail** → correct the status/evidence; do not
mark a safeguard implemented without proof.

## Test 7 — Manual evidence is attached and defensible
**Do:** Open two or three manually-evidenced actions in the portal (e.g. a documentation/§164.316 or
workforce-training §164.308(a)(5) action); confirm the uploaded **evidence**, **owner**, and **test date**
are present, and that `HIPAA Evidence – Register` records the source.
**Expected:** Each manual action carries proof, an owner, and a date — an OCR/BAA-audit-ready record.
**Fail** → attach the evidence and record it in the register.

## Test 8 — Control mapping / shared controls behave as expected (evidence once, score many)
**Do:** After the HITECH baseline actions are implemented, create a second assessment from a licensed
template (a pilot of HITRUST CSF or NIST) and inspect the shared/mapped controls.
**Expected:** Controls already satisfied for HITECH (e.g. audit, MFA) show as **implemented** in the new
assessment via **shared/control mapping** — you did not redo the work. **Fail** → verify the action is a
shared/Microsoft-managed control and its status is set.

## Test 9 — Posture report is accurate and complete
**Do:** Run `CMPHIPAA-Report.ps1` for the `HIPAA Posture – Report`.
**Expected:** The report rolls up the score, the safeguard-status breakdown (Administrative / Physical /
Technical), the evidence register, the role-separation snapshot, and the licensing — matching the portal.
It notes that the **authoritative score and export** are the portal's Compliance Manager export. **Fail**
→ confirm inputs and re-run.

## Test 10 — Safe automation defaults
**Do:** Run `CMPHIPAA-Configuration.ps1` and `CMPHIPAA-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `CMPHIPAA-Discovery.ps1`, `CMPHIPAA-Validation.ps1`, and `CMPHIPAA-Report.ps1` are
read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to expand:** Tests 1–2 (guardrails + licensing), 3–4 (assessment + ownership + mapping), 5–7
(evidence accuracy), 8 (control mapping), and 9–10 (reporting + safety) all pass for the HITECH pilot →
proceed to the full program (Implementation Step 8). Any fail → correct and re-test. **Whether the
resulting score/evidence satisfies the HIPAA obligation is a compliance/privacy/legal decision, not a
technical one.**
