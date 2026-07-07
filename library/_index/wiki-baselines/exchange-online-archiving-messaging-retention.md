# Exchange Online Archiving & Messaging Retention (Archive Mailboxes, EOA & Holds)

> **Version 1.0.0** · Category: Messaging · Solution code: EXOARCH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

## Outcome
Primary mailboxes stop hitting quota, unmanaged **PST** data is brought under service control, and mail
that must be preserved for legal or regulatory reasons is held so it cannot be lost — all without
deleting anything. Concretely: archive mailboxes and **auto-expanding archive** are enabled where the
plan allows, aged mail automatically **moves to the archive** via Messaging Records Management (MRM)
tags, historical PSTs are **imported into the archive**, and **litigation** and **In-Place/eDiscovery
holds** are applied where a preservation obligation exists.

## Approach
This is **Exchange Online Archiving (EOA)** implemented specifically — not a broad data-governance
program. It follows the house model **Assess → Design → Configure → Pilot → Validate → Expand**: the
current archive/hold posture and mailbox sizes are assessed, the archive tags/policy and hold scope are
designed, and everything is enabled against a small **pilot** scope first, validated against explicit
pass/fail gates (archives provisioned, move-to-archive working, PSTs ingested, holds enforced), and only
then expanded fleet-wide in controlled waves. Automation is delivered as five **Exchange Online
PowerShell (EXO V3)** / Microsoft Graph scripts that are read-only or `-WhatIf` by default, with no
stored credentials.

## Why it is low-risk
- **Nothing is deleted.** Move-to-archive relocates mail; it does not remove it. Held items cannot be
  purged.
- **Pilot-first with gates and a rollback.** Every change is validated on a small scope before broad
  rollout, and each step has a documented rollback (with the deliberate exception that auto-expanding
  archive is one-way and held mailboxes are never rolled back).
- **Licensing is verified up front.** Archiving and auto-expanding archive are plan-dependent; the
  solution checks entitlement before enabling rather than assuming it.
- **Legal stays in control of legal.** The solution applies the holds the legal/records owner
  determines; **it never decides what to preserve or for how long.**

## Boundary
Scoped to **email archiving and holds**. Broader Microsoft Purview work — DLP, sensitivity labels, and
cross-workload retention/records across SharePoint, OneDrive, and Teams — is a **separate product** and
is intentionally out of scope here.


---


# 1. Solution Overview — Exchange Online Archiving & Messaging Retention

## What this solution is
Mailboxes grow, users hoard mail in local **PST** files, and legal or regulatory events demand that
messaging data be preserved and discoverable. This solution implements **Exchange Online Archiving
(EOA)** specifically: it enables the **archive mailbox** and **auto-expanding archive** for the users
in scope, builds **Messaging Records Management (MRM)** archive/retention tags and a retention policy
that automatically **moves aged mail to the archive**, imports existing **PSTs into the archive**, and
applies **litigation hold** and **In-Place / eDiscovery holds** where a preservation obligation exists.
The result: primary mailbox size is controlled, mail is preserved where it must be, and nothing that is
under hold is purged — using the Exchange admin center (EAC), the Microsoft Purview compliance portal,
the Microsoft 365 admin center, and **Exchange Online PowerShell (EXO V3)** with **Microsoft Graph**.

## Scope — what this is, and what it deliberately is NOT
This solution is **scoped to email archiving and holds**. It handles archive mailboxes, auto-expanding
archive, MRM move-to-archive/retention tags, PST import to the archive, and litigation/In-Place/
eDiscovery holds on Exchange mailboxes.

It is **not** a broad Microsoft Purview data-governance project. **Purview Data Loss Prevention (DLP)**,
**sensitivity labels**, **Purview retention labels / retention policies across SharePoint, OneDrive,
and Teams**, and **records-management disposition review** are a **separate concern covered by a
different product** — do not expect this solution to configure them. The one adjacency to be aware of:
the newer **Microsoft Purview retention** model and the legacy **MRM (messaging records management)**
model both act on mailbox items, and Microsoft's guidance is generally to prefer Purview retention for
new *retention/deletion* requirements. This solution stays in the MRM lane because MRM is the mechanism
that performs the **move-to-archive** action (Purview retention does not move items to the archive), and
because archive enablement, auto-expanding archive, PST import, and litigation/In-Place holds are the
archiving-specific tasks in scope. Where your organization also needs cross-workload retention/DLP/
labels, treat that as the separate Purview product — this document notes the boundary and does not
overlap it.

## Why this matters
- **Mailbox bloat is a cost and a support problem.** Primary mailboxes hit their quota, users get
  "mailbox full", and support spends time on cleanup. Moving aged mail to the archive (which has its own
  large quota and can auto-expand) controls the primary mailbox without deleting anything.
