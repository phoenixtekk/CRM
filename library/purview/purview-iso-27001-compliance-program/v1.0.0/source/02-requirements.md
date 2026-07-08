# 2. Requirements — Microsoft Purview ISO 27001 Compliance Program

These are the **solution-specific** prerequisites for standing up an ISO 27001-aligned Purview program.
They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders,
and a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to
implement if missing**.

---

## 2.1 Licensing sufficient for the ISO template and the supporting controls
- **Description:** The **ISO/IEC 27001 assessment template** in Compliance Manager is a **premium
  template**, and the technical controls that back Annex A (advanced/endpoint DLP, automatic labeling,
  Audit **Premium**, insider risk) are advanced capabilities — typically **Microsoft 365 E5** or the
  **E5 Compliance** add-on, or the **Compliance Manager Premium Assessment Add-On** for additional
  premium assessments. Extends GR-#1.
- **Why required:** Without the entitlement, the **ISO template will not be available** to create the
  assessment, and advanced controls (endpoint DLP, auto-labeling, Audit Premium) that provide key
  evidence will not function. The **number** of premium assessments available depends on licensing/seat
  count.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in
  **Purview → Compliance Manager → Assessment templates** confirm the **ISO/IEC 27001** template is
  listed and selectable. **Flag "verify your licensing/tenant"** — availability evolves.
- **How to implement if missing:** Acquire/assign E5 / E5 Compliance (or the premium-assessment add-on)
  before creating the ISO assessment; scope the initial program to controls your plan covers.

## 2.2 The ISMS scope, risk assessment, and Statement of Applicability (from the ISMS/risk function)
- **Description:** The **defined ISMS scope**, the **risk assessment / risk-treatment plan**, and the
  **Statement of Applicability (SoA)** that lists **which Annex A controls are applicable** and why —
  produced by the organization's ISMS/risk/compliance function, **not** by this solution.
- **Why required:** The program configures and evidences the **in-scope, applicable** controls. Without
  the SoA there is no authoritative list of which Annex A controls to map — and applicability is a
  **determination**, not a technical default.
- **How to verify:** Confirm a current, approved **SoA** and risk-treatment plan exist and name the
  applicable Annex A controls and their owners.
- **How to implement if missing:** Engage the ISMS/risk function to produce the SoA and risk treatment
  **before** the control-mapping phase. This is deferred to them; the program does not author it.

## 2.3 Compliance Manager roles with separation of duties
- **Description:** The **Compliance Manager role groups** assigned least-privilege — **Compliance
  Manager Administrators** (program owners), **Compliance Manager Assessors** (create assessments, edit
  test status), **Compliance Manager Contributors** (edit improvement actions), **Compliance Manager
  Readers** (auditors/oversight, read-only). Global/Compliance Administrator only where genuinely
  required. Extends GR-#2. **Verify exact role/role-group names in your tenant — Purview role naming
  evolves.**
- **Why required:** ISO 27001 values **segregation of duties** (A.5.3); Compliance Manager enforces
  fine-grained role groups, and separating administrators from contributors from read-only auditors is
  itself an auditable access control.
- **How to verify:** **Purview → Settings → Roles & scopes → Permissions** (or Microsoft Purview roles)
  — confirm membership of each Compliance Manager role group.
- **How to implement if missing:** Assign the least-privilege role groups under change control; separate
  program administrators, action contributors, and read-only auditors.

## 2.4 Roles for the supporting technical controls
- **Description:** The least-privilege Purview roles to configure the **supporting** controls the program
  evidences: **Information Protection** (sensitivity labels), **DLP Compliance Management / Compliance
  Data Administrator** (DLP), **Records Management / Retention Management** (retention/disposition), and
  **Audit** roles (unified audit / Audit Premium). Extends GR-#2.
- **Why required:** Each technical control is configured in its own Purview area under its own role;
  without the matching role the control cannot be built or its evidence collected.
- **How to verify:** Confirm the account(s) that will run the Implementation Guide hold the roles for
  labels, DLP, retention, and audit.
- **How to implement if missing:** Assign the least-privilege role groups per control area; separate
  authors from reviewers where possible.

