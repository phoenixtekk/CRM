# 2. Requirements Guide — eDiscovery Readiness Assessment (Microsoft Purview)

These are the prerequisites to run the **assessment and the readiness proof**. They complement — and
do **not** repeat — the six shared **[Purview category Global Requirements](global-requirements-purview.md)**
(compliance licensing, least-privilege Purview roles, S&C PowerShell + Graph toolchain, in-scope data
sources, compliance/records/legal stakeholders, and a pilot scope + change control). Verify each of
the six there first; the solution-specific items below add the eDiscovery detail. Each entry is
**Description · Why · Verify · Implement-if-missing.**

## 2.1 eDiscovery tier / licensing known (Standard vs Premium)
**Description:** Confirmation of which eDiscovery tier the tenant is licensed for. **Content Search**
and **eDiscovery (Standard)** cases and holds are available in most enterprise plans (e.g. Microsoft
365 E3); **eDiscovery (Premium)** — custodians, review sets, analytics/de-duplication, structured
export — requires **Microsoft 365 E5** or the **E5 eDiscovery and Audit** add-on (see category GR #1).
**Why:** Readiness for a Premium *review* workflow cannot be asserted without the Premium tier; the
assessment must record the tier so the scorecard reflects real capability, not aspiration.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; open `https://purview.microsoft.com`
→ **eDiscovery** — if you cannot create custodians/review sets you are on Standard only. Run
`EDREADY-Discovery.ps1` (reports which case types/holds exist). **Plan names and gating change —
verify in your tenant.**
**Implement:** Record the tier in the scorecard. If Premium review capability is required and absent,
assign E5 / E5 eDiscovery and Audit before claiming Premium readiness.

## 2.2 eDiscovery role groups (least privilege) — the assessor's access
**Description:** The assessor needs at least **eDiscovery Manager** to read cases/searches and place
the proof hold, and visibility of **eDiscovery Administrator** membership; reading role membership
needs an appropriate Purview role (category GR #2). No Global Administrator is used to run the proof.
**Why:** The assessment evaluates *whether roles are least-privilege*; the assessor themselves must
operate through the role groups, modelling the target state.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles & scopes → Permissions →
Microsoft Purview solutions → eDiscovery Manager / eDiscovery Administrator**; or PowerShell
`Get-RoleGroupMember "eDiscovery Manager"` / `Get-RoleGroupMember "eDiscovery Administrator"`. Run
`EDREADY-Discovery.ps1`.
**Implement:** Add the assessor to **eDiscovery Manager** (and note the current membership as an
assessment finding). Do **not** grant Global Admin for the assessment.

## 2.3 Unified audit log enabled (defensibility evidence)
**Description:** The Microsoft Purview **unified audit log** is on, so case, search, hold, and export
activity — including the readiness proof — is recorded.
**Why:** The audit trail *is* the evidence of defensibility. A tenant with auditing **off** is a
high-severity readiness gap: preservation actions cannot be proven after the fact.
**Verify:** Purview → **Audit** returns results; or `EDREADY-Discovery.ps1` reads
`UnifiedAuditLogIngestionEnabled`.
**Implement:** Enable auditing (the remediation script can do this with `-Commit`), then allow time
for events to populate. Turning auditing on is itself a scored remediation item.

## 2.4 Data-source scope mapped (workloads + inactive mailboxes)
**Description:** A written map of the workloads a matter would have to cover — **Exchange** mailboxes
(remembering **Teams chat** is stored in mailboxes), **SharePoint** sites, **OneDrive** accounts, and
**Teams / M365 Group** sites and files — plus an inventory of **inactive/legacy mailboxes** and any
third-party/imported data (extends category GR #4).
**Why:** Coverage blind spots (Teams messages, M365 Group sites, inactive mailboxes) are the classic
cause of incomplete collection; readiness means these are known *before* a matter.
**Verify:** A scope note lists the workloads and any out-of-scope items; `EDREADY-Scope.ps1` reports
mailbox coverage, litigation-hold state, and inactive mailboxes.
**Implement:** Enumerate the workloads and inactive mailboxes; capture the map as a scorecard input.

## 2.5 Named legal/records owner + intake process (scope & hold determination)
**Description:** A named legal, compliance, or records owner who **decides** matter scope, custodians,
holds, and production, and a **matter-intake step** where that sign-off is captured before any
configuration (this is the eDiscovery-specific expression of category GR #5).
**Why:** Scope and hold are **legal determinations**, not IT defaults. Readiness is not just technical
— an org with perfect tooling but no intake/sign-off process is **not ready**.
**Verify:** A matter-intake template/record exists with a named legal owner and a hold-instruction
field. Confirmed with the stakeholder, recorded as a Process-domain finding.
**Implement:** Establish the intake step (legal signs off scope + hold before configuration). Absence
is a scored Process gap; the assessment provides the target-state description.

## 2.6 PowerShell modules and connectivity
**Description:** The **ExchangeOnlineManagement** module (provides **Security & Compliance PowerShell**
`Connect-IPPSSession` **and** Exchange Online `Connect-ExchangeOnline`, used by the scope/mailbox
checks) and, for Premium signals, the **Microsoft.Graph.Security** module (category GR #3).
**Why:** The five scripts run through these — compliance objects via S&C PowerShell, mailbox/inactive
coverage via Exchange Online, optional Premium case status via Graph. Graph cmdlet parameters are
version-dependent — **verify in your tenant.**
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Security`;
`Connect-IPPSSession` and `Connect-ExchangeOnline` succeed with modern auth (MFA).
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Security -Scope CurrentUser`. **Modern auth only — no stored
credentials or app secrets in scripts.**

## 2.7 Dedicated test account for the readiness proof (non-sensitive)
**Description:** A **dedicated, non-sensitive test account** (for example an IT scratch mailbox) with
a little seeded mail/files, used as the **proof custodian** so the full case → hold → search →
confirm → remove-hold rehearsal never touches a real person.
**Why:** The readiness proof is a **capability rehearsal**; it must run in test. Using a real
custodian would place a real hold — out of scope for an assessment and a legal action in its own right.
**Verify:** A test account exists (placeholder `readiness-pilot@contoso.com`) with seeded content.
**Implement:** Provision the test account, seed a few messages/files, and reserve the proof names from
Section 1's reference design.

## 2.8 Change control + rollback for the proof (and for remediation)
**Description:** A change record covering the readiness-proof hold and any remediation (role-group
changes, enabling audit), with a defined rollback (remove the proof hold/policy, revert role
membership) — the eDiscovery expression of category GR #6.
**Why:** Even a test hold and role changes are configuration changes in a production tenant; they
need an approver, a pilot gate, and a documented rollback.
**Verify:** A change ticket names the approver, the test scope, and the rollback steps.
**Implement:** Record the change; run remediation `-WhatIf` first; place the proof hold only after
sign-off; remove it at the end of the proof.

---
## Checklist
- [ ] Category GR #1–#6 verified (licensing, roles, toolchain, data scope, stakeholders, pilot/change control)
- [ ] eDiscovery **tier** known (Standard vs **Premium/E5**) — `EDREADY-Discovery.ps1` — *verify in tenant*
- [ ] Assessor in **eDiscovery Manager**; **eDiscovery Administrator** membership reviewed; no Global Admin for the proof
- [ ] **Unified audit log** status checked (on = ready; off = high-severity gap) — `EDREADY-Discovery.ps1`
- [ ] Workloads + **inactive mailboxes** mapped — `EDREADY-Scope.ps1`
- [ ] Named **legal/records owner** + **matter-intake** process on record
- [ ] Modules installed (`ExchangeOnlineManagement`, `Microsoft.Graph.Security`); modern auth works
- [ ] **Dedicated test account** for the readiness proof (non-sensitive, seeded)
- [ ] Change control + rollback for the proof hold and remediation
