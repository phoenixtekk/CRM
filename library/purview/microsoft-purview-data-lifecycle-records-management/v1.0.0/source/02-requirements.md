# 2. Requirements

These are the **solution-specific** prerequisites for implementing data lifecycle and records
management org-wide in Microsoft Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell +
Graph toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal
stakeholders; and a pilot scope with change control). Do not repeat those — verify them first, then
confirm the lifecycle/records-specific prerequisites below. Each is stated as **Description / Why /
Verify / Implement if missing.**

---

## 2.1 Compliance licensing for records & advanced retention
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks the features this
  solution uses — basic retention policies and labels are broadly available, but **records management**
  (record and regulatory-record labels, the file plan), **auto-apply** label policies, **adaptive
  scopes**, **event-based retention**, and **disposition review** are generally in an **E5 / E5
  Compliance-class** plan or the equivalent Purview add-on.
- **Why required:** These capabilities are **plan-gated**; without the right plan the records labels,
  auto-apply policies, adaptive scopes, and disposition reviews in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/
  add-on. In the Microsoft Purview portal, confirm both **Data lifecycle management** and **Records
  management** solutions are visible. *Feature-to-plan mapping changes — verify the exact entitlement in
  your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin and any accounts that will manage records, before configuration.

## 2.2 The retention schedule (input from records & legal)
- **Description:** The authoritative **retention schedule** for the tenant's content: the categories,
  each category's **retention period**, its **trigger** (created / last-modified / labeled / **event**),
  whether it is a **record** or **regulatory record**, the applicable **regulatory citation/authority**,
  and the **disposition authority** (automatic vs review, and who reviews).
- **Why required:** This solution **implements** the schedule; it does not author it. Policies and labels
  are a direct translation of the schedule — without it there is nothing correct to configure.
- **Verify:** Confirm records/legal has provided (or signed off) a schedule naming each category, period,
  trigger, record status, citation, and disposition path — or at least a pilot subset of categories.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal
  functions** — request the schedule before configuring. Do not invent retention periods, record status,
  event triggers, or disposition rules.

## 2.3 Roles for lifecycle & records management
- **Description:** The least-privilege role groups to create and manage retention/records in Microsoft
  Purview: **Records Management** or **Compliance Administrator** / **Compliance Data Administrator** for
  labels, policies, the file plan, and events; **Disposition Management** for reviewers; and the
  workload admin rights (Exchange / SharePoint) where item- or location-level application requires them.
- **Why required:** Creating labels, publishing/auto-applying policies, building the file plan, raising
  events, and acting on disposition each require the corresponding Purview role; disposition reviewers
  must be in **Disposition Management** or they cannot see the queue.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm the
  admin's membership; confirm reviewers are in **Disposition Management**.
- **Implement if missing:** Have a Global Admin / Compliance Admin add the accounts to the least-
  privilege role groups under change control. Grant **Disposition Management** only to the named reviewer
  accounts.

## 2.4 In-scope workloads and their state (Exchange / SPO / OneDrive / Teams)
- **Description:** Confirmation of which **workloads and locations** are in scope and that they are in a
  state retention can apply to — Exchange mailboxes, SharePoint sites, OneDrive accounts, Microsoft 365
  Groups, and **Teams** chats and channel messages (Teams retention is configured through its own
  locations and interacts with the underlying group/mailbox).
- **Why required:** A retention policy keys off the locations selected; Teams and Groups have specific
  location behaviors, and OneDrive/SharePoint retention depends on the site/account existing. Scoping the
  wrong locations either under-covers or over-covers content.
- **Verify:** Confirm the in-scope workloads with stakeholders; confirm Teams/Groups are included or
  excluded deliberately; identify any locations that must be excluded (e.g. a journaling mailbox).
- **Implement if missing:** Define the location scope per workload before authoring policies; document
  any deliberate exclusions.

## 2.5 Existing Purview program posture (alignment, not duplication)
- **Description:** Knowledge of the organization's **existing Microsoft Purview posture** — sensitivity
  (information-protection) labels, DLP policies, and any retention labels/policies already in force — so
  this org-wide lifecycle/records work **aligns** to it rather than conflicting or duplicating, and so
  **retention precedence** is understood before adding overlapping policies.
- **Why required:** Retention outcomes interact via Microsoft's retention-precedence rules; an unaware
  new policy can conflict with an existing one. Sensitivity labels and DLP are owned by the broader
  Purview program and must not be re-implemented here.
- **Verify:** Enumerate existing labels/policies (`Get-ComplianceTag`, `Get-RetentionCompliancePolicy`,
  `Get-RetentionComplianceRule`) and confirm which are owned by the broader program; note any existing
  tenant-wide retention that a new policy would overlap.
- **Implement if missing:** Engage the Purview program owners; capture the existing baseline (the
  assessment script does this) before adding policies or labels.

## 2.6 SharePoint records mechanics (referenced, not rebuilt)
- **Description:** For the SharePoint portion of scope, the **SharePoint-specific records/retention
  mechanics** — default library labels, in-place records inside document libraries, PnP-driven
  site/library application, and adaptive **site** scopes — which are implemented in depth by the
  **SharePoint records/retention product**.
- **Why required:** This org-wide product configures the tenant-level policies, labels, file plan,
  events, and disposition; the SharePoint-library-level application detail is that product's province.
  Duplicating it risks divergent guidance.
- **Verify:** Confirm whether the SharePoint records/retention product is in play for SPO sites; if so,
  align label names and defer library-application mechanics to it.
- **Implement if missing:** Where SPO library-level records work is required, use the SharePoint
  records/retention product for that mechanic and keep the label inventory consistent across both.

## 2.7 Lifecycle/records automation toolchain
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for retention labels, policies, records, file-plan descriptors,
  and events (`Get-ComplianceTag`, `New-RetentionCompliancePolicy`/`Rule`,
  `New-FilePlanProperty*`, `New-ComplianceRetentionEventType`, `New-ComplianceRetentionEvent`), and
  **Microsoft Graph PowerShell** for supporting reads — a modern-auth / MFA-capable admin.
- **Why required:** The provided scripts and the configuration steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-RetentionCompliancePolicy`
  return without error; `Connect-MgGraph` succeeds where used. In Government clouds, confirm the correct
  `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.8 Change control and a documented rollback for lifecycle/records
- **Description:** An approved change window and a **rollback plan** specific to retention/records: how
  to disable/unpublish a retention policy or label policy, how to remove a non-regulatory retention
  label, and how a non-regulatory record is un-declared — plus the explicit note that **regulatory
  records, completed disposition, and elapsed event-based deletions cannot be rolled back**.
- **Why required:** Tenant-wide retention and records declaration are high-impact; a documented,
  rehearsed rollback is the safety net for the reversible parts and forces a conscious decision on the
  irreversible parts.
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering policy/label disable,
  label removal, and record un-declaration for the pilot categories.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control
  sign-off, and explicitly flag any **regulatory-record** category as **no-rollback** before applying it.
