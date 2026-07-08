# 3. Implementation Guide — Microsoft Purview HIPAA Compliance Program

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Compliance Manager**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`, for role groups and technical evidence) and **Microsoft
Graph** (for licensing and Conditional Access / MFA evidence). Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Portal paths,
template availability, and cmdlets are plan-dependent and the portal evolves — verify against your
tenant.**

> **Model:** Baseline the posture, design the assessment/scope/safeguard-map, configure roles +
> assessment + action plan + automatic testing, validate the technical evidence behind each safeguard,
> report, then expand. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand.**
> **Compliance Manager measures — it does not enforce.** Any *technical* remediation a mapped action
> recommends (a new DLP/label/retention/CA policy) is a **separate, piloted-in-simulation** change owned
> by that feature's solution; and **HIPAA applicability, addressable-spec choices, risk-analysis
> outcomes, and evidence adequacy are compliance/privacy/legal determinations**, not decisions this guide
> makes.

---

## Step 1 — Baseline the posture and capture role/licensing readiness (Assess)
1. Confirm licensing (Requirement 2.1): portal → **Compliance Manager → Assessment templates** — the
   **HIPAA/HITECH** template (and **HITRUST CSF** where scoped) show as available. **Verify entitlement
   with Microsoft licensing — do not assume.**
2. Run `CMPHIPAA-Discovery.ps1` (read-only). It reports the licensing SKUs it can read, the membership of
   each Compliance Manager role group (the `HIPAA Roles – Separation Evidence` snapshot), flags any
   administrator who is also a contributor, and captures the current state of the common technical
   safeguards (unified audit ingestion, DLP/retention/label presence). Note the current **Compliance
   Score** from the portal dashboard as the starting point.
3. **Pass/fail gate:** licensing confirmed for the HIPAA (and any HITRUST) template, the Compliance
   Manager role groups exist, and you have the baseline recorded. **Do not proceed** until the HIPAA
   Security/Privacy Officers and compliance/legal (Requirement 2.3) have confirmed which safeguards apply
   and are in scope. Fail → resolve before configuring.

## Step 2 — Assign roles with least-privilege separation (Configure — guardrails)
1. Portal → `Settings → Roles & scopes → Permissions`: populate the Compliance Manager role groups
   (Requirement 2.2):
   - **Compliance Manager Administrators** → the program owners / IT config staff.
   - **Compliance Manager Assessors** → assessment leads who create assessments and set **test** status.
   - **Compliance Manager Contributors** → the safeguard/action **owners** who update actions/evidence.
   - **Compliance Manager Readers** → oversight/auditors and the HIPAA **Security/Privacy Officer**,
     **read-only**.
2. Or manage membership with `CMPHIPAA-Set-Scope.ps1` — it composes `Add-RoleGroupMember` /
   `Remove-RoleGroupMember`. **It runs with `-WhatIf` by default** and prints exactly what it would
   change; add `-Commit` to apply. Grant the **minimum** role each person needs.
3. **Pass/fail gate:** each person holds the least-privilege role; administrators are separated from
   contributors; the Security/Privacy Officer and auditors are read-only. Re-run `CMPHIPAA-Discovery.ps1`
   and confirm the `HIPAA Roles – Separation Evidence` snapshot. **Rollback:** remove any over-granted
   membership with `CMPHIPAA-Set-Scope.ps1 -Commit`.

## Step 3 — Design the assessment, scope, and safeguard map (Design)
1. With the HIPAA owners, confirm the **in-scope assessment template(s)** (Requirement 2.4): **HIPAA/HITECH**
   plus **HITRUST CSF** where entitled and required. **Applicability is the owners' determination.**
2. Confirm the **in-scope ePHI workloads** and the **classification / sensitive-information-type** approach
   used to *identify* ePHI, and complete the **safeguard → Purview control map** — which capability
   (Audit, labels, DLP, retention, Conditional Access, etc.) evidences each safeguard. Record it as
   `HIPAA Control Map – Safeguards`.
3. Decide the **grouping** (HIPAA program group; HITRUST/NIST alongside for shared-control leverage), and
   assign a **business owner** per assessment.
4. Record the design as `HIPAA Scope – Record` (templates, ePHI scope, grouping, owners, in-/out-of-scope
   safeguards, addressable-spec decisions, risk-analysis reference). Use `CMPHIPAA-Configuration.ps1`
   (`-WhatIf` first) to scaffold the control-map and scope artifacts from the owner-provided inputs.

## Step 4 — Create the pilot assessment (Configure — pilot-first)
1. Portal → **Compliance Manager → Assessments → Add assessment**: create `HIPAA Assessment – HITECH –
   Pilot` from the **HIPAA/HITECH** template, in the agreed group. (Premium/HITRUST templates require the
   entitlement from Requirement 2.1.)
2. **Keep the pilot to one assessment.** Validating the HITECH assessment end-to-end — safeguard mapping,
   ownership, evidence, automatic testing — proves the model before you build the full program. Compliance
   Manager does not change your tenant, so creating the assessment is safe; the *work* it surfaces is what
   you pilot.
3. **Pass/fail gate:** the pilot assessment exists in the correct group with an owner, and its improvement
   actions and current score are visible. Fail → check template availability/licensing. **Rollback:** an
   assessment can be removed in the portal without affecting tenant configuration.

## Step 5 — Build the improvement-action plan and evidence register (Configure)
1. For `HIPAA Assessment – HITECH – Pilot`, assign each **improvement action** an **owner**, a **target
   date**, an **implementation status**, and its **mapped safeguard**, in the portal (action → **Assign** /
   edit).
2. Use `CMPHIPAA-Configuration.ps1` to build the tracking artifacts from the owner-provided list — it
   validates the action plan and, with `-Commit`, writes the local `HIPAA Action Plan – Pilot`,
   `HIPAA Evidence – Register`, and `HIPAA Control Map – Safeguards` files (owner, target date, status,
   mapped safeguard, evidence source per action). **It runs with `-WhatIf` by default** and only
   *describes* the plan; **it makes no tenant changes** — Compliance Manager has no write API, so
   assignments and evidence upload happen in the portal, driven by these artifacts.
3. Attach **evidence** to each action in the portal (audit configuration exports, DLP/label/retention
   policy proof, Conditional Access reports) and record its source in the register.
4. **Pass/fail gate:** every pilot action has an owner, a target date, a status, a mapped safeguard, and a
   named evidence source. Fail → complete the plan before validating.

## Step 6 — Enable automatic testing where it applies (Configure)
1. Portal → **Compliance Manager → Settings**: set the **automatic testing** option (`HIPAA Automatic
   Testing – Setting`) per the owners' decision (Requirement 2.6). Eligible actions will update their
   **test status** from your Microsoft 365 configuration signals.
2. Run `CMPHIPAA-Validation.ps1` (read-only) to confirm the **underlying technical safeguards** the
   automatable actions depend on are present — **unified audit logging enabled**, **DLP / retention /
   sensitivity-label** policies for ePHI present, **Conditional Access / MFA** configured. This tells you
   which safeguards can auto-pass and which still need **manual** evidence.
3. **Pass/fail gate:** automatic testing is set as agreed, and you know which safeguards are auto-tested vs
   manual-evidence. Fail → enable automatic testing or record the manual-evidence actions.

## Step 7 — Validate the evidence behind each safeguard (Pilot → Validate)
1. Run the Testing Guide (`05-testing.md`). Confirm: the pilot assessment shows a score; each action's
   **implementation** and **test** status is set with **evidence**; automatic-tested actions reflect the
   real technical state (cross-checked by `CMPHIPAA-Validation.ps1`); the safeguard map is complete; role
   separation holds.
2. Where a mapped action recommends a **new technical control** (enable audit, add a DLP for ePHI, deploy
   a sensitivity label with encryption, add retention, tighten Conditional Access), **pilot that change in
   simulation/test first** under its own change control — those high-impact changes are owned by their
   feature's solution, not switched on blind here. Re-run `CMPHIPAA-Validation.ps1` to capture the new
   evidence.
3. Run `CMPHIPAA-Report.ps1` for the `HIPAA Posture – Report` (score, safeguard-status rollup, evidence
   register, role separation, licensing).
4. **Pass/fail gate:** the pilot assessment is fully owned, mapped, evidenced, and tested; automatic
   testing reflects reality; the posture report is accurate. Fail → complete evidence/testing and
   re-validate.

## Step 8 — Expand to the full HIPAA program and run the cadence (Expand)
1. With the HIPAA owners, create the remaining production assessment(s) — `HIPAA Assessment – Security
   Rule – Production` and, where entitled, `HIPAA Assessment – HITRUST CSF – Production` — from their
   licensed templates, in the agreed grouping. **Lean on control mapping:** controls already implemented
   for the HITECH pilot often satisfy the same safeguard in HITRUST/NIST automatically (shared controls),
   so the incremental effort is the *gap*.
2. Extend the **action plan**, **evidence register**, and **safeguard map** to the new assessments
   (owners, dates, evidence) with `CMPHIPAA-Configuration.ps1`.
3. Stand up the **maintenance cadence**: periodic re-test/re-evidence of safeguards, review of owners
   (joiners/leavers, Security/Privacy Officer changes), watch for **template/regulation updates**
   Microsoft publishes, and re-run `CMPHIPAA-Report.ps1` on a schedule for the posture trend and the
   annual **evaluation** (§164.308(a)(8)).
4. **Pass/fail gate:** the full in-scope program exists, is owned, mapped, and evidenced, automatic
   testing is running, and a recurring review is scheduled. **Rollback:** any assessment can be removed in
   the portal without touching tenant configuration; scope can be narrowed at any time.

---

### What this guide does NOT decide
- **Which HIPAA safeguards apply, how each addressable specification is satisfied, the risk-analysis
  outcome, and whether the evidence satisfies the obligation** — **compliance/privacy/legal
  determinations**. This guide configures the assessment, the safeguard map, the action plan, and the
  evidence, and produces the score and posture; adequacy and sign-off belong to those functions.
- **The high-impact technical controls a mapped action recommends** — enabling audit, DLP for ePHI,
  labels/encryption, retention, Conditional Access — are **separate, piloted-in-simulation** changes owned
  by their own solution; Compliance Manager only measures whether they are in place.
- **Records-retention schedules, legal holds, and breach-notification decisions** — deferred to
  records/privacy/legal; this program provides the technical preservation method and the evidence.
