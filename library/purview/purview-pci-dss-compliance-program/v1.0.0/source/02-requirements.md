# 2. Requirements Guide — Microsoft Purview PCI-DSS Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
**PCI-DSS-program-specific** detail. **Licensing, template availability, sensitive-information-type
names, and portal paths are plan-dependent and the portal evolves — verify each against your own
licensing and tenant. Which PCI-DSS version/SAQ applies and how your CDE is scoped are QSA/compliance
determinations.**

## 2.1 Licensing — Compliance Manager premium template + advanced DLP/labeling
**Description:** Compliance Manager and the **Data Protection Baseline** are available to all Microsoft
365 subscriptions, but the **PCI-DSS assessment template** is a **premium template** requiring
**Microsoft 365 E5 / E5 Compliance** or the **Compliance Manager Premium Assessment Add-On**. The
cardholder-data controls likewise need the right plan: **DLP for Exchange/SharePoint/OneDrive/Teams**
is broadly available, but **endpoint DLP**, **auto-labeling**, and **Audit (Premium)** long-retention
require **E5 / E5 Compliance**. (GCC/GCC High and other sovereign clouds may differ.)
**Why:** The PCI-DSS template and several controls are entitlement-gated; a template or feature you
plan to use may not be available on your plan — the most common blocker.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for E5 / E5 Compliance / add-on; Purview
portal → **Compliance Manager → Assessment templates**, confirm **PCI-DSS** shows as available to
create. `CMPPCI-Discovery.ps1` reports the licensing SKUs it can read via Graph and whether advanced
DLP/audit surfaces respond. **Confirm exact entitlement with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required E5 / E5 Compliance / Premium Assessment Add-On before
relying on the PCI-DSS template or advanced DLP/audit.

## 2.2 PCI-DSS version, SAQ, and Cardholder Data Environment (CDE) scope decided
**Description:** The **PCI-DSS version** you must meet (the current standard is **v4.0 / v4.0.1** —
confirm the version your acquirer/QSA requires), the applicable **SAQ** (or full ROC), and the
**Cardholder Data Environment (CDE)** scope — the systems, people, and processes that store, process,
or transmit **cardholder data (PAN)** — plus which requirements are **in scope** for Purview to support
versus tracked as **evidence links** to another system.
**Why:** CDE scoping and SAQ applicability are the **QSA/compliance determination** that defines the
whole program; the score and controls are only meaningful against a defined scope. Getting scope wrong
either over-builds or leaves the CDE unprotected.
**Verify:** The version, SAQ, in-scope requirements, and CDE boundary are recorded and confirmed by the
QSA/compliance owners (`PCI Scope – Record`, `PCI Control Map – Record`).
**Implement:** Engage the QSA/compliance function; capture the version, SAQ, CDE boundary, and the
Purview-to-requirement control map before configuring.

## 2.3 Compliance role groups populated with least-privilege separation (PCI-DSS Req 7)
**Description:** The Compliance/Compliance-Manager role groups — **Compliance Manager Administrators**,
**Assessors**, **Contributors**, **Readers** (plus **Compliance Administrator** / **Compliance Data
Administrator** for DLP/label/audit configuration) — populated so administrators are separated from
action **contributors** and from read-only **readers/auditors/QSA**.
**Why:** Least-privilege separation *is* PCI-DSS Requirement 7 (restrict access by need-to-know) applied
to the compliance program itself, and it is the auditable access control behind the evidence. Evidence
is only defensible if access to it was governed.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or, via `Connect-IPPSSession`,
`Get-RoleGroupMember 'Compliance Manager Contributors'` etc.) shows the intended, separated membership.
`CMPPCI-Discovery.ps1` prints each group's membership as `PCI Roles – Separation Evidence` and flags
administrators who are also contributors. **Verify the exact role-group names in your tenant — Purview
role naming evolves.**
**Implement:** Assign membership under change control with `CMPPCI-Set-Scope.ps1` (`-WhatIf` first, then
`-Commit`); grant the **minimum** role each person needs and keep readers/auditors/QSA read-only.

