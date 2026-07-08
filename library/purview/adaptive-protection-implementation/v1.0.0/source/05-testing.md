# Testing & Validation — Adaptive Protection in Microsoft Purview

Run these gates in order. Each has an explicit **pass/fail** signal. **Do not enforce** (Phase 6 —
DLP to enforce, CA to on) until every gate passes **and** HR/legal have confirmed the approach is
acceptable. Where a test involves a real user's activity, use a **sanctioned test account/action**
with HR/legal awareness — do not covertly test on a real employee, because the underlying signal is
insider-risk monitoring.

Use the scripts where noted; they are read-only or `-WhatIf`/simulation and change nothing you don't
approve.

---

## Gate 1 — Licensing and roles are in place

**Why:** Adaptive Protection spans three surfaces, each plan- and role-gated.
**How:** Confirm E5 / E5 Compliance (IRM + DLP) and **Entra ID P2** (CA); confirm IRM/DLP/CA roles are
assigned to named people. Run `PURVAP-Discovery.ps1`.
**Pass:** Licensing present; **Insider Risk Management → Adaptive Protection** is available; the DLP
**risk-level condition** is selectable; the CA **Insider risk** condition is available; roles assigned.
**Fail:** Any surface missing its licence/role → acquire/assign before proceeding.

## Gate 2 — The IRM source signal is scoring (and privacy is on)

**Why:** No IRM scoring source means no risk levels and no adaptive behavior.
**How:** Purview → **Insider Risk Management → Policies** (a policy is **On** and scoring); **Settings
→ Privacy** (anonymization on). `PURVAP-Discovery.ps1` reports the policy signal and prompts to confirm
privacy in-portal.
**Pass:** An insider-risk policy is active and scoring; IRM anonymization is on and role separation
intact.
**Fail:** No scoring source, or privacy posture off without written exception → fix in IRM first.

## Gate 3 — Adaptive Protection is active with the three levels defined

**Why:** The risk-level engine must be on before DLP/CA can read a level.
**How:** Purview → **Insider Risk Management → Adaptive Protection** — confirm Quick or Custom setup
and the **Elevated / Moderate / Minor** definitions.
**Pass:** Adaptive Protection shows **active**; the three levels are defined per the agreed mapping;
in-scope users are eligible for a dynamic level.
**Fail:** Adaptive Protection inactive or misconfigured, or levels undefined → complete Phase 2.

## Gate 4 — The DLP policy is healthy, in SIMULATION, scoped to the pilot

**Why:** A mis-scoped or prematurely-enforcing DLP policy blocks legitimate work.
**How:** Purview → **Data Loss Prevention → Policies**; `PURVAP-Set-DlpPolicy.ps1 -WhatIf` to
re-validate the plan; `PURVAP-Test-Readiness.ps1` to confirm mode/scope.
**Pass:** `DLP-Adaptive-Protection` is **On in simulation/test**, **healthy** (no configuration
warning), scoped to **`SG-AP-Pilot`** only, with the three rules (`AP-Elevated-Block`,
`AP-Moderate-WarnOverride`, `AP-Minor-Audit`) each combining the **risk-level** and
**label/classification** conditions.
**Fail:** Policy enforcing prematurely, over-scoped, unhealthy, or missing a rule/condition → correct
before testing detections.

## Gate 5 — The Conditional Access policy is in REPORT-ONLY with break-glass excluded

**Why:** A blocking CA policy without a break-glass exclusion can lock out administrators.
**How:** Entra → **Conditional Access** — inspect `CA-InsiderRisk-Elevated`.
**Pass:** The policy is **Report-only**, scoped to `SG-AP-Pilot`, uses the **Insider risk = Elevated**
condition, applies the agreed grant/session control, and **excludes the break-glass account**.
**Fail:** Policy already **On**, no break-glass exclusion, or wrong condition → set report-only and fix
before enforcing.

## Gate 6 — A sanctioned test account receives a risk level

**Why:** Proves the source→level path (IRM scoring → Adaptive Protection level) works.
**How:** With a **pilot test account** in `SG-AP-Pilot`, perform **benign, sanctioned** activity that
its insider-risk policy scores (per the IRM policy driving Adaptive Protection), then check the account
is assigned a **risk level**.
**Pass:** The account is assigned an **Elevated / Moderate / Minor** level consistent with the mapping,
within the expected window.
**Fail:** No level assigned → confirm the IRM policy is scoring the account (Gate 2), Adaptive
Protection is active (Gate 3), and enough time has passed for propagation.

## Gate 7 — DLP simulation shows the correct per-level action WOULD apply

**Why:** Proves the level→DLP-action path adapts by level, before anything blocks.
**How:** With the Gate-6 account at a known level, perform a **sanctioned** action on **labeled** test
content (e.g. attempt to share/copy a labeled test file). Review **Activity explorer / DLP simulation**
results.
**Pass:** Simulation shows the matching rule would act as mapped — **audit** at Minor,
**warn/override** at Moderate, **block** at Elevated — on the labeled content, and **not** on
unlabeled/out-of-condition content.
**Fail:** No match, or the wrong rule matched → check the risk-level condition, the label condition,
the workload coverage (and device onboarding for endpoint actions).

## Gate 8 — CA report-only shows the Elevated control WOULD apply

**Why:** Proves the level→access-control path before enforcing access.
**How:** With the test account at **Elevated**, have it sign in to an in-scope app; review the Entra
**sign-in logs → report-only** results for `CA-InsiderRisk-Elevated`.
**Pass:** The sign-in log shows the policy **would** apply the agreed control for the Elevated-risk
account, and **would not** for a Minor/Moderate/normal account.
**Fail:** Policy not evaluating, or applying to the wrong users → check the Insider risk condition,
scope, and Entra ID P2.

## Gate 9 — Reporting reconciles with the portal

**Why:** Leadership needs a defensible, privacy-respecting summary of adaptive enforcement.
**How:** Run `PURVAP-Report.ps1` (read-only) and compare to **Activity explorer / DLP alerts** and the
CA report-only insights.
**Pass:** The rollup (matches/actions by risk level and workload over the window) reconciles with the
portal, with no identity exposure beyond what the report is authorized to show.
**Fail:** Rollup diverges materially from the portal → the portal is authoritative; reconcile before
reporting.

## Gate 10 — HR/legal confirm before enforcement

**Why:** The underlying monitoring's applicability, and any judgement about a user, are HR/legal's.
**How:** Walk the adaptive behavior with HR/legal: how levels are assigned, what each level does to
DLP/CA, and that a level is **not** a misconduct finding.
**Pass:** HR/legal confirm the mapping, the controls, and that **determinations sit with them**; the
lawful basis (R8) is recorded in writing.
**Fail:** Ambiguity about applicability or ownership of outcomes → resolve **before** enforcing.

---

### Exit criteria (all must be true before Expand/enforce)

- [ ] Licensing + roles across IRM/DLP/CA (Gate 1)
- [ ] IRM source signal scoring; privacy on (Gate 2)
- [ ] Adaptive Protection active; three levels defined (Gate 3)
- [ ] DLP policy healthy, simulation, pilot-scoped (Gate 4)
- [ ] CA policy report-only, break-glass excluded (Gate 5)
- [ ] Test account receives a risk level (Gate 6)
- [ ] DLP simulation: correct per-level action would apply (Gate 7)
- [ ] CA report-only: Elevated control would apply (Gate 8)
- [ ] Reporting reconciles with portal (Gate 9)
- [ ] HR/legal confirmed; lawful basis recorded (Gate 10)
