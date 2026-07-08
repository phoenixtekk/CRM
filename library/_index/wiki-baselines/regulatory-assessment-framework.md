# Regulatory Assessment Framework — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: CMPFRAME

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Regulatory Assessment Framework (Microsoft Purview)

Most organizations assess each regulation in a **silo** — a separate audit for HIPAA, another for NIST
800-53, another for ISO 27001, another for a state privacy law — each re-testing the *same* underlying
controls as if they were unrelated. The cost is duplicated effort, inconsistent evidence, and a
compliance gap the moment the frameworks drift apart. Microsoft Purview **Compliance Manager** provides
the mechanism to end that: **control mapping**, where one implemented control scores across every
assessment that references it. This solution builds a **Regulatory Assessment Framework** around it —
define a canonical set of **shared controls** once, **cross-walk** each to the regulations it satisfies,
and **assess many** from one owned, evidenced implementation.

This is a complete, deploy-it-today package for standing up a multi-regulation compliance framework,
written for a competent Microsoft 365 / compliance administrator and built to be run **with** the
organization's compliance, records, privacy, and legal functions — who own **which** regulations apply
and **whether** the evidence satisfies them.

## What you get
- A plain-language **Solution Overview** of the framework — the building blocks (**assessments,
  improvement actions, control mapping, assessment groups, evidence**), the **canonical control set +
  crosswalk** model, the role-separation model, and the honest limits (it **measures, it doesn't
  enforce**; premium templates are licensing-gated; the portal is authoritative).
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: per-regulation
  template licensing, the canonical shared-control set, the control-to-regulation crosswalk, the
  separated role groups, named governance owners, the in-scope regulation set and group design,
  shared-control owners and evidence sources, automatic testing, and the pilot regulation.
- An **Implementation Guide** that baselines the score, defines the canonical control set, builds the
  **crosswalk**, assigns roles with least-privilege separation, creates a multi-regulation **assessment
  group** and a **pilot** regulation, implements and evidences the shared controls, enables **automatic
  testing**, validates, reports the **coverage matrix**, then expands to the full regulation set — with
  pass/fail gates and rollback at every step, and any high-impact technical remediation **piloted in
  simulation/test first**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): readiness + role-separation +
  licensing discovery, a crosswalk / shared-control-plan builder, a technical-evidence validator, a
  coverage-matrix report, and a role-membership helper — **read-only or `-WhatIf` by default, no
  secrets**.
- **Testing** and **Best Practices** that prove the crosswalk, shared-control coverage, evidence
  accuracy, and separation before anything expands.

## Why it matters
- **Map once, assess many.** A single well-implemented shared control satisfies requirements across every
  regulation that references it — the fastest, most defensible path to coverage across a whole framework
  set, with the incremental work reduced to each regulation's gap.
- **One evidence record, every framework.** Because controls are shared, owners, test dates, and proof
  are captured **once** and reused across all mapped regulations — consistent, not three different
  versions of the "same" control.
- **Coverage and gaps become visible.** The crosswalk and coverage matrix show, per regulation, exactly
  what shared controls satisfy and what still needs work — no more discovering a gap in an audit.
- **Measurement, not enforcement.** Compliance Manager changes nothing on the tenant; the technical
  changes shared controls depend on are separate, piloted changes — this solution keeps that boundary
  clear and safe.

## The bottom line
Many regulations turned into **one shared-control framework** in Microsoft Purview — mapped once, scored
many, owned, tested, and evidenced — **delivered, validated, and audit-ready.** A fraction of the cost of
a consulting engagement, self-guided and tested.

*Compliance Manager premium/custom templates are licensing-dependent (Microsoft 365 E5 / E5 Compliance /
Premium Assessment Add-On) and the Purview portal evolves; verify capability and template availability
against your own licensing and tenant. Regulatory applicability and whether the evidence satisfies an
obligation are deferred to your compliance, records, privacy, and legal functions.*


---


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


---


# 2. Requirements Guide — Regulatory Assessment Framework (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
framework-specific detail. **Licensing, template availability, and portal paths are plan-dependent and
the portal evolves — verify each against your own licensing and tenant.**

