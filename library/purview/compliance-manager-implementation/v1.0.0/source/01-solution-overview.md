# 1. Solution Overview — Microsoft Purview Compliance Manager Implementation

## What this solution is
**Compliance Manager** is the Microsoft Purview capability that turns your compliance posture into a
**measured, points-based score** you can manage. It provides **assessments** (a set of controls drawn
from a regulation, standard, or internal policy, built from a **template**), **improvement actions**
(the specific technical and operational steps that raise the score), **control mapping** (one action
can satisfy a control that appears in many assessments), and an **evidence** store (documentation,
test results, owners, and dates attached to each action). The result is a **Compliance Score** and a
defensible record of what is implemented, by whom, tested when, with proof.

This solution is a repeatable, deploy-it-today way to stand Compliance Manager up correctly: capture
the **baseline** score, design the **assessments and scope** with your compliance stakeholders, build
the **improvement-action plan** with owners and evidence, turn on **automatic testing** where it
applies, validate the technical evidence behind the actions, and then expand to the full assessment
set with a maintenance cadence. It uses only the **Microsoft Purview portal**, **Security & Compliance
PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **Compliance Manager measures; it does not enforce.** Compliance Manager is an **assessment and
> scoring** tool — it reads your posture, recommends improvement actions, and records evidence. It does
> **not** change tenant configuration or block anything. The *technical* changes an improvement action
> recommends (enabling audit, DLP, MFA, retention, labels, etc.) are made in those features — and,
> because several are **high-impact**, they are **piloted in simulation/test first** under their own
> change control. This solution stands up the measurement, ownership, and evidence discipline; the
> enforcement of any given control is a separate, piloted change.

## Why this matters
- **Compliance status is a guess without a score.** "Are we compliant?" has no defensible answer
  without a control-by-control assessment. Compliance Manager makes it a **measured number** backed by
  evidence, so gaps are visible, owned, and tracked instead of discovered in an audit.
- **Evidence is the deliverable auditors want.** A score is only defensible if each improvement action
  carries **who owns it, its implementation status, its test status/date, and the proof**. Compliance
  Manager centralizes that record; this solution makes producing it a routine, not a fire drill.
- **Control mapping avoids duplicated effort.** One well-implemented control (say, unified audit
  logging) can satisfy requirements across NIST, ISO, HIPAA, and your internal baseline at once.
  Compliance Manager's **shared/control mapping** shows that leverage so you fix once and score many.
- **Regulatory applicability is not a technical call.** *Which* regulations apply, *which* controls are
  in scope, and *whether* the evidence satisfies the obligation are **compliance/records/privacy/legal
  determinations**. This solution provides the configuration method and the evidence; it does not
  decide applicability or sign off on adequacy.

## How it works
1. **Baseline the score (Assess).** The default **Data Protection Baseline** assessment is present for
   all Microsoft 365 tenants; capture the current **Compliance Score**, the improvement actions, and
   the role/licensing readiness as the starting point (`CM Roles – Separation Evidence`).
2. **Design the assessments and scope (Design).** With compliance stakeholders, decide which
   **assessment templates** are in scope (the included baseline plus any **premium templates** — NIST
   800-53, ISO 27001, HIPAA/HITECH, GDPR, etc. — that your licensing entitles), how assessments are
   **grouped**, and who **owns** each area. Regulatory applicability is the stakeholders' call.
3. **Populate roles with separation (Configure — guardrails).** The Compliance Manager role groups are
   assigned least-privilege so the people who *administer* Compliance Manager are separated from those
   who *contribute* action updates and those who only *read* — the auditable access record.
4. **Create the assessments and the action plan (Configure).** Create the in-scope assessments from
   their templates in the portal, then build the **improvement-action plan** (`CM Action Plan – Pilot`):
   each action assigned an **owner**, a **target date**, an **implementation status**, and a **test
   status**, with **evidence** attached.
5. **Turn on automatic testing where it applies (Configure).** Compliance Manager can **automatically
   test** certain improvement actions by reading signals from your Microsoft 365 configuration
   (continuous monitoring) — enable it so technical actions update their status without manual re-checks
   (`CM Automatic Testing – Setting`). Availability is plan/action-dependent; verify.
6. **Validate the evidence (Pilot → Validate).** Confirm the **technical state** behind the actions
   (audit enabled, DLP/retention/label/CA present, etc.) matches what the assessment claims, attach the
   evidence, and set test status/date — piloting any *technical* remediation in simulation/test first.
7. **Report and expand (Validate → Expand).** Roll up the score posture, evidence register, and role
   separation (`CM Score Posture – Report`); then add the remaining assessments and stand up the
   **maintenance cadence** (re-test, re-evidence, review owners, watch template/regulation updates).

