# 5. Testing & Acceptance — SASE / SSE Architecture & Design Blueprint

Testing is organized by phase, each test with an explicit **PASS/FAIL gate**. Every phase has a
**pilot acceptance gate** — the combined condition that must be met before the phase expands from
pilot to broad scope (Implementation §03, Part C). **No phase expands until its pilot acceptance gate
is PASS.**

> Run `SASE-Validation.ps1` for the scripted readiness checks and `SASE-Report.ps1` for the
> capability-coverage + gap report; the manual gates below are operator-verified on a steered pilot
> endpoint. Record results against the phase, e.g. `Validation Results – SWG – Pilot`.

---

## Group 0 — Design & operating-model readiness (run once, before Phase 0 expands)

**T0.1 — Design artifacts exist.** `SASE Reference Architecture – Edge – Design`,
`SASE Policy Model – Edge – Design`, and `SASE Adoption Roadmap – Edge – Program` are authored and
approved (R7).
- PASS: all three approved. FAIL: any missing/unapproved.

**T0.2 — Operating model defined.** Roles in `SASE Operating Model – Edge – Run` are assigned and the
KPI baseline is captured (R2, R12); `SASE-Report.ps1` produces a baseline.
- PASS: roles assigned + baseline captured. FAIL: no owner or no baseline.

**T0.3 — Targeting groups present.** Per-phase pilot/broad groups exist (R8); `SASE-Validation.ps1`
confirms.
- PASS: groups present and correctly named. FAIL: missing/misnamed.

**Readiness gate:** T0.1–T0.3 PASS before Phase 0 expands.

---

## Group 1 — Phase 0: Baseline & Steering

**T1.1 — Steering active.** Pilot endpoints in `SASE Phase Scope – Baseline – Pilot` are steered and
appear in the edge.
- PASS: traffic visible from pilot endpoints. FAIL: not steered.

**T1.2 — Identity attribution.** Steered traffic is attributed to the correct user/Entra group.
- PASS: correct identity on traffic. FAIL: anonymous/wrong identity.

**T1.3 — No user impact (monitor-only).** Inspection/enforcement is monitor-only; users see no change.
- PASS: zero functional impact. FAIL: user-visible breakage.

**Phase 0 acceptance gate:** T1.1–T1.3 PASS for the pilot scope.

---

## Group 2 — Phase 1: Secure Web Gateway (SWG)

**T2.1 — Certificate trust.** The decryption root is trusted on the steered scope; inspected sites load
without TLS errors (R9).
- PASS: no TLS trust errors. FAIL: certificate warnings.

**T2.2 — SSL inspection working.** Inspectable HTTPS traffic is decrypted and visible to policy.
- PASS: inspected traffic visible. FAIL: traffic opaque/bypassed unexpectedly.

**T2.3 — Exceptions honored.** Destinations on the governed exception list are **not** decrypted; pinned/
regulated apps work.
- PASS: exceptions bypass inspection, apps work. FAIL: a pinned/regulated app breaks.

**T2.4 — SWG policy decides as designed.** A test user hits allowed/blocked/inspected categories and
gets the designed action per the policy model.
- PASS: actions match design. FAIL: wrong/inconsistent action.

**SWG acceptance gate:** T2.1–T2.4 PASS; **zero broken pinned/regulated apps**.

---

## Group 3 — Phase 2: CASB & Cloud-App Control

**T3.1 — Shadow-IT visibility.** Unsanctioned cloud apps used by the pilot are discovered and listed.
- PASS: shadow IT visible. FAIL: no discovery.

**T3.2 — Cloud-app control action.** A sanctioned/tolerated/unsanctioned app gets its designed inline
action (allow/restrict/block) per the policy model.
- PASS: control behaves as designed. FAIL: wrong action.

**T3.3 — Identity-first targeting.** The action correctly varies by the user's Entra group.
- PASS: per-group policy applies. FAIL: policy not identity-scoped.

**CASB acceptance gate:** T3.1–T3.3 PASS for the pilot scope.

---

## Group 4 — Phase 3: ZTNA for Private Apps

**T4.1 — Entitled access works.** A pilot user reaches exactly the private apps mapped to their Entra
group (R10).
- PASS: entitled apps reachable. FAIL: cannot reach an entitled app.

**T4.2 — Least privilege enforced.** The same user **cannot** reach private apps they are not entitled
to (no broad network access).
- PASS: non-entitled apps blocked. FAIL: over-broad access.

**T4.3 — VPN displacement.** With ZTNA active for the pilot, the legacy VPN path is not required for the
published apps.
- PASS: apps reachable without VPN. FAIL: still VPN-dependent.

**ZTNA acceptance gate:** T4.1–T4.3 PASS; rollback (re-enable VPN) confirmed available (R11).

---

## Group 5 — Phase 4: Data-Protection-Adjacent & Optimization

**T5.1 — Hooks fire.** The designed-in content-aware hooks (`SASE Policy – Data Hook – Pilot`) trigger
on the test condition.
- PASS: hook fires as designed. FAIL: no trigger / wrong trigger.

**T5.2 — No undue impact.** The hooks and tuned policy do not break normal pilot usage.
- PASS: usage unaffected. FAIL: false positives break work.

**T5.3 — Performance acceptable.** Inspection/steering overhead is within the agreed target on the pilot.
- PASS: performance within target. FAIL: unacceptable latency.

**Optimization acceptance gate:** T5.1–T5.3 PASS for the pilot scope.

---

## Group 6 — Operating-model health (ongoing)

**T6.1 — KPI dashboard live.** `SASE-Report.ps1` produces current KPI values (steering/inspection
coverage, policy consistency, ZTNA displacement, etc.).
- PASS: KPIs reported. FAIL: no measurement.

**T6.2 — Exception register current.** SSL-inspection and steering-bypass exceptions are documented and
in-date.
- PASS: register current. FAIL: stale/undocumented exceptions.

**Run gate:** T6.1–T6.2 PASS before the program is declared in steady-state run.

---

## Program-level exit (per phase)

A phase is **complete** only when its acceptance gate above is PASS. Capture results against the phase
name (`Validation Results – <Phase> – Pilot`). **No phase expands to broad scope until its pilot gate
passes** and change control + rollback are confirmed (R11).