## 2.1 Licensing — base Compliance Manager and premium/custom templates for each in-scope regulation
**Description:** Compliance Manager and the **Data Protection Baseline** assessment are available to all
Microsoft 365 / Office 365 commercial subscriptions. Each **regulation-specific template** you intend to
put in the framework (NIST 800-53, ISO 27001, HIPAA/HITECH, GDPR, and hundreds more) plus **custom
templates** require **Microsoft 365 E5 / E5 Compliance** or the **Compliance Manager Premium Assessment
Add-On**; the **number** of premium assessments you can create is a function of your licensing / seat
entitlement. (GCC/GCC High and other sovereign clouds may differ.)
**Why:** The whole framework is *assess-many* — it only works if the templates for the regulations you
map to are actually available on your plan. A template you plan to assess against being unavailable is
the most common blocker.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for the E5 / E5 Compliance / add-on
entitlement; in the Purview portal → **Compliance Manager → Assessment templates**, confirm **each**
regulation template you intend to include shows as **available to create**. `CMPFRAME-Discovery.ps1`
reports the licensing SKUs it can read via Graph and how many are still available to create where the
portal exposes it. **Confirm exact entitlement with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required E5 / E5 Compliance / Premium Assessment Add-On, and confirm
the count of premium assessments available covers your regulation set, before relying on the framework.

## 2.2 The canonical shared-control set defined with compliance stakeholders
**Description:** A named, agreed **canonical set of shared controls** the organization will manage
centrally (`RAF Control Set – Canonical`) — the controls that recur across the in-scope regulations
(e.g. audit logging, DLP, retention/records, encryption/sensitivity labels, access control/MFA,
incident response, data classification). This is the *map-once* foundation.
**Why:** The framework's leverage comes from managing the shared controls **once**; without an agreed
canonical set there is nothing to map, and each regulation collapses back into a silo.
**Verify:** The canonical control set is documented, each control has a clear technical meaning and an
owner, and compliance stakeholders have signed off that it reflects the organization's real controls.
**Implement:** Workshop the recurring controls with compliance/security stakeholders; record them as
`RAF Control Set – Canonical` before building the crosswalk.

## 2.3 The control-to-regulation crosswalk agreed (map once, assess many)
**Description:** A **crosswalk** (`RAF Crosswalk – Register`) mapping **each canonical control** to the
**regulations/standards** it satisfies, so one implemented control scores across every framework that
references it. For Microsoft-shipped templates, control mapping is maintained by Microsoft; for
**custom** templates, you define the mapping.
**Why:** The crosswalk is the artifact that turns *map-once* into *assess-many* and produces the
coverage matrix. It also makes the framework-specific **gap** (controls a regulation needs that the
shared set does not cover) explicit.
**Verify:** Every canonical control lists the regulations it maps to; every in-scope regulation lists
the shared controls that cover it and the gap that remains. `CMPFRAME-Configuration.ps1` validates the
crosswalk structure and writes the local register.
**Implement:** Build the crosswalk from the canonical set and the in-scope regulation list with
compliance stakeholders; **regulatory applicability of each control is their determination**, not a
technical default.

## 2.4 Compliance Manager role groups populated with least-privilege separation
**Description:** The Compliance-Manager-specific role groups — **Compliance Manager Administrators**,
**Compliance Manager Assessors**, **Compliance Manager Contributors**, and **Compliance Manager
Readers** — populated so administrators are separated from control **contributors** and from read-only
**readers/auditors**. (Global Administrator, Compliance Administrator, and Compliance Data
Administrator also grant access.)
**Why:** Least-privilege separation is the auditable access control: contributors update controls and
evidence without administrator rights, and oversight/auditors get read-only. The evidence a
multi-regulation framework produces is only defensible if access to it was governed.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or, via `Connect-IPPSSession`,
`Get-RoleGroupMember 'Compliance Manager Contributors'` etc.) shows the intended, separated membership.
`CMPFRAME-Discovery.ps1` prints each group's membership as the `RAF Roles – Separation Evidence`
snapshot and flags administrators who are also contributors. **Verify the exact role-group names in your
tenant — Purview role naming evolves.**
**Implement:** Assign membership under change control with `CMPFRAME-Set-Scope.ps1` (`-WhatIf` first,
then `-Commit`); grant the **minimum** role each person needs and keep readers/auditors read-only.