## 2.5 Unified audit logging enabled (the evidence backbone)
- **Description:** **Unified audit logging** turned on for the tenant (Audit Standard; **Audit Premium**
  where longer retention / higher-value events are needed) — the source of the logging and monitoring
  evidence (A.8.15 Logging, A.8.16 Monitoring activities) and the trail behind DLP/label/retention
  activity.
- **Why required:** A large share of ISO 27001 technical evidence — who did what, when, to which data —
  comes from the audit log. Labels, DLP, and retention activity, and the delivered evidence/report
  scripts, all depend on it.
- **How to verify:** Confirm audit logging is on (e.g. `Get-AdminAuditLogConfig |
  Select UnifiedAuditLogIngestionEnabled`, or the Purview **Audit** page). The Discovery script reports
  this.
- **How to implement if missing:** Enable unified audit logging and confirm ingestion **before** relying
  on any logging/monitoring evidence — audit data only accrues from the time it is enabled.

## 2.6 A classification intent and in-scope data (for labels, DLP, and retention)
- **Description:** A documented view of the **information categories** in scope for classification
  (A.5.12/5.13), the **data-leakage channels** DLP must cover (A.8.12), and the **records/retention
  requirements** (A.8.10 Information deletion, A.5.33 Protection of records) — mapped to the SITs,
  labels, and retention settings that implement them. Extends GR-#4.
- **Why required:** The label scheme, DLP policies, and retention/disposition all key off the
  classification intent and the in-scope data; without it, the technical controls are guesswork.
- **How to verify:** Confirm the classification scheme, the DLP-covered locations, and the
  records/retention requirements with the data owners and records function.
- **How to implement if missing:** Define the classification intent and in-scope data with stakeholders;
  **the retention *schedule* and records *file plan* are records/legal determinations** — deferred — you
  configure the settings they specify.

## 2.7 A pilot scope, simulation/test mode, and change control
- **Description:** A named **pilot ring** (`ISO27001 Pilot Ring – Stage1`) and the agreement that each
  high-impact control — **DLP, sensitivity labels, retention/disposition** — is built in
  **simulation/test/disabled mode first**, with a **change-control window** to move to enforcement.
  Extends GR-#6.
- **Why required:** Labels, DLP, and retention are high-impact; enforcing without a simulation/test
  baseline and a limited ring is how these controls disrupt the business. The house model mandates
  **simulate/test first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that simulation/test mode is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and agree change control before enabling any
  enforcement.

## 2.8 An evidence owner, register, and retention approach
- **Description:** A named owner for the **`ISO27001 Evidence – Register`** and a decision on **where
  evidence lives and how long it is kept** — improvement-action evidence in Compliance Manager, plus the
  exported technical evidence (audit extracts, policy/label/retention configuration snapshots, test
  results) the delivered scripts produce.
- **Why required:** ISO 27001 audits consume **evidence with owner, date, and proof**. A control without
  a retained evidence trail is not defensible; someone must own collecting, storing, and refreshing it.
- **How to verify:** Confirm the evidence owner, the storage location, and the evidence-retention
  approach.
- **How to implement if missing:** Assign the owner and agree the storage/retention before the validation
  phase generates evidence.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Licensing for ISO template + advanced controls (E5 / E5 Compliance; verify) | ISO template + advanced controls available |
| 2.2 | ISMS scope, risk assessment, **SoA** (from ISMS/risk) | Applicable Annex A controls defined (determination deferred) |
| 2.3 | Compliance Manager roles with separation | Auditable, least-privilege program access |
| 2.4 | Roles for labels / DLP / retention / audit | Supporting controls configurable |
| 2.5 | Unified audit logging enabled | Logging/monitoring evidence backbone present |
| 2.6 | Classification intent + in-scope data | Labels/DLP/retention key off correct scope |
| 2.7 | Pilot ring + simulation/test + change control | Simulate/test-first enforced |
| 2.8 | Evidence owner + register + retention | Evidence is owned, stored, defensible |

> **Deferred to the ISMS / risk / compliance / records / legal / certification-body functions:** the ISMS
> scope, the risk assessment and treatment plan, the **Statement of Applicability** (which Annex A
> controls apply), the management-system clauses (4–10), retention **schedules** / records **file plans**,
> and the **certification determination** itself. This solution provides the technical control
> configuration and the evidence, not those determinations.