- **PST sprawl is a data-governance and data-loss risk.** Mail sitting in local `.pst` files is
  unmanaged, unsearchable by eDiscovery, unbacked-up, and lost when a laptop dies. Importing PSTs into
  the archive brings that data under service management and eDiscovery.
- **Preservation obligations are legal exposure.** When litigation or an investigation is reasonably
  anticipated, mailbox data must be preserved unaltered. Litigation hold and In-Place/eDiscovery holds
  preserve items even if a user (or a retention policy) tries to delete them.

## How it works
1. **Licensing gates everything (verify first).** The archive mailbox, and especially **auto-expanding
   archive**, are **license-dependent** — availability depends on the Exchange Online / Microsoft 365
   plan assigned to each user (see Requirements). Confirm the plan before enabling; do not assume every
   user is entitled. *(Verify in your tenant/plan.)*
2. **Enable the archive mailbox** for users in scope (per-mailbox `Enable-Mailbox -Archive`, or the EAC).
   Once provisioned, a second archive appears in Outlook/OWA as an "In-Place Archive / Online Archive".
3. **Enable auto-expanding archive** so the archive grows beyond the base archive quota automatically as
   it fills — organization-wide or per-mailbox — **where the plan supports it**. Auto-expanding archive
   is a one-way switch (it cannot be turned off once on) — this document calls that out at the step.
4. **Build MRM tags and a retention policy.** Create archive/retention tags — an **archive tag** (a
   "Move to Archive" default-policy tag / DPT that moves items older than *N* days to the archive), plus
   any personal or retention tags — bundle them into a **retention policy**, and apply the policy to the
   in-scope mailboxes. The **Managed Folder Assistant** (MFA) processes mailboxes and executes the moves.
5. **Import PSTs to the archive.** Bring existing local PST data in via the Microsoft Purview / Microsoft
   365 **Import service** (network upload or drive shipping) with a mapping file targeting each user's
   **archive**, so historical mail lands in the archive rather than inflating the primary mailbox.
6. **Apply holds where required.** For mailboxes with a preservation obligation, apply **litigation
   hold** (mailbox-level, simple, indefinite or time-boxed) or an **In-Place / eDiscovery hold** (scoped,
   query-based, tied to an eDiscovery case) so items are preserved even if deleted. **What must be held,
   and for how long, is a legal/records determination — this solution applies the technical hold the
   legal/records owner specifies; it does not decide scope or duration.**

## The reference model (artifacts this solution creates)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the docs, scripts,
EAC, and Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Archive posture / size assessment export | `Archive Posture – EXO – Discovery` |
| Move-to-archive default policy tag (DPT) | `Move to Archive – Default – Prod` |
| Personal archive tag (user-applied) | `Archive Now – Personal – Prod` |
| Retention policy bundling the tags | `Archive Retention Policy – EXO – Prod` |
| Pilot mailbox scope | `Archive Scope – Pilot – Stage1` |
| Broad mailbox scope | `Archive Scope – Broad – Stage2` |
| PST import job (to archive) | `PST Import – Archive – Ingest` |
| Litigation hold (mailbox-level) | `Litigation Hold – <Matter> – Legal` |
| In-Place / eDiscovery hold | `eDiscovery Hold – <Matter> – Legal` |
| Move / retention validation report | `Archive Validation – EXO – Report` |

> Replace `<Matter>` with the legal/records matter identifier the legal owner provides. Never invent a
> matter name.

## Benefits
- Primary mailbox size is controlled without deleting mail — aged items move to a large, auto-expanding
  archive.
- Unmanaged PST data is ingested into the service, where it is backed by the platform and reachable by
  eDiscovery.
- Preservation obligations are met technically: held items cannot be purged, so the organization is
  defensible and discoverable.
- Every change is **pilot-first** with explicit pass/fail gates and a rollback, so production mail is
  protected.

## Limitations (be honest with buyers)
- **Archiving and auto-expanding archive are license-dependent.** Not every plan includes the archive
  mailbox, and auto-expanding archive availability/limits differ by plan and change over time — **verify
  in your tenant/plan**; this solution flags it but cannot grant entitlement.
- **Auto-expanding archive cannot be disabled once enabled**, and moving a mailbox with an
  auto-expanded (multi-chunk) archive can be slow — plan before enabling.
- **MRM move-to-archive is not instant.** The Managed Folder Assistant runs on its own cadence; a newly
  applied policy can take a work cycle (and re-runs) before all items move. Very large mailboxes take
  longer.
- **MRM archive tags act only on the archive move**, not on cross-workload retention. For
  retention/deletion across SharePoint/OneDrive/Teams, or for DLP/labels, use the separate Purview
  product (see Scope).
