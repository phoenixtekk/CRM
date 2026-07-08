# 2. Requirements

These are the **solution-specific** prerequisites for delivering regulatory & immutable records and a
mapped file plan in Microsoft Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell +
Graph toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal
stakeholders; and a pilot scope with change control). Do not repeat those — verify them first, then
confirm the records-immutability and file-plan-specific prerequisites below. Each is stated as
**Description / Why / Verify / Implement if missing.**

---

## 2.1 Compliance licensing for records management & the file plan
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks **records management** —
  **record labels**, **regulatory-record labels**, the **file plan** and its descriptors, **auto-apply**
  label policies, and **adaptive scopes** — which is generally an **E5 / E5 Compliance-class** plan or
  the equivalent Purview add-on. (Basic retention labels are broadly available; the immutability and
  file-plan features this solution centers on are the plan-gated ones.)
- **Why required:** These capabilities are **plan-gated**; without the right plan the record/regulatory
  labels and file-plan descriptors in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/add-on.
  In the Microsoft Purview portal, confirm the **Records management** solution (with **File plan** and
  **Disposition**) is visible. *Feature-to-plan mapping changes — verify the exact entitlement in your
  tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin and any accounts that will manage records, before configuration.

## 2.2 The records determination (input from records & legal)
- **Description:** The authoritative determination for the in-scope content: for each category, whether
  it is a **record** or a **regulatory record**, the **lock duration** and its **trigger** (created /
  last-modified / labeled / event), the applicable **retention authority** and **regulatory citation**,
  the owning **department** and **reference ID**, and the **disposition authority** (automatic vs
  reviewed, and who reviews).
- **Why required:** This solution **implements** the determination; it does not author it. Record status
  (especially the irreversible **regulatory** designation), lock periods, and citations are legal/records
  calls — without them there is nothing correct and defensible to configure.
- **Verify:** Confirm records/legal has provided (or signed off) a records determination naming each
  category's record status, lock period/trigger, authority, citation, department, reference ID, and
  disposition path — or at least a pilot subset of categories, and an explicit sign-off for any
  **regulatory-record** category.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal
  functions** — request the determination before configuring. Do not invent record status, lock periods,
  citations, or the regulatory designation.

## 2.3 Roles for records management, the file plan & disposition
- **Description:** The least-privilege role groups to create and manage records in Microsoft Purview:
  **Records Management** (or **Compliance Administrator** / **Compliance Data Administrator**) for record
  labels, the file plan, and descriptors; **Disposition Management** for the named reviewer accounts; and
  the workload admin rights (Exchange / SharePoint) where item- or location-level application requires
  them.
- **Why required:** Creating record/regulatory labels, building the file plan, and acting on disposition
  each require the corresponding Purview role; disposition reviewers must be in **Disposition Management**
  or they cannot see the queue. Applying/declaring records where users do it requires the label be
  published to them.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm the
  admin's membership; confirm reviewers are in **Disposition Management**.
- **Implement if missing:** Have a Global Admin / Compliance Admin add the accounts to the least-
  privilege role groups under change control. Grant **Disposition Management** only to the named reviewer
  accounts, and keep records configuration separate from disposition review (duty separation).

## 2.4 In-scope workloads and their state (Exchange / SPO / OneDrive / Teams)
- **Description:** Confirmation of which **workloads and locations** hold the records in scope and that
  they are in a state a record label can apply to — Exchange mailboxes, SharePoint sites, OneDrive
  accounts, Microsoft 365 Groups, and Teams content — plus which of these will **publish** the record
  labels for manual declaration and which will **auto-apply** by condition.
- **Why required:** Record declaration keys off where the label is published/applied; a record label
  locking the wrong location either over-locks live content or misses the records it should cover.
- **Verify:** Confirm the in-scope workloads with stakeholders; identify the pilot locations; identify
  any locations that must be excluded from record declaration.
- **Implement if missing:** Define the location scope per workload before authoring labels; document any
  deliberate exclusions.

## 2.5 Existing Purview records posture (alignment, not duplication)
- **Description:** Knowledge of the organization's **existing records/retention posture** — any record
  or regulatory labels already in force, existing file-plan descriptors, and any retention labels/
  policies the broader lifecycle program owns — so this immutability + file-plan work **aligns** to it
  rather than duplicating labels or conflicting via retention precedence.
- **Why required:** A duplicate record label per workload fragments the file plan; an unaware new label
  can interact with existing retention via Microsoft's precedence rules. The broader lifecycle/records
  program owns tenant-wide retention policies and must not be re-implemented here.
- **Verify:** Enumerate existing labels and descriptors (`Get-ComplianceTag`,
  `Get-FilePlanPropertyAuthority` and the other `Get-FilePlanProperty*` cmdlets) and confirm which are
  owned by the broader program (the assessment script does this).
- **Implement if missing:** Engage the lifecycle/records program owners; capture the existing baseline
  before adding labels or descriptors, and reuse existing descriptors rather than minting duplicates.

## 2.6 SharePoint records mechanics (referenced, not rebuilt)
- **Description:** For the SharePoint portion of scope, the **SharePoint-specific records mechanics** —
  default library labels, in-place records inside document libraries, and PnP-driven site/library
  application — which are implemented in depth by the **SharePoint records/retention product**.
- **Why required:** This solution configures the record/regulatory labels and the file plan; the
  SharePoint-library-level application detail is that product's province. Duplicating it risks divergent
  guidance and divergent label names.
- **Verify:** Confirm whether the SharePoint records/retention product is in play for SPO sites; if so,
  align label names and defer library-application mechanics to it.
- **Implement if missing:** Where SPO library-level records work is required, use the SharePoint
  records/retention product for that mechanic and keep the label inventory consistent across both.

## 2.7 Records/file-plan automation toolchain
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for record labels, regulatory labels, and file-plan descriptors
  (`Get-ComplianceTag` / `New-ComplianceTag`, the `New-FilePlanProperty*` / `Get-FilePlanProperty*`
  family), and **Microsoft Graph PowerShell** for supporting directory reads — a modern-auth / MFA-
  capable admin.
- **Why required:** The provided scripts and the configuration steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect, and the records/file-plan cmdlets must
  be present (they depend on the plan and role in 2.1/2.3).
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-FilePlanPropertyAuthority`
  return without error; `Connect-MgGraph` succeeds where used. In Government clouds, confirm the correct
  `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.8 Change control and a documented rollback — with the irreversible parts flagged
- **Description:** An approved change window and a **rollback plan** specific to records: how to unpublish
  a record label policy, how to remove a non-regulatory record label from items, and how a records
  manager **un-declares** a non-regulatory record — **plus the explicit statement that a
  regulatory-record label, once applied, cannot be removed, changed, un-declared, or shortened**.
- **Why required:** Records declaration is high-impact and partly irreversible; a documented, rehearsed
  rollback is the safety net for the reversible parts and forces a conscious, signed-off decision on the
  irreversible **regulatory** parts before they are applied.
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label-policy unpublish,
  non-record-label removal, and non-regulatory record un-declaration for the pilot categories — and an
  explicit **no-rollback** flag on every regulatory-record category.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control
  sign-off, and explicitly flag any **regulatory-record** category as **no-rollback** with a records/
  legal sign-off reference before applying it.
