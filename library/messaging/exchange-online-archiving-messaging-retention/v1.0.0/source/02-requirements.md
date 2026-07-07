# 2. Requirements

This solution assumes the **shared Messaging category requirements** are already met — a Microsoft 365
tenant with Exchange Online, least-privilege admin roles, the **ExchangeOnlineManagement (EXO V3)** +
Microsoft Graph toolchain, DNS control, hybrid Exchange/AD access where applicable, and a pilot scope
with change control. See **`global-requirements-messaging.md`** for those six; do not duplicate them.
Below are the prerequisites **specific to Exchange Online Archiving, MRM, PST import, and holds**.

---

## 2.1 Archiving-capable licensing (verify per user — this gates the whole solution)
- **Description:** Each in-scope user must have a plan that includes the **archive mailbox**, and — if
  you intend to use it — **auto-expanding archive**. Archive availability and auto-expanding archive
  limits are **plan-dependent** (for example, they are included with several Exchange Online Plan 2 /
  Microsoft 365 enterprise plans, and Exchange Online Archiving is also sold as a standalone add-on for
  some plans). Exact entitlement and quota **change over time and by plan**.
- **Why required:** You cannot enable an archive for a user whose plan does not grant one, and
  auto-expanding archive silently does nothing for unlicensed users. This is the single most common
  blocker.
- **How to verify:** In the Microsoft 365 admin center, check the plans assigned under
  **Billing > Licenses** and each user's assigned licenses. In PowerShell, confirm the archive is
  provisionable and, once enabled, `Get-Mailbox <user> | Format-List ArchiveStatus,ArchiveGuid,
  AutoExpandingArchiveEnabled`. **Treat entitlement as "verify in your tenant/plan" — do not assume.**
- **How to implement if missing:** Assign an archiving-capable plan or the Exchange Online Archiving
  add-on to the users in scope before enabling their archives.

## 2.2 Least-privilege admin roles for archiving, MRM, import, and holds
- **Description:** The work needs specific role groups, not blanket Global Admin:
  - **Recipient Management** or **Organization Management** (EAC) — to enable archives and manage
    mailboxes.
  - **Records Management** role / **Retention Management** — to create and assign MRM archive/retention
    tags and the retention policy.
  - **Mailbox Import Export** management role (not assigned to any role group by default) — required to
    import PSTs; assign it explicitly to the operator.
  - **eDiscovery Manager / eDiscovery Administrator** (Microsoft Purview) — to create eDiscovery cases
    and In-Place/eDiscovery holds. **Litigation hold** can be set with Exchange recipient-admin rights.
- **Why required:** Each capability is gated by its own role; PST import in particular fails without the
  **Mailbox Import Export** role, which is off by default.
- **How to verify:** In the EAC / Purview portal roles, confirm the operator holds the roles above; run
  `Get-ManagementRoleAssignment -Role "Mailbox Import Export"` to confirm the import role is assigned.
- **How to implement if missing:** Have an Organization Management admin assign the least-privilege
  role(s) under change control; add the **Mailbox Import Export** role to a role group (or the operator)
  before the PST import step.

## 2.3 A PST source inventory (only if importing PSTs)
- **Description:** If PST import is in scope, a discovered inventory of the `.pst` files to ingest —
  their file paths, the owning user, and the target (archive) — plus a staging location the operator can
  reach. The Microsoft 365 **Import service** accepts **network upload** (upload to Azure with AzCopy)
  or **drive shipping**.
- **Why required:** The import needs a mapping file (CSV) that maps each PST to a target mailbox/archive;
  without a clean inventory you cannot build it, and PSTs left on endpoints stay unmanaged.
- **How to verify:** Confirm the PST file list, owners, and that the files are gathered to a staging
  share the operator can read.
- **How to implement if missing:** Collect the PSTs to a staging location and build the inventory before
  the import step. (Discovery of *where* PSTs live on endpoints is out of scope here — bring the files.)

## 2.4 Legal / records stakeholders and a hold determination (only if applying holds)
- **Description:** A named **legal/records owner** who determines **what to preserve, for whom, and for
  how long**, referencing a **matter/case identifier**. The technical hold (litigation or In-Place/
  eDiscovery) is applied to that determination.
- **Why required:** Applying, scoping, or releasing a hold has legal consequences. The implementer
  configures the hold; **the legal/records owner decides its scope and duration** — this is not an
  implementer decision.
- **How to verify:** Confirm a documented determination exists (custodians, date range/query, matter ID,
  retention duration) and an approver.
- **How to implement if missing:** Do **not** apply or release holds without a documented legal/records
  determination. Obtain it first.

## 2.5 Managed Folder Assistant / archive-move expectations set
- **Description:** Agreement that **move-to-archive is not instantaneous** — the **Managed Folder
  Assistant (MFA)** processes mailboxes on its own workcycle, and large mailboxes may take multiple runs
  before items finish moving to the archive.
- **Why required:** Sets realistic validation timing so a "nothing moved yet" observation right after
  applying the policy is not misread as failure.
- **How to verify:** Confirm the service owner accepts that validation of moves happens after the MFA
  has processed the pilot mailboxes (you can trigger it with `Start-ManagedFolderAssistant`).
- **How to implement if missing:** Communicate the timing before enabling; schedule validation after the
  MFA has run.

## 2.6 Commercial vs Government cloud confirmed
- **Description:** Know which cloud the tenant is in. Portal URLs differ: Commercial uses
  `admin.microsoft.com`, `admin.exchange.microsoft.com`, and `purview.microsoft.com`; **GCC High / DoD**
  use `*.office365.us` / `*.microsoft.us` equivalents, and some capabilities/limits differ.
- **Why required:** Steps that reference a portal URL or a `Connect-ExchangeOnline` environment parameter
  must target the correct cloud, or they fail or hit the wrong tenant.
- **How to verify:** Confirm the tenant's cloud instance; for PowerShell, note whether
  `Connect-ExchangeOnline -ExchangeEnvironmentName` needs a Government value.
- **How to implement if missing:** Record the cloud and substitute the correct portal URLs / connection
  parameters throughout; **verify on your cloud** rather than assuming Commercial paths.
