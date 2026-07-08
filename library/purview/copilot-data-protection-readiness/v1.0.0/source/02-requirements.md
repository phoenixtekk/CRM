# 2. Requirements Guide — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

Verify **every** requirement before configuring. Each entry gives **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant compliance licensing, least-privilege
Purview roles, the Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/
records/privacy/legal stakeholders, and a pilot scope + change control) are in
`global-requirements-purview.md` (GR §1–§6) — this guide adds the **Copilot-readiness-specific**
prerequisites and points back to the relevant GR item.

> **Availability caveat.** Several controls below (DLP for Microsoft 365 Copilot, Restricted SharePoint
> Search, Restricted Content Discovery, SharePoint Advanced Management data-access-governance reports,
> container and mandatory labeling) are **licensing-/tenant-dependent** and some are **evolving or in
> preview**. Where this guide names a portal path, policy location, or cmdlet, **confirm it exists in
> your tenant** rather than assuming — items marked *(verify)* are "verify in your tenant" by design.

## 2.1 Compliance licensing for the readiness controls (verify)
**Description:** The licensing the remediation levers require — commonly **Microsoft 365 E5** or the
**E5 Compliance** add-on for advanced DLP, auto-labeling, and container labeling; **SharePoint Advanced
Management (SAM)** for the Data Access Governance oversharing reports, site access reviews, Restricted
Content Discovery, and Restricted Access Control; and, for the AI controls, a **Microsoft 365 Copilot**
license (SAM is reported to be included with Copilot — *verify in your tenant*). The **DLP for Microsoft
365 Copilot** location availability is evolving and licensing-gated *(verify)*.
**Why:** These controls are plan-gated; the Copilot DLP location, SAM reports, and auto-labeling simply
will not appear without the right plan.
**Verify:** In the M365 admin center confirm the subscriptions/add-ons; in the Purview portal confirm
**Information Protection**, **Data Loss Prevention**, and (if used) **DSPM for AI** render; in the
SharePoint admin center confirm the SAM reports/controls are present. Run `AICOPILOT-ReadinessScope.ps1`
(read-only) to enumerate the labels, DLP, and auto-labeling features available to feed remediation.
**Implement:** Assign/purchase the required licensing before starting; where a control is absent, note it
out of scope and proceed with the licensed subset (e.g. do access remediation via native SharePoint
sharing controls if SAM is not licensed).

## 2.2 Least-privilege Purview & SharePoint roles (GR §2)
**Description:** Membership in the least-privilege role groups the work needs: **Information Protection
Admin** (labels, label policies, auto-labeling), **Compliance Administrator / DLP** role for DLP
policies, and **SharePoint Administrator** for the SharePoint access controls (DAG reports, RSS, RCD,
site access). Reading DSPM for AI needs the matching information-protection/DSPM role. Confirm the
**exact current role-group names** in your portal.
**Why:** Purview and SharePoint use fine-grained roles; creating a label vs. a DLP policy vs. changing
site access each need the matching role, and separation of duties should be preserved.
**Verify:** Purview portal → **Settings / Roles & scopes → Role groups** for the compliance roles;
Microsoft 365 admin center → roles for **SharePoint Administrator**. Confirm you can open Information
Protection, DLP, and the SharePoint admin center without an access error.
**Implement:** Assign the least-privilege role groups under change control; reserve Global/Compliance
Administrator for initial enablement only.

## 2.3 Purview auditing (unified audit log) on (GR §4)
**Description:** The **unified audit log** enabled, so Copilot interactions, sharing events, and label
activity are recorded and available to DSPM for AI, activity explorer, and the validation reports.
**Why:** Readiness evidence (what Copilot touched, what changed) and DSPM for AI reporting draw on
auditing; without it you cannot validate or evidence outcomes.
**Verify:** Purview portal → **Audit** shows searching is on; `AICOPILOT-ReadinessScope.ps1` reports the
audit state.
**Implement:** Turn on auditing (it may take time to fully populate) before relying on the reports.

