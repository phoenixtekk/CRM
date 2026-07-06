# 5. Testing & Acceptance — Collaboration & AI Platform Consolidation Strategy & Roadmap

Testing is organized by wave, each test with an explicit **PASS/FAIL gate**. Every wave has a **pilot
acceptance gate** (before it expands from pilot to broad scope) and, crucially, a **decommission gate**
per legacy system — the combined **coexistence-exit criteria** that must PASS before any legacy system
is retired (Implementation §03, Part C). **No wave expands until its pilot gate is PASS; no legacy
system is decommissioned until its decommission gate is PASS.**

> Run `GWCONSOL-Validation.ps1` for the scripted target-state conformance checks and
> `GWCONSOL-Report.ps1` for the cost/savings + decommission-readiness report; the manual gates below are
> operator-verified with the estate map, dependency map, and governance clearance. Record results
> against the wave/system, e.g. `Decommission Results – Exchange – Collab`.

---

## Group 0 — Strategy & operating-model readiness (run once, before Wave 0 expands)

**T0.1 — Strategy artifacts exist.** `Consolidation Strategy – Platform – Design`, `Consolidation
Estate Map – Platform – Design`, `Consolidation Roadmap – Platform – Program`, and `Consolidation Cost
Model – Platform – Run` are authored and approved (R5).
- PASS: all four approved. FAIL: any missing/unapproved.

**T0.2 — Operating model + cost baseline defined.** Roles in `Consolidation Operating Model – Platform –
Run` are assigned and the KPI + cost baseline is captured (R2, R9, R12); `GWCONSOL-Report.ps1` produces
a baseline.
- PASS: roles assigned + baseline captured. FAIL: no owner or no baseline.

**T0.3 — Scope groups present.** Per-wave pilot/broad groups exist (R7); `GWCONSOL-Validation.ps1`
confirms.
- PASS: groups present and correctly named. FAIL: missing/misnamed.

**T0.4 — Exit criteria defined per candidate.** Every decommission candidate in the estate map has
recorded coexistence-exit criteria and a dependency order (R6, R8).
- PASS: all candidates have exit criteria + dependency order. FAIL: any candidate without.

**Readiness gate:** T0.1–T0.4 PASS before Wave 0 expands.

---

## Group 1 — Wave 1: Collaboration Consolidation

**T1.1 — Pilot migrated & verified.** The `Consolidation Wave Scope – Collab – Pilot` cohort's mail/
files/chat data is migrated to the target and verified.
- PASS: pilot data on target and verified. FAIL: data missing/unverified.

**T1.2 — Target capability validated.** The pilot works entirely on the target collaboration platform.
- PASS: pilot productive on target. FAIL: pilot still dependent on legacy for normal work.

**T1.3 — No residual dependency (per legacy system).** For each legacy collaboration system, no active
users, integrations, or service dependencies remain (R8) for the retired scope.
- PASS: dependency map clear for the scope. FAIL: a live dependency remains.

**T1.4 — Governance clearance.** Retention/eDiscovery obligations are cleared for the system being
retired; no active legal hold blocks decommission (R10).
- PASS: governance sign-off recorded. FAIL: hold/obligation outstanding.

**Collaboration pilot gate:** T1.1–T1.2 PASS before broad expansion.
**Collaboration decommission gate (per system):** T1.1–T1.4 PASS + rollback available (R11) before the
legacy collaboration system is retired.

---

## Group 2 — Wave 2: AI Platform Consolidation

**T2.1 — Target AI validated.** The target AI capability (Gemini) is validated in production for the
`Consolidation Wave Scope – AI – Pilot` cohort. *Preview/rolling-out capabilities are confirmed in-tenant,
not assumed.*
- PASS: target AI works for the pilot's use cases. FAIL: capability unconfirmed/absent.

**T2.2 — No Copilot-embedded dependency.** No workflow in the retired scope still depends on the legacy
Microsoft AI/Copilot surface (R8).
- PASS: no residual Copilot dependency. FAIL: a workflow still depends on it.

**T2.3 — Licence reclaim identified.** The legacy AI/Copilot licences freed by retirement are identified
for reharvest (feeds realized-savings).
- PASS: reclaimable licences identified. FAIL: not quantified.

**AI decommission gate:** T2.1–T2.3 PASS + rollback available (R11) before the legacy AI/Copilot surface
is retired.

---

## Group 3 — Wave 3: Identity & Management Consolidation

**T3.1 — Consolidated model authoritative.** Users/groups/licensing flow correctly from the consolidated
identity/management model for the `Consolidation Wave Scope – Identity – Pilot` cohort.
- PASS: consolidated model authoritative for the pilot. FAIL: still dual-sourced.

**T3.2 — No duplicate-surface dependency.** No service account, sync connector, or management policy in
the retired scope still depends on the duplicate legacy surface (R8).
- PASS: duplicate surface has no live dependency. FAIL: a dependency remains.

**T3.3 — Provisioning integrity.** Joiner/mover/leaver flows work end-to-end on the consolidated model.
- PASS: JML verified on target. FAIL: provisioning breaks.

**Identity/Management decommission gate:** T3.1–T3.3 PASS + rollback available (R11) before a duplicate
identity/management surface is retired.

---

## Group 4 — Wave 4: Decommission & Sustain

**T4.1 — All exit criteria met.** Every remaining decommission candidate's coexistence-exit criteria
(R6) and governance clearance (R10) are PASS; `GWCONSOL-Report.ps1` shows no open blockers.
- PASS: no open exit-criteria blockers. FAIL: any candidate blocked.

**T4.2 — Decommission caused no impact.** Each executed retirement produced no production impact for the
scope.
- PASS: zero post-decommission incidents. FAIL: user-visible breakage.

**T4.3 — Coexistence footprint retired.** The legacy platform footprint is zero, or the only remainder
is the recorded, approved retained-exception set.
- PASS: footprint zero or exceptions-only. FAIL: unretired systems without exception.

**Sustain gate:** T4.1–T4.3 PASS for the program to be declared consolidated.

---

## Group 5 — Cost & operating-model health (ongoing)

**T5.1 — Realized savings tracked.** `GWCONSOL-Report.ps1` shows realized savings against the cost model
as systems retire.
- PASS: savings reported and tracking the projection. FAIL: no measurement / off-model.

**T5.2 — Estate/dependency map current.** The estate map and dependency map are re-confirmed as
migrations complete; no undocumented legacy system remains.
- PASS: maps current. FAIL: stale/undocumented estate.

**Run gate:** T5.1–T5.2 PASS before the program is declared in steady-state run.

---

## Program-level exit (per wave / per decommission)

A wave is **complete** only when its pilot acceptance gate is PASS; a legacy system is **retired** only
when its decommission gate (coexistence-exit criteria) is PASS. Capture results against the wave/system
name (`Decommission Results – <System> – <Wave>`). **No legacy system is decommissioned until its
coexistence-exit criteria pass**, in dependency order (R8), with governance clearance (R10) and change
control + rollback confirmed (R11).
