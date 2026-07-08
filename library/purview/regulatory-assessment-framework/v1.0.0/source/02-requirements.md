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