## 2.5 Named compliance, records, privacy & legal owners (applicability + adequacy)
**Description:** Named owners in **compliance, records-management, privacy, and legal** who decide
**which regulations/standards apply**, which controls are **in scope** or **out of scope**, and whether
the collected **evidence satisfies** each obligation — plus a **control owner** for each canonical
shared control and a **business owner** per regulation assessment.
**Why:** Regulatory applicability and evidence adequacy are **not** technical determinations. The score,
crosswalk, and evidence are inputs to a compliance decision; the decision itself belongs to these
functions.
**Verify:** The in-scope regulations/standards, the scoped/out-of-scope controls, and the named
approvers are recorded (`RAF Scope – Record`).
**Implement:** Engage the governance functions, capture the applicable frameworks and the scope
decisions, and assign owners before building the action plan.

## 2.6 In-scope regulation set and the assessment-group design
**Description:** The **set of regulations** the framework will cover — starting with a **pilot**
regulation and expanding to the full set — and how the assessments are organized into a
multi-regulation **assessment group** (`RAF Group – <Program>`) so shared controls and reporting stay
coherent.
**Why:** The assessment group is the container that keeps the framework's regulations together; the
in-scope set and grouping are what make the coverage matrix meaningful.
**Verify:** The regulation list and group design are agreed with the governance owners; each chosen
regulation's template shows as available (Requirement 2.1); a pilot regulation is chosen.
**Implement:** Confirm each template's availability, design the group, and pick the pilot regulation
before creating assessments; where a needed framework has no Microsoft template, plan a **custom
template** and its crosswalk entries.

## 2.7 Shared-control owners, evidence sources, and automatic-testing decision
**Description:** For each canonical shared control, the **owner**, the **target date**, where the
**evidence** will come from, and whether it is a candidate for **automatic testing** (auto-updated from
Microsoft 365 signals) versus **manual** evidence upload — plus awareness that automatic testing depends
on the **underlying technical controls** (unified audit logging, DLP/retention/label policies,
Conditional Access/MFA) actually being present.
**Why:** A framework with no owners and no evidence is not defensible; and automatic testing only keeps
a shared control current where the underlying signal exists. Knowing which is which prevents a false
sense of coverage across every mapped regulation.
**Verify:** Each shared control has an owner, a target date, and a named evidence source; automatic-vs-
manual controls are identified (`RAF Action Plan – Shared`, `RAF Evidence – Register`). Purview portal →
**Compliance Manager → Settings** exposes the automatic-testing option (`RAF Automatic Testing –
Setting`); `CMPFRAME-Validation.ps1` reports the state of the common technical signals.
**Implement:** Build the action plan with `CMPFRAME-Configuration.ps1` (`-WhatIf` first) from the
owner-provided list; enable automatic testing where governance owners agree; plan manual evidence for
the rest.

## 2.8 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession` for role-group and evidence cmdlets) and **Microsoft Graph PowerShell** (for
licensing and Conditional Access/MFA evidence), used with a modern-auth / MFA-capable admin holding the
appropriate Compliance Manager and read roles.
**Why:** The five provided scripts assess readiness, roles, licensing, and technical evidence through
Security & Compliance PowerShell and Graph, and structure the crosswalk/coverage locally. Compliance
Manager itself is **portal-managed** — the scripts support it, they do not create assessments or push
the crosswalk.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup` returns the Compliance
Manager groups. `CMPFRAME-Discovery.ps1` performs these checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module Microsoft.Graph`; sign in with
the role-holding admin and grant the read scopes the scripts request.

