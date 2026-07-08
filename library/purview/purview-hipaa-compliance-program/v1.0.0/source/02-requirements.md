# 2. Requirements Guide — Microsoft Purview HIPAA Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/compliance licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
**HIPAA-program-specific** detail. **Licensing, template availability, and portal paths are
plan-dependent and the portal evolves — verify each against your own licensing and tenant.**

## 2.1 Licensing — Compliance Manager premium templates (HIPAA/HITECH, HITRUST CSF)
**Description:** Compliance Manager and the **Data Protection Baseline** assessment are available to all
Microsoft 365 / Office 365 commercial subscriptions, but the **HIPAA/HITECH** premium template — and the
**HITRUST CSF** template where you scope it — require **Microsoft 365 E5 / E5 Compliance** or the
**Compliance Manager Premium Assessment Add-On**; the **number** of premium assessments you can create is
a function of your licensing / seat entitlement. The Purview technical controls the safeguards map to
(advanced/auto DLP, auto-labeling, Audit Premium, Insider Risk, Communication Compliance) are themselves
largely **E5 / E5 Compliance** capabilities.
**Why:** The baseline is free but the HIPAA and HITRUST templates and the advanced controls that evidence
several safeguards are entitlement-gated — the most common blocker to standing up the program.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for the E5 / E5 Compliance / add-on
entitlement; in the Purview portal → **Compliance Manager → Assessment templates**, confirm **HIPAA/HITECH**
(and HITRUST CSF where needed) show as **available to create**. `CMPHIPAA-Discovery.ps1` reports the
licensing SKUs it can read via Graph. **Confirm exact entitlement with Microsoft licensing — do not
assume.** GCC/GCC High and sovereign clouds may differ.
**Implement:** Assign/purchase the required E5 / E5 Compliance / Premium Assessment Add-On before relying
on the HIPAA/HITECH or HITRUST template or the advanced controls.

## 2.2 Compliance Manager role groups populated with least-privilege separation
**Description:** The Compliance-Manager role groups — **Compliance Manager Administrators**,
**Compliance Manager Assessors**, **Compliance Manager Contributors**, **Compliance Manager Readers** —
populated so administrators are separated from safeguard/action **contributors** and from read-only
**readers/auditors** (the HIPAA **Security Officer** / **Privacy Officer** typically sit as
readers/oversight). Global Administrator, Compliance Administrator, and Compliance Data Administrator also
grant access.
**Why:** Least-privilege separation is the auditable access control for a HIPAA program: the evidence you
produce is only defensible if access to it was itself governed — contributors update actions/evidence
without administrator rights, and oversight/auditors get read-only.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or, via `Connect-IPPSSession`,
`Get-RoleGroupMember 'Compliance Manager Contributors'` etc.) shows the intended, separated membership.
`CMPHIPAA-Discovery.ps1` prints each group's membership as the `HIPAA Roles – Separation Evidence`
snapshot and flags an administrator who is also a contributor. **Verify the exact role-group names in your
tenant — Purview role naming evolves.**
**Implement:** Assign membership under change control with `CMPHIPAA-Set-Scope.ps1` (`-WhatIf` first, then
`-Commit`); grant the **minimum** role each person needs and keep readers/auditors read-only.

## 2.3 Named HIPAA compliance, privacy, security & legal owners (applicability + adequacy)
**Description:** Named owners — the **HIPAA Security Officer** and **Privacy Officer** and the
**compliance/records/legal** functions — who decide **which safeguards apply**, how each **addressable**
specification is satisfied, the outcome of the **risk analysis** (§164.308(a)(1)), which controls are
**in/out of scope**, and whether the collected **evidence satisfies** the obligation — plus a **business
owner** per in-scope assessment.
**Why:** HIPAA applicability, the required-vs-addressable choices, the risk-analysis outcome, and evidence
adequacy are **not** technical determinations. The score and evidence are inputs to a compliance decision;
the decision belongs to these functions.
**Verify:** The applicable safeguards, the addressable-spec decisions, the risk-analysis reference, the
scoped/out-of-scope controls, and the named approvers are recorded (`HIPAA Scope – Record`).
**Implement:** Engage the Security/Privacy Officers and compliance/legal, capture the safeguard
applicability and scope decisions, and assign an owner per assessment before building the action plan.