- **Holds are technical, not legal advice.** This solution applies the hold the legal/records owner
  specifies; **what to hold and for how long is their determination**, not the implementer's.
- **Commercial vs Government clouds differ.** Portal URLs and some capability availability differ on
  **GCC / GCC High / DoD** (`*.office365.us`, `*.microsoft.us`) — noted where it matters; verify on your
  cloud.

## The standard deployment model
> Assess the current archive/hold posture and licensing → design the tags, policy, and hold scope →
> configure them → enable and apply to a **pilot** scope first → validate (archives provisioned,
> move-to-archive working, PSTs ingested, holds enforced) → expand to the broad scope.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback.


---


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


---


# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*


---


# 3. Implementation

Follow the house model: **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with
pass/fail gates and a documented rollback. Name every artifact exactly as in the reference model
(§1) and reuse the names in testing, troubleshooting, and the scripts.

**High-impact warning.** Enabling auto-expanding archive is a **one-way switch** (it cannot be turned
off). Applying a hold has legal consequences. Move-to-archive changes what users see in Outlook. Treat
all of these as production changes under change control.

Throughout, connect with modern auth (no stored credentials):
```powershell
Connect-ExchangeOnline           # add -ExchangeEnvironmentName O365USGovGCCHigh / O365USGovDoD on Gov clouds
Connect-MgGraph -Scopes 'User.Read.All','Organization.Read.All','Mail.ReadWrite'  # where Graph is used
```

---

## Stage 0 — Assess (read-only)
1. **Capture the current archive/hold posture and mailbox sizes.** Run **`EXOARCH-Discovery.ps1`**
   (read-only). It reports, per mailbox: `ArchiveStatus`, `ArchiveGuid`, `AutoExpandingArchiveEnabled`,
   the retention policy applied, primary and archive mailbox sizes, `LitigationHoldEnabled`, and
   any In-Place hold GUIDs. Save the export as **`Archive Posture – EXO – Discovery`**.
2. **Confirm licensing per user (the gate).** Cross-check the assessment against archiving-capable
   licensing (Requirement 2.1). Flag any in-scope user whose plan does not include the archive — they
   cannot be enabled until licensed. *(Verify in your tenant/plan.)*
3. **Identify the drivers.** From the posture: which mailboxes are near quota (archive candidates),
   which have PSTs to ingest (Requirement 2.3), and which are subject to a hold determination
   (Requirement 2.4).

**Pass gate (Assess):** you have a saved `Archive Posture – EXO – Discovery` export, a confirmed
licensed pilot set, and a clear list of what each pilot mailbox needs (archive enable / PST import /
hold).

## Stage 1 — Design
4. **Define the pilot and broad scopes.** Choose a small, representative, **licensed** pilot set →
   `Archive Scope – Pilot – Stage1`; define the eventual broad set → `Archive Scope – Broad – Stage2`.
   Use a mail-enabled security group or an explicit UPN list.
5. **Design the MRM tags and policy.**
   - **`Move to Archive – Default – Prod`** — a **default policy tag (DPT)** with retention action
     **MoveToArchive** and an age (e.g. move items older than **730 days / 2 years**). This is the tag
     that controls the automatic move-to-archive.
   - **`Archive Now – Personal – Prod`** — an optional **personal tag** (action MoveToArchive) users can
     apply on demand from Outlook/OWA.
   - **`Archive Retention Policy – EXO – Prod`** — the **retention policy** that bundles the tags above
     and is linked to the mailboxes in scope.
   Decide the archive-move age with the service/records owner (this is a policy decision, not a technical
   default).
6. **Design the hold scope (from the legal/records determination only).** For each matter, decide
   litigation hold (`Litigation Hold – <Matter> – Legal`, mailbox-level, simple) vs In-Place/eDiscovery
   hold (`eDiscovery Hold – <Matter> – Legal`, query/date-scoped, tied to a Purview eDiscovery case).
   **Take scope and duration from the legal owner — do not invent them.**

## Stage 2 — Configure (build; safe/`-WhatIf` first)
7. **Enable archive mailboxes for the pilot.** Preview first, then apply.
   ```powershell
   # Preview — no change
   .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -WhatIf
   # Apply
   .\EXOARCH-EnableArchive.ps1 -Identities (Get-Content .\pilot.txt) -Commit
   ```
   Under the hood this is `Enable-Mailbox <id> -Archive`. The helper skips users already archive-enabled
   and warns on users it cannot confirm are licensed.
8. **Enable auto-expanding archive where the plan supports it (one-way — confirm first).**
   - Org-wide: `Set-OrganizationConfig -AutoExpandingArchive` (affects all archive-enabled mailboxes;
     cannot be undone).
   - Per-mailbox: `Enable-Mailbox <id> -AutoExpandingArchive`.
   **`EXOARCH-EnableArchive.ps1 -AutoExpand`** gates this behind `-Commit` and prints the irreversibility
   warning before acting. *(Availability/limits are plan-dependent — verify in your tenant/plan.)*
