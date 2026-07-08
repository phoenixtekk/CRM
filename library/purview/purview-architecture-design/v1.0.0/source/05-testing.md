# 5. Testing Guide — Microsoft Purview Architecture & Design

Run these after designing the capability map, RBAC model, scoping strategy, and naming standard
(Implementation Steps 2–5) and standing up the foundation guardrails (Step 6), and again at each phase
boundary as the roadmap executes. Every test here is **safe and read-only** or contained to the
**foundation guardrails** (role-group membership and the pilot ring) — no capability policy is enforced
by this solution. The point is to prove the **design is conformant** — capabilities licensable, roles
separated, scopes in place, naming applied — before capabilities are built against it. **Applicability,
retention schedules, and lawful basis remain compliance/records/privacy/legal determinations — these
tests validate the architecture, not the determinations.**

## Test 1 — Licensing supports every in-scope capability
**Do:** Run `PURVARCH-Discovery.ps1`; compare its subscribed-SKU / capability-availability output to the
`PA Capability Map – Tenant – Design`.
**Expected:** Every capability marked **in scope** is licensable on the plan; capabilities that are not
are marked **deferred (not licensed)**, not designed into a phase. **Fail** → correct the map or the
licensing (Requirement 2.1) before proceeding. **The script mapping is indicative — confirm entitlement
with Microsoft licensing.**

## Test 2 — The capability map is complete and phased
**Do:** Review the `PA Capability Map – Tenant – Design` and `PA Phase Roadmap – Program – Design`.
**Expected:** Every in-scope capability has an **owner**, a **phase**, and a **status**; phases are
sequenced with entry/exit gates and dependencies. **Fail** → complete the map/roadmap with the
governance owners (Implementation Step 2).

## Test 3 — RBAC separation of duties holds
**Do:** Run `PURVARCH-Validation.ps1`; review the `PA RBAC SoD – Conflicts` register against the
`PA RBAC Model – Tenant – Design`.
**Expected:** Each capability domain has named least-privilege role groups; no person administers two
**separated** domains (e.g. insider risk **and** eDiscovery) unless the owners explicitly accepted it;
readers/auditors are read-only; Global Administrator / Compliance Administrator are reserved, not the
default. **Fail** → resolve conflicts with `PURVARCH-Configuration.ps1` (Implementation Step 6) before
building capabilities.

## Test 4 — Least-privilege role membership is applied
**Do:** Run `PURVARCH-Discovery.ps1`; review each designed role group's membership.
**Expected:** Each function holds the **minimum** role it needs; nobody holds a broad role that subsumes
a function they should not have. **Fail** → correct membership with `PURVARCH-Configuration.ps1`
(`-WhatIf` then `-Commit`).

## Test 5 — The pilot ring exists and is scoped
**Do:** Run `PURVARCH-Set-Scope.ps1` with no action switch (dry-run) and review the `SG-PA-Pilot`
membership; where adaptive scopes are used, confirm `AS-PA-Pilot` exists.
**Expected:** A named pilot ring (`SG-PA-Pilot`) exists with the intended population, and any designed
adaptive scope is present — the mechanism that will contain every high-impact capability policy to a
defined population before enforcement. **Fail** → scaffold the ring/scope (Implementation Step 6).
Adaptive-scope availability is licensing-gated — **verify in your tenant**.

## Test 6 — The scoping strategy is coherent
**Do:** Review the `PA Scoping Plan – Tenant – Design` against the capability map.
**Expected:** Each capability has a chosen **adaptive vs static** scope, administrative-unit use is
decided, and the in-scope workloads/data sources are agreed — so every later policy inherits a defined
scope. **Fail** → complete the scoping plan (Implementation Step 4).

## Test 7 — The naming standard is documented and drift is visible
**Do:** Run `PURVARCH-Validation.ps1`; review the list of existing objects that do **not** conform to
`PA Naming Standard – Tenant – Design`.
**Expected:** The `<Purpose> – <Scope> – <Stage>` standard (with `Sim` / `Prod`) is documented and
agreed; nonconforming existing objects are identified for planned remediation. **Fail** → finalize the
standard and record the drift (Implementation Step 5).

## Test 8 — Simulation-first discipline is designed in
**Do:** Confirm the design and roadmap state that every high-impact capability policy (DLP, labels,
retention, insider risk) is created in **simulation/test/disabled** mode first, named with the `Sim`
suffix, and scoped to `SG-PA-Pilot`.
**Expected:** The pilot-in-simulation pattern is an explicit, named part of the architecture, not an
afterthought — the pilot ring and naming standard make it enforceable. **Fail** → add the pattern to the
roadmap and naming standard before executing any phase.

## Test 9 — The design posture report is accurate and complete
**Do:** Run `PURVARCH-Report.ps1` for the `PA Design Posture – Report`.
**Expected:** The report rolls up capability coverage vs licensing, the RBAC separation snapshot, scope
coverage, naming conformance, and phase status — matching the portal and the design artifacts. It notes
that the **authoritative** role/scope/policy state lives in the Purview portal. **Fail** → confirm the
inputs and re-run.

## Test 10 — Safe automation defaults
**Do:** Run `PURVARCH-Configuration.ps1` and `PURVARCH-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `PURVARCH-Discovery.ps1`, `PURVARCH-Validation.ps1`, and `PURVARCH-Report.ps1`
are read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to execute the roadmap:** Tests 1–2 (licensing + map), 3–4 (RBAC separation + least privilege),
5–6 (scoping + pilot ring), 7–8 (naming + simulation-first), and 9–10 (reporting + safety) all pass →
begin Phase 0/1 (Implementation Step 8), each capability built against this design and piloted in
simulation/test. Any fail → correct and re-test. **Whether the resulting architecture satisfies a
regulatory obligation is a compliance/legal decision, not a technical one.**