## 2.9 A pilot regulation and change control
**Description:** A named **pilot regulation assessment** (`RAF Assessment – <Regulation> – Pilot`)
validated first — its shared-control coverage, evidence, and automatic-testing behaviour — before the
full regulation set is built, plus a **change-control** path for any technical remediation a shared
control triggers (consistent with `global-requirements-purview.md` §6).
**Why:** Standing up every regulation at once produces an unmanageable action backlog; validating one
regulation end-to-end proves the shared-control, crosswalk, evidence, and testing model before scaling.
Technical remediations are high-impact and are piloted in simulation/test under change control.
**Verify:** A named pilot regulation and its owner exist; a change window/approval path for technical
remediation is defined.
**Implement:** Choose one regulation as the pilot, validate it end-to-end, then expand; agree change
control before acting on any high-impact shared control.


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


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


---


# 5. Testing Guide — Regulatory Assessment Framework (Microsoft Purview)

Run these after assigning roles (Step 4), building the crosswalk (Step 3), and creating the group and
pilot regulation with shared-control implementation and automatic testing (Steps 5–7), and again after
each change and before expanding. Every test here is **safe and read-only** or contained to the **pilot
assessment** — Compliance Manager itself changes nothing on the tenant; the point is to prove the
**shared-control coverage, crosswalk, evidence, automatic testing, and role separation** all work before
you build the full framework set. **Adequacy and applicability remain a compliance/legal determination —
these tests validate the mechanism.**

## Test 1 — Role separation is in place (the access guardrail)
**Do:** Run `CMPFRAME-Discovery.ps1`; review the `RAF Roles – Separation Evidence` snapshot of each
Compliance Manager role group's membership.
**Expected:** Administrators are separated from contributors; assessors set test status; readers/
auditors are **read-only**. No administrator is silently also a contributor unless the governance owners
accepted it. **Fail** → correct membership with `CMPFRAME-Set-Scope.ps1` (Implementation Step 4) before
proceeding.

## Test 2 — Licensing supports every in-scope regulation template
**Do:** Run `CMPFRAME-Discovery.ps1` and, in the portal → **Compliance Manager → Assessment templates**,
confirm **each** regulation template in the framework is available to create.
**Expected:** The **Data Protection Baseline** is present, and each **premium/custom** template for the
regulations you map to shows as available under your entitlement, with enough premium-assessment count
remaining. **Fail** → resolve licensing (Requirement 2.1) before creating that assessment.

## Test 3 — The canonical control set and crosswalk are complete and coherent
**Do:** Run `CMPFRAME-Configuration.ps1` (dry-run) against `RAF Control Set – Canonical` and
`RAF Crosswalk – Register`.
**Expected:** Every canonical control has an owner and maps to at least one regulation; every in-scope
regulation lists its covering shared controls and its remaining **gap**; no control is orphaned and no
regulation is unmapped. **Fail** → complete the set/crosswalk with compliance owners (Steps 2–3).

## Test 4 — The assessment group and pilot regulation exist and are scored
**Do:** In the portal → **Compliance Manager → Assessments**, open `RAF Group – <Program>` and the
`RAF Assessment – <Regulation> – Pilot` within it.
**Expected:** The pilot assessment is in the group, has an owner, and shows a **Compliance Score** and
its improvement actions. **Fail** → recreate/repair the group/assessment (Implementation Step 5).

## Test 5 — Every shared control has an owner, target date, status, and evidence source
**Do:** Run `CMPFRAME-Report.ps1`; review `RAF Action Plan – Shared` / `RAF Evidence – Register` against
the pilot assessment's actions in the portal.
**Expected:** Each shared control has an **owner**, a **target date**, an **implementation status**, and
a **named evidence source**; nothing is unassigned. **Fail** → complete the plan with
`CMPFRAME-Configuration.ps1` and assign in the portal.

