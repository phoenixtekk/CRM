# 2. Requirements

These are the **solution-specific** prerequisites for applying records, retention, and information
governance to SharePoint Online content. They build **on** the shared SharePoint category
requirements in **`global-requirements-sharepoint.md`** (M365 tenant + SharePoint/OneDrive licensing;
least-privilege SharePoint admin access; the SPO Management Shell / PnP / Graph toolchain; the
information-architecture and identity/group source of truth; a pilot scope and change control; and the
security/compliance/records stakeholders). Do not repeat those — verify them first, then confirm the
records/retention-specific prerequisites below. Each is stated as **Description / Why / Verify /
Implement if missing.**

---

## 2.1 Compliance licensing for records & advanced retention
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks the records and
  retention features this solution uses — retention labels and policies, **records management** (record
  and regulatory-record labels, file plan), **auto-apply** policies, **adaptive scopes**, **event-based
  retention**, and **disposition review**. These are generally in an E5 / E5 Compliance-class plan or
  the equivalent Purview add-on.
- **Why required:** Basic retention policies exist broadly, but records declaration, auto-apply,
  adaptive scopes, and disposition review are **plan-dependent** — without the right plan the labels
  and policies in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/
  add-on. In the Microsoft Purview portal, confirm **Records management** and **Data lifecycle
  management** solutions are available. *Feature-to-plan mapping changes — verify the exact entitlement
  in your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to
  the admin and any accounts that will manage records, before configuration.

## 2.2 The records / retention schedule (input from records & legal)
- **Description:** The authoritative **records/retention schedule** for SharePoint content: the
  categories, each category's **retention period**, its **trigger** (created / last-modified / labeled
  / event-based), whether it is a **record** or **regulatory record**, and the **disposition
  authority** (automatic vs review, and who reviews).
- **Why required:** This solution **implements** the schedule; it does not author it. Labels and
  policies are a direct translation of the schedule. Without it there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) a schedule that names each category,
  period, trigger, record status, and disposition path.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal
  functions** — request the schedule (or a pilot subset of categories) before configuring. Do not
  invent retention periods, record status, or disposition rules.

## 2.3 Roles for records & retention management
- **Description:** The least-privilege roles to create and manage retention/records: **Records
  Management** or **Compliance Administrator** / **Compliance Data Administrator** role group in
  Microsoft Purview for labels/policies/file plan, plus **Disposition Management** for reviewers, and
  **SharePoint Administrator** for site/library-level application. (Assigned via role groups in the
  Purview portal / Entra roles.)
- **Why required:** Creating labels, publishing/auto-applying policies, configuring records, and acting
  on disposition each require the corresponding Purview role; applying default library labels at the
  site requires SharePoint admin/site rights.
- **Verify:** In the Microsoft Purview portal → Roles & scopes → Permissions (role groups), confirm the
  admin's membership; confirm reviewers are in **Disposition Management**.
- **Implement if missing:** Have a Global Admin / Compliance Admin add the accounts to the least-
  privilege role groups under change control. Grant **Disposition Management** only to the named
  reviewer accounts.

## 2.4 Existing Purview program posture (alignment, not duplication)
- **Description:** Knowledge of the organization's **existing Microsoft Purview posture** — sensitivity
  (information-protection) labels, DLP policies, existing retention labels/policies, and any
  tenant-wide retention already in force — so this SharePoint records/retention work **aligns** to it
  rather than conflicting or duplicating.
- **Why required:** Retention outcomes interact via Microsoft's retention-precedence rules; an
  unaware new policy can conflict with an existing one. Sensitivity labels and DLP are owned by the
  broader Purview program and must not be re-implemented here.
- **Verify:** Enumerate existing labels/policies (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`)
  and confirm which are owned by the broader program. Confirm no conflicting SharePoint-scoped
  retention already exists for the pilot sites.
- **Implement if missing:** Engage the Purview program owners; capture the existing baseline (the
  assessment script does this) before adding labels/policies.

## 2.5 A pilot SharePoint site set with representative content
- **Description:** A bounded set of SharePoint sites/libraries — `Scope – Records-Pilot – Static` —
  containing content representative of the schedule categories (e.g. a contracts library, a finance
  library), on which to prove the configuration before tenant-wide expansion.
- **Why required:** Records declaration and disposition are high-impact and partly irreversible
  (regulatory records especially). The pilot proves the label→apply→declare→dispose chain on real,
  bounded content with a rollback available.
- **Verify:** Confirm the named pilot sites exist, their owners are informed, and the content maps to
  the pilot's schedule categories.
- **Implement if missing:** Stand up or nominate pilot sites and confirm owner awareness (a record
  label will lock content) before applying anything.

## 2.6 SharePoint records/retention automation toolchain
- **Description:** On top of the category toolchain (SPO Management Shell / PnP / Graph), the
  **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the Exchange Online
  Management module) for retention labels/policies and records cmdlets (`Get-ComplianceTag`,
  `New-RetentionCompliancePolicy`, etc.), and **PnP PowerShell** for applying default library labels
  (`Get-PnPLabel` / `Set-PnPLabel`).
- **Why required:** The provided scripts and the configuration steps use Security & Compliance
  PowerShell for labels/policies/records and PnP for library-level label application; both are needed.
- **Verify:** `Connect-IPPSSession` and `Connect-PnPOnline` both succeed with the admin's modern-auth
  (MFA) sign-in; `Get-ComplianceTag` and `Get-PnPLabel` return without error.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **PnP.PowerShell** modules,
  register the PnP Entra app registration where interactive/app auth requires it, and confirm both
  connections. Never store credentials in scripts.

## 2.7 Change control and a documented rollback for records/retention
- **Description:** An approved change window and a **rollback plan** specific to retention/records:
  how to remove a default library label, unpublish/disable a policy, and (for non-regulatory records)
  how content is unlocked — plus the explicit note that **regulatory records and elapsed disposition
  cannot be rolled back**.
- **Why required:** Tenant-wide retention and records declaration are high-impact; a documented,
  rehearsed rollback is the safety net for the reversible parts and forces a conscious decision on the
  irreversible parts.
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label removal,
  policy disable, and record un-declaration for the pilot categories.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control
  sign-off, and explicitly flag any regulatory-record category as **no-rollback** before applying it.