9. **Create the MRM tags and retention policy.** Use **`EXOARCH-Set-MrmPolicy.ps1`** (supports
   `-WhatIf`), which is idempotent:
   ```powershell
   .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -WhatIf   # preview the tag/policy it will create
   .\EXOARCH-Set-MrmPolicy.ps1 -ArchiveAgeDays 730 -Commit   # create/update
   ```
   It creates:
   - `New-RetentionPolicyTag "Move to Archive – Default – Prod" -Type All -RetentionAction MoveToArchive -AgeLimitForRetention 730 -RetentionEnabled $true`
   - `New-RetentionPolicyTag "Archive Now – Personal – Prod" -Type Personal -RetentionAction MoveToArchive -AgeLimitForRetention 0 -RetentionEnabled $true`
   - `New-RetentionPolicy "Archive Retention Policy – EXO – Prod" -RetentionPolicyTagLinks "Move to Archive – Default – Prod","Archive Now – Personal – Prod"`
   (If a tag/policy already exists, it updates the links with `Set-*` instead of failing.)
10. **Assign the retention policy to the pilot scope, then run the assistant.**
    ```powershell
    Get-Content .\pilot.txt | ForEach-Object { Set-Mailbox $_ -RetentionPolicy "Archive Retention Policy – EXO – Prod" }
    Get-Content .\pilot.txt | ForEach-Object { Start-ManagedFolderAssistant $_ }   # trigger processing
    ```
11. **Import PSTs to the archive (if in scope).** Build the import mapping CSV so each PST targets the
    user's **archive** (`IsArchive` = `TRUE`), name the job **`PST Import – Archive – Ingest`**, and use
    the Microsoft Purview / Microsoft 365 **Import** service (network upload with AzCopy, or drive
    shipping) per Microsoft's documented steps. The mapping CSV columns and the `SAS` upload URL come
    from the Import job in the portal — **follow the portal's current wizard**; do not hardcode a SAS URL.
    Confirm each row's target is the archive before submitting.
12. **Apply holds (from the legal/records determination only).**
    - **Litigation hold:** `Set-Mailbox <id> -LitigationHoldEnabled $true` (optionally
      `-LitigationHoldDuration <days>` and `-LitigationHoldOwner <name>`), recorded as
      `Litigation Hold – <Matter> – Legal`.
    - **In-Place / eDiscovery hold:** create the hold inside a **Microsoft Purview eDiscovery (Standard)**
      case, scoped by custodian and query/date range, recorded as `eDiscovery Hold – <Matter> – Legal`.
    Use **`EXOARCH-Set-Holds.ps1 -WhatIf`** to preview and to *report* current holds; apply only with
    `-Commit` and only against the legal-owner-provided list.

## Stage 3 — Pilot validate (pass/fail gates)
13. Run the validation script and the tests in **§5**:
    ```powershell
    .\EXOARCH-Validation.ps1 -Identities (Get-Content .\pilot.txt)
    ```
    **Pass gates (all must hold for the pilot before expanding):**
    - Every licensed pilot mailbox shows `ArchiveStatus = Active` (and `AutoExpandingArchiveEnabled =
      True` if that was in scope).
    - The pilot mailboxes have `Archive Retention Policy – EXO – Prod` assigned, and after the MFA has
      run, aged items have moved to the archive (archive item count/size increased; primary decreased).
    - Imported PSTs appear in the target archives (`PST Import – Archive – Ingest` shows completed).
    - Held mailboxes report the expected `LitigationHoldEnabled = True` and/or the In-Place hold GUID.
    **Fail:** if any gate fails, stop, diagnose with **§6**, and do not expand.

## Stage 4 — Expand
14. Repeat Stages 2–3 against `Archive Scope – Broad – Stage2` in controlled waves (enable archives →
    assign policy → trigger MFA → import PSTs → apply holds per determination), validating each wave with
    **`EXOARCH-Validation.ps1`** before the next.
15. **Report.** Produce **`Archive Validation – EXO – Report`** with **`EXOARCH-Report.ps1`** for the
    service/records owner: archives enabled, auto-expand status, policy coverage, archive growth, PST
    imports completed, and holds in force.

---

## Rollback
- **Archive move-to-archive:** remove the retention policy from a mailbox
  (`Set-Mailbox <id> -RetentionPolicy $null` or reassign the prior policy). Items already moved to the
  archive **stay in the archive** — MRM does not move them back; users still access them from the archive.