## 2.4 Unified audit logging enabled and retained (PCI-DSS Req 10)
**Description:** **Unified audit logging** (Purview Audit) **enabled** tenant-wide, with a **retention**
period that meets PCI-DSS Requirement 10's log-retention expectation (PCI-DSS calls for a minimum
retention with recent logs immediately available — **confirm the exact figure against your PCI-DSS
version/QSA**). **Audit (Premium)** provides longer default retention and custom retention policies and
requires E5-class licensing.
**Why:** Requirement 10 (log and monitor all access to system components and cardholder data) is a
**direct** Purview control — the audit log is the evidence that access is recorded. If logging is off or
under-retained, the requirement fails at the source.
**Verify:** `Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled` returns `True`; check
audit-retention policies in the portal. `CMPPCI-Discovery.ps1` / `CMPPCI-Validation.ps1` report the
ingestion state and any custom retention policies they can read. **Confirm the required retention figure
against your PCI-DSS version/QSA — do not assume.**
**Implement:** Enable unified audit logging (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
$true`) and configure an audit-retention policy that meets the requirement; verify Audit (Premium)
entitlement for extended retention.

## 2.5 Cardholder-data sensitive information type and classification confirmed (PCI-DSS Req 3)
**Description:** The **sensitive information type (SIT)** that detects cardholder data — the built-in
**Credit Card Number** SIT (and any custom/**EDM** SIT your CDE needs for stored PAN) — confirmed
available, and an understanding of **where cardholder data lives** across the in-scope workloads
(Exchange, SharePoint, OneDrive, Teams, and endpoints where in scope).
**Why:** Requirement 3 (protect stored account data) keys off detecting PAN. The DLP policy and label
depend on the SIT; if the SIT is wrong or PAN lives outside the scanned workloads, protection has gaps.
**Verify:** `Get-DlpSensitiveInformationType` lists the **Credit Card Number** SIT (and any custom
SITs); Purview **Data Classification / Content Explorer** shows where the SIT is detected.
`CMPPCI-Discovery.ps1` confirms the SIT is present. **Note:** PAN detection is pattern/checksum-based
and can false-positive/negative — treat matches as signals to review, not proof.
**Implement:** Confirm the built-in SIT; where the CDE needs precise matching of known PANs, plan a
custom **Exact Data Match (EDM)** SIT (its own effort). Confirm the in-scope workloads cover where PAN
resides.

## 2.6 Cardholder-data DLP + label design agreed, to be piloted in SIMULATION (PCI-DSS Req 3)
**Description:** The design of the cardholder-data **DLP policy** (`DLP-PCI-CardholderData`) and
**sensitivity label** (`Label-PCI-CardholderData`) — the workloads in scope, the actions (audit /
notify / restrict / block), and the exceptions — with the explicit intent to deploy the DLP policy in
**test/simulation mode first** and only enforce after validation.
**Why:** DLP and labels are **high-impact**: an over-broad block on cardholder data can disrupt
legitimate payment operations. Simulation mode shows what *would* be caught with no user impact, so you
tune before enforcing. This is the category's Assess→…→Pilot(simulate)→Expand(enforce) rule.
**Verify:** The policy/label design, in-scope workloads, actions, and exceptions are documented, and
the agreed rollout is **simulation → validate → enforce**. `CMPPCI-Discovery.ps1` reports any existing
Credit Card Number DLP policy/label and its mode.
**Implement:** Build the DLP policy in **`TestWithNotifications`/`TestWithoutNotifications` (simulation)
mode** with `CMPPCI-Configuration.ps1` (`-WhatIf` first, then `-Commit`); publish the label to the
pilot scope; move to enforce only after Testing (`05-testing.md`) passes.

## 2.7 Improvement-action owners and evidence sources identified (PCI-DSS Req 12)
**Description:** For the pilot assessment, the **owner** of each improvement action, the **target
date**, and the **evidence source** — including, for the out-of-scope-for-Purview requirements
(firewalls, segmentation, physical, anti-malware, testing), the **link to the owning system's
evidence** so the whole standard is represented in one record.
**Why:** A score with no owners and no evidence is not defensible; Requirement 12 expects documented,
owned security policy. Ownership and evidence source turn recommendations into a trackable, auditable
plan (`PCI Action Plan – Pilot`, `PCI Evidence – Register`).
**Verify:** Each in-scope action has an owner, a target date, and a named evidence source;
out-of-scope requirements carry an evidence link. **Implement:** Build the action plan with
`CMPPCI-Configuration.ps1` (`-WhatIf` first) from the owner-provided list; capture the evidence source
per action.

## 2.8 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (`Connect-IPPSSession` for
role-group, DLP, label, and audit cmdlets) and **Microsoft Graph PowerShell** (for licensing evidence),
used with a modern-auth / MFA-capable admin holding the appropriate Compliance and read roles.
**Why:** The five provided scripts assess readiness, configure the cardholder-data DLP in simulation,
validate the technical evidence, and report — through Security & Compliance PowerShell and Graph.
Compliance Manager assessments/evidence are **portal-managed**; the scripts support them.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup`,
`Get-DlpCompliancePolicy`, and `Get-AdminAuditLogConfig` return data. `CMPPCI-Discovery.ps1` performs
these checks. **Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module
Microsoft.Graph`; sign in with the role-holding admin and grant the read scopes the scripts request.

## 2.9 A pilot scope and change control (simulation before enforcement)
**Description:** A named **pilot scope** (`SG-PCI-Pilot` — users/sites in the CDE or a representative
subset) validated first — the assessment, action plan, DLP **in simulation**, and label — before
tenant-wide enforcement, plus a **change-control** path for moving DLP from simulation to enforce
(consistent with `global-requirements-purview.md` §6).
**Why:** Enforcing cardholder-data DLP across the whole tenant at once is high-impact; validating one
scope end-to-end proves ownership, evidence, and the DLP's precision before scaling. DLP enforcement is
piloted in simulation under change control.
**Verify:** A named pilot scope and owner exist; the DLP policy is in simulation mode; a change
window/approval path for enforcement is defined. **Implement:** Choose the pilot scope, validate it
end-to-end (Testing), then expand; agree change control before moving DLP to enforce.
