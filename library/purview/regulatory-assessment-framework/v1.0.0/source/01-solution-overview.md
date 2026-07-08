# 1. Solution Overview — Regulatory Assessment Framework (Microsoft Purview)

## What this solution is
Most organizations assess each regulation in a **silo**: a separate audit for HIPAA, another for NIST
800-53, another for ISO 27001, another for a state privacy law — each re-testing the *same* underlying
controls (audit logging, DLP, retention, encryption, MFA) as if they were unrelated. That is
duplicated effort, inconsistent evidence, and a compliance gap when the frameworks drift out of sync.

This solution builds a **Regulatory Assessment Framework** in **Microsoft Purview Compliance Manager**:
you define a **canonical set of shared controls** once, **cross-walk** each control to the regulations
it satisfies, and let Compliance Manager's **control mapping** score that single implementation across
**many** assessments at once. The result is *map once, assess many* — one owned, evidenced control set
that produces a defensible Compliance Score against every regulation in scope, with the incremental
work reduced to each new framework's **gap**. It uses only the **Microsoft Purview portal**, **Security
& Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **Compliance Manager measures; it does not enforce.** Compliance Manager is an **assessment and
> scoring** tool — it reads posture, recommends improvement actions, maps shared controls, and stores
> evidence. It does **not** change tenant configuration or block anything. The *technical* changes a
> shared control depends on (enabling audit, DLP, retention, labels, Conditional Access/MFA) are made in
> those features — and, because several are **high-impact**, they are **piloted in simulation/test
> first** under their own change control. This framework stands up the mapping, ownership, and evidence
> discipline; enforcing any given control is a separate, piloted change owned by that feature's solution.

## Why this matters
- **Silos duplicate work and produce inconsistent evidence.** Assessing each regulation independently
  re-tests the same controls repeatedly and lets the "same" control be evidenced three different ways.
  A shared-control framework tests once and evidences once — consistently — across every framework.
- **Shared controls are where the leverage is.** A single well-implemented control (e.g. unified audit
  logging) can satisfy requirements in NIST, ISO, HIPAA, GDPR, and an internal baseline simultaneously.
  Compliance Manager's **control mapping** surfaces that leverage; this framework makes it the operating
  model, so you fix once and score many.
- **A crosswalk makes coverage and gaps visible.** Mapping each canonical control to the regulations it
  serves produces a **coverage matrix**: you can see, per regulation, exactly which controls are
  satisfied by shared work and which are the framework-specific **gap** that still needs attention.
- **Applicability and adequacy are not technical calls.** *Which* regulations apply, *which* controls
  are in scope, and *whether* the evidence satisfies the obligation are **compliance/records/privacy/
  legal determinations**. This solution provides the mapping method, the configuration, and the
  evidence; it does not decide applicability or sign off on adequacy.

## How it works
1. **Baseline and inventory (Assess).** Capture the current **Compliance Score** and the included
   **Data Protection Baseline** assessment, read the licensing that gates premium templates, and
   snapshot Compliance Manager role separation (`RAF Roles – Separation Evidence`).
2. **Define the canonical control set (Design).** With compliance stakeholders, agree the **shared
   control set** the organization will manage centrally (`RAF Control Set – Canonical`) — the controls
   that recur across the in-scope regulations (audit, DLP, retention, encryption/labels, access/MFA,
   etc.).
3. **Build the crosswalk (Design).** Map each canonical control to the **regulations/standards** it
   satisfies (`RAF Crosswalk – Register`) — this is the map-once artifact that drives *assess-many*.
   Regulatory applicability is the stakeholders' call.
4. **Configure roles with separation (Configure — guardrails).** Populate the Compliance Manager role
   groups least-privilege so administrators are separated from action contributors and read-only
   readers/auditors — the auditable access record.
5. **Create the assessment group and pilot one framework (Configure — pilot-first).** Create a
   multi-regulation **assessment group** (`RAF Group – <Program>`) and, within it, a **pilot**
   assessment (`RAF Assessment – <Regulation> – Pilot`) from a licensed template; validate the shared
   controls end-to-end before expanding.
6. **Implement the shared controls and evidence them (Pilot → Validate).** Own each shared control
   (`RAF Action Plan – Shared`), attach evidence (`RAF Evidence – Register`), enable **automatic
   testing** where eligible, and confirm the technical state behind each control — piloting any
   *technical* remediation in simulation/test first.
7. **Report coverage and expand (Validate → Expand).** Produce the **coverage matrix**
   (`RAF Coverage – Matrix`) — per regulation, how much is covered by shared controls vs the remaining
   gap — then add the remaining regulation assessments to the group and run the maintenance cadence.

## The building blocks (what Compliance Manager gives you)
- **Assessments** — a grouping of controls from a **template** (a regulation, standard, or policy). The
  **Data Protection Baseline** is included; **premium templates** (NIST 800-53, ISO 27001, HIPAA/HITECH,
  GDPR, and hundreds more) are licensing-gated; you can build **custom templates** for frameworks
  Microsoft does not ship.
