# 3. Implementation Guide — Microsoft Purview CMMC Compliance Program

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Compliance Manager**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`, for role groups and technical evidence) and
**Microsoft Graph** (for licensing and Conditional Access/MFA evidence). Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Portal paths,
template availability, cloud (Commercial vs GCC/GCC High), and cmdlets are plan-/cloud-dependent and
the portal evolves — verify against your tenant.**

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| Pilot assessment | `CMMC Assessment – NIST 800-171 – Pilot` |
| Production assessment | `CMMC Assessment – Level 2 – Production` |
| Improvement-action plan | `CMMC Action Plan – Pilot` |
| Control map | `CMMC Control Map – NIST 800-171` |
| Evidence register | `CMMC Evidence – Register` |
| Automatic-testing setting | `CMMC Automatic Testing – Setting` |
| Score posture report | `CMMC Score Posture – Report` |
| Role-separation evidence | `CMMC Roles – Separation Evidence` |
| Scope / CUI-boundary record | `CMMC Scope – Record` |

> **Model:** Baseline the posture, design the assessment/scope/owners, configure roles + the assessment
> + the action plan + control map + automatic testing, validate the evidence behind the actions,
> report, then expand. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand.**
> **Compliance Manager measures — it does not certify.** Any *technical* remediation an improvement
> action recommends (audit, DLP, MFA/Conditional Access, retention, labels, encryption) is a
> **separate, piloted change** owned by that feature's solution; and **CMMC applicability, the target
> level, evidence adequacy, the SPRS score, and certification are compliance/security/legal/C3PAO
> determinations**, not decisions this guide makes.

---

## Step 1 — Baseline the posture and capture role/licensing readiness (Assess)
1. Confirm licensing and cloud (Requirements 2.1–2.2): in the portal → **Compliance Manager →
   Assessment templates**, the **CMMC Level 2** and/or **NIST SP 800-171** template shows as available
   in your cloud. **Verify entitlement and template name with Microsoft licensing — do not assume.**
2. Run `CMMC-Discovery.ps1` (read-only). It reports the licensing SKUs it can read, the membership of
   each Compliance Manager role group (the `CMMC Roles – Separation Evidence` snapshot), and flags any
   administrator who is also a contributor. Note the current **Compliance Score** from the portal
   dashboard as your starting point.
3. **Pass/fail gate:** licensing/cloud confirmed for the CMMC/NIST template, the Compliance Manager
   role groups exist, and the baseline score is recorded. **Do not proceed** until the governance
   owners (Requirement 2.4) have confirmed the **target level** and which requirements are in scope.
   Fail → resolve before configuring.

## Step 2 — Assign roles with least-privilege separation (Configure — guardrails)
1. Portal → `Settings → Roles & scopes → Permissions`: populate the Compliance Manager role groups
   (Requirement 2.3):
   - **Compliance Manager Administrators** → the program owners / IT config staff.
   - **Compliance Manager Assessors** → assessment leads who create assessments and set **test** status.
   - **Compliance Manager Contributors** → the improvement-action **owners** who update actions/evidence.
   - **Compliance Manager Readers** → oversight/auditors and any external **C3PAO reader**, **read-only**.
2. Or manage membership with `CMMC-Set-Scope.ps1` — it composes `Add-RoleGroupMember` /
   `Remove-RoleGroupMember`. **It runs with `-WhatIf` by default** and prints exactly what it would
   change; add `-Commit` to apply. Grant the **minimum** role each person needs.
3. **Pass/fail gate:** each person holds the least-privilege role; administrators are separated from
   contributors; readers/auditors are read-only. Re-run `CMMC-Discovery.ps1` and confirm the
   `CMMC Roles – Separation Evidence` snapshot. **Rollback:** remove any over-granted membership with
   `CMMC-Set-Scope.ps1 -Commit`.

## Step 3 — Design the assessment, CUI boundary, and owners (Design)
1. With the governance owners, confirm the **target CMMC level** and the **in-scope NIST 800-171
   requirements** (Requirement 2.4), and the **CUI boundary/enclave** and **SSP** (Requirement 2.5).
   **Applicability, the level, and the boundary are the owners' determinations**, not technical
   defaults.
2. Decide how domains are **grouped** (by the 14 NIST 800-171 families) so control mapping and
   reporting are coherent, and assign a **business owner** per domain.
3. Record the design as `CMMC Scope – Record` (target level, CUI boundary, SSP reference, in-/out-of-
   scope requirements, grouping, owners).

## Step 4 — Create the pilot assessment (Configure — pilot-first)
1. Portal → **Compliance Manager → Assessments → Add assessment**: create
   `CMMC Assessment – NIST 800-171 – Pilot` from the **CMMC Level 2** / **NIST SP 800-171** template, in
   the agreed group. (The premium template requires the entitlement from Requirement 2.1.)
2. **Keep the pilot to one assessment.** Validating one CMMC assessment end-to-end — ownership,
   evidence, automatic testing — proves the model before you build the production set. Compliance
   Manager does not change your tenant, so creating the assessment is safe; the *work* it surfaces (the
   improvement actions) is what you pilot.
3. **Pass/fail gate:** the pilot assessment exists in the correct group with an owner, and its
   improvement actions and current score are visible. Fail → check template availability/licensing/cloud.
   **Rollback:** an assessment can be removed in the portal without affecting tenant configuration.

## Step 5 — Build the action plan, control map, and evidence register (Configure)
1. For `CMMC Assessment – NIST 800-171 – Pilot`, assign each **improvement action** an **owner**, a
   **target date**, and an **implementation status**, in the portal (action → **Assign** / edit).
2. Use `CMMC-Configuration.ps1` to build the tracking artifacts from the owner-provided list — it
   validates the plan and, with `-Commit`, writes the local `CMMC Action Plan – Pilot`,
   `CMMC Control Map – NIST 800-171` (requirement/family → action → owner → evidence), and
   `CMMC Evidence – Register` files. **It runs with `-WhatIf` by default** and only *describes* the
   plan; **it makes no tenant changes** — Compliance Manager has no write API, so assignments and
   evidence upload happen in the portal, driven by these artifacts.
3. Attach **evidence** to each action in the portal (documents, test results, SSP/POA&M references) and
   record its source in the register.
4. **Pass/fail gate:** every pilot action is mapped to its NIST 800-171 requirement/family and has an
   owner, a target date, a status, and a named evidence source. Fail → complete the plan before
   validating.

## Step 6 — Enable automatic testing where it applies (Configure)
1. Portal → **Compliance Manager → Settings**: set the **automatic testing** option
   (`CMMC Automatic Testing – Setting`) per the governance owners' decision (Requirement 2.7). Eligible
   improvement actions will update their **test status** from your Microsoft 365 configuration signals.
2. Run `CMMC-Validation.ps1` (read-only) to confirm the **underlying technical signals** the automatable
   NIST 800-171 actions depend on are present — e.g. **unified audit logging enabled** (AU),
   **Conditional Access / MFA** configured (AC/IA), **DLP / retention / sensitivity-label / encryption**
   policies present (MP/SC). This tells you which actions can auto-pass and which still need **manual**
   evidence.
3. **Pass/fail gate:** automatic testing is set as agreed, and you know which actions are auto-tested vs
   manual-evidence. Fail → enable automatic testing or record the manual-evidence actions.

## Step 7 — Validate the evidence behind the actions (Pilot → Validate)
1. Run the Testing Guide (`05-testing.md`). Confirm: the pilot assessment shows a score; each action's
   **implementation** and **test** status is set with **evidence**; automatic-tested actions reflect
   the real technical state (cross-checked by `CMMC-Validation.ps1`); role separation holds.
2. Where an action recommends a **technical change** (enable audit, add a DLP/retention/label/encryption
   policy, tighten Conditional Access/MFA), **pilot that change in simulation/test first** under its own
   change control — those high-impact changes are owned by their feature's solution, not switched on
   blind here. Re-run `CMMC-Validation.ps1` to capture the new evidence.
3. Run `CMMC-Report.ps1` for the `CMMC Score Posture – Report` (score, action-status rollup, control-map
   coverage by NIST 800-171 family, evidence register, role separation, licensing).
4. **Pass/fail gate:** the pilot assessment is fully owned, evidenced, and tested; automatic testing
   reflects reality; the posture report is accurate. Fail → complete evidence/testing and re-validate.
   **Whether the posture satisfies CMMC is a compliance/C3PAO determination, not this gate.**

## Step 8 — Expand to the full CMMC set and run the cadence (Expand)
1. With the governance owners, create the production assessment(s) — `CMMC Assessment – Level 2 –
   Production` (and any additional frameworks) — from the licensed template(s), in the agreed grouping.
   **Lean on control mapping:** actions already implemented in the pilot often satisfy the same NIST
   800-171 requirement in the production assessment automatically (shared controls), so the incremental
   effort is the *gap*.
2. Extend the **action plan**, **control map**, and **evidence register** to the production assessment
   (owners, dates, evidence) with `CMMC-Configuration.ps1`.
3. Stand up the **maintenance cadence** toward the C3PAO assessment: periodic re-test/re-evidence of
   actions, review of owners (joiners/leavers), keeping the **SSP/POA&M** current, watching for
   **template/regulation updates** Microsoft publishes, and re-running `CMMC-Report.ps1` on a schedule
   for the posture trend.
4. **Pass/fail gate:** the full in-scope set exists, is owned and evidenced, automatic testing is
   running, and a recurring review is scheduled. **Rollback:** any assessment can be removed in the
   portal without touching tenant configuration; scope can be narrowed at any time.

---

### What this guide does NOT decide
- **CMMC applicability, the target level, whether the evidence satisfies a requirement, the NIST
  800-171 DoD Assessment Methodology / SPRS score, and certification** — these are
  **compliance/security/legal/C3PAO determinations**. This guide configures the assessment, the action
  plan, the control map, and the evidence, and produces the score and posture; adequacy, scoring, and
  sign-off belong to those functions and the assessor.
- **The high-impact technical changes an action recommends** — enabling audit, DLP, retention, labels,
  encryption, Conditional Access/MFA, etc. are **separate, piloted-in-simulation** changes owned by
  their own solution; Compliance Manager only measures whether they are in place.

### Order of operations
`Baseline → roles (separation) → design scope/boundary/owners → create pilot assessment → action plan + control map + evidence → automatic testing → validate evidence → posture report → expand to production + cadence`
