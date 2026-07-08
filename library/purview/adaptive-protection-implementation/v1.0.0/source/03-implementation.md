# Implementation — Adaptive Protection in Microsoft Purview

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (simulation/test / report-only) → Validate → Expand**) and —
because Adaptive Protection is driven by people-monitoring signals — it confirms the **IRM source
signal and its privacy guardrails FIRST**, then builds enforcement in **simulation/report-only**
before anything blocks. Every object is named verbatim so the scripts, testing, and troubleshooting
line up. Replace the `contoso.com` / sample group names with your own.

> **Portal note.** Adaptive Protection **setup** (Quick/Custom, the risk-level mapping) is done in the
> **Microsoft Purview portal** (`purview.microsoft.com` → **Insider Risk Management → Adaptive
> Protection**). The **DLP policy** is authored in **Purview → Data Loss Prevention**; the **CA
> policy** in **Entra → Conditional Access**. PowerShell (S&C PowerShell / Graph) is used here for
> **readiness, DLP scaffolding, validation, and reporting** — not to invent a setup path a surface
> does not expose. Where a portal path or capability may differ by tenant/licence, **verify against
> your licensing/tenant.**

> **Hard gate before you enforce.** Do **not** move DLP from simulation to enforce, or turn the CA
> policy on, until Requirement **R8** (HR/legal/privacy engagement + lawful basis for the underlying
> monitoring) is satisfied **in writing**. Adaptive Protection acts on people-derived risk; the
> applicability is a legal determination, not a technical one.

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** Verify E5 / E5 Compliance (IRM + DLP) on in-scope users and **Entra ID
   P2** for the CA integration. In Purview, **Insider Risk Management → Adaptive Protection** is
   present.
2. **Confirm the IRM source signal + privacy (R3).** Run **`PURVAP-Discovery.ps1`** (read-only).
   Confirm an insider-risk policy exists and is scoring, that IRM **anonymization** is on, and that IRM
   role separation is intact.
   - **Gate 0a:** an IRM scoring source exists and privacy posture is on → continue. Otherwise stand
     up / fix the IRM policy first (see the IRM solution).
3. **Confirm roles across all three surfaces (R2).** IRM Admin, DLP (Compliance Administrator), and
   Conditional Access Administrator mapped to named people; break-glass account identified for CA (R7).
4. **Confirm the toolchain** (`global-requirements-purview.md` §3): `Connect-IPPSSession`,
   `Connect-ExchangeOnline`, and `Connect-MgGraph` all succeed with an MFA-capable admin.

## Phase 1 — Design (agree it with HR/legal, then name everything)

Decide and **record with HR/legal/privacy**:

- **Setup mode (R4):** **Quick setup** (recommended default) to start, or **Custom setup** with an
  explicit mapping, e.g.:
  - **Elevated** = a **high-severity** insider-risk alert (or the Custom threshold you agree).
  - **Moderate** = a **medium-severity** alert.
  - **Minor** = a **low-severity** alert.
- **Pilot scope:** a named group, `SG-AP-Pilot`, holding a small set of sanctioned pilot users.
- **The DLP policy** and its verbatim rule names (Phase 3):
  - Policy: **`DLP-Adaptive-Protection`** (scoped to `SG-AP-Pilot`, **simulation/test** first).
  - Rule **`AP-Elevated-Block`** — risk level **Elevated** → **block** (with policy tip).
  - Rule **`AP-Moderate-WarnOverride`** — risk level **Moderate** → **block with override / warn**
    (user can justify and proceed).
  - Rule **`AP-Minor-Audit`** — risk level **Minor** → **audit only** (allow, notify/record).
- **The label/classification condition (R5):** the sensitivity label(s) — e.g. **Confidential** /
  **Highly Confidential** — (or sensitive info types) each rule additionally requires, so protection
  keys on **labeled sensitive content**.
- **The Conditional Access policy:** **`CA-InsiderRisk-Elevated`** — Insider risk = **Elevated** →
  the agreed control (block, or require MFA / password change / limited session), **report-only**
  first, with the **break-glass account excluded**.

## Phase 2 — Configure Adaptive Protection (the risk-level engine)

In **Purview → Insider Risk Management → Adaptive Protection**:

1. **Choose the setup path.** Select **Quick setup** (uses Microsoft's recommended default insider-risk
   policy and thresholds) or **Custom setup** (map **Elevated / Moderate / Minor** to your chosen
   insider-risk policies and thresholds from Phase 1).
2. **Turn Adaptive Protection on.** Confirm it reports as **active** and that in-scope users will begin
   receiving a **dynamic risk level** as their insider-risk scoring warrants.
3. **Confirm the risk level is available as a condition.** Begin authoring a DLP rule (Phase 3) and
   confirm the condition *"the user's risk level for adaptive protection is …"* is selectable. If it is
   not yet visible, allow propagation time and **verify availability in your tenant.**
- **Pass/fail:** Adaptive Protection shows active with the three levels defined; the DLP condition is
  selectable. **Rollback:** turning Adaptive Protection off stops new level assignment (existing DLP/CA
  rules simply stop matching the condition).

## Phase 3 — Build the DLP enforcement in SIMULATION/TEST first

