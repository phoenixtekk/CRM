# 2. Requirements Guide — Microsoft Purview CMMC Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
CMMC-specific detail. **Licensing, template availability, cloud (Commercial vs GCC/GCC High), and
portal paths are plan-/cloud-dependent and the portal evolves — verify each against your own tenant.**

## 2.1 Licensing — Compliance Manager and the CMMC / NIST 800-171 premium template
**Description:** Compliance Manager and the **Data Protection Baseline** assessment are available to all
Microsoft 365 / Office 365 commercial subscriptions. The **CMMC Level 2** and **NIST SP 800-171**
**premium assessment templates** (and custom templates) require **Microsoft 365 E5 / E5 Compliance** or
the **Compliance Manager Premium Assessment Add-On**; the **number** of premium assessments you can
create is a function of your licensing / seat entitlement.
**Why:** The baseline is included, but the CMMC/NIST 800-171 template is entitlement-gated — the single
most common blocker. A template you plan to assess against may not be available on your plan.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for the E5 / E5 Compliance / add-on
entitlement; in the Purview portal → **Compliance Manager → Assessment templates**, confirm the
**CMMC Level 2** and/or **NIST SP 800-171** template shows as **available to create**.
`CMMC-Discovery.ps1` reports the licensing SKUs it can read via Graph. **Confirm exact entitlement and
the exact template name with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required E5 / E5 Compliance / Premium Assessment Add-On before
relying on the CMMC/NIST template.

## 2.2 Cloud environment for CUI (Commercial vs GCC / GCC High)
**Description:** The Microsoft 365 **cloud** the CUI workloads live in — **Commercial**, **GCC**, or
**GCC High**. Many CMMC Level 2 / CUI obligations (including ITAR-controlled data) require **GCC High**;
DFARS 7012 requires the cloud service to meet **FedRAMP Moderate (or equivalent)** and support the
required incident-reporting and forensic obligations.
**Why:** Feature availability, assessment-template naming, portal paths, and even which cmdlets work
**differ** between Commercial and government clouds. Building the program in the wrong cloud is a rework
and, for regulated CUI, a compliance failure.
**Verify:** Confirm the tenant's cloud with your governance owners and Microsoft; check that the CMMC
template and Compliance Manager features you need are present **in that cloud**. **Which cloud CUI must
reside in is a compliance/contractual determination.**
**Implement:** Ensure CUI workloads are in the contractually required cloud before building the program;
if a migration is needed, that is a separate, governed project.

## 2.3 Compliance Manager role groups populated with least-privilege separation
**Description:** The Compliance-Manager-specific role groups — **Compliance Manager Administrators**,
**Compliance Manager Assessors**, **Compliance Manager Contributors**, and **Compliance Manager
Readers** — populated so administrators are separated from action **contributors** and from read-only
**readers/auditors** (including any external C3PAO reader access). (Global Administrator, Compliance
Administrator, and Compliance Data Administrator also grant access.)
**Why:** Least-privilege separation is itself a CMMC control (Access Control / least privilege) and the
auditable access record: contributors update actions and evidence without administrator rights, and
oversight/assessors get read-only. The evidence you produce is only defensible if access to it was
governed.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or, via `Connect-IPPSSession`,
`Get-RoleGroupMember 'Compliance Manager Contributors'` etc.) shows the intended, separated membership.
`CMMC-Discovery.ps1` prints each group's membership as the `CMMC Roles – Separation Evidence` snapshot
and flags administrators who are also contributors. **Verify the exact role-group names in your tenant
— Purview role naming evolves.**
**Implement:** Assign membership under change control with `CMMC-Set-Scope.ps1` (`-WhatIf` first, then
`-Commit`); grant the **minimum** role each person needs and keep readers/auditors read-only.

## 2.4 Named compliance, security & legal owners (applicability + adequacy + certification)
**Description:** Named owners in **compliance, security, and legal** who decide **which CMMC level** is
sought, **which NIST 800-171 requirements** are in or out of scope, whether **System Security Plan
(SSP)** and **Plan of Action & Milestones (POA&M)** evidence satisfies the obligation, and who owns the
relationship with the **C3PAO** — plus a **business owner** for each in-scope domain.
**Why:** CMMC applicability, the level sought, evidence adequacy, the SPRS score, and the certification
determination are **not** technical determinations. The score and evidence are inputs to a compliance
decision; the decision itself belongs to these functions and, ultimately, the assessor.
**Verify:** The target level, the in-/out-of-scope requirements, the SSP/POA&M owners, and the named
approvers are recorded (`CMMC Scope – Record`).
**Implement:** Engage the governance functions, capture the target level and scope decisions, and
assign an owner per domain before building the action plan.