- **Retention tags/policy:** an unused tag/policy can be removed (`Remove-RetentionPolicyTag` /
  `Remove-RetentionPolicy`) once no mailbox references it.
- **Archive mailbox:** an archive can be disabled (`Disable-Mailbox <id> -Archive`), but **archive
  contents are removed on disable** and there is a grace period before the archive is unrecoverable — do
  not disable an archive that received PST data or that is under any hold. **Auto-expanding archive
  cannot be turned off** once enabled — there is no rollback for that switch; do not enable it without
  sign-off.
- **Holds:** a hold is released only on the legal/records owner's instruction (litigation:
  `Set-Mailbox <id> -LitigationHoldEnabled $false`; In-Place/eDiscovery: remove/close in the Purview
  case). **Never release a hold on your own initiative.**


---


# 5. Testing & Validation

Run these after each pilot wave and before expanding. Each test states an expected **pass** and a
**fail**. Reuse the artifact names from §1. `EXOARCH-Validation.ps1` automates most of these; the
manual checks confirm the user-visible result.

---

## Test 1 — Archive mailbox provisioned
- **How:** `Get-Mailbox <pilot-user> | Format-List ArchiveStatus,ArchiveGuid,ArchiveName` (or
  `EXOARCH-Validation.ps1`).
- **Pass:** `ArchiveStatus = Active` and a non-zero `ArchiveGuid` for every licensed pilot user. In
  Outlook/OWA the user sees an **Online Archive / In-Place Archive** node.
- **Fail:** `ArchiveStatus = None` or an all-zero `ArchiveGuid`. Common cause: user not licensed for an
  archive (Requirement 2.1) or enable not yet replicated — see §6.

## Test 2 — Auto-expanding archive (if in scope)
- **How:** `Get-Mailbox <pilot-user> | Format-List AutoExpandingArchiveEnabled` and
  `Get-OrganizationConfig | Format-List AutoExpandingArchive`.
- **Pass:** `AutoExpandingArchiveEnabled = True` (per-mailbox) or the org flag is on, for the users where
  auto-expand was intended and the plan supports it.
- **Fail:** `False` where it was intended. Confirm plan support (**verify in your tenant/plan**) and that
  the switch was committed — remember it is **one-way**, so absence means it was never applied, not
  reverted.

## Test 3 — Retention policy assigned
- **How:** `Get-Mailbox <pilot-user> | Format-List RetentionPolicy`.
- **Pass:** returns `Archive Retention Policy – EXO – Prod` for every pilot mailbox.
- **Fail:** blank or a different policy. Re-run the assignment step (Implementation step 10).

## Test 4 — Tags and policy exist and are linked
- **How:** `Get-RetentionPolicy "Archive Retention Policy – EXO – Prod" | Format-List RetentionPolicyTagLinks`
  and `Get-RetentionPolicyTag | Where-Object Name -like '*Archive*'`.
- **Pass:** the policy links `Move to Archive – Default – Prod` and `Archive Now – Personal – Prod`; the
  DPT shows `RetentionAction = MoveToArchive`, `RetentionEnabled = True`, and the intended
  `AgeLimitForRetention`.
- **Fail:** missing link or a tag with `RetentionEnabled = False`. Re-run `EXOARCH-Set-MrmPolicy.ps1
  -Commit`.

## Test 5 — Move-to-archive actually moves aged mail (the key behavioral test)
- **How:** trigger and re-measure:
  ```powershell
  Start-ManagedFolderAssistant <pilot-user>
  # allow the assistant to process, then compare sizes:
  Get-MailboxStatistics <pilot-user>            # primary size / item count
  Get-MailboxStatistics <pilot-user> -Archive   # archive size / item count
  ```
- **Pass:** after the MFA has processed the mailbox (may take a work cycle / multiple runs), the
  **archive** item count/size has increased and the **primary** has decreased for a mailbox that had mail
  older than the DPT age. Aged items now appear under the Online Archive in Outlook/OWA.
- **Fail:** no movement after the MFA has run repeatedly over the expected window. Check the DPT age vs
  the mailbox's mail age, that the policy is assigned, and §6 (MRM diagnostics).

## Test 6 — PST import landed in the archive
- **How:** confirm the **`PST Import – Archive – Ingest`** job shows **Completed** in the Import service,
  then `Get-MailboxStatistics <pilot-user> -Archive` and spot-check in OWA under the Online Archive.
- **Pass:** the imported folders/items appear in the **archive** (not the primary), item counts match the
  source PSTs, and the job reports completed with no failed rows.