## 2.4 A sensitivity-label taxonomy and classification intent (GR §4, §5)
**Description:** An agreed **sensitivity-label taxonomy** (or a decision to use a starter set) and a
**classification intent** — which labels denote content that must be protected from broad access / kept
out of Copilot — approved by compliance/privacy stakeholders. Protected labels that Copilot should honor
must carry **encryption with usage rights**.
**Why:** Labels are the primary Copilot control (Copilot honors label encryption/usage rights, and DLP
for Copilot keys off labels). Auto-labeling and DLP have nothing to act on without a taxonomy and intent.
**Verify:** Purview portal → **Information Protection → Sensitivity labels**; confirm the labels and,
for protected ones, that encryption/usage rights are configured. Confirm the intent with stakeholders
(GR §5).
**Implement:** If the taxonomy is thin or absent, define a minimal starter taxonomy and the "keep out of
Copilot" intent with stakeholders **before** authoring auto-labeling/DLP — a thin taxonomy is itself an
early finding. (Full taxonomy *design* is a separate exercise; here you need enough to remediate.)

## 2.5 In-scope SharePoint/OneDrive/Teams estate and Copilot rollout ring (GR §4, §6)
**Description:** The **workloads and sites in scope** for oversharing discovery (SharePoint, OneDrive,
Teams/Groups) and the **Copilot rollout ring** — the pilot population who will get Copilot first, which
doubles as the readiness pilot scope.
**Why:** Oversharing discovery and remediation key off the in-scope sites; piloting readiness on the
same ring that gets Copilot first keeps the pilot representative.
**Verify:** Confirm the in-scope sites/workloads and the named Copilot pilot ring with stakeholders.
**Implement:** Define the scope and the rollout ring before discovery; if Copilot is not yet deployed,
you are in **pre-adoption** mode — the goal is to remediate oversharing *before* enabling Copilot.

## 2.6 SharePoint Advanced Management controls availability (verify)
**Description:** Availability of the SharePoint access controls this playbook uses: **Data Access
Governance (DAG)** oversharing reports (sharing links, "Everyone Except External Users," sensitivity
labels applied), **site access reviews**, **Restricted Content Discovery (RCD)** (excludes a site's
content from Copilot and org-wide search), **Restricted Access Control (RAC)** (limits a site to a named
group), and **Restricted SharePoint Search (RSS)** (an interim allow-list of up to 100 sites for
search/Copilot). *(All are SAM/SharePoint-admin features; availability and exact names are
tenant-dependent — verify.)*
**Why:** These are the access-remediation and interim-containment levers; RSS/RCD let you fence off
not-yet-cleaned sites from Copilot while you remediate properly.
**Verify:** SharePoint admin center → **Reports / Settings / Data access governance**; confirm the
reports and controls are present. RSS state is checked via SharePoint Online Management Shell
(`Get-SPOTenantRestrictedSearchMode`) — *documented method, run under SharePoint admin*.
**Implement:** If SAM is unlicensed, remediate access via native SharePoint site/sharing settings and
Microsoft Graph permission review instead, and note the interim controls as unavailable.

## 2.7 Pilot in simulation/test and change control (GR §6)
**Description:** A confirmed **pilot ring**, that **simulation/test/disabled** mode is available for
labeling and DLP, and a **change window/approval path** — no label policy, auto-labeling policy, DLP
policy, or sharing restriction is enforced before it is piloted and validated.
**Why:** Labels, DLP, and access changes are high-impact; the house model mandates
Assess→Design→Configure→**Pilot (simulate/test)**→Validate→Expand(enforce).
**Verify:** Confirm the named pilot ring, that auto-labeling supports **simulation** and DLP supports
**test/disabled**, and the change-control path.
**Implement:** Define the pilot and agree change control before enforcing anything.

## 2.8 Stakeholder ownership of the go/no-go (GR §5)
**Description:** Named **compliance, records, privacy, security, and legal** owners who will approve the
final **Copilot readiness go/no-go**, and agreement that they own the determination of "acceptable
exposure."
**Why:** The decision to enable Copilot broadly is a governance decision, not a technical one; this
solution supplies the evidence, the owners make the call.
**Verify:** Confirm the named approvers and the criteria they will judge against.
**Implement:** Identify the owners and capture the readiness criteria before the pilot so the go/no-go is
decided against agreed gates, not improvised.
