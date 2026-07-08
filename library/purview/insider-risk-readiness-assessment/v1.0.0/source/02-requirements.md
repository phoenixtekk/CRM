# 2. Requirements — Insider Risk Readiness Assessment (Microsoft Purview)

These are the **solution-specific** prerequisites for an Insider Risk Management (IRM) **readiness
assessment** — the privacy, roles/role-separation, connectors, and scoping groundwork you complete **before**
deploying IRM against named users. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a
pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

> **IRM is largely portal-configured with a limited PowerShell/Graph surface.** Several items below are
> verified in the **Microsoft Purview portal**, not by a cmdlet. Where that is the case it is stated and
> flagged **"verify in the Purview portal / verify your licensing/tenant"** — this assessment never invents a
> cmdlet or portal path.

---

## 2.1 Licensing sufficient for Insider Risk Management (verify)
- **Description:** IRM is **plan-gated**. It typically requires **Microsoft 365 E5**, the **Microsoft 365 E5
  Compliance** add-on, or a dedicated **Insider Risk Management** add-on (education A5/A5 Compliance
  equivalents apply; some capabilities and analytics features may be in **preview**). This extends GR-#1 with
  the IRM-specific plan detail.
- **Why required:** Without the plan, **Insider Risk Management does not appear** in the Purview portal, the
  **Analytics** scan is unavailable, and no policy can be created — the entire capability is inert.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal** confirm **Insider Risk Management** is visible and openable. The Discovery script also
  reports a licensing **signal** by inspecting subscribed SKU service plans for an insider-risk plan —
  treat it as a signal, and **flag "verify your licensing/tenant."**
- **How to implement if missing:** Acquire/assign the required licensing before configuring; do not scaffold
  policies against a plan you do not hold.

## 2.2 The IRM role groups, assigned as SEPARATED duties
- **Description:** The distinct Purview **IRM role groups** — **Insider Risk Management Admins**
  (configure policies/settings/connectors), **Insider Risk Management Analysts** (triage alerts / work cases
  on **pseudonymized** data), **Insider Risk Management Investigators** (full case content, forensic
  evidence, **de-anonymized** identity within a case), and **Insider Risk Management Auditors** (review the
  IRM audit trail) — plus the all-powerful **Insider Risk Management** super-group. These must be assigned to
  **different people**, and IRM must be kept **separate from HR and Legal**. Extends GR-#2. This is the
  central control of an IRM deployment.
- **Why required:** Collapsing configuration, triage, investigation, and audit into one person (or handing the
  Investigator/de-anonymization role to HR/Legal by default) destroys the separation-of-duties that makes IRM
  defensible and privacy-respecting. Least privilege here is a privacy control, not just a security one.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (or Microsoft Purview
  roles); confirm membership of each IRM role group. The Discovery/Validate scripts enumerate the IRM role
  groups (`Get-RoleGroup` / `Get-RoleGroupMember`) and **flag separation conflicts** — the same identity in
  conflicting roles, or membership of the super-group.
- **How to implement if missing:** Assign each least-privilege IRM role group to a **different** named owner
  under change control; remove anyone from the super-group who does not require it; ensure HR/Legal are
  **reviewers/escalation** recipients, not default Investigators.

## 2.3 Privacy-by-design settings: anonymization ON and minimum indicators
- **Description:** The IRM **privacy** posture — **anonymization ("Show anonymized versions of usernames")
  turned ON** so analysts triage **pseudonymized** identities, and only the **minimum indicators** enabled for
  the intended policy. Configured in **Purview portal → Insider Risk Management → Settings → Privacy** and
  **→ Policy indicators**.
- **Why required:** IRM examines what named people do; **privacy-by-design is the deployment**. Anonymization
  is what lets triage happen without exposing identities, and minimizing indicators collects only what the
  policy needs — both are prerequisites to a defensible, works-council-/privacy-officer-acceptable rollout.
- **How to verify:** **Purview portal → Insider Risk Management → Settings → Privacy** shows the anonymization
  setting; **→ Policy indicators** shows enabled indicators. This is a **portal setting** — the scripts
  **direct you to verify it in the portal** (they do not toggle it) and flag it in the readiness scorecard.
- **How to implement if missing:** Turn anonymization **on** before any analyst has access; enable only the
  indicators the intended template requires; document the privacy decision with the privacy stakeholder.

## 2.4 The connectors the intended policy needs (HR / Entra / DLP / Defender), healthy
- **Description:** The **signal connectors** for the readiness policy: the **HR data connector**
  (`HR Connector – Readiness`) for resignation dates, role changes, and performance/PIP events (required by
  *departing-user* / *disgruntled-user* templates); the built-in **Entra** account-deletion signal; **DLP**
  policy signal; and **Microsoft Defender for Endpoint** integration for security-violation indicators.
  Optional **healthcare** and **physical-badging** connectors for those domains. Extends GR-#4.
