# 2. Requirements Guide — Microsoft Purview NIST 800-53 Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control) are in
`global-requirements-purview.md` — this guide adds the NIST 800-53-specific detail.

> **Licensing/tenant boundary.** The Compliance Manager **NIST SP 800-53 premium template**, advanced DLP,
> auto-labeling, and DSPM require **Microsoft 365 E5** or the **E5 Compliance** add-on. Portal paths,
> improvement-action counts, and template versions **evolve** — confirm the current template and your
> entitlements rather than assuming. Where this guide flags "verify your licensing/tenant," do so before
> relying on the feature.
>
> **Authorization boundary.** This solution provides the technical configuration and evidence. The
> **authorization determination (ATO), the authorization boundary, residual-risk acceptance, and control
> applicability/tailoring are deferred to your Authorizing Official, security, compliance, records, privacy,
> and legal functions.**

## 2.1 Compliance licensing for the NIST 800-53 template and supporting controls
**Description:** Compliance Manager's **NIST SP 800-53 Rev. 5** assessment is a **premium template** (beyond
the default Data Protection Baseline) and the supporting controls (advanced/auto-labeling DLP, DSPM,
Audit Premium retention) require **E5** or the **E5 Compliance** add-on. Premium-template packs may also be
metered/licensed separately in your tenant.
**Why:** The template and several supporting controls are plan-gated; without the right plan the template
won't be addable and the controls won't be available (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; in Purview, `Compliance Manager → Assessment templates`
— confirm **NIST SP 800-53** is listable/addable. `CMPNIST-Scope.ps1` reads `subscribedSkus`/service plans
via Graph and reports whether an E5/E5-Compliance-bearing plan is present.
**Implement:** Assign/purchase E5 or E5 Compliance before adding the template; confirm premium-template
availability for your licensing.

## 2.2 Purview roles (least-privilege) for Compliance Manager and the supporting controls
**Description:** **Compliance Manager** uses its own role groups (**Compliance Manager Administrator /
Assessor / Contributor / Reader**). Configuring the supporting controls needs **Compliance Administrator**
or **Compliance Data Administrator**, plus the capability-specific roles: **Information Protection** (labels),
the **DLP** roles, **Records Management**, and **Audit** roles. Reserve Global Administrator for one-time
enablement only.
**Why:** Purview uses fine-grained role groups; assessment work, DLP, labels, retention, and audit each need
the matching role (GR §2). Separation of duties is itself a NIST control (AC-5).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership. `CMPNIST-Scope.ps1`
attempts the read operations and reports which endpoints/roles are accessible.
**Implement:** Assign the least-privilege role groups under change control; give assessors **Compliance
Manager Reader/Assessor**, the configuring admin the capability roles, keeping duties separated.

## 2.3 Security & Compliance PowerShell + Exchange Online PowerShell + Graph
**Description:** The `ExchangeOnlineManagement` module provides `Connect-IPPSSession` (Security & Compliance
PowerShell — DLP, labels, retention, `*-UnifiedAuditLogRetentionPolicy`) and `Connect-ExchangeOnline`
(`Get/Set-AdminAuditLogConfig`, mailbox audit). `Microsoft.Graph` is used for licensing/role reads.
**Why:** The supporting-control inventory and configuration run through these endpoints; the scripts use the
right one for each task (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession`, `Connect-ExchangeOnline`,
and `Connect-MgGraph` all succeed with a modern-auth/MFA admin. `CMPNIST-Scope.ps1` reports which endpoints
are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph
-Scope CurrentUser`.

## 2.4 In-scope system boundary, data, and workloads (from the security/AO function)
**Description:** A documented statement of the **system/authorization boundary** the 800-53 assessment covers
— the in-scope workloads (Exchange, SharePoint, OneDrive, Teams, endpoints) and the **information types /
impact level** (e.g. moderate/high) that drive which controls and labels apply.
**Why:** NIST control applicability and the label/DLP/retention design key off the boundary and impact level;
these are **AO/security determinations**, not technical defaults (GR §4, §5).
**Verify:** You can name the authorization boundary, the in-scope workloads, and the impact level, with named
approvers.
**Implement:** Capture the boundary, impact level, and in-scope data from the security/AO function before
mapping controls. **The boundary determination is deferred to them.**

## 2.5 Control applicability / tailoring baseline (deferred to compliance/security)
**Description:** The **tailored control baseline** — which 800-53 controls (and which control enhancements)
apply at your impact level, and any tailoring/inheritance decisions.
**Why:** Not every control applies, and Purview only implements a subset; the map must record which controls
are in scope, which Purview covers, and which are deferred to process. **Applicability is a governance
determination** (GR §5).
**Verify:** You have the tailored baseline (or the relevant overlay) and named approvers; you can identify the
technical families Purview will support.
**Implement:** Obtain the tailored baseline from compliance/security before building the control-to-Purview
map. **The applicability/tailoring determination is deferred to them.**

## 2.6 Unified audit logging and audit-evidence retention requirements (AU family)
**Description:** For the **AU** family, unified audit logging must be **on** and an audit-log **retention
requirement** (how long which events are kept) must be defined by compliance/records — the solution
configures `Control Evidence – NIST AU – Audit Retention` to it.
**Why:** AU-2/AU-6/AU-11 evidence only exists if logging is on and retained; audit is **not retroactive**
(GR §6 change discipline). Retention duration is a records determination, not a technical default.
**Verify:** `Get-AdminAuditLogConfig | FL UnifiedAuditLogIngestionEnabled` (should be `True`); a documented
retention requirement per event class exists. `CMPNIST-Discovery.ps1` reports logging state and existing
retention policies.
**Implement:** Enable ingestion under change control (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
$true`); capture the retention requirement. **The retention-schedule adequacy is deferred to compliance/records.**

## 2.7 A pilot scope and change control (simulation/test first)
**Description:** A limited **pilot** — a bounded user/site set and the supporting DLP policy in
**simulation/test mode** — to validate before tenant-wide enforcement, plus an agreed change window (GR §6).
Purview DLP supports a **test/simulation mode** that MUST be used before enforce.
**Why:** DLP, label, and retention changes are high-impact; validate them small and in simulation first.
**Verify:** A named pilot scope (`NIST Pilot – Control Set – Stage1`), that DLP simulation mode is available,
and a change approval exist.
**Implement:** Define the pilot scope and change window; keep new DLP policies in simulation until validated.

## 2.8 Evidence-handling and assessment-package requirements (from the assessor/AO)
**Description:** How control evidence must be **collected, formatted, and retained** for the assessment
package (e.g. improvement-action artifacts in Compliance Manager, policy exports, audit-config snapshots),
and who signs off.
**Why:** The assessor/AO consumes the evidence; the format and retention are their requirement. The solution
produces the artifacts; it does not judge sufficiency.
**Verify:** You can name the evidence format, the retention for evidence, and the assessor/AO approvers.
**Implement:** Capture the evidence requirements before generating `NIST 800-53 – Control Evidence – Report`.
**Evidence sufficiency and the authorization decision are deferred to the assessor/AO.**
