# 2. Requirements Guide — Implementing Microsoft Purview: Foundation, Roles & Onboarding

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Compliance licensing inventory (which capabilities are actually available)
**Description:** A confirmed inventory of the tenant's **compliance licensing** — E3 for baseline
capabilities, **Microsoft 365 E5** or the **E5 Compliance** add-on for advanced DLP, auto-labeling,
insider risk, communication compliance, Audit Premium (long-term retention), and DSPM.
**Why:** Purview capabilities are plan-gated; the foundation must record what the current plan unlocks
so downstream capability solutions are scoped to what you can actually use (Global Requirement 1).
**Verify:** Microsoft 365 admin center → `Billing → Licenses` shows the subscriptions/add-ons; run
`PURVIMP-Assess-Readiness.ps1` — it reads `subscribedSkus` via Graph and reports which compliance SKUs
are present. Confirm capabilities appear in the Purview portal.
**Implement:** Assign/purchase the required licensing before enabling a capability that needs it. Where
a capability is not licensed, record it as out-of-scope for now rather than attempting to enable it.

## 2.2 Least-privilege Purview admin access (not blanket Global Admin)
**Description:** An account holding **Compliance Administrator** (to configure Purview) plus, for the
one-time setup actions that require it, a **Global Administrator** who enables the unified audit log and
consents Graph scopes. Everyday configuration uses the least-privilege compliance role, per Global
Requirement 2.
**Why:** Purview's fine-grained role model exists to limit exposure to sensitive compliance data;
over-granting Global Administrator undermines the foundation you are building.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path in your tenant) —
confirm your account is in **Compliance Administrator**. `Connect-IPPSSession` succeeds.
**Implement:** Add the account to **Compliance Administrator**; reserve a named Global Administrator only
for the audit-enablement and Graph-consent steps.

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides
`Connect-IPPSSession` for Security & Compliance PowerShell **and** `Connect-ExchangeOnline` for the
audit-config cmdlets) and the **Microsoft Graph PowerShell SDK**, with a modern-auth/MFA admin account
(Global Requirement 3).
**Why:** Every script in this solution runs through S&C PowerShell, Exchange Online PowerShell, and/or
Graph.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `PURVIMP-Assess-Readiness.ps1` installs
missing modules and reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph permission scopes (consented, read-first)
**Description:** Delegated Graph scopes for the read-only assessment and baseline:
`Organization.Read.All`, `Directory.Read.All`, `User.Read.All`, `RoleManagement.Read.Directory`,
`SecurityEvents.Read.All` (Secure Score). No write scopes are required for the foundation scripts.
**Why:** The readiness, baseline, and scope scripts read licensing, role, and Secure Score data through
Graph; keeping to read scopes matches the safe-by-default posture.
**Verify:** Run `PURVIMP-Report-ComplianceBaseline.ps1` (read-only) — it connects with the read scopes
and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 In-scope workloads and endpoint onboarding intent
**Description:** The **workloads in scope** for Purview — Exchange Online, SharePoint Online, OneDrive,
Teams (connected by virtue of being M365 workloads) and **endpoints/devices** (which require explicit
onboarding to Purview) — plus the classification/sensitivity intent that will drive labels, DLP, and
retention later (Global Requirement 4).
**Why:** Purview policies key off the in-scope workloads; endpoints in particular are not automatically
connected and must be onboarded before endpoint DLP can see them.
**Verify:** Run `PURVIMP-Scope-Config.ps1` — it confirms the M365 workloads and reports device
onboarding status from the Purview device-onboarding surface. Confirm the in-scope list with
stakeholders.
**Implement:** Define the scope; plan endpoint onboarding (Purview portal → `Settings → Device
onboarding`, verify path) for a later endpoint-DLP solution — the foundation records readiness, it does
not roll out device onboarding tenant-wide.

## 2.6 Unified audit log — enable early
**Description:** The **unified audit log** turned on so activity is recorded from day one (search and
long-term retention are licensing-dependent).
**Why:** Audit history **cannot be back-filled** — if ingestion was never enabled, the record simply
does not exist. Content Explorer, Activity Explorer, and every investigation depend on it.
**Verify:** `PURVIMP-Enable-CoreServices.ps1` (read-only by default) reports
`UnifiedAuditLogIngestionEnabled`; in the portal, audit search returns results.
**Implement:** Enable with `PURVIMP-Enable-CoreServices.ps1 -Commit` (wraps
`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`) — a one-time action; ingestion can take
up to ~24 hours to begin surfacing results.

## 2.7 Content Explorer / Activity Explorer visibility roles
**Description:** The role groups that grant visibility into classified content — **Content Explorer
Content Viewer** and **Content Explorer List Viewer** — assigned to the people who need to see what is
classified where (Activity Explorer visibility comes with the data-classification roles).
**Why:** These Explorers are the foundation's *observability*; without the viewer roles, admins cannot
see classification results even though the data is being classified.
**Verify:** Run `PURVIMP-Enable-CoreServices.ps1` — it reports whether the viewer role groups exist and
have members. In the portal, `Data classification → Content explorer` renders.
**Implement:** Add the intended reviewers to the viewer role groups with `PURVIMP-Set-RoleGroups.ps1`.

## 2.8 Stakeholders and a captured Compliance Manager baseline
**Description:** Engagement with **compliance, records, privacy, security, and legal** stakeholders
(Global Requirement 5), and a **captured Compliance Manager baseline** score/assessment exported from
the portal.
**Why:** The foundation aligns to enterprise policy, not technical defaults; the captured baseline makes
future compliance improvement measurable. Regulatory/records/legal determinations are the stakeholders'
to make.
**Verify:** Named approvers are recorded; Purview portal → `Compliance Manager` shows a score, and you
have exported the assessment (`Assessments → Export`). `PURVIMP-Report-ComplianceBaseline.ps1` captures
the supporting signals (Secure Score, audit status, role posture).
**Implement:** Identify owners; open Compliance Manager, note the current score and the default
data-protection baseline assessment, export it, and store it as `Purview Compliance Baseline – Report`.

## 2.9 A pilot ring and change control
**Description:** A small **pilot ring** (`Purview Pilot Ring – Stage1`) — a handful of named admins and
one or two in-scope sites/teams — and a **change-control** process, per Global Requirement 6.
**Why:** The foundation is validated on the ring before the tenant is treated as production-ready; every
downstream capability policy is piloted in simulation/test/disabled mode in its own solution.
**Verify:** The ring is defined and a change window/approval path exists.
**Implement:** Define the ring and agree change control before applying role or service changes.

---
## Checklist
- [ ] Compliance licensing inventoried; available capabilities recorded (E3 vs E5 / E5 Compliance)
- [ ] Compliance Administrator access confirmed; Global Admin reserved for one-time setup
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] Graph read scopes consented (no write scopes needed for the foundation)
- [ ] In-scope workloads agreed; endpoint onboarding readiness assessed
- [ ] Unified audit log enabled (or scheduled to enable early)
- [ ] Content/Activity Explorer viewer roles assigned
- [ ] Stakeholders named; Compliance Manager baseline exported as `Purview Compliance Baseline – Report`
- [ ] `Purview Pilot Ring – Stage1` defined; change control agreed