- **Why required:** Templates are inert without their connectors — *data theft by departing users* needs the
  HR resignation signal or Entra account deletion; security-violation indicators need Defender integration.
  Readiness confirms the required connectors exist and are healthy *before* a policy is scoped.
- **How to verify:** **Purview portal → Data Connectors** shows configured connectors and their health/last
  import; **Insider Risk Management → Settings** shows Defender/DLP integration. Connector health is **portal-
  verified** — the scripts flag it as a portal check in the scorecard (connector state is not reliably
  scriptable). **Flag "verify in the Purview portal."**
- **How to implement if missing:** Stand up and schedule the **HR data connector** (CSV/API import per
  Microsoft docs), enable the Entra/DLP/Defender signals the template needs, and confirm a successful import
  before scoping the policy.

## 2.5 Audit logging enabled (the correlation substrate)
- **Description:** The **unified audit log** must be **enabled** in the tenant — IRM correlates M365 audit
  activity (downloads, sharing, DLP matches, device events) into risk signals.
- **Why required:** With audit logging off, IRM has little to correlate and the readiness reporting/validation
  scripts (which read audit state) cannot confirm a signal substrate exists.
- **How to verify:** The Discovery/Validate scripts read the audit configuration
  (`(Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled`) and report PASS/FAIL; also confirm in the
  Purview portal audit page.
- **How to implement if missing:** Enable unified audit logging (`Enable-OrganizationCustomization` /
  `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true` per Microsoft docs) and allow ingestion to
  begin before relying on IRM signal.

## 2.6 The readiness scope: a priority-user group and a chosen template
- **Description:** A **narrow readiness scope** — a **priority user group** (`IRM Priority Users – Readiness –
  Scope`, backed by an Entra security group) and a chosen **policy template** (e.g. *data theft by departing
  users* → `IRM – Data Theft Departing Users – Readiness Pilot`). The policy is created **disabled or
  minimal**; priority-user groups define who a policy watches most closely. Extends GR-#6.
- **Why required:** IRM must never be switched on broadly from an assessment. A small, named priority-user
  scope (backed by a security group you control) is the least-exposing way to prove the policy is wired
  correctly before any expansion — and the expansion decision is HR/privacy/legal's, not the assessment's.
- **How to verify:** The backing security group's existence and membership are scriptable (Graph) — the
  Config/Set-Scope scripts create/report it; the **priority-user-group binding and the policy** are
  **portal-configured** and verified in **Insider Risk Management → Settings → Priority user groups** and
  **→ Policies**. **Flag "verify in the Purview portal."**
- **How to implement if missing:** Create the backing group (Config script, `-Commit`), keep it minimal, bind
  it as a priority user group in the portal, and create the template policy **disabled/minimal** — expansion
  deferred.

## 2.7 The HR / privacy / legal stakeholder sign-off path
- **Description:** A named path to the **HR, privacy, and legal** stakeholders who own IRM **outcomes** —
  works-council/employee-representation consultation where applicable, regional monitoring/notice obligations,
  the decision to open cases, and any disciplinary/legal action. Extends GR-#5 with IRM's HR sensitivity.
- **Why required:** IRM's outputs are about people. The **determination** — whether monitoring is lawful in a
  jurisdiction, whether to act on a signal, what a case means — is **not** technical. The readiness scorecard
  is handed to these stakeholders; they own expansion and operation.
- **How to verify:** Confirm the named HR/privacy/legal owners, any works-council/consultation requirement,
  and the escalation path for alerts. Confirm they are **reviewers/escalation recipients**, not default
  holders of the Investigator role (Req 2.2).
- **How to implement if missing:** Identify the owners, complete any required consultation, and agree the
  escalation/decision path **before** IRM produces anything about a named person.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | IRM licensing (E5 / E5 Compliance / IRM add-on; verify) | IRM & Analytics available |
| 2.2 | IRM role groups assigned as **separated** duties | Admin/Analyst/Investigator/Auditor distinct; super-group minimal; separate from HR/Legal |
| 2.3 | Privacy-by-design: **anonymization ON** + minimum indicators | Pseudonymized triage; data-minimizing |
| 2.4 | Connectors (HR / Entra / DLP / Defender) present & healthy | The template has signal |
| 2.5 | Unified audit logging enabled | Correlation substrate exists |
| 2.6 | Readiness scope: priority-user group + template, **disabled/minimal** | Least-exposing pilot only |
| 2.7 | HR / privacy / legal sign-off path | Outcomes owned by governance functions |

> **Deferred to HR / privacy / legal:** whether monitoring is lawful in your jurisdiction, works-council/
> consultation requirements, whether to open a case, what a risk score means for a person, and any
> disciplinary/legal action. This solution delivers the technical **readiness** method and evidence, not the
> determination — and it operates against **no** individual.