## Test 6 — Shared controls score across many regulations (map once, assess many)
**Do:** After the pilot's shared controls are implemented, create a **second** regulation assessment
from a licensed template in the same group (a pilot of expansion) and inspect the mapped/shared controls.
**Expected:** Controls already satisfied by the shared implementation show as **implemented** in the new
assessment via **control mapping** — you did not redo the work; only the second regulation's **gap**
remains. `CMPFRAME-Report.ps1` shows the shared-control leverage (regulations per control). **Fail** →
verify the action is a shared/Microsoft-managed control and its status is set, or fix the custom-template
mapping in the crosswalk.

## Test 7 — Automatic testing reflects the real technical state (true evidence)
**Do:** Confirm automatic testing is enabled (`RAF Automatic Testing – Setting`), then run
`CMPFRAME-Validation.ps1` (read-only) and compare its findings to the auto-tested shared controls'
status.
**Expected:** For a shared control Compliance Manager auto-tests (e.g. **unified audit logging
enabled**), the tool's finding matches the action's **test status** — the score reflects reality, not a
stale value. **Fail** → confirm auto-testing eligibility and the underlying signal; some controls need
manual evidence.

## Test 8 — A not-yet-implemented shared control scores as such (no false pass)
**Do:** Pick a shared control whose technical control is **not** in place; check its status in the portal
and cross-check with `CMPFRAME-Validation.ps1`.
**Expected:** The action shows **Not implemented / not tested** (or Failed) in **every** regulation it
maps to, and the tool confirms the control is absent — the score is **not** inflated anywhere. **Fail** →
correct the status/evidence; do not mark implemented without proof.

## Test 9 — Manual evidence is attached and defensible
**Do:** Open two or three manually-evidenced shared controls in the portal; confirm the uploaded
**evidence**, **owner**, and **test date** are present, and that `RAF Evidence – Register` records the
source.
**Expected:** Each manual control carries proof, an owner, and a date — an auditor-ready record reused
across every mapped regulation. **Fail** → attach the evidence and record it in the register.

## Test 10 — Coverage matrix is accurate and complete
**Do:** Run `CMPFRAME-Report.ps1` for the `RAF Coverage – Matrix`.
**Expected:** The report shows, per regulation, coverage by shared controls vs the remaining gap, the
shared-control leverage, the evidence register, the role-separation snapshot, and the licensing —
matching the portal. It notes that the **authoritative score and export** are the portal's Compliance
Manager export. **Fail** → confirm inputs and re-run.

