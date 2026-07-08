# 2. Requirements Guide — Microsoft Purview Compliance Manager Implementation

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
Compliance-Manager-specific detail. **Licensing, template availability, and portal paths are
plan-dependent and the portal evolves — verify each against your own licensing and tenant.**

## 2.1 Licensing — base Compliance Manager and premium/custom templates
**Description:** Compliance Manager and the **Data Protection Baseline** assessment are available to all
Microsoft 365 / Office 365 commercial subscriptions. **Premium assessment templates** (NIST 800-53,
ISO 27001, HIPAA/HITECH, GDPR, and hundreds more) and **custom templates** require **Microsoft 365 E5
/ E5 Compliance** or the **Compliance Manager Premium Assessment Add-On**; the **number** of premium
assessments you can create is a function of your licensing / seat entitlement. (GCC/GCC High and other
sovereign clouds may differ.)
**Why:** The baseline is free but every regulation-specific template is entitlement-gated; a template
you plan to assess against may not be available on your plan — the most common blocker.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for the E5 / E5 Compliance / add-on
entitlement; in the Purview portal → **Compliance Manager → Assessment templates**, confirm the
templates you need show as **available to create**. `CMPMGR-Discovery.ps1` reports the licensing SKUs
it can read via Graph. **Confirm exact entitlement with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required E5 / E5 Compliance / Premium Assessment Add-On before
relying on a premium or custom template.

## 2.2 Compliance Manager role groups populated with least-privilege separation
**Description:** The Compliance-Manager-specific role groups — **Compliance Manager Administrators**,
**Compliance Manager Assessors**, **Compliance Manager Contributors**, and **Compliance Manager
Readers** — populated so administrators are separated from action **contributors** and from read-only
**readers/auditors**. (Global Administrator, Compliance Administrator, and Compliance Data
Administrator also grant access.)
**Why:** Least-privilege separation is the auditable access control: assessors/contributors update
actions and evidence without administrator rights, and oversight/auditors get read-only. The evidence
you produce is only defensible if access to it was governed.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or, via `Connect-IPPSSession`,
`Get-RoleGroupMember 'Compliance Manager Contributors'` etc.) shows the intended, separated membership.
`CMPMGR-Discovery.ps1` prints each group's membership as the `CM Roles – Separation Evidence` snapshot
and flags administrators who are also contributors. **Verify the exact role-group names in your tenant
— Purview role naming evolves.**
**Implement:** Assign membership under change control with `CMPMGR-Set-Scope.ps1` (`-WhatIf` first,
then `-Commit`); grant the **minimum** role each person needs and keep readers/auditors read-only.

## 2.3 Named compliance, records, privacy & legal owners (applicability + adequacy)
**Description:** Named owners in **compliance, records-management, privacy, and legal** who decide
**which regulations/standards apply**, which controls are **in scope** or **out of scope**, and whether
the collected **evidence satisfies** the obligation — plus a **business owner** for each in-scope
assessment.
**Why:** Regulatory applicability and evidence adequacy are **not** technical determinations. The score
and evidence are inputs to a compliance decision; the decision itself belongs to these functions.
**Verify:** The in-scope regulations/standards, the scoped/out-of-scope controls, and the named
approvers are recorded (`CM Scope – Record`).
**Implement:** Engage the governance functions, capture the applicable frameworks and the scope
decisions, and assign an owner per assessment before building the action plan.

## 2.4 In-scope assessment templates and grouping decided
**Description:** The **set of assessment templates** to stand up — starting with the **Data Protection
Baseline** and adding the licensed **premium** (and any **custom**) templates your obligations require —
and how assessments are **grouped** (e.g. by regulation, business unit, or environment) so control
mapping and reporting are coherent.
**Why:** Assessments are the unit of scoring; picking the right templates and grouping is what makes
the score meaningful and lets shared controls map across frameworks.
**Verify:** The template list and grouping are agreed with the governance owners; each chosen template
shows as available (Requirement 2.1).
**Implement:** Confirm each template's availability and create a grouping plan before creating
assessments; where a needed framework has no template, plan a **custom template**.

## 2.5 Improvement-action owners and evidence sources identified
**Description:** For the pilot assessment, the **owner** of each improvement action, the **target
date**, and where the **evidence** will come from — including which actions are candidates for
**automatic testing** (auto-updated from Microsoft 365 signals) versus **manual** evidence upload.
**Why:** A score with no owners and no evidence is not defensible. Ownership and evidence source are
what turn recommendations into a trackable, auditable plan (`CM Action Plan – Pilot`,
`CM Evidence – Register`).
**Verify:** Each pilot action has an owner, a target date, and a named evidence source; automatic-vs-
manual actions are identified.
**Implement:** Build the action plan with `CMPMGR-Configuration.ps1` (`-WhatIf` first) from the
owner-provided list; capture the evidence source per action.

## 2.6 Automatic-testing decision and the underlying technical signals
**Description:** A decision on whether to enable **automatic testing** of eligible improvement actions
(continuous monitoring reads your Microsoft 365 configuration to update an action's status), and
awareness that automatic testing depends on the **underlying technical controls** (e.g. unified audit
logging, DLP/retention/sensitivity-label policies, Conditional Access/MFA) actually being present.
**Why:** Automatic testing keeps technical actions current without manual re-checks — but only for
**eligible** actions, and only when the underlying signal exists. Knowing which is which prevents a
false sense of coverage.
**Verify:** Purview portal → **Compliance Manager → Settings** for the automatic-testing option
(`CM Automatic Testing – Setting`); `CMPMGR-Validation.ps1` reports the state of the common technical
signals (audit, DLP, retention, labels, Conditional Access) that back automatable actions.
**Implement:** Enable automatic testing where your governance owners agree; for actions it can't
auto-test, plan manual evidence.

## 2.7 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession` for role-group and evidence cmdlets) and **Microsoft Graph PowerShell** (for
licensing and Conditional Access/MFA evidence), used with a modern-auth / MFA-capable admin holding the
appropriate Compliance Manager and read roles.
**Why:** The five provided scripts assess readiness, roles, and technical evidence through Security &
Compliance PowerShell and Graph. Compliance Manager itself is **portal-managed** — the scripts support
it, they do not create assessments.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup` returns the
Compliance Manager groups. `CMPMGR-Discovery.ps1` performs these checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module Microsoft.Graph`; sign in
with the role-holding admin and grant the read scopes the scripts request.

## 2.8 A pilot assessment and change control
**Description:** A named **pilot assessment** (`CM Assessment – Baseline – Pilot`, typically the Data
Protection Baseline) validated first — its action plan, evidence, and automatic-testing behaviour —
before the full set of production assessments is built, plus a **change-control** path for any
technical remediation an action triggers (consistent with `global-requirements-purview.md` §6).
**Why:** Standing up every framework at once produces an unmanageable action backlog; validating one
assessment end-to-end proves the ownership, evidence, and testing model before scaling. Technical
remediations are high-impact and are piloted in simulation/test under change control.
**Verify:** A named pilot assessment and its owner exist; a change window/approval path for technical
remediation is defined.
**Implement:** Choose the baseline as the pilot, validate it end-to-end, then expand; agree change
control before acting on any high-impact improvement action.