## 2.5 CUI boundary / scope and the SSP defined
**Description:** A defined **CUI boundary** (the systems, enclave, users, and data that store, process,
or transmit CUI) and a **System Security Plan (SSP)** that describes how each NIST 800-171 requirement
is met — the authoritative scope the assessment measures against.
**Why:** CMMC scores against a boundary; without an agreed boundary and SSP the assessment is measuring
the wrong estate, and the C3PAO will scope to the boundary anyway.
**Verify:** A documented CUI boundary/enclave and a current SSP exist, agreed with the governance
owners (`CMMC Scope – Record`).
**Implement:** Define and document the CUI boundary and SSP with security/compliance before creating the
assessment. **Boundary definition is a compliance/security determination.**

## 2.6 Improvement-action owners and evidence sources identified
**Description:** For the pilot assessment, the **owner** of each improvement action, the **target
date**, and where the **evidence** comes from — including which actions are candidates for **automatic
testing** (auto-updated from Microsoft 365 signals) versus **manual** evidence upload (policies,
procedures, screenshots, SSP/POA&M references).
**Why:** A CMMC posture with no owners and no evidence is not defensible to a C3PAO. Ownership and
evidence source turn recommendations into a trackable, auditable plan (`CMMC Action Plan – Pilot`,
`CMMC Evidence – Register`, `CMMC Control Map – NIST 800-171`).
**Verify:** Each pilot action has an owner, a target date, and a named evidence source; automatic-vs-
manual actions are identified.
**Implement:** Build the action plan and control map with `CMMC-Configuration.ps1` (`-WhatIf` first)
from the owner-provided list; capture the evidence source per action.

## 2.7 Automatic-testing decision and the underlying technical signals
**Description:** A decision on whether to enable **automatic testing** of eligible improvement actions
(continuous monitoring reads your Microsoft 365 configuration to update an action's status), and
awareness that automatic testing depends on the **underlying technical controls** — e.g. **unified
audit logging** (AU family), **Conditional Access / MFA** (AC/IA families), **DLP / retention /
sensitivity-label / encryption** policies (MP/SC families) — actually being present.
**Why:** Automatic testing keeps technical actions current without manual re-checks — but only for
**eligible** actions, and only when the underlying signal exists. Knowing which is which prevents a
false sense of coverage against the 110 requirements.
**Verify:** Purview portal → **Compliance Manager → Settings** for the automatic-testing option
(`CMMC Automatic Testing – Setting`); `CMMC-Validation.ps1` reports the state of the common technical
signals (audit, DLP, retention, labels, Conditional Access/MFA) that back automatable NIST 800-171
actions.
**Implement:** Enable automatic testing where your governance owners agree; for actions it can't
auto-test, plan manual evidence.

## 2.8 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession` for role-group and evidence cmdlets) and **Microsoft Graph PowerShell** (for
licensing and Conditional Access/MFA evidence), used with a modern-auth / MFA-capable admin holding the
appropriate Compliance Manager and read roles. In **GCC High**, use the environment-specific endpoints
(`Connect-IPPSSession -ConnectionUri`/`Connect-MgGraph -Environment`).
**Why:** The five provided scripts assess readiness, roles, and technical evidence through Security &
Compliance PowerShell and Graph. Compliance Manager itself is **portal-managed** — the scripts support
it, they do not create assessments.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup` returns the Compliance
Manager groups. `CMMC-Discovery.ps1` performs these checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module Microsoft.Graph`; sign in
with the role-holding admin and grant the read scopes the scripts request. Confirm the correct cloud
endpoints for GCC/GCC High.

## 2.9 A pilot assessment and change control
**Description:** A named **pilot assessment** (`CMMC Assessment – NIST 800-171 – Pilot`) validated first
— its action plan, evidence, and automatic-testing behaviour — before the full production assessment is
built, plus a **change-control** path for any technical remediation an action triggers (consistent with
`global-requirements-purview.md` §6).
**Why:** Standing up every requirement at once produces an unmanageable action backlog; validating one
assessment end-to-end proves the ownership, evidence, and testing model before scaling. Technical
remediations are high-impact and are piloted in simulation/test under change control.
**Verify:** A named pilot assessment and its owner exist; a change window/approval path for technical
remediation is defined.
**Implement:** Use the CMMC/NIST 800-171 template as the pilot, validate it end-to-end, then expand;
agree change control before acting on any high-impact improvement action.

---
## Checklist
- [ ] Licensing: Compliance Manager + CMMC Level 2 / NIST 800-171 premium template available — `CMMC-Discovery.ps1`
- [ ] Cloud confirmed for CUI (Commercial / GCC / GCC High) and template present in that cloud
- [ ] Compliance Manager role groups populated with least-privilege separation — `CMMC-Set-Scope.ps1`
- [ ] Compliance/security/legal owners named; target level + in-/out-of-scope requirements recorded (`CMMC Scope – Record`)
- [ ] CUI boundary + SSP defined
- [ ] Improvement-action owners + evidence sources identified (auto vs manual) — `CMMC-Configuration.ps1`
- [ ] Automatic-testing decision + underlying signals checked — `CMMC-Validation.ps1`
- [ ] S&C PowerShell + Graph toolchain (correct cloud endpoints) — `CMMC-Discovery.ps1`
- [ ] Pilot assessment named + change control for technical remediation