- **Fail:** items landed in the primary mailbox (mapping row's archive target was not set), or the job
  failed. Correct the mapping CSV (`IsArchive = TRUE`) / import role (Requirement 2.2) and re-run.

## Test 7 — Litigation hold enforced
- **How:** `Get-Mailbox <held-user> | Format-List LitigationHoldEnabled,LitigationHoldDate,
  LitigationHoldDuration`. Optionally verify preservation: delete a test item and confirm it is
  recoverable from **Recoverable Items** (it must not be purgeable while held).
- **Pass:** `LitigationHoldEnabled = True` (and the intended duration) for every mailbox on the legal
  owner's list; a hard-deleted test item remains recoverable.
- **Fail:** `False` where the determination requires a hold, or a deleted item is unrecoverable. Re-apply
  per the determination (Implementation step 12).

## Test 8 — In-Place / eDiscovery hold enforced
- **How:** in the Purview eDiscovery case, confirm `eDiscovery Hold – <Matter> – Legal` is **On** with
  the intended sources; `Get-Mailbox <held-user> | Format-List InPlaceHolds` shows the hold GUID.
- **Pass:** the hold is on, scoped to the custodians/query from the determination, and the mailbox lists
  the hold.
- **Fail:** hold off or wrong scope. Correct in the case per the legal owner; do not change scope on your
  own.

## Test 9 — Nothing under hold was disabled/removed
- **How:** re-run `EXOARCH-Discovery.ps1` and confirm no mailbox that should be held has an archive
  disabled or a hold missing.
- **Pass:** every mailbox that had a hold still has it; no held archive was disabled by the rollback path.
- **Fail:** a hold or held archive is missing — investigate immediately (a held item must never be lost).

---

**Overall pilot pass criteria:** Tests 1, 3, 4, 5 pass for the pilot scope; Tests 2, 6, 7, 8 pass for
whichever of auto-expand / PST import / holds were in scope; Test 9 passes always. Only then expand to
`Archive Scope – Broad – Stage2`.


---


# 6. Troubleshooting

Common failure modes for Exchange Online Archiving, MRM move-to-archive, PST import, and holds — with
the likely root cause and the fix. Reuse the artifact names from §1. Start every investigation by
re-running `EXOARCH-Discovery.ps1` to capture the current state.

---

## Archive won't enable / `ArchiveStatus` stays `None`
- **Symptom:** `Enable-Mailbox -Archive` fails, or `ArchiveStatus = None` after enabling.
- **Likely cause:** the user's plan does not include an archive mailbox (the #1 cause), or the enable
  hasn't replicated yet.
- **Fix:** verify archiving-capable licensing for that user (Requirement 2.1 — **verify in your
  tenant/plan**); assign an archiving-capable plan / the Exchange Online Archiving add-on, then re-enable.
  If licensed, allow time and re-check with `Get-Mailbox <id> | fl ArchiveStatus,ArchiveGuid`.

## Auto-expanding archive doesn't seem to apply
- **Symptom:** archive fills to the base quota and does not grow; `AutoExpandingArchiveEnabled = False`.
- **Likely cause:** auto-expand was never committed, the mailbox isn't archive-enabled yet, or the plan
  doesn't support auto-expand.
- **Fix:** confirm the archive is Active first, then enable auto-expand (`Enable-Mailbox <id>
  -AutoExpandingArchive` or org-wide `Set-OrganizationConfig -AutoExpandingArchive`). Remember it is
  **one-way** — a `False` value means it was never turned on, not reverted. Auto-expand
  availability/limits are **plan-dependent — verify in your tenant/plan**.

## Aged mail is not moving to the archive
- **Symptom:** the archive stays empty / primary mailbox doesn't shrink after assigning the policy.
- **Likely causes & fixes:**
  1. **Managed Folder Assistant hasn't processed the mailbox yet.** Move-to-archive is not instant.
     Trigger it: `Start-ManagedFolderAssistant <id>`, then re-check after it runs (large mailboxes take
     multiple cycles). This is expected, not a failure.
  2. **Retention policy not assigned.** `Get-Mailbox <id> | fl RetentionPolicy` should return
     `Archive Retention Policy – EXO – Prod`; if blank, run Implementation step 10.
  3. **DPT disabled or wrong age.** `Get-RetentionPolicyTag "Move to Archive – Default – Prod"` should
     show `RetentionAction = MoveToArchive`, `RetentionEnabled = True`, and an `AgeLimitForRetention`
     that is actually less than the age of mail in the mailbox. If the age is set higher than the
     mailbox's mail, nothing qualifies to move yet.
  4. **Tag not linked to the policy.** Re-run `EXOARCH-Set-MrmPolicy.ps1 -Commit` to relink.

## PST import landed in the primary mailbox, not the archive
- **Symptom:** imported folders appear in the primary mailbox; the archive is empty.
- **Likely cause:** the import mapping CSV row did not set the archive as the target
  (`IsArchive` not `TRUE`).
- **Fix:** correct the mapping CSV so each row's target is the archive (`IsArchive = TRUE`) and re-run
  the **`PST Import – Archive – Ingest`** job. (Items already in the primary can be moved to the archive
  by the move-to-archive policy over time, but re-importing correctly is cleaner for large sets.)

## PST import fails immediately / access denied
- **Symptom:** the import job or the mapping submission fails with a permissions error.
- **Likely cause:** the operator lacks the **Mailbox Import Export** management role (it is not assigned
  to any role group by default).
- **Fix:** assign the role (Requirement 2.2), sign out/in to refresh the token, and re-submit. Revoke the
  role after the import window (Best Practices).

## Litigation hold set but a deleted item is unrecoverable
- **Symptom:** `LitigationHoldEnabled = True` yet a hard-deleted test item cannot be recovered.
- **Likely cause:** the hold was only just applied (there can be a short propagation delay before it is
  fully effective), or you tested the wrong mailbox.
- **Fix:** confirm `LitigationHoldEnabled = True` and `LitigationHoldDate` is set on the exact mailbox;
  allow propagation, then re-test recovery from **Recoverable Items**. If it persists, re-apply per the
  determination and escalate — a held item must never be lost.

## In-Place / eDiscovery hold not showing on the mailbox
- **Symptom:** the Purview case shows the hold but `Get-Mailbox <id> | fl InPlaceHolds` is empty (or
  vice-versa).
- **Likely causes & fixes:** the hold is still propagating (allow time), the custodian/source scope in
  the case does not include that mailbox (correct the source in the case — **with the legal owner**), or
  the hold is off. Do not change hold scope on your own initiative.

## "I disabled an archive and lost data"
- **Symptom:** archive contents gone after `Disable-Mailbox -Archive`.
- **Cause:** disabling an archive **removes its contents** (there is a limited grace period before it is
  unrecoverable).
- **Fix / prevention:** never disable an archive that received PST data or that is (or its mailbox is)
  under any hold. If within the grace period, an archive can sometimes be reconnected — act immediately
  and escalate; do not rely on it.

## Portal path or connection fails on a Government cloud
- **Symptom:** a portal URL 404s, or `Connect-ExchangeOnline` reaches the wrong tenant.
- **Cause:** Commercial paths/parameters used on **GCC High / DoD**.
- **Fix:** use the sovereign-cloud portal URLs (`*.office365.us` / `*.microsoft.us`) and
  `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (or the DoD value). Confirm the
  tenant's cloud (Requirement 2.6) — **verify on your cloud**.


---


# 7. Best Practices

Durable practices for running Exchange Online Archiving, MRM, PST import, and holds well. These outlast
any single rollout.

## Licensing & entitlement
- **Verify archiving entitlement before you enable anything.** Archive and auto-expanding archive
  availability are plan-dependent and change over time — confirm per user (Requirement 2.1), never
  assume. A batch enable against unlicensed users produces silent no-ops and confusing tickets.
- **Right-size scope to entitlement.** Enable archives for users who actually need them (near quota,
  PSTs to ingest, or a hold obligation) rather than the whole tenant blindly.

## Auto-expanding archive (treat as irreversible)
- **Enable auto-expanding archive deliberately, with sign-off.** It **cannot be turned off**. Enable it
  where mailboxes will genuinely exceed the base archive quota, not reflexively.
- **Expect slower mailbox moves** for auto-expanded (multi-chunk) archives; factor that into any future
  migration or region move.

## MRM tags & policy hygiene
- **One archive DPT, named and reused.** Keep a single `Move to Archive – Default – Prod` DPT and one
  `Archive Retention Policy – EXO – Prod`; don't proliferate near-duplicate tags. Fewer, well-named
  artifacts are easier to validate and troubleshoot.
- **Set the archive-move age with the records owner**, and document it. It is a policy decision (how old
  before mail moves), not a technical default.
- **Trigger the Managed Folder Assistant to validate, but let it run naturally in production.**
  `Start-ManagedFolderAssistant` is for pilots/validation; don't script constant forced runs fleet-wide.
- **Remember the MRM vs Purview boundary.** MRM archive tags move items to the archive. For
  retention/deletion across workloads, DLP, or sensitivity labels, use the separate Purview product —
  keep the two models from silently overlapping on the same mailboxes without intent.

## PST import
- **Assign the Mailbox Import Export role explicitly and remove it after.** It is off by default and
  powerful — grant it for the import window under change control, then revoke.
- **Always target the archive (`IsArchive = TRUE`) for historical PST data**, so ingestion controls the
  primary mailbox rather than inflating it.
- **Validate item counts** against the source PSTs; a "completed" job with a lower count means dropped
  rows — reconcile before retiring the source PSTs.
- **Do not delete source PSTs until import is validated** and (if relevant) the archive is under the
  intended policy/hold.

## Holds & preservation
- **Holds follow a documented legal/records determination — always.** The implementer applies; the
  legal/records owner decides scope and duration. Record the matter ID in the artifact name
  (`Litigation Hold – <Matter> – Legal` / `eDiscovery Hold – <Matter> – Legal`).
- **Never disable an archive or release a hold on a held mailbox on your own initiative.** A held item
  lost is a defensibility failure. Rollback paths explicitly exclude held mailboxes.
- **Prefer litigation hold for simple, mailbox-wide preservation** and In-Place/eDiscovery holds when
  scope must be query- or date-bound to a matter.
- **Track hold inventory.** Periodically report which mailboxes are held and why, so holds are released
  when the legal owner closes the matter — stale holds accumulate cost and risk.

## Change discipline
- **Pilot-first, every time**, with the §5 pass/fail gates and the §3 rollback ready before touching
  production. Archive enablement, move-to-archive, and holds are all user- or legally-visible.
- **Keep artifact names verbatim** across EAC, Purview, docs, and scripts — consistent names are what
  make validation and troubleshooting fast.
- **Confirm your cloud.** Substitute the correct portal URLs and `Connect-ExchangeOnline
  -ExchangeEnvironmentName` value on GCC High / DoD; don't assume Commercial paths.
- **No secrets in automation.** Use modern-auth `Connect-ExchangeOnline` / `Connect-MgGraph`; never store
  credentials in scripts or scheduled tasks.


---


# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **1. Solution Overview** | What Exchange Online Archiving is here, how it works, the reference model/artifacts, benefits, limitations, and the explicit boundary vs Purview DLP/labels/retention. |
| **2. Requirements** | Solution-specific prerequisites (archiving-capable licensing, least-privilege roles incl. Mailbox Import Export, PST source, legal/records determination, MFA timing, Commercial-vs-Gov) with verify/implement steps — on top of the shared Messaging requirements. |
| **3. Implementation** | Exact ordered steps: assess → design → enable archives + auto-expand → build MRM tags/policy → import PSTs → apply holds → pilot-validate → expand, with pass/fail gates and a rollback. Every artifact named. |
| **5. Testing & Validation** | Nine tests (archive provisioned, auto-expand, policy assigned, tags linked, move-to-archive working, PST landed in archive, litigation hold, In-Place hold, nothing-held-lost), each with pass/fail. |
| **6. Troubleshooting** | Common failure modes (archive won't enable, auto-expand not applying, mail not moving, PST in wrong place, hold not enforcing) with root cause and fix. |
| **7. Best Practices** | Durable practices for licensing, irreversible auto-expand, MRM hygiene, PST import, holds/preservation, and change discipline. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk summary for decision-makers. |

## PowerShell scripts (5) — Exchange Online PowerShell (EXO V3) / Microsoft Graph
All are **safe by default** (read-only or `-WhatIf`/report unless an explicit `-Commit`), use modern-auth
`Connect-ExchangeOnline` (no stored credentials), and reuse the artifact names from the reference model.

| Script | What it does | Safe default |
|---|---|---|
| **EXOARCH-Discovery.ps1** | Read-only assessment: per-mailbox archive status, auto-expand flag, retention policy, primary/archive sizes, litigation + In-Place holds. Emits `Archive Posture – EXO – Discovery`. | Read-only |
| **EXOARCH-EnableArchive.ps1** | Enables the archive mailbox (and optionally the **irreversible** auto-expanding archive) for a scope; skips already-enabled; warns on unlicensed. | Dry-run unless `-Commit`; `-WhatIf` |
| **EXOARCH-Set-MrmPolicy.ps1** | Idempotently creates/updates the MRM move-to-archive DPT `Move to Archive – Default – Prod`, personal tag `Archive Now – Personal – Prod`, and policy `Archive Retention Policy – EXO – Prod`. | Preview unless `-Commit`; `-WhatIf` |
| **EXOARCH-Set-Holds.ps1** | Reports current holds; with `-Commit -Matter` applies **litigation hold** per the legal/records determination. (In-Place/eDiscovery holds are created in the Purview case.) | Report unless `-Commit`; `-WhatIf` |
| **EXOARCH-Validation.ps1** | Read-only pass/fail validation of archive, auto-expand, policy assignment, move-to-archive/PST ingest, and holds; optionally triggers the Managed Folder Assistant; emits `Archive Validation – EXO – Report`. | Read-only |

> **Licensing note:** archive and auto-expanding archive availability are **plan-dependent** — verify in
> your tenant/plan before enabling. **Holds** are technical only; **what to preserve and for how long is
> a legal/records determination**, not an implementer decision.