## The four building blocks (what Compliance Manager gives you)
- **Assessments** — a grouping of controls from a **template** (a regulation, standard, or policy).
  The **Data Protection Baseline** is included; **premium templates** are licensing-gated, and you can
  build **custom templates** to add your own or non-Microsoft controls.
- **Improvement actions** — the recommended steps that raise the score. Each has **points**,
  **implementation status** (Not implemented / Implemented / Alternative / Planned / Out of scope),
  **test status** (Not assessed / Passed / Failed…), an **owner**, and **evidence**. Actions are
  **customer-managed** (yours) or **Microsoft-managed** (Microsoft's shared responsibility).
- **Controls & control mapping** — a control is a requirement of a regulation/standard; the **same**
  control (and the action that satisfies it) can appear across **many** assessments, so one fix scores
  in several places (shared / control mapping).
- **Evidence & the score** — points accrue as actions are implemented and tested; **evidence**
  (documents, test results, owner, date) attached to each action is the defensible audit trail. The
  **authoritative score and export** live in the Compliance Manager area of the portal.

## The role-separation model (least privilege)
| Role group | Who | Can (typical) |
|---|---|---|
| **Compliance Manager Administrators** | Program owners / IT config | Read and edit all Compliance Manager data; manage settings, templates, and role assignment |
| **Compliance Manager Assessors** | Assessment leads | Read data, **create assessments**, implement improvement actions, and edit **test** status |
| **Compliance Manager Contributors** | Action owners | Read data, create assessments, and **edit improvement actions** (not test status) |
| **Compliance Manager Readers** | Oversight / auditors | **Read-only** access to Compliance Manager data |
> Global Administrator, Compliance Administrator, and Compliance Data Administrator also have access.
> **Verify the exact role/role-group names and rights in your tenant** — Purview role naming and
> Compliance Manager permissions evolve; do not assume. Least privilege is the point: assessors and
> contributors should not need administrator rights, and readers/auditors get read-only.

## What you can control
- The **assessment templates** in scope (the included baseline plus licensed premium/custom templates)
  and how assessments are **grouped**.
- The **improvement-action plan** — owners, target dates, implementation status, test status, and the
  **evidence** attached to each action.
- Whether **automatic testing** of eligible actions is on, so technical actions self-update.
- The **role-group membership** that enforces least-privilege separation.
- The **pilot subset** (a single baseline assessment) validated first before the full set is built.

## Limitations (be honest with buyers)
- **It measures, it doesn't enforce.** Compliance Manager scores and recommends; it does **not** change
  your tenant. Acting on an improvement action is a **separate** configuration change (piloted in
  simulation/test where high-impact) owned by that feature's solution.
- **Premium content is licensing-gated.** The **Data Protection Baseline** is included; **premium
  assessment templates** (NIST, ISO, HIPAA, GDPR, etc.) require **Microsoft 365 E5 / E5 Compliance**
  or the **Compliance Manager Premium Assessment Add-On**, and the **number** of premium assessments
  available depends on your licensing/seat count. **Verify entitlement — do not assume a template is
  available.**
- **Portal-driven.** Assessments, improvement actions, evidence upload, and the authoritative score are
  managed in the **Purview portal**. Compliance Manager does **not** expose a broad public
  PowerShell/Graph API to create assessments or set action status programmatically; the provided
  scripts assess **readiness, roles, and the technical evidence** behind actions and structure the
  action/evidence plan — they do not replace the portal.
- **Automatic testing is partial.** Only **eligible** improvement actions auto-test from Microsoft 365
  signals; others require manual implementation/test and uploaded evidence. Availability is
  plan/action-dependent — verify.
- **Applicability and adequacy are not technical.** *Which* regulations apply and *whether* evidence
  satisfies them are **compliance/records/privacy/legal** determinations, not outputs of this tool.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates or tracks is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Baseline assessment (pilot) | `CM Assessment – Baseline – Pilot` |
| Production assessment (per regulation) | `CM Assessment – <Regulation> – Production` |
| Improvement-action plan (pilot) | `CM Action Plan – Pilot` |
| Evidence register | `CM Evidence – Register` |
| Automatic-testing setting | `CM Automatic Testing – Setting` |
| Score posture report | `CM Score Posture – Report` |
| Role-separation evidence snapshot | `CM Roles – Separation Evidence` |
| Assessment scope / owners record | `CM Scope – Record` |

## The standard deployment model
> Baseline the score → design the in-scope assessments, grouping, and owners → configure roles
> (separation), create assessments, build the action plan, enable automatic testing → validate the
> evidence behind the actions (piloting any technical remediation in simulation/test) → report the
> posture → expand to the full assessment set and run the maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** —
> regulatory applicability and adequacy deferred to compliance/records/privacy/legal at every step.