- **Improvement actions** — the recommended steps that raise the score. Each has **points**,
  **implementation status**, **test status**, an **owner**, and **evidence**. Actions are
  **customer-managed** (yours) or **Microsoft-managed** (Microsoft's shared responsibility).
- **Controls & control mapping** — a control is a requirement of a regulation/standard; the **same**
  control (and the action that satisfies it) can appear across **many** assessments. This mapping is the
  engine of *map once, assess many* — the framework this solution builds around it.
- **Assessment groups** — a way to group related assessments (here, all the regulations in one program)
  so shared controls and reporting stay coherent across the framework.
- **Evidence & the score** — points accrue as actions are implemented and tested; **evidence**
  (documents, test results, owner, date) attached to each action is the defensible audit trail. The
  **authoritative score and export** live in the Compliance Manager area of the portal.

## The role-separation model (least privilege)
| Role group | Who | Can (typical) |
|---|---|---|
| **Compliance Manager Administrators** | Program owners / IT config | Read and edit all Compliance Manager data; manage settings, templates, groups, and role assignment |
| **Compliance Manager Assessors** | Assessment leads | Read data, **create assessments**, implement improvement actions, and edit **test** status |
| **Compliance Manager Contributors** | Control/action owners | Read data, create assessments, and **edit improvement actions** (not test status) |
| **Compliance Manager Readers** | Oversight / auditors | **Read-only** access to Compliance Manager data |
> Global Administrator, Compliance Administrator, and Compliance Data Administrator also have access.
> **Verify the exact role/role-group names and rights in your tenant** — Purview role naming and
> Compliance Manager permissions evolve; do not assume. Least privilege is the point: assessors and
> contributors should not need administrator rights, and readers/auditors get read-only.

## What you can control
- The **canonical shared-control set** the organization manages centrally, and the **crosswalk** that
  maps each control to the regulations it satisfies.
- The **regulation assessments** in scope (baseline + licensed premium/custom templates) and how they
  are **grouped** into the framework program.
- The **shared-control action plan** — owners, target dates, implementation status, test status, and the
  **evidence** attached to each control.
- Whether **automatic testing** of eligible actions is on, so technical shared controls self-update.
- The **role-group membership** that enforces least-privilege separation.
- The **pilot subset** (one regulation assessment) validated first before the full set is built.

## Limitations (be honest with buyers)
- **It measures, it doesn't enforce.** Compliance Manager scores and recommends; it does **not** change
  your tenant. Implementing a shared control is a **separate** configuration change (piloted in
  simulation/test where high-impact) owned by that feature's solution.
- **Premium content is licensing-gated.** The **Data Protection Baseline** is included; **premium
  assessment templates** require **Microsoft 365 E5 / E5 Compliance** or the **Compliance Manager
  Premium Assessment Add-On**, and the **number** of premium assessments available depends on your
  licensing/seat count. **Verify entitlement — do not assume a template is available.**
- **Portal-driven; no broad write API.** Assessments, groups, improvement actions, evidence upload, and
  the authoritative score are managed in the **Purview portal**. Compliance Manager does **not** expose a
  broad public PowerShell/Graph API to create assessments, set action status, or push a crosswalk; the
  provided scripts assess **readiness, roles, licensing, and the technical evidence** behind shared
  controls and **structure the crosswalk/coverage locally** — they do not replace the portal.
- **Control mapping is not automatic across every custom framework.** Microsoft maintains the mapping
  for its shipped templates; for **custom templates** you define the control-to-action mapping yourself.
  The crosswalk this solution builds is the plan that makes that mapping deliberate.
- **Automatic testing is partial.** Only **eligible** improvement actions auto-test from Microsoft 365
  signals; others require manual implementation/test and uploaded evidence. Availability is
  plan/action-dependent — verify.
- **Applicability and adequacy are not technical.** *Which* regulations apply and *whether* evidence
  satisfies them are **compliance/records/privacy/legal** determinations, not outputs of this tool.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in; they never
  embed credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates or tracks is named `RAF <Purpose> – <Scope>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Canonical shared-control set | `RAF Control Set – Canonical` |
| Control-to-regulation crosswalk | `RAF Crosswalk – Register` |
| Multi-regulation assessment group | `RAF Group – <Program>` |
| Pilot regulation assessment | `RAF Assessment – <Regulation> – Pilot` |
| Production regulation assessment | `RAF Assessment – <Regulation> – Production` |
| Shared-control action plan | `RAF Action Plan – Shared` |
| Evidence register | `RAF Evidence – Register` |
| Cross-framework coverage matrix | `RAF Coverage – Matrix` |
| Automatic-testing setting | `RAF Automatic Testing – Setting` |
| Role-separation evidence snapshot | `RAF Roles – Separation Evidence` |
| Framework scope / owners record | `RAF Scope – Record` |

## The standard deployment model
> Baseline the score and inventory licensing/roles → define the canonical shared-control set and build
> the crosswalk to each regulation → configure roles (separation), create the assessment group, and
> pilot one regulation assessment → implement and evidence the shared controls (piloting any technical
> remediation in simulation/test), enable automatic testing, validate → report the coverage matrix →
> expand to the full regulation set and run the maintenance cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand** —
> regulatory applicability and adequacy deferred to compliance/records/privacy/legal at every step.
