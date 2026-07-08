# 3. Implementation Guide — Regulatory Assessment Framework (Microsoft Purview)

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Compliance Manager**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`, for role groups and technical evidence) and **Microsoft
Graph** (for licensing and Conditional Access/MFA evidence). Artifact names follow the `RAF <Purpose> –
<Scope>` convention from the Overview and are reused verbatim. **Portal paths, template availability,
and cmdlets are plan-dependent and the portal evolves — verify against your tenant.**

> **Model:** Baseline and inventory → define the canonical shared-control set and the crosswalk →
> configure roles + the assessment group + the pilot regulation → implement and evidence the shared
> controls + automatic testing → validate → report the coverage matrix → expand to the full regulation
> set. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.**
> **Compliance Manager measures — it does not enforce.** Any *technical* remediation a shared control
> requires is a **separate, piloted change** owned by that feature's solution; and **regulatory
> applicability and evidence adequacy are compliance/records/privacy/legal determinations**, not
> decisions this guide makes.

---

## Step 1 — Baseline the score and inventory licensing/roles (Assess)
1. Confirm licensing (Requirement 2.1): in the portal → **Compliance Manager → Assessment templates**,
   confirm **each** regulation template you intend to map shows as available to create. **Verify
   entitlement with Microsoft licensing — do not assume.**
2. Run `CMPFRAME-Discovery.ps1` (read-only). It reports the licensing SKUs it can read, the membership of
   each Compliance Manager role group (the `RAF Roles – Separation Evidence` snapshot), and flags any
   administrator who is also a contributor. Note the current **Compliance Score** and the **Data
   Protection Baseline** improvement actions from the portal dashboard as your starting point.
3. **Pass/fail gate:** licensing confirmed for every regulation template in scope, the Compliance
   Manager role groups exist, and the baseline score is recorded. **Do not proceed** until the
   governance owners (Requirement 2.5) have confirmed which regulations apply and are in scope. Fail →
   resolve before designing the framework.

## Step 2 — Define the canonical shared-control set (Design)
1. With compliance/security stakeholders, agree the **shared controls** the organization will manage
   centrally (Requirement 2.2) — the controls that recur across the in-scope regulations (audit, DLP,
   retention/records, encryption/labels, access/MFA, incident response, classification, etc.).
2. Record them as `RAF Control Set – Canonical`, each with a clear technical meaning and a **control
   owner**. This is the *map-once* foundation — keep it tight and real; a control you can't evidence
   does not belong in the set.
3. **Pass/fail gate:** the canonical set is documented, owned, and signed off by compliance stakeholders.
   Fail → complete the set before building the crosswalk.

## Step 3 — Build the control-to-regulation crosswalk (Design)
1. Map **each canonical control** to the **regulations/standards** it satisfies (Requirement 2.3),
   producing `RAF Crosswalk – Register`. For Microsoft-shipped templates, control mapping is maintained
   by Microsoft (you confirm it); for **custom** templates, you define the mapping.
2. Run `CMPFRAME-Configuration.ps1` to **validate** the crosswalk from the owner-provided list and, with
   `-Commit`, write the local `RAF Crosswalk – Register` and `RAF Action Plan – Shared` files (control,
   mapped regulations, owner, target date, evidence source). **It runs with `-WhatIf` by default** and
   only *describes* the plan; **it makes no tenant changes** — Compliance Manager has no write API, so
   assessment creation and evidence upload happen in the portal, driven by these artifacts.
3. Record the framework scope, in-/out-of-scope controls, and named approvers as `RAF Scope – Record`.
4. **Pass/fail gate:** every canonical control maps to at least one regulation; every in-scope
   regulation lists its covering shared controls and the remaining **gap**. Fail → complete the crosswalk
   with compliance owners before configuring.

## Step 4 — Assign roles with least-privilege separation (Configure — guardrails)
1. Portal → `Settings → Roles & scopes → Permissions`: populate the Compliance Manager role groups
   (Requirement 2.4):
   - **Compliance Manager Administrators** → the program owners / IT config staff.
   - **Compliance Manager Assessors** → assessment leads who create assessments and set **test** status.
   - **Compliance Manager Contributors** → the shared-control **owners** who update actions/evidence.
   - **Compliance Manager Readers** → oversight/auditors, **read-only**.
2. Or manage membership with `CMPFRAME-Set-Scope.ps1` — it composes `Add-RoleGroupMember` /
   `Remove-RoleGroupMember`. **It runs with `-WhatIf` by default** and prints exactly what it would
   change; add `-Commit` to apply. Grant the **minimum** role each person needs.
3. **Pass/fail gate:** each person holds the least-privilege role; administrators are separated from
   contributors; readers/auditors are read-only. Re-run `CMPFRAME-Discovery.ps1` and confirm the
   `RAF Roles – Separation Evidence` snapshot. **Rollback:** remove any over-granted membership with
   `CMPFRAME-Set-Scope.ps1 -Commit`.

## Step 5 — Create the assessment group and the pilot regulation (Configure — pilot-first)
1. Portal → **Compliance Manager → Assessments**: create a multi-regulation **assessment group**
   `RAF Group – <Program>` (Requirement 2.6) that will hold the framework's regulations.
2. Within that group → **Add assessment**: create `RAF Assessment – <Regulation> – Pilot` from the pilot
   regulation's template (baseline, premium, or custom — subject to the entitlement from Requirement
   2.1).
3. **Keep the pilot to one regulation.** Validating one regulation end-to-end — shared-control coverage,
   evidence, automatic testing — proves the crosswalk model before you create the full framework set.
   Compliance Manager does not change your tenant, so creating the group/assessment is safe; the *work*
   it surfaces is what you pilot.
4. **Pass/fail gate:** the group exists and the pilot assessment is in it with an owner, and its
   improvement actions and current score are visible. Fail → check template availability/licensing.
   **Rollback:** a group/assessment can be removed in the portal without affecting tenant configuration.

## Step 6 — Implement and evidence the shared controls (Configure → Pilot)
1. For the pilot assessment, assign each **shared control's** improvement action an **owner**, a
   **target date**, and an **implementation status**, in the portal (action → **Assign** / edit),
   driven by `RAF Action Plan – Shared`.
2. Where a shared control depends on a **technical change** (enable audit, add a DLP/retention/label
   policy, tighten Conditional Access/MFA), **pilot that change in simulation/test first** under its own
   change control — those high-impact changes are owned by their feature's solution, not switched on
   blind here.
3. Attach **evidence** to each action in the portal (documents, test results) and record its source in
   `RAF Evidence – Register` (use `CMPFRAME-Configuration.ps1 -Commit` to structure the register from the
   owner-provided list; the upload itself is in the portal).
4. **Pass/fail gate:** every pilot shared control has an owner, a target date, a status, and a named
   evidence source; technical remediations were piloted in simulation/test. Fail → complete before
   validating.

## Step 7 — Enable automatic testing and validate the evidence (Pilot → Validate)
1. Portal → **Compliance Manager → Settings**: set the **automatic testing** option
   (`RAF Automatic Testing – Setting`) per the governance owners' decision (Requirement 2.7). Eligible
   improvement actions update their **test status** from your Microsoft 365 configuration signals.
2. Run `CMPFRAME-Validation.ps1` (read-only) to confirm the **underlying technical signals** the shared
   controls depend on are present — e.g. **unified audit logging enabled**, **DLP / retention /
   sensitivity-label** policies present, **Conditional Access / MFA** configured. This tells you which
   shared controls can auto-pass and which still need **manual** evidence, and cross-checks that
   auto-tested actions reflect the real technical state.
3. Run the Testing Guide (`05-testing.md`) to confirm score, ownership, evidence, automatic testing, and
   role separation for the pilot.
4. **Pass/fail gate:** the pilot regulation is fully owned, evidenced, and tested; automatic testing
   reflects reality; role separation holds. Fail → complete evidence/testing and re-validate.

## Step 8 — Report coverage and expand to the full regulation set (Validate → Expand)
1. Run `CMPFRAME-Report.ps1` for the `RAF Coverage – Matrix` — per regulation, how much is covered by
   the shared controls vs the remaining framework-specific **gap**, plus the shared-control leverage
   (how many regulations each control scores against), the evidence register, role separation, and
   licensing.
2. With the governance owners, create the remaining regulation assessments in the group —
   `RAF Assessment – <Regulation> – Production` — from their licensed templates. **Lean on control
   mapping:** shared controls already implemented for the pilot often satisfy controls in the new
   assessments automatically, so the incremental effort is each regulation's **gap**.
3. Extend the crosswalk, action plan, and evidence register to the new regulations (owners, dates,
   evidence) with `CMPFRAME-Configuration.ps1`.
4. Stand up the **maintenance cadence**: periodic re-test/re-evidence of shared controls, review of
   owners (joiners/leavers), watch for **template/regulation updates** Microsoft publishes (which can add
   controls and shift coverage), and re-run `CMPFRAME-Report.ps1` on a schedule for the coverage trend.
5. **Pass/fail gate:** the full in-scope regulation set exists in the group, shared controls are owned
   and evidenced, the coverage matrix is accurate, automatic testing is running, and a recurring review
   is scheduled. **Rollback:** any assessment/group can be removed in the portal without touching tenant
   configuration; scope can be narrowed at any time.

---

### What this guide does NOT decide
- **Which regulations/standards apply and whether the evidence satisfies them** — a
  **compliance/records/privacy/legal determination**. This guide builds the shared-control set, the
  crosswalk, the assessments, and the evidence, and produces the coverage matrix; adequacy and sign-off
  belong to those functions.
- **The high-impact technical changes a shared control requires** — enabling audit, DLP, retention,
  labels, Conditional Access, etc. are **separate, piloted-in-simulation** changes owned by their own
  solution; Compliance Manager only measures whether they are in place.
