# 2. Requirements Guide — Microsoft Purview FINRA/SEC Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the FINRA/SEC-program
detail.

> **Regulatory/licensing boundary.** Regulatory records, Communication Compliance, Audit Premium, and
> auto-classification require **Microsoft 365 E5** or the **E5 Compliance** add-on and evolve; confirm
> your entitlements rather than assuming. **Which rules apply, which records/communications are in
> scope, which retention periods and supervisory lexicons are required, and whether a configuration
> satisfies FINRA/SEC** are **compliance/records/legal determinations** — this solution configures the
> control and produces evidence; it does not make the determination. Where this guide flags "verify
> your licensing/tenant" or "compliance/legal to determine," do so before relying on the item.

## 2.1 Compliance licensing for records, supervision, and audit evidence
**Description:** The program spans three licensed control domains. **Records/regulatory-records
retention** and **auto-classification** need **E5 / E5 Compliance**; **Communication Compliance** needs
**E5 / E5 Compliance** (or the Insider Risk Management add-on family); **Audit Premium** (high-value
events, long-term retention) needs **E5 / E5 Compliance / Audit add-on**, assigned **per user**.
**Why:** Every control below is plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `CMPFINRA-Discovery.ps1`, which reports
whether records/Communication-Compliance/Audit-Premium-bearing plans are present via Graph. **Confirm
plan/service-plan names against your tenant — they change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to in-scope users before expecting the feature.

## 2.2 Least-privilege roles with reviewer separation
**Description:** Distinct least-privilege roles for each domain — **Records Management** / **Retention
Management** for labels & policies; **Compliance Administrator** / **Communication Compliance** role
groups (Admin, Analyst, Investigator, Viewer) for supervision, kept **separate** from the configuring
admin; **Audit Manager/Reader** for evidence; **Compliance Manager** roles for assessments. Global
Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups; **Communication Compliance is HR/privacy-sensitive and
demands reviewer role separation** so configurers can't self-review and reviewers see only their scope (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`CMPFINRA-Scope.ps1` reports the role groups it can see and connection identity.
**Implement:** Assign the least-privilege role groups under change control; document the reviewer
separation for the supervision control.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
retention labels/policies, `*-RetentionCompliancePolicy`/`*-ComplianceTag`, `*-SupervisoryReview*`,
`*-UnifiedAuditLogRetentionPolicy`) and `Microsoft.Graph` (licensing reads), with a modern-auth/MFA admin.
**Why:** All configuration and the provided scripts run through Security & Compliance PowerShell and
Graph (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and
`Connect-MgGraph` succeed; `CMPFINRA-Discovery.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`;
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 In-scope population, workloads, and communications channels
**Description:** The **registered/covered persons** in scope, the **workloads** holding books-and-records
(Exchange, SharePoint, OneDrive, Teams) and the **communication channels** to supervise (Exchange email,
Teams chat/channels, and any connected channels), plus a **classification intent** to drive labels.
**Why:** Retention, supervision, and audit controls key off the in-scope population/workloads/channels (GR §4).
**Verify:** Confirm the population (a group/OU of covered persons), the in-scope workloads/channels, and
the classification approach with compliance; `CMPFINRA-Scope.ps1` enumerates the target group's members
and the mailboxes/sites in scope (read-only).
**Implement:** Define the covered-persons group and the in-scope workloads/channels before authoring
controls.

## 2.5 The rule-to-control map and retention schedule (from compliance/records/legal)
**Description:** A documented statement — **from compliance, records, and legal** — of which FINRA/SEC
obligations are in scope, what must be **retained and for how long** (the records schedule), which
communications must be **supervised** and against what conditions/lexicon, and who approves.
**Why:** Rule applicability, retention duration, and supervisory scope are **regulatory/legal
determinations**, not technical defaults (GR §5); the solution configures to them and evidences them —
it does not decide them.
**Verify:** You can name, per control domain, the obligation, the required retention/supervision, and
the named approver; these populate the `Control Map – FINRA/SEC – Purview` register.
**Implement:** Capture the rule-to-control map, retention schedule, and supervisory scope with approvals
before configuring — especially before any **regulatory-records** (irreversible) label.

## 2.6 Communication Compliance privacy & governance preconditions
**Description:** For the supervision control specifically: agreement on **privacy-by-design** (data
minimization, **pseudonymization** of monitored users where the tenant supports it), **reviewer role
separation**, works-council/employee-notice obligations where applicable, and the disposition of review
outcomes.
**Why:** Supervision reads employees' communications — it is HR/privacy-sensitive; outcomes and case
actions are **HR/legal's**, and mis-scoped monitoring is a privacy risk (GR §5, and the category's
insider-risk/comms-compliance sensitivity rule).
**Verify:** Named reviewers (separated from configurers), a privacy/notice sign-off, and whether
pseudonymization is enabled in the tenant.
**Implement:** Obtain the privacy sign-off and reviewer roster; enable pseudonymization if required;
**build the policy in test mode** until sign-off is complete.

## 2.7 Unified audit logging on, and an evidence-retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the audit-trail control captures
evidence, plus a documented statement of how long audit **evidence** must be retained.
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a compliance determination (GR §5/§6).
**Verify:** `CMPFINRA-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit
retention policies.
**Implement:** Enable unified audit under change control (via the Purview Audit solution / Exchange
Online), then create the evidence-retention policy in Step 4 of the Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`FINRA/SEC Pilot – Registered Persons – Stage1` — a small set
of covered persons/mailboxes/sites) and a **change-control** window. Retention labels can be trialed with
**non-regulatory** records first; Communication Compliance supports a **test mode**; audit changes are
reversible.
**Why:** Records/regulatory-records, supervision, and retention are **high-impact** — regulatory records
are effectively irreversible — so every change is piloted in simulation/test/disabled mode before
enforcement (GR §6).
**Verify:** A named pilot scope, confirmation that test/disabled mode is available for each control, and a
change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling or applying any control —
**never apply a regulatory-records label outside the pilot without explicit compliance sign-off.**
