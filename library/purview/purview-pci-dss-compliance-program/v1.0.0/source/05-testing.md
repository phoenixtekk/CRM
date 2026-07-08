# 5. Testing Guide — Microsoft Purview PCI-DSS Compliance Program

Run these after assigning roles (Step 3), enabling audit logging (Step 4), and creating the pilot
assessment, action plan, cardholder-data DLP **in simulation**, and label (Steps 5–6), and again after
each change and before enforcing/expanding. Every test here is **safe and read-only** or contained to
**simulation/pilot scope** — the DLP policy is non-enforcing while you test, and Compliance Manager
changes nothing on the tenant. The point is to prove the **score, ownership, evidence, audit logging,
DLP detection, label, and role separation** all work before enforcement. **Whether the resulting
evidence satisfies PCI-DSS is a QSA/compliance determination — these tests validate the mechanism.**

## Test 1 — Role separation is in place (the access guardrail, Req 7)
**Do:** Run `CMPPCI-Discovery.ps1`; review the `PCI Roles – Separation Evidence` snapshot of each role
group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status;
readers/auditors/QSA are **read-only**. No administrator is silently also a contributor unless the
governance owners accepted it. **Fail** → correct membership with `CMPPCI-Set-Scope.ps1`
(Implementation Step 3) before proceeding.

## Test 2 — Licensing supports the PCI-DSS template and advanced controls
**Do:** Run `CMPPCI-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm **PCI-DSS** is available to create.
**Expected:** The PCI-DSS premium template is available under your entitlement, and advanced DLP/audit
surfaces respond. **Fail** → resolve licensing (Requirement 2.1) before creating the assessment or
relying on advanced controls.

## Test 3 — Unified audit logging is enabled and retained (Req 10)
**Do:** Run `CMPPCI-Validation.ps1` (read-only).
**Expected:** `UnifiedAuditLogIngestionEnabled` is `True` and an audit-retention policy meeting your
PCI-DSS version's Requirement 10 is present. **Fail** → enable logging / add the retention policy
(Implementation Step 4); Req 10 evidence is not defensible without it.

## Test 4 — The PCI-DSS assessment exists and is scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `PCI Assessment – Baseline – Pilot`.
**Expected:** The assessment is in the agreed group, has an owner, and shows a **Compliance Score** and
its improvement actions mapped to PCI-DSS requirements. **Fail** → recreate/repair the assessment
(Implementation Step 5).

## Test 5 — Every action has an owner, target date, status, and evidence source/link (Req 12)
**Do:** Run `CMPPCI-Report.ps1`; review the `PCI Action Plan – Pilot` / `PCI Evidence – Register` rollup
against the assessment's actions in the portal.
**Expected:** Each in-scope action has an **owner**, **target date**, **implementation status**, and
**named evidence source**; out-of-scope-for-Purview requirements carry an **evidence link** to the
owning system; nothing is unassigned. **Fail** → complete the plan with `CMPPCI-Configuration.ps1` and
assign in the portal.

## Test 6 — The cardholder-data DLP detects PAN in SIMULATION (Req 3 — no blocking)
**Do:** Confirm `DLP-PCI-CardholderData` is in **simulation/test mode** (`CMPPCI-Validation.ps1`), then
place a **synthetic test card number** (a standard test PAN, never a real card) in a pilot-scope
location and review the policy → **Simulation/Overview** in the portal.
**Expected:** The policy **matches** the test PAN via the Credit Card Number rule and records the match
**without blocking** the user — simulation audits/notifies only. **Fail** → check the rule's SIT,
confidence, and scope; the DLP isn't detecting cardholder data yet.

## Test 7 — A location with no cardholder data does not false-match (precision)
**Do:** Review the simulation results for content that contains card-like but non-PAN numbers (e.g. a
16-digit order ID) in the pilot scope.
**Expected:** The policy does **not** flag non-PAN numbers (the Credit Card Number SIT uses a Luhn
checksum + context), or false positives are few enough to tune out before enforcing. **Fail** → raise
the rule's confidence/instance threshold or add context requirements before moving to enforce.

## Test 8 — The cardholder-data label is published to the pilot scope (Req 3)
**Do:** Confirm `Label-PCI-CardholderData` is published (`CMPPCI-Validation.ps1` reports label
presence; verify the label policy scope in the portal).
**Expected:** The label is available to `SG-PCI-Pilot` users (and, where entitled, auto-labeling on the
Credit Card Number SIT is configured as a separate pilot). **Fail** → publish/scope the label
(Implementation Step 6).

## Test 9 — Evidence is attached and defensible
**Do:** Open two or three in-scope actions in the portal; confirm the uploaded **evidence**, **owner**,
and **test date** are present, and that `PCI Evidence – Register` records the source.
**Expected:** Each action carries proof, an owner, and a date — a QSA-ready record. Req 3 is recorded as
*piloted, pending enforcement* until the DLP is enforcing. **Fail** → attach the evidence and record it
in the register.

## Test 10 — Posture report is accurate, and automation defaults are safe
**Do:** Run `CMPPCI-Report.ps1` for the `PCI Posture – Report`; then run `CMPPCI-Configuration.ps1` and
`CMPPCI-Set-Scope.ps1` with no action switch.
**Expected:** The report rolls up the score inputs, the control-to-evidence map, audit state, DLP mode +
simulation summary, role separation, and licensing — matching the portal, and noting the **portal
Compliance Manager export** as authoritative. `CMPPCI-Configuration.ps1` and `CMPPCI-Set-Scope.ps1` run
in **`-WhatIf`** mode and only *describe* changes; `CMPPCI-Discovery.ps1`, `CMPPCI-Validation.ps1`, and
`CMPPCI-Report.ps1` are read-only. **Fail** → stop; do not run with `-Commit`, and do not enforce DLP,
until the dry-run output and simulation results are correct.

---
**Gate to enforce + expand:** Tests 1–2 (guardrails + licensing), 3 (audit/Req 10), 4–5 (assessment +
ownership), 6–8 (DLP detection in simulation + precision + label/Req 3), and 9–10 (evidence + reporting
+ safety) all pass for the pilot → move the DLP from simulation to **enforce** under change control and
expand to the full requirement set (Implementation Step 8). Any fail → correct and re-test. **Whether
the score/evidence satisfies PCI-DSS, and how the CDE is scoped, are QSA/compliance determinations, not
technical ones.**