In **Purview → Data Loss Prevention → Policies → Create policy** (custom), create
**`DLP-Adaptive-Protection`**, scoped to **`SG-AP-Pilot`**, on the in-scope workloads, and set the
policy **mode to simulation / test** (e.g. *Test it out first* — run in test **without** showing
policy tips initially). Then add three rules, each combining the **risk-level** condition with the
**sensitivity-label** condition from Phase 1:

1. **`AP-Elevated-Block`**
   - Conditions: risk level = **Elevated** **AND** content has the sensitivity label(s) (or SIT).
   - Action: **Block** (restrict access / block the action), with a **policy tip**.
2. **`AP-Moderate-WarnOverride`**
   - Conditions: risk level = **Moderate** **AND** the same label/classification condition.
   - Action: **Block with override** / **warn** — the user is warned and may proceed with a business
     justification (recorded).
3. **`AP-Minor-Audit`**
   - Conditions: risk level = **Minor** **AND** the same label/classification condition.
   - Action: **Audit only** — allow, but generate an audit/alert record.

- **Pilot rule:** keep the policy in **simulation/test** and scoped to `SG-AP-Pilot`. Simulation shows
  what the rules **would** do (matches per level) **without blocking anyone**.
- **Pass/fail:** the policy shows **On (test/simulation)** and **healthy** (no configuration warning);
  simulation begins reporting matches once pilot users have risk levels. `PURVAP-Set-DlpPolicy.ps1
  -WhatIf` validates prerequisites and prints the intended policy/rule plan before you build (its
  `-Commit` path can scaffold the policy shell in simulation mode; the **risk-level condition itself is
  added in the portal** where PowerShell does not expose it — **verify in your tenant**).
- **Rollback:** set the policy **mode = Disable** (or delete the rule); simulation changes nothing for
  users, so rollback in the pilot is trivial.

## Phase 4 — Build the Conditional Access control in REPORT-ONLY first

In **Entra → Protection → Conditional Access → New policy**, create **`CA-InsiderRisk-Elevated`**:

1. **Users:** the pilot scope (`SG-AP-Pilot`), **excluding** the **break-glass** account (R7).
2. **Conditions → Insider risk:** set to **Elevated** (verify the condition is available with Entra ID
   P2).
3. **Grant / Session:** the agreed control — **block**, or **require MFA / password change**, or a
   **limited session** — per Phase 1.
4. **Enable policy: Report-only.** This evaluates the policy and logs what **would** happen **without**
   enforcing it.
- **Pass/fail:** the policy shows **Report-only**; sign-in logs show it evaluating for Elevated-risk
  pilot users. **Rollback:** set the policy **Off**; report-only never blocks.

## Phase 5 — Pilot and validate (run the gates)

Work the gates in `05-testing.md`. In summary, with a **sanctioned pilot test account**:

- Confirm Adaptive Protection assigns the account a **risk level** after sanctioned risky activity
  (e.g. the insider-risk scoring the account triggers).
- In **DLP simulation**, confirm the matching rule (**Elevated/Moderate/Minor**) reports it **would**
  take the mapped action on labeled content.
- In **CA report-only**, confirm the sign-in log shows `CA-InsiderRisk-Elevated` would apply when the
  account is Elevated.
- Confirm reporting (`PURVAP-Report.ps1`) reconciles with **Activity explorer / DLP alerts** and the
  CA report-only insights.
- **Do not enforce** until every gate passes **and** HR/legal confirm the approach (R8).

## Phase 6 — Expand (enforce, then widen — only after the gate passes)

1. **Enforce DLP.** Change `DLP-Adaptive-Protection` **mode from simulation/test to enforce** (turn on
   policy tips / actions). Watch the first cohort closely.
2. **Turn on Conditional Access.** Change `CA-InsiderRisk-Elevated` from **report-only to On**, with the
   break-glass exclusion verified.
3. **Widen scope deliberately** — group-by-group, not tenant-wide in one move — using
   `PURVAP-Set-Scope.ps1` (`-WhatIf` first) to stage `SG-AP-Pilot` → broader groups. **Re-run the
   gates** after each expansion. Keep the IRM privacy posture and role separation intact as you scale.

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Adaptive Protection mis-mapped | Adjust the level→threshold mapping (Custom setup), or revert to Quick setup; turn Adaptive Protection off to stop new level assignment. |
| DLP rule too aggressive | Set `DLP-Adaptive-Protection` **mode = simulation** (or Disable) — actions stop immediately; tune conditions and re-pilot. |
| DLP scoped too far | Remove the added members from `SG-AP-Pilot` (`PURVAP-Set-Scope.ps1`); the policy follows the group. |
| CA policy blocking legitimate work | Set `CA-InsiderRisk-Elevated` to **report-only** or **Off**; confirm the break-glass exclusion. |
| Risk levels too sensitive | Retune the IRM source policy / Custom thresholds so fewer users reach Elevated/Moderate. |

> **Never** treat a user's risk level as a finding of misconduct or a disciplinary trigger — it
> tightens **controls**, not judgement. Whether risky activity warrants a consequence is an
> **HR/legal determination** (see IRM); this solution automates protection, not decisions.
