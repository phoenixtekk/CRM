# Requirements

These are the **solution-specific** prerequisites for the data archiving strategy. They are **in
addition to** the six category-wide prerequisites in the **Purview Global Requirements**
(`global-requirements-purview.md`) — tenant licensing, least-privilege roles, the S&C
PowerShell + Graph toolchain, in-scope data sources, compliance/records/legal stakeholders, and a
pilot scope + change control. Verify each item below before starting the implementation steps.

> Every capability here is **licensing-/plan-dependent** and the portals **evolve**. Where a plan or
> path is called out, **verify your licensing/tenant** rather than assuming availability.

---

## R1. Exchange Online archiving licensing (archive mailbox + auto-expanding archive)

- **Description:** Each user who will get an archive mailbox needs a plan that includes archiving:
  **Exchange Online Plan 2** (included in **Microsoft 365 E3 and E5**) or **Exchange Online Plan 1
  plus the Exchange Online Archiving add-on**. **Auto-expanding archive** requires the same Plan 2 /
  add-on entitlement.
- **Why required:** Without the entitlement, `Enable-Mailbox -Archive` will not provision an archive,
  and auto-expanding archive is unavailable.
- **How to verify:** Microsoft 365 admin center → **Billing → Licenses** confirm E3/E5 or the
  archiving add-on; in Exchange Online PowerShell `Get-Mailbox <user> | fl ArchiveStatus,ArchiveGuid`
  and `Get-OrganizationConfig | fl AutoExpandingArchive`.
- **How to implement if missing:** Assign the correct licensing before enabling archives. Confirm the
  archive feature is visible in the Purview / Exchange admin surfaces — *verify your licensing/tenant.*

## R2. Least-privilege roles for archiving and lifecycle

- **Description:** The engineer needs the specific roles for the two surfaces:
  - **Exchange Online** — a role group with **Mail Recipients** and **Recipient Policies** management
    (e.g. **Recipient Management**) to enable archives and manage MRM tags/policies, and permission to
    run the **Managed Folder Assistant**.
  - **Microsoft Purview** — **Compliance Administrator** or **Compliance Data Administrator** (or the
    scoped **Retention Management** role) to create and publish **Data Lifecycle Management** retention
    policies/labels.
  - **Global Administrator** only where genuinely required (e.g. org-wide `Set-OrganizationConfig`).
- **Why required:** Purview and Exchange use fine-grained role groups; the matching role is required
  for each configuration action.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; Exchange admin center →
  **Roles → Admin roles**. Confirm membership.
- **How to implement if missing:** Assign the least-privilege role group under change control; avoid
  standing Global Administrator.

## R3. Managed Folder Assistant / MRM understanding and toolchain

- **Description:** A workstation with the **ExchangeOnlineManagement** module (for
  `Connect-ExchangeOnline` **and** `Connect-IPPSSession`) and **Microsoft Graph PowerShell**,
  signed in with a **modern-auth / MFA** admin account. The engineer must understand that MRM
  archiving is driven by the **Managed Folder Assistant (MFA)**, which runs on its own work cycle and
  can be triggered on demand with `Start-ManagedFolderAssistant`.
- **Why required:** Configuration, validation, and the provided scripts run through these modules;
  archiving does not take effect until the MFA processes the mailbox.
- **How to verify:** `Connect-ExchangeOnline`, `Connect-IPPSSession`, and `Connect-MgGraph` all
  succeed; `Get-Command Start-ManagedFolderAssistant` resolves.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement` and
  `Install-Module Microsoft.Graph`; confirm modern-auth sign-in.

## R4. In-scope mailboxes / sites and the tiering intent

- **Description:** The **in-scope workloads** (which mailboxes get archives; whether SharePoint cold
  tiering is in scope) and a **tiering intent**: at what **age** cold content should move to archive
  (e.g. items older than **2 years** move to archive), and what stays in the primary store.
- **Why required:** MRM move-to-archive tags key off an **age limit**, and the archive scope keys off
  the mailbox set; both must be defined before authoring policy.
- **How to verify:** Confirm the pilot mailbox list, the target age threshold, and whether SharePoint
  **Microsoft 365 Archive** tiering is in scope with stakeholders.
- **How to implement if missing:** Define the scope and the age threshold before creating tags.

## R5. Records / compliance / legal sign-off on the retention timeline

- **Description:** Named approval from **records management / compliance / legal** for the **retention
  timeline** and for **any disposition (delete) action** — including confirmation of any **legal
  holds** that must suppress deletion.
- **Why required:** The archiving *mechanism* is technical; **how long to keep and when to dispose is
  a records/legal determination** and must not be set to a technical default. Deletion is
  irreversible and can conflict with legal hold.
- **How to verify:** Confirm the approved retention schedule (or that only *keep/move-to-archive* is
  in scope for now), and confirm the legal-hold position with legal.
- **How to implement if missing:** Do **not** enable any delete action. Configure archiving (move +
  keep) only, and defer disposition until records/legal has approved a schedule.

## R6. A named pilot scope, change window, and rollback plan

- **Description:** A **named pilot group** of test mailboxes (never production users for the first
  ring), an agreed **change window**, and a **rollback plan** that accounts for the fact that
  archiving is **not trivially reversible**.
- **Why required:** Every high-impact archiving change is piloted first; enabling auto-expanding
  archive and moving items are hard to undo, and delete is irreversible.
- **How to verify:** Confirm the pilot group membership, the approval path, and that the rollback plan
  is documented (see the Implementation Guide's rollback section).
- **How to implement if missing:** Define the pilot group and change control, and disable all delete
  actions, before touching production.