## 2.4 In-scope ePHI, workloads, and the safeguard → control map decided
**Description:** The **workloads and data sources holding ePHI** (Exchange, SharePoint, OneDrive, Teams,
endpoints, and any in-scope data estate), the **sensitive-information-type / classification** approach
used to *identify* ePHI, and the agreed **HIPAA safeguard → Purview control map** (`HIPAA Control Map –
Safeguards`) — which Purview capability evidences each safeguard.
**Why:** The program's score and evidence key off the in-scope ePHI workloads and the classification
scheme; the safeguard map is what turns "we run Purview" into "here is the control that satisfies
§164.312(b)."
**Verify:** The in-scope ePHI workloads, the SIT/classification approach, and the safeguard→control map
are agreed with the owners; each mapped Purview capability shows as available (Requirement 2.1).
**Implement:** Confirm the ePHI scope and classification intent, then complete the safeguard→control map
before building the assessment and action plan.

## 2.5 Improvement-action owners and evidence sources identified
**Description:** For the pilot assessment, the **owner** of each improvement action, its **target date**,
its mapped **safeguard**, and where the **evidence** comes from — including which actions are candidates
for **automatic testing** (auto-updated from Microsoft 365 signals) versus **manual** evidence upload.
**Why:** A HIPAA score with no owners and no evidence is not defensible; ownership and evidence source are
what turn recommendations into a trackable, auditor-ready plan (`HIPAA Action Plan – Pilot`,
`HIPAA Evidence – Register`).
**Verify:** Each pilot action has an owner, a target date, a mapped safeguard, and a named evidence
source; automatic-vs-manual actions are identified.
**Implement:** Build the action plan with `CMPHIPAA-Configuration.ps1` (`-WhatIf` first) from the
owner-provided list; capture the evidence source and mapped safeguard per action.

## 2.6 Automatic-testing decision and the underlying technical safeguards
**Description:** A decision on whether to enable **automatic testing** of eligible actions (continuous
monitoring reads your Microsoft 365 configuration to update an action's status), and awareness that
automatic testing depends on the **underlying technical safeguards** actually being present — e.g.
**unified audit logging** (§164.312(b)), **DLP/label/retention** for ePHI, **Conditional Access / MFA**
(§164.312(a),(d)).
**Why:** Automatic testing keeps technical safeguards current without manual re-checks — but only for
**eligible** actions and only when the underlying signal exists. Knowing which is which prevents a false
sense of coverage in a compliance record.
**Verify:** Purview portal → **Compliance Manager → Settings** for the automatic-testing option
(`HIPAA Automatic Testing – Setting`); `CMPHIPAA-Validation.ps1` reports the state of the common technical
safeguards (audit, DLP, retention, labels, Conditional Access) that back the mapped actions.
**Implement:** Enable automatic testing where the owners agree; for actions it can't auto-test, plan
manual evidence.

## 2.7 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing `Connect-IPPSSession`
for role-group and evidence cmdlets) and **Microsoft Graph PowerShell** (for licensing and Conditional
Access / MFA evidence), used with a modern-auth / MFA-capable admin holding the appropriate Compliance
Manager and read roles.
**Why:** The five provided scripts assess readiness, roles, and technical evidence through Security &
Compliance PowerShell and Graph. Compliance Manager itself is **portal-managed** — the scripts support it,
they do not create assessments.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup` returns the Compliance
Manager groups. `CMPHIPAA-Discovery.ps1` performs these checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module Microsoft.Graph`; sign in with
the role-holding admin and grant the read scopes the scripts request.

## 2.8 A pilot assessment and change control
**Description:** A named **pilot assessment** (`HIPAA Assessment – HITECH – Pilot`) validated first — its
action plan, evidence, and automatic-testing behaviour — before the full **production** program is built,
plus a **change-control** path for any technical remediation a mapped action triggers (a new DLP, label,
retention, or Conditional Access policy — consistent with `global-requirements-purview.md` §6).
**Why:** Standing up every safeguard and framework at once produces an unmanageable action backlog;
validating one HIPAA assessment end-to-end proves the ownership, evidence, and testing model before
scaling. Technical remediations are high-impact and are piloted in **simulation/test** under change
control.
**Verify:** A named pilot assessment and its owner exist; a change window / approval path for technical
remediation is defined.
**Implement:** Choose the HITECH pilot, validate it end-to-end, then expand; agree change control before
acting on any high-impact improvement action.