## Test 11 — Safe automation defaults
**Do:** Run `CMPFRAME-Configuration.ps1` and `CMPFRAME-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is written until
`-Commit` is supplied. `CMPFRAME-Discovery.ps1`, `CMPFRAME-Validation.ps1`, and `CMPFRAME-Report.ps1` are
read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output is correct.

---
**Gate to expand:** Tests 1–2 (guardrails + licensing), 3 (control set + crosswalk), 4–5 (assessment +
ownership), 6 (map-once/assess-many), 7–9 (evidence accuracy), and 10–11 (reporting + safety) all pass
for the pilot → proceed to the full regulation set (Implementation Step 8). Any fail → correct and
re-test. **Whether the resulting score/evidence satisfies an obligation is a compliance/legal decision,
not a technical one.**


---


# 6. Troubleshooting — Regulatory Assessment Framework (Microsoft Purview)

Common issues, grouped by stage. Each has a **symptom**, the **likely cause**, and a **resolution**.
None of the tools change tenant configuration: `CMPFRAME-Configuration.ps1` and `CMPFRAME-Report.ps1`
only read/write **local** artifact files, `CMPFRAME-Set-Scope.ps1` is `-WhatIf` by default and touches
only role-group membership with `-Commit`, and `CMPFRAME-Discovery.ps1` / `CMPFRAME-Validation.ps1` are
read-only. Compliance Manager **measures**, it does not enforce — so most issues are licensing, role, or
crosswalk-input problems.

## Licensing & template availability

**Symptom:** a regulation's template does not appear under **Compliance Manager → Assessment templates**.
**Likely cause:** the template is a premium template not covered by the tenant's entitlement, or licensing
isn't assigned (Requirement 2.1). Template availability is plan-dependent and evolves.
**Resolution:** verify entitlement with Microsoft licensing (do not assume), assign it, and re-check. If it
is genuinely unavailable, record the regulation as **not-yet-licensed** in `RAF Scope – Record` rather than
proceeding — that is a legitimate scoping result, not a tool failure.

**Symptom:** `CMPFRAME-Discovery.ps1` can't read licensing SKUs.
**Likely cause:** `Microsoft.Graph` not installed or `Organization.Read.All` not consented.
**Resolution:** `Install-Module Microsoft.Graph -Scope CurrentUser`, re-run and consent, or confirm
licensing in the Microsoft 365 admin center.

## Crosswalk input (CMPFRAME-Configuration.ps1)

**Symptom:** "Input CSV missing required column(s)".
**Likely cause:** the input file lacks one of `Control, Regulations, Owner, TargetDate, EvidenceSource`
(optional `AutoTest`).
**Resolution:** add the headers exactly; `Regulations` is a **semicolon-separated** list
(e.g. `NIST 800-53;ISO 27001;HIPAA`).

**Symptom:** validation reports `[orphan]`, `[owner]`, `[date]`, or `[evid]` issues.
**Likely cause:** a control maps to no regulation, or has no owner / target date / evidence source.
**Resolution:** these are real gaps — resolve them with the control owners before `-Commit`. A control you
cannot evidence does not belong in the canonical set.

**Symptom:** `-Commit` wrote nothing / files missing.
**Likely cause:** `-Commit` was omitted (default is dry-run), or `-OutDir` isn't writable.
**Resolution:** re-run with `-Commit` and a writable `-OutDir`; the three files
(`RAF-Crosswalk-Register.csv`, `RAF-Action-Plan-Shared.csv`, `RAF-Evidence-Register.csv`) are written there.

## Roles & separation (CMPFRAME-Set-Scope.ps1)

**Symptom:** "Role group '… ' not found or not readable".
**Likely cause:** the Compliance Manager role-group names differ in your tenant, or the signed-in admin
can't manage role groups.
**Resolution:** confirm the names under **Settings → Roles & scopes → Permissions**, and sign in with an
account allowed to manage role groups. Verify names against your tenant — Purview evolves.

**Symptom:** you want to add someone but the tool says they are "already a member".
**Likely cause:** membership matches by display name or the UPN local-part; the person is already in the group.
**Resolution:** no action needed. To move someone to a lower-privilege role, `Remove` them from the higher
group and `Add` to the correct one, keeping administrators separated from contributors.

## Reporting (CMPFRAME-Report.ps1)

**Symptom:** "Crosswalk file not found".
**Likely cause:** you ran the report before `CMPFRAME-Configuration.ps1 -Commit` produced the register.
**Resolution:** commit the configuration first, then point `-CrosswalkPath` at the generated
`RAF-Crosswalk-Register.csv`.

**Symptom:** every regulation shows "awaiting evidence".
**Likely cause:** no `-EvidencePath` was supplied, or the evidence register's `TestStatus` is still
`Not assessed`.
**Resolution:** attach evidence and update status in the Purview portal, refresh
`RAF-Evidence-Register.csv`, and pass `-EvidencePath`. Remember coverage counts controls **mapped and
evidenced** — not regulatory adequacy.

## Automatic testing & signals (CMPFRAME-Validation.ps1)

**Symptom:** a shared control shows **ABSENT** even though you think the control exists.
**Likely cause:** wrong endpoint/role, or the underlying technical control (audit, DLP, retention, labels,
Conditional Access) genuinely isn't in place yet.
**Resolution:** confirm connectivity/role and re-read; if the control really is absent, implement it as a
**separate, simulation/test-piloted change** owned by that feature's solution — not switched on blind here.

**Symptom:** automatic testing in Compliance Manager doesn't update an action's status.
**Likely cause:** automatic testing isn't enabled, the action isn't eligible for automatic testing, or the
signal hasn't propagated.
**Resolution:** enable automatic testing (Requirement 2.7) per the governance owners' decision, confirm the
action is auto-testable, and allow time to propagate; otherwise attach **manual** evidence.

## What these gates do NOT decide
Whether a **regulation applies**, and whether the **evidence satisfies it**, are
**compliance / records / privacy / legal determinations** (Requirement 2.5) — the framework builds the
shared-control set, the crosswalk, the assessments, and the coverage matrix; adequacy and sign-off belong
to those functions. The **high-impact technical changes** a shared control requires (enabling audit, DLP,
retention, labels, Conditional Access) are separate, simulation-piloted changes owned by their own solution.


---


# 7. Best Practices — Regulatory Assessment Framework (Microsoft Purview)

- **Map once, assess many — that is the whole point.** Define a **canonical shared-control set**, map it
  to every regulation it satisfies, and let Compliance Manager's control mapping score one implementation
  across all of them. Prioritize **high-point, widely-mapped** shared controls for the most coverage per
  unit of effort, and only do each regulation's **gap** when you add it.
- **Keep the canonical control set tight and real.** A control you cannot evidence does not belong in the
  set. `RAF Control Set – Canonical` should reflect controls the organization actually operates — not an
  aspirational list — so the crosswalk and coverage matrix stay honest.
- **The crosswalk is the asset — maintain it.** `RAF Crosswalk – Register` is what turns silos into a
  framework. Review it whenever a regulation is added or a template is updated; a stale crosswalk quietly
  breaks the map-once/assess-many leverage.
- **Pilot one regulation before building the full set.** Validate one regulation end-to-end — shared
  controls owned, evidenced, and auto-tested — before creating a stack of assessments. One regulation
  proven properly beats ten with unassigned actions and no proof.
- **Assign an owner and a date to every shared control.** A coverage matrix with unowned, undated
  controls is not a plan. Ownership and target dates in `RAF Action Plan – Shared` are what make the
  framework trackable and auditable.
- **Evidence once, reuse across regulations.** Attach documentation, test results, an owner, and a test
  date to each shared control. Because it is shared, that one evidence record satisfies every mapped
  regulation — `RAF Evidence – Register` is the auditor-ready record; don't re-evidence the same control
  per framework.
- **Enable automatic testing — but know its limits.** Turn on automatic testing so eligible shared
  controls self-update from Microsoft 365 signals; but confirm with `CMPFRAME-Validation.ps1` that the
  **underlying control actually exists**, and plan **manual evidence** for controls that can't auto-test.
  Automatic testing is not full coverage.
- **Never mark a shared control implemented without proof.** A false "implemented" inflates the score in
  **every** regulation it maps to and fails the first audit. If the technical control isn't in place, it
  stays Not implemented — `CMPFRAME-Validation.ps1` is your cross-check against wishful status.
- **Compliance Manager measures; it does not enforce.** Implementing a shared control — enabling audit,
  DLP, retention, labels, Conditional Access — is a **separate, high-impact change** owned by that
  feature's solution and **piloted in simulation/test first**. Don't switch controls on tenant-wide from
  the score dashboard.
- **Least privilege and separation.** Keep **Administrators** separate from **Contributors**, and keep
  **Readers/auditors** read-only. Manage membership with `CMPFRAME-Set-Scope.ps1` (`-WhatIf` then
  `-Commit`) and re-snapshot with `CMPFRAME-Discovery.ps1` — membership drifts as people join and leave.
- **Always dry-run automation.** `CMPFRAME-Configuration.ps1` and `CMPFRAME-Set-Scope.ps1` default to
  **`-WhatIf`**. Read every line of the planned change; run `-Commit` only after the output is right. The
  discovery, validation, and report scripts are read-only.
- **Applicability and adequacy belong to compliance/legal.** *Which* regulations apply, *which* controls
  are in/out of scope, and *whether* the evidence satisfies each obligation are **compliance, records,
  privacy, and legal** determinations. The framework provides method, crosswalk, score, and evidence —
  not the verdict.
- **Watch for template and regulation updates.** Microsoft updates assessment templates as regulations
  change; a template update can add controls, move your score, and change the crosswalk mapping. Review
  updates on a cadence and re-baseline affected assessments.
- **Group deliberately.** Keep the framework's regulations in one **assessment group** (`RAF Group –
  <Program>`) so control mapping and the coverage matrix stay coherent; add per-business-unit or
  per-environment groups only when they genuinely differ.
- **Verify licensing and template availability against your tenant.** The baseline is included; premium
  and custom templates are entitlement-gated and the count is seat-dependent; GCC/GCC High may differ.
  Confirm your regulation set fits your premium-assessment entitlement — never assume a template is
  available.
- **The portal is authoritative.** Assessments, groups, evidence upload, and the official score/export
  live in the Purview portal; the scripts assess readiness, roles, licensing, and technical evidence and
  structure the crosswalk/coverage — they support the portal, they don't replace it.


---


# 8. Deliverables Summary — Regulatory Assessment Framework (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the map-once/assess-many model, and what's in the box |
| 1. Solution Overview | What the framework is, how it works, the building blocks (assessments, improvement actions, control mapping, groups, evidence), the canonical control set + crosswalk model, the role-separation model, limitations, and the naming convention |
| 2. Requirements Guide | Every framework-specific prerequisite with Verify / Implement-if-missing (per-regulation template licensing, the canonical control set, the crosswalk, role separation, governance owners, the in-scope regulation set + group design, shared-control owners + evidence + automatic testing, toolchain, pilot regulation) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps — baseline/inventory, define the control set, build the crosswalk, roles-with-separation, create the group + pilot regulation, implement + evidence shared controls, enable automatic testing, validate, report coverage, expand; applicability/adequacy deferred to compliance/legal |
| 5. Testing Guide | Validation procedures with pass/fail gates (separation, licensing, control set + crosswalk, assessment/ownership, map-once/assess-many, evidence accuracy, coverage matrix, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, evidence-first, map-once recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `CMPFRAME-Discovery.ps1` | Readiness + **role-separation** + licensing assessment; prints the `RAF Roles – Separation Evidence` snapshot and the SKUs/entitlement that gate the regulation templates | **Read-only** |
| `CMPFRAME-Configuration.ps1` | **Crosswalk & shared-control-plan builder** — validates the canonical control set and control-to-regulation crosswalk and writes the local `RAF Crosswalk – Register` / `RAF Action Plan – Shared` / `RAF Evidence – Register` (no tenant writes; Compliance Manager is portal-managed) | **`-WhatIf`** (needs `-Commit`) |
| `CMPFRAME-Validation.ps1` | Collects the **technical evidence** behind automatable shared controls — unified audit, DLP/retention/label presence, Conditional Access/MFA — and reports pass/absent per signal | **Read-only** |
| `CMPFRAME-Report.ps1` | **Coverage-matrix rollup** — per-regulation coverage vs gap, shared-control leverage (regulations per control), evidence register, role separation, and licensing; notes the authoritative score/export is the portal | **Read-only** |
| `CMPFRAME-Set-Scope.ps1` | Role/health helper — manage Compliance Manager **role-group membership** for least-privilege separation | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. `CMPFRAME-Configuration.ps1`
and `CMPFRAME-Set-Scope.ps1` are **safe-by-default** (`-WhatIf`) and only make a change when `-Commit` is
supplied. Compliance Manager itself is **portal-managed** — the scripts assess readiness, roles, licensing,
and the technical evidence behind shared controls and structure the crosswalk/coverage plan; they do not
create assessments, set action status, or push the crosswalk (there is no broad public write API for that).

## Artifacts this solution creates (naming convention)
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

## Outcome
Many regulations assessed from **one shared-control framework** in Microsoft Purview — a canonical
control set mapped once via `RAF Crosswalk – Register`, scored across every regulation through control
mapping, with shared controls owned, tested, and evidenced **once** and reused across frameworks. The
**coverage matrix** shows, per regulation, what shared controls satisfy and the remaining gap;
**automatic testing** keeps technical shared controls current; **least-privilege separation** is
enforced. The capability is in place, validated, and audit-ready, with **regulatory applicability and
adequacy in the hands of compliance, records, privacy, and legal**.
