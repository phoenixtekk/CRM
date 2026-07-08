# 3. Implementation Guide — Microsoft Purview Compliance Manager Implementation

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Compliance Manager**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`, for role groups and technical evidence) and
**Microsoft Graph** (for licensing and Conditional Access/MFA evidence). Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Portal paths,
template availability, and cmdlets are plan-dependent and the portal evolves — verify against your
tenant.**

> **Model:** Baseline the score, design the assessments/scope/owners, configure roles + assessments +
> the action plan + automatic testing, validate the evidence behind the actions, report, then expand.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**
> **Compliance Manager measures — it does not enforce.** Any *technical* remediation an improvement
> action recommends is a **separate, piloted change** owned by that feature's solution; and
> **regulatory applicability and evidence adequacy are compliance/records/privacy/legal
> determinations**, not decisions this guide makes.

---

## Step 1 — Baseline the score and capture the role/licensing readiness (Assess)
1. Confirm licensing (Requirement 2.1): in the portal → **Compliance Manager → Assessment templates**,
   the templates you need show as available. **Verify entitlement with Microsoft licensing — do not
   assume.**
2. Run `CMPMGR-Discovery.ps1` (read-only). It reports the licensing SKUs it can read, the membership of
   each Compliance Manager role group (the `CM Roles – Separation Evidence` snapshot), and flags any
   administrator who is also a contributor. Note the current **Compliance Score** and the **Data
   Protection Baseline** improvement actions from the portal dashboard as your starting point.
3. **Pass/fail gate:** licensing confirmed for the templates in scope, the Compliance Manager role
   groups exist, and you have the baseline score recorded. **Do not proceed** until the governance
   owners (Requirement 2.3) have confirmed which frameworks apply and are in scope. Fail → resolve
   before configuring.

## Step 2 — Assign roles with least-privilege separation (Configure — guardrails)
1. Portal → `Settings → Roles & scopes → Permissions`: populate the Compliance Manager role groups
   (Requirement 2.2):
   - **Compliance Manager Administrators** → the program owners / IT config staff.
   - **Compliance Manager Assessors** → assessment leads who create assessments and set **test** status.
   - **Compliance Manager Contributors** → the improvement-action **owners** who update actions/evidence.
   - **Compliance Manager Readers** → oversight/auditors, **read-only**.
2. Or manage membership with `CMPMGR-Set-Scope.ps1` — it composes `Add-RoleGroupMember` /
   `Remove-RoleGroupMember`. **It runs with `-WhatIf` by default** and prints exactly what it would
   change; add `-Commit` to apply. Grant the **minimum** role each person needs.
3. **Pass/fail gate:** each person holds the least-privilege role; administrators are separated from
   contributors; readers/auditors are read-only. Re-run `CMPMGR-Discovery.ps1` and confirm the
   `CM Roles – Separation Evidence` snapshot. **Rollback:** remove any over-granted membership with
   `CMPMGR-Set-Scope.ps1 -Commit`.

## Step 3 — Design the in-scope assessments, grouping, and owners (Design)
1. With the governance owners, confirm the **in-scope assessment templates** (Requirement 2.4): the
   **Data Protection Baseline** plus the licensed **premium**/**custom** templates your obligations
   require. **Applicability is the owners' determination**, not a technical default.
2. Decide the **grouping** (by regulation / business unit / environment) so control mapping and
   reporting are coherent, and assign a **business owner** per assessment.
3. Record the design as `CM Scope – Record` (templates, grouping, owners, in-/out-of-scope controls).

## Step 4 — Create the pilot assessment (Configure — pilot-first)
1. Portal → **Compliance Manager → Assessments → Add assessment**: create
   `CM Assessment – Baseline – Pilot` from the **Data Protection Baseline** template, in the agreed
   group. (Premium/custom templates require the entitlement from Requirement 2.1.)
2. **Keep the pilot to one assessment.** Validating the baseline end-to-end — ownership, evidence,
   automatic testing — proves the model before you create the full framework set. Compliance Manager
   does not change your tenant, so creating the assessment is safe; the *work* it surfaces is what you
   pilot.
3. **Pass/fail gate:** the pilot assessment exists in the correct group with an owner, and its
   improvement actions and current score are visible. Fail → check template availability/licensing.
   **Rollback:** an assessment can be removed in the portal without affecting tenant configuration.

## Step 5 — Build the improvement-action plan and evidence register (Configure)
1. For `CM Assessment – Baseline – Pilot`, assign each **improvement action** an **owner**, a **target
   date**, and an **implementation status**, in the portal (action → **Assign** / edit).
2. Use `CMPMGR-Configuration.ps1` to build the tracking artifacts from the owner-provided list — it
   validates the action plan and, with `-Commit`, writes the local `CM Action Plan – Pilot` and
   `CM Evidence – Register` files (owner, target date, status, evidence source per action). **It runs
   with `-WhatIf` by default** and only *describes* the plan; **it makes no tenant changes** —
   Compliance Manager has no write API, so assignments and evidence upload happen in the portal, driven
   by these artifacts.
3. Attach **evidence** to each action in the portal (documents, test results) and record its source in
   the register.
4. **Pass/fail gate:** every pilot action has an owner, a target date, a status, and a named evidence
   source. Fail → complete the plan before validating.

## Step 6 — Enable automatic testing where it applies (Configure)
1. Portal → **Compliance Manager → Settings**: set the **automatic testing** option
   (`CM Automatic Testing – Setting`) per the governance owners' decision (Requirement 2.6). Eligible
   improvement actions will update their **test status** from your Microsoft 365 configuration signals.
2. Run `CMPMGR-Validation.ps1` (read-only) to confirm the **underlying technical signals** the
   automatable actions depend on are present — e.g. **unified audit logging enabled**, **DLP /
   retention / sensitivity-label** policies present, **Conditional Access / MFA** configured. This
   tells you which actions can auto-pass and which still need **manual** evidence.
3. **Pass/fail gate:** automatic testing is set as agreed, and you know which actions are auto-tested
   vs manual-evidence. Fail → enable automatic testing or record the manual-evidence actions.

## Step 7 — Validate the evidence behind the actions (Pilot → Validate)
1. Run the Testing Guide (`05-testing.md`). Confirm: the pilot assessment shows a score; each action's
   **implementation** and **test** status is set with **evidence**; automatic-tested actions reflect
   the real technical state (cross-checked by `CMPMGR-Validation.ps1`); role separation holds.
2. Where an action recommends a **technical change** (enable audit, add a DLP/retention/label policy,
   tighten Conditional Access), **pilot that change in simulation/test first** under its own change
   control — those high-impact changes are owned by their feature's solution, not switched on blind
   here. Re-run `CMPMGR-Validation.ps1` to capture the new evidence.
3. Run `CMPMGR-Report.ps1` for the `CM Score Posture – Report` (score, action status rollup, evidence
   register, role separation, licensing).
4. **Pass/fail gate:** the pilot assessment is fully owned, evidenced, and tested; automatic testing
   reflects reality; the posture report is accurate. Fail → complete evidence/testing and re-validate.

## Step 8 — Expand to the full assessment set and run the cadence (Expand)
1. With the governance owners, create the remaining production assessments —
   `CM Assessment – <Regulation> – Production` — from their licensed templates, in the agreed grouping.
   **Lean on control mapping:** actions already implemented for the baseline often satisfy controls in
   the new assessments automatically (shared controls), so the incremental effort is the *gap*.
2. Extend the **action plan** and **evidence register** to the new assessments (owners, dates,
   evidence) with `CMPMGR-Configuration.ps1`.
3. Stand up the **maintenance cadence**: periodic re-test/re-evidence of actions, review of owners
   (joiners/leavers), watch for **template/regulation updates** Microsoft publishes, and re-run
   `CMPMGR-Report.ps1` on a schedule for the posture trend.
4. **Pass/fail gate:** the full in-scope set exists, is owned and evidenced, automatic testing is
   running, and a recurring review is scheduled. **Rollback:** any assessment can be removed in the
   portal without touching tenant configuration; scope can be narrowed at any time.

---

### What this guide does NOT decide
- **Which regulations/standards apply and whether the evidence satisfies them** — a
  **compliance/records/privacy/legal determination**. This guide configures the assessments, the action
  plan, and the evidence, and produces the score and posture; adequacy and sign-off belong to those
  functions.
- **The high-impact technical changes an action recommends** — enabling audit, DLP, retention, labels,
  Conditional Access, etc. are **separate, piloted-in-simulation** changes owned by their own solution;
  Compliance Manager only measures whether they are in place.
