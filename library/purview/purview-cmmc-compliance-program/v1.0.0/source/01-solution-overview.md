# 1. Solution Overview — Microsoft Purview CMMC Compliance Program

## What this solution is
The **Cybersecurity Maturity Model Certification (CMMC)** program requires organizations in the U.S.
Defense Industrial Base that handle **Controlled Unclassified Information (CUI)** to implement — and
**evidence** — a defined set of security controls. **CMMC Level 2** aligns to the **110 security
requirements of NIST SP 800-171**, organized into **14 control families/domains** (Access Control,
Audit & Accountability, Configuration Management, Identification & Authentication, and so on).

This solution stands up a **Purview-backed CMMC compliance program** using **Microsoft Purview
Compliance Manager**: it uses the **CMMC Level 2** (and/or **NIST SP 800-171**) **assessment template**
to turn CMMC obligations into a **measured, points-based posture**; it maps each requirement to the
**control** and the **improvement action** that satisfies it, assigns an **owner**, and attaches
**evidence** (documentation, test results, dates); and it validates the **technical evidence** behind
the actions from your Microsoft 365 configuration. The result is a **defensible, evidenced CMMC
control record** — configured, piloted on a single assessment first, validated, then expanded — using
only the **Microsoft Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`),
and **Microsoft Graph**.

> **What this does — and does not — do.** This solution delivers the **program**: control mapping,
> configured controls, the ownership/evidence discipline, and the score. It does **not** issue a CMMC
> certification, produce a formal **assessment determination**, or replace the **C3PAO** (CMMC
> Third-Party Assessment Organization) assessment. **C3PAO assessment and certification
> determinations are deferred to the assessor and to your compliance/security governance.** Compliance
> Manager *measures* your posture; the *technical* changes an improvement action recommends (enabling
> audit, DLP, MFA/Conditional Access, retention, labels, encryption) are made in those features and,
> because several are **high-impact**, are **piloted in simulation/test first** under their own change
> control.

## Why this matters
- **"Are we CMMC-ready?" needs a number, not a guess.** Without a control-by-control assessment,
  CMMC readiness is unknowable. Compliance Manager makes it a **measured posture** backed by evidence,
  so gaps against the 110 NIST 800-171 requirements are visible, owned, and tracked — not discovered by
  a C3PAO.
- **Evidence is the deliverable the assessor wants.** A CMMC posture is only defensible if each
  requirement carries **who owns it, its implementation status, its test status/date, and the proof**.
  This solution centralizes that record (`CMMC Evidence – Register`) so producing it is a routine, not
  a scramble.
- **Control mapping avoids duplicated effort.** One well-implemented control (say, unified audit
  logging, which satisfies the **Audit & Accountability (AU)** family) can also map to your NIST
  800-53, ISO 27001, or internal baseline. Compliance Manager's **shared/control mapping** shows that
  leverage so you fix once and score in several frameworks.
- **The determination is not a technical call.** *Whether* your evidence satisfies a CMMC requirement,
  your **NIST 800-171 DoD Assessment Methodology** score, your **SPRS** submission, and your
  certification level are **assessor/compliance/legal determinations**. This solution provides the
  configuration method and the evidence; it does not score you for the DoD or sign off on adequacy.

## How it works
1. **Baseline the posture (Assess).** Capture the current **Compliance Score**, the Compliance Manager
   role/licensing readiness, and the state of the technical signals that back CMMC controls
   (`CMMC Roles – Separation Evidence`, `CMMC-Discovery.ps1`).
2. **Design the assessment and scope (Design).** With compliance/security stakeholders, confirm the
   **CMMC Level 2** (and/or **NIST SP 800-171**) assessment template is licensed and available, agree
   the **CUI boundary/enclave** in scope, and record which requirements are in- or out-of-scope
   (`CMMC Scope – Record`). **Which requirements apply and the certification level sought are the
   stakeholders' call.**
3. **Populate roles with separation (Configure — guardrails).** Assign the Compliance Manager role
   groups least-privilege so **administrators** are separated from action **contributors** and
   read-only **readers/auditors** — the auditable access record.
4. **Create the assessment and the action plan (Configure).** Create `CMMC Assessment – NIST 800-171 –
   Pilot` from the template, then build the **improvement-action plan** (`CMMC Action Plan – Pilot`):
   each action assigned an **owner**, a **target date**, an **implementation status**, and a **test
   status**, with **evidence** attached, indexed to its NIST 800-171 requirement (`CMMC Control Map –
   NIST 800-171`).
5. **Turn on automatic testing where it applies (Configure).** Compliance Manager can **automatically
   test** eligible improvement actions from your Microsoft 365 configuration signals; enable it so
   technical actions update status without manual re-checks (`CMMC Automatic Testing – Setting`).
   Availability is plan/action-dependent — verify.
6. **Validate the evidence (Pilot → Validate).** Confirm the **technical state** behind the actions
   (audit enabled, DLP/retention/labels present, Conditional Access/MFA configured) matches what the
   assessment claims, attach evidence, and set test status/date — piloting any *technical* remediation
   in simulation/test first (`CMMC-Validation.ps1`).
7. **Report and expand (Validate → Expand).** Roll up the posture, evidence register, and role
   separation (`CMMC Score Posture – Report`); then complete the remaining CMMC domains/assessments
   and stand up the **maintenance cadence** (re-test, re-evidence, review owners, watch for
   template/regulation updates ahead of the C3PAO assessment).

## The building blocks (what Compliance Manager gives you for CMMC)
- **Assessment** — the **CMMC Level 2** / **NIST SP 800-171** template's controls as a scored
  assessment. **Verify the exact template name and availability in your tenant** — template naming and
  the CMMC model evolve; do not assume.
- **Improvement actions** — the recommended steps that raise the score, each with **points**,
  **implementation status** (Not implemented / Implemented / Alternative / Planned / Out of scope),
  **test status**, an **owner**, and **evidence**. Actions are **customer-managed** (yours) or
  **Microsoft-managed** (Microsoft's shared responsibility for the platform).
- **Controls & control mapping** — each NIST 800-171 requirement is a control; the **same** control
  can appear across many assessments, so one fix scores in several frameworks (shared/control mapping).
- **Evidence & the score** — points accrue as actions are implemented and tested; **evidence**
  attached to each action is the defensible audit trail. The **authoritative score and export** live
  in the Compliance Manager area of the portal.

## The role-separation model (least privilege)
| Role group | Who | Can (typical) |
|---|---|---|
| **Compliance Manager Administrators** | Program owners / IT config | Read and edit all Compliance Manager data; manage settings, templates, and role assignment |
| **Compliance Manager Assessors** | Assessment leads | Read data, **create assessments**, implement improvement actions, and edit **test** status |
| **Compliance Manager Contributors** | Action owners | Read data, create assessments, and **edit improvement actions** (not test status) |
| **Compliance Manager Readers** | Oversight / assessors / auditors | **Read-only** access to Compliance Manager data |
> Global Administrator, Compliance Administrator, and Compliance Data Administrator also have access.
> **Verify the exact role/role-group names and rights in your tenant** — Purview role naming and
> Compliance Manager permissions evolve. Least privilege is the point: assessors/contributors should
> not need administrator rights, and readers/auditors get read-only.

## Limitations (be honest with buyers)
- **It measures, it doesn't certify.** Compliance Manager scores and recommends; it does **not** change
  your tenant, produce a CMMC certification, or replace the **C3PAO assessment**. Certification and the
  formal assessment determination are the assessor's; acting on an improvement action is a **separate**,
  piloted configuration change owned by that feature's solution.
- **Premium/CMMC templates are licensing-gated.** The **Data Protection Baseline** is included; the
  **CMMC Level 2 / NIST SP 800-171** and other **premium assessment templates** require **Microsoft 365
  E5 / E5 Compliance** or the **Compliance Manager Premium Assessment Add-On**, and the **number** of
  premium assessments depends on your licensing/seat count. **Verify entitlement — do not assume a
  template is available.**
- **CUI often means a sovereign cloud.** Many CMMC-regulated organizations must run CUI workloads in
  **GCC High** (or GCC). Feature availability, template naming, and portal paths **differ** in
  government clouds — **verify against your tenant/cloud**.
- **Portal-driven.** Assessments, improvement actions, evidence upload, and the authoritative score are
  managed in the **Purview portal**. Compliance Manager does **not** expose a broad public
  PowerShell/Graph API to create assessments or set action status programmatically; the provided
  scripts assess **readiness, roles, and the technical evidence** behind actions and structure the
  action/evidence/control-map plan — they do not replace the portal.
- **Automatic testing is partial.** Only **eligible** actions auto-test from Microsoft 365 signals;
  others require manual implementation/test and uploaded evidence. Availability is plan/action-dependent
  — verify.
- **Applicability, adequacy, and the SPRS score are not technical.** *Which* requirements apply,
  *whether* evidence satisfies them, your **NIST 800-171 DoD Assessment Methodology** score, and the
  **SPRS** submission are **compliance/security/legal/assessor** determinations, not outputs of this
  tool.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates or tracks is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal:

| Artifact | Name |
|---|---|
| Assessment (pilot) | `CMMC Assessment – NIST 800-171 – Pilot` |
| Assessment (production) | `CMMC Assessment – Level 2 – Production` |
| Improvement-action plan (pilot) | `CMMC Action Plan – Pilot` |
| Control map (requirement → action → evidence) | `CMMC Control Map – NIST 800-171` |
| Evidence register | `CMMC Evidence – Register` |
| Automatic-testing setting | `CMMC Automatic Testing – Setting` |
| Score posture report | `CMMC Score Posture – Report` |
| Role-separation evidence snapshot | `CMMC Roles – Separation Evidence` |
| Scope / CUI-boundary record | `CMMC Scope – Record` |

## The standard deployment model
> Baseline the posture → design the in-scope CMMC/NIST 800-171 assessment, CUI boundary, and owners →
> configure roles (separation), create the assessment, build the action plan + control map, enable
> automatic testing → validate the evidence behind the actions (piloting any technical remediation in
> simulation/test) → report the posture → expand to the full domain set and run the maintenance cadence
> toward the C3PAO assessment.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** — CMMC
> certification, assessment determinations, and SPRS scoring deferred to the C3PAO and to
> compliance/security/legal at every step.
