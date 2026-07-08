# Data Archiving Strategy — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLCARCH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

## The problem

Cold, infrequently accessed data clogs primary mail and content stores. Left unaddressed, it drives
up storage cost, slows the environment, and becomes a **compliance gap and data-risk exposure** —
data nobody manages, on the most expensive tier, with no defined lifecycle.

## The solution

This solution delivers an end-to-end **data archiving strategy** in Microsoft Purview and Exchange
Online. It moves cold data off primary stores **without losing it and without breaking access**,
using three coordinated levers:

- **Mailbox archiving** — Exchange Online archive mailboxes (and auto-expanding archive where
  volume warrants), keeping cold mail fully searchable in a lower-cost tier.
- **Retention / lifecycle policy** — Messaging Records Management move-to-archive tags that age
  content into the archive automatically, plus Purview Data Lifecycle Management retention policies
  that keep (and, where the records schedule requires, dispose of) content on a defined timeline.
- **Tiering** — a hot → warm → cold model so storage cost tracks how often data is actually used.

## How it is delivered

Every high-impact change is **piloted on a limited, named scope before tenant-wide expansion**:
**Assess → Design → Configure → Pilot → Validate → Expand**. The pilot uses test mailboxes,
disables all delete actions, and gates every write behind an explicit confirmation, because
archiving moves data and is not trivially reversible. Configuration is proven with **pass/fail
gates** and captured **evidence** at each step.

## What is included

Seven guides (Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices,
Deliverables) and **five PowerShell tools** (Discovery, Configuration/Remediation, Validation,
Reporting, and a scope/health helper) — all read-only or preview-mode by default, with no
credentials in code.

## Boundaries and assurances

- **Records / compliance / legal own the retention timeline** and any disposition decision; this
  solution provides the technical method and the evidence, not the determination.
- Microsoft Purview and Exchange archiving features are **licensing-/plan-dependent and evolving** —
  availability and paths are verified against current Microsoft documentation, never invented.
- Automation is **PowerShell** with modern-auth sign-in and **no hardcoded secrets**.

## The bottom line

Cold data is archived — **contained, still accessible, cost-optimized, validated, and defensible**
— in Microsoft Purview.


---


# Solution Overview

## What this delivers

This solution delivers a **data archiving strategy** in Microsoft Purview and Exchange Online:
a defensible way to move **cold, infrequently accessed data** off primary stores into lower-cost
archive tiers **without losing it and without breaking access**. It combines three levers:

1. **Mailbox archiving** — Exchange Online **archive mailboxes** (In-Place Archive) and, where
   volume warrants, **auto-expanding archive**, so a user's cold mail moves out of the primary
   mailbox into archive storage that is still fully searchable.
2. **Retention / lifecycle policy** — **Messaging Records Management (MRM)** *move-to-archive* tags
   and policies that age content into the archive automatically, plus **Microsoft Purview Data
   Lifecycle Management** retention policies that keep (and, where the records schedule requires,
   dispose of) content on a defined timeline.
3. **Tiering** — a hot → warm → cold model (primary mailbox → archive mailbox → cold/archive
   storage such as **Microsoft 365 Archive** for SharePoint), so the storage cost of data tracks
   its access frequency.

The outcome is a configured, **piloted**, and **validated** archiving capability with named
policies, pass/fail gates, evidence, and a documented rollback — so cold data is contained and the
strategy is operable and defensible.

> **Scope boundary.** This solution provides the **technical configuration method and evidence**.
> The **retention schedule itself** — how long each class of content must be kept, when it may be
> disposed, and what is a business record — is a **records / compliance / legal determination** and
> is **deferred** to those functions (see the category Global Requirements). We configure what they
> decide; we do not decide it.

## How it works in Microsoft Purview and Exchange Online

- **Archive mailbox (In-Place Archive)** is an additional mailbox that appears alongside the primary
  mailbox in Outlook / Outlook on the web. Enabling it requires **Exchange Online Plan 2** (included
  in Microsoft 365 E3/E5) or **Exchange Online Plan 1 with the Exchange Online Archiving add-on** —
  *verify your licensing/tenant.*
- **Auto-expanding archive** adds storage automatically as the archive fills, for users with very
  large archives. It is enabled per-mailbox (`Enable-Mailbox -AutoExpandingArchive`) or org-wide
  (`Set-OrganizationConfig -AutoExpandingArchive $true`). **Enabling it is not reversible** — pilot
  deliberately.
- **MRM move-to-archive tags** (retention tags with `RetentionAction MoveToArchive`) are linked into
  a **retention policy** assigned to mailboxes; the **Managed Folder Assistant (MFA)** processes
  mailboxes and moves aged items into the archive.
- **Purview Data Lifecycle Management** retention policies and labels apply *keep* / *keep-and-delete*
  / *delete* actions across Exchange, SharePoint, OneDrive and Teams from the Purview portal.
- **Tiering to cold storage** — **Microsoft 365 Archive** moves inactive SharePoint sites to a cold
  storage tier (pay-as-you-go via an Azure subscription). It is **evolving / billing-gated** — treat
  paths and availability as *verify your licensing/tenant.*

## The delivery model

This solution follows the standard Purview delivery model, and **every high-impact change is piloted
on a limited scope before tenant-wide expansion**:

| Phase | What happens |
|-------|--------------|
| **Assess** | Inventory mailbox sizes, existing archive status, current MRM tags/policies, existing DLM retention policies, and the org-level auto-expanding archive setting. Confirm licensing and roles. |
| **Design** | Define the tiering model (what ages to archive, at what age), name the MRM tags and policy, and capture the retention timeline **as decided by records/compliance** — not by us. |
| **Configure** | Create the MRM move-to-archive tag and policy; enable archive mailboxes for the pilot scope; stage the DLM retention policy against the pilot scope. Scripts default to **read-only / `-WhatIf`**. |
| **Pilot** | Apply to a **named pilot group** of test mailboxes only. Run the Managed Folder Assistant and observe items moving to archive. **No delete action** is enabled in pilot. |
| **Validate** | Run pass/fail checks: archive enabled, policy assigned, MFA processed, items in archive, retention policy applied. Capture evidence. |
| **Expand (enforce)** | Widen scope to production mailboxes under change control once the pilot passes. |

> **Reversibility caveat.** Archiving moves data. Once items are moved into the archive or an
> auto-expanding archive is enabled, the change is **not trivially reversible**, and any *delete*
> action is irreversible. This is why the pilot uses test mailboxes, disables delete actions, and
> gates all write operations behind an explicit `-Commit` switch.

## What is included

- **Solution Overview** (this document).
- **Requirements Guide** — solution-specific prerequisites with verify/implement steps.
- **Implementation Guide** — exact ordered configuration steps, every policy and tag named, with
  pass/fail gates and rollback.
- **Testing & Validation** — the gates that prove the archiving strategy works.
- **Troubleshooting** — common failure signatures and resolutions.
- **Best Practices** — how to keep the strategy healthy and defensible.
- **5 PowerShell scripts** — Discovery, Configuration/Remediation, Validation, Reporting, and a
  scope/health helper (Exchange Online + Security & Compliance PowerShell; read-only or `-WhatIf`
  by default; no credentials in code).


---


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


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# Implementation

This guide configures the archiving strategy in exact, ordered steps. **Every high-impact change is
piloted on a named test scope first**, with pass/fail gates and a rollback for each step. Cmdlet
names and portal paths follow Microsoft's public documentation; where a capability is plan-gated or
the portal is evolving, **verify your licensing/tenant**. All write operations in the provided
scripts are gated behind an explicit `-Commit` switch (default is read-only / `-WhatIf`).

**Named objects used throughout (adjust to your naming standard):**

| Object | Name used in this guide |
|--------|--------------------------|
| Pilot mailbox group (mail-enabled security group) | `grp-archive-pilot` |
| MRM move-to-archive tag (Default Policy Tag, all content) | `MTA-2yr` (Move to Archive, 730 days) |
| MRM optional personal tag | `MTA-Personal-1yr` (Move to Archive, 365 days) |
| MRM retention policy | `RP-Corp-Archive` |
| Purview DLM retention policy (keep only in pilot) | `DLM-Exchange-Keep` |
| Placeholder domain | `contoso.com` |

> Retention *durations* (730/365 days above) are **illustrative**. Use the values **records/compliance
> approved** (Requirement R5). Do **not** enable any *delete* action until records/legal has signed off.

---

## Step 0 — Preflight (read-only)

1. Connect and confirm access:
   ```powershell
   Connect-ExchangeOnline
   Connect-IPPSSession
   Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"
   ```
2. Run the scope/health helper: `.\Get-ArchiveScopeHealth.ps1 -PilotGroup grp-archive-pilot`.
3. Run discovery: `.\Invoke-ArchiveDiscovery.ps1 -OutputPath .\discovery`.

**Pass/fail gate:** All three connections succeed; discovery reports current archive status, mailbox
sizes, existing MRM tags/policies, existing DLM retention policies, and the org-level
`AutoExpandingArchive` value. **If any connection fails, stop** and resolve licensing/roles (R1–R3).

**Rollback:** None — read-only.

---

## Step 1 — Confirm licensing and the org-level auto-expanding archive posture

1. Verify Plan 2 / archiving entitlement on the pilot users (R1).
2. Check the org setting **without changing it yet**:
   ```powershell
   Get-OrganizationConfig | Format-List AutoExpandingArchive
   ```
3. **Decide the tiering design** with stakeholders: which mailboxes get archives, the age threshold
   for move-to-archive, and whether **auto-expanding archive** is needed (only for users whose
   archive will exceed the base archive quota).

**Pass/fail gate:** Entitlement confirmed on all pilot users; the design (age threshold, scope,
auto-expanding yes/no) is documented and approved.

**Rollback:** None — no change made.

> **Caution:** `Set-OrganizationConfig -AutoExpandingArchive $true` is **org-wide and not
> reversible.** Prefer **per-mailbox** `Enable-Mailbox -AutoExpandingArchive` during pilot so the
> blast radius is limited to test users.

---

## Step 2 — Enable archive mailboxes for the PILOT scope only

1. Preview with the configuration script (default `-WhatIf`):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableArchive -WhatIf
   ```
2. Apply to the pilot scope:
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableArchive -Commit
   ```
   (Equivalent manual cmdlet: `Enable-Mailbox -Identity <user> -Archive`.)
3. If the design calls for auto-expanding archive on specific pilot users:
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -EnableAutoExpanding -Commit
   ```
   (Equivalent: `Enable-Mailbox -Identity <user> -AutoExpandingArchive`.)

**Pass/fail gate:** `Get-Mailbox <pilotuser> | fl ArchiveStatus,ArchiveGuid` shows
`ArchiveStatus = Active` and a non-empty `ArchiveGuid` for every pilot user.

**Rollback:** `Disable-Mailbox -Identity <user> -Archive` disconnects the archive; the disconnected
archive is retained for **30 days** and can be reconnected within that window, after which it is
**permanently removed**. Auto-expanding archive, once enabled, **cannot be disabled**.

---

## Step 3 — Create the MRM move-to-archive tag and retention policy

1. Preview, then create the tag and policy (script gates writes behind `-Commit`):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -CreateMrmPolicy -TagName MTA-2yr -AgeDays 730 `
       -PolicyName RP-Corp-Archive -WhatIf
   .\Set-ArchiveStrategy.ps1 -CreateMrmPolicy -TagName MTA-2yr -AgeDays 730 `
       -PolicyName RP-Corp-Archive -Commit
   ```
   Equivalent manual cmdlets:
   ```powershell
   New-RetentionPolicyTag -Name "MTA-2yr" -Type All -RetentionAction MoveToArchive `
       -AgeLimitForRetention 730 -RetentionEnabled $true
   New-RetentionPolicy   -Name "RP-Corp-Archive" -RetentionPolicyTagLinks "MTA-2yr"
   ```
2. (Optional) add a **personal** move-to-archive tag users can apply to folders:
   ```powershell
   New-RetentionPolicyTag -Name "MTA-Personal-1yr" -Type Personal `
       -RetentionAction MoveToArchive -AgeLimitForRetention 365 -RetentionEnabled $true
   Set-RetentionPolicy -Identity "RP-Corp-Archive" `
       -RetentionPolicyTagLinks "MTA-2yr","MTA-Personal-1yr"
   ```

**Pass/fail gate:** `Get-RetentionPolicyTag "MTA-2yr"` shows `RetentionAction = MoveToArchive` and the
expected `AgeLimitForRetention`; `Get-RetentionPolicy "RP-Corp-Archive"` lists the tag(s).

**Rollback:** `Set-RetentionPolicy -Identity RP-Corp-Archive -RetentionPolicyTagLinks @()` unlinks the
tags (stops future moves); `Remove-RetentionPolicyTag` / `Remove-RetentionPolicy` removes them.
**Items already moved to the archive are not moved back.**

---

## Step 4 — Assign the policy to the pilot mailboxes and run the Managed Folder Assistant

1. Assign and process (preview then commit):
   ```powershell
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -AssignPolicy RP-Corp-Archive -WhatIf
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -AssignPolicy RP-Corp-Archive -Commit
   .\Set-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -RunAssistant -Commit
   ```
   Equivalent manual cmdlets:
   ```powershell
   Set-Mailbox -Identity <pilotuser> -RetentionPolicy "RP-Corp-Archive"
   Start-ManagedFolderAssistant -Identity <pilotuser>
   ```

**Pass/fail gate:** `Get-Mailbox <pilotuser> | fl RetentionPolicy` shows `RP-Corp-Archive`; after the
MFA cycle, `Get-MailboxStatistics <pilotuser> -Archive` shows a growing archive
`TotalItemSize`/`ItemCount` for items older than the age threshold.

**Rollback:** `Set-Mailbox -Identity <user> -RetentionPolicy "Default MRM Policy"` reverts to the
built-in policy; future moves stop. Already-archived items remain in the archive.

---

## Step 5 — (Optional, keep-only in pilot) stage a Purview DLM retention policy

> Only if records/compliance has approved a **keep** timeline. **Do not** enable *delete* in pilot.

1. In the **Purview portal → Data Lifecycle Management → Retention policies**, or via PowerShell:
   ```powershell
   New-RetentionCompliancePolicy -Name "DLM-Exchange-Keep" -ExchangeLocation <pilot mailbox(es)>
   New-RetentionComplianceRule   -Name "DLM-Exchange-Keep-Rule" -Policy "DLM-Exchange-Keep" `
       -RetentionDuration 2555 -RetentionComplianceAction Keep
   ```
   (`Keep` only — no `Delete`/`KeepAndDelete` until R5 sign-off. `2555` days ≈ 7 years, illustrative.)
2. Scope the policy to the **pilot mailboxes only** for the first ring.

**Pass/fail gate:** `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" | fl DistributionStatus`
reaches a healthy/`Success` distribution state and applies to the pilot scope only.

**Rollback:** `Set-RetentionCompliancePolicy -Identity "DLM-Exchange-Keep" -Enabled $false` or
`Remove-RetentionCompliancePolicy`. Because the action is **Keep**, no data is deleted, so rollback is
safe.

---

## Step 6 — Validate the pilot

Run the validation script and capture evidence:
```powershell
.\Test-ArchiveStrategy.ps1 -PilotGroup grp-archive-pilot -PolicyName RP-Corp-Archive `
    -OutputPath .\validation
```

**Pass/fail gate:** All pilot users show archive enabled, `RP-Corp-Archive` assigned, MFA processed,
archive item count > 0 where aged content exists, and (if staged) the DLM policy in a healthy state.
See **Testing & Validation** for the full gate list.

**Rollback:** See each step above; disable/unlink rather than delete.

---

## Step 7 — Expand (enforce) to production under change control

Only after the pilot passes and is signed off:

1. Widen the archive-enable + policy-assignment scope from `grp-archive-pilot` to the approved
   production population (in rings, not all at once).
2. If auto-expanding archive is org-wide by design, enable it org-wide **only now** and **only with
   explicit approval** — remember it is **irreversible**:
   ```powershell
   Set-OrganizationConfig -AutoExpandingArchive $true
   ```
3. (Optional, tiering) enable **Microsoft 365 Archive** for inactive SharePoint sites from the
   **SharePoint admin center / Microsoft 365 Archive** — pay-as-you-go via an Azure subscription;
   **verify your licensing/tenant** as this capability is billing-gated and evolving.
4. Re-run `Test-ArchiveStrategy.ps1` and `Export-ArchiveReport.ps1` for each ring and archive the
   evidence.

**Pass/fail gate:** Each ring validates green before the next ring starts; reports show archive
adoption and primary-store reduction trending as designed.

**Rollback:** Pause expansion; for a ring, unlink/reassign policies and disable archives per Steps 2–4
(bearing the reversibility caveats in mind). Never enable a delete action to "clean up" a rollback.


---


# Testing & Validation

Validation proves the archiving strategy is configured, took effect, and is defensible — with
**explicit pass/fail gates** and captured evidence. Run these against the **pilot scope first**, then
against each expansion ring. Most checks are automated by `Test-ArchiveStrategy.ps1` (read-only);
the manual cmdlets are given so results can be reproduced by hand.

> All checks are **read-only**. None of them move or delete data.

---

## Gate 1 — Licensing and connectivity

| Check | Method | Pass |
|-------|--------|------|
| Admin can reach both surfaces | `Connect-ExchangeOnline` + `Connect-IPPSSession` succeed | No auth error |
| Pilot users are archiving-entitled | `Get-Mailbox <user> \| fl PersistedCapabilities` / license check in admin center | Plan 2 / archiving add-on present |

**Fail action:** resolve licensing (R1) / roles (R2) before continuing.

## Gate 2 — Archive mailbox provisioned

| Check | Method | Pass |
|-------|--------|------|
| Archive enabled for every pilot user | `Get-Mailbox <user> \| fl ArchiveStatus,ArchiveGuid` | `ArchiveStatus = Active`, non-empty `ArchiveGuid` |
| Auto-expanding archive matches design | `Get-Mailbox <user> \| fl AutoExpandingArchiveEnabled` and `Get-OrganizationConfig \| fl AutoExpandingArchive` | Matches the approved design |

## Gate 3 — MRM tag and policy correct

| Check | Method | Pass |
|-------|--------|------|
| Move-to-archive tag exists and is correct | `Get-RetentionPolicyTag "MTA-2yr" \| fl RetentionAction,AgeLimitForRetention,RetentionEnabled` | `RetentionAction = MoveToArchive`, expected age, `RetentionEnabled = True` |
| Policy links the tag | `Get-RetentionPolicy "RP-Corp-Archive" \| fl RetentionPolicyTagLinks` | Includes `MTA-2yr` |
| Policy assigned to pilot mailboxes | `Get-Mailbox <user> \| fl RetentionPolicy` | `RP-Corp-Archive` |

## Gate 4 — Managed Folder Assistant processed and items moved

| Check | Method | Pass |
|-------|--------|------|
| MFA has processed the mailbox | Confirm the MFA work cycle completed (or `Start-ManagedFolderAssistant` was run) and no error | Processed without error |
| Aged items are in the archive | `Get-MailboxStatistics <user> -Archive \| fl ItemCount,TotalItemSize` before vs. after | Archive `ItemCount`/`TotalItemSize` increased for users with content older than the age threshold |
| Primary store reduced | Compare `Get-MailboxStatistics <user>` primary size before/after | Primary `TotalItemSize` trending down where content aged out |

> If aged content exists but nothing moved, MFA may not have run yet (it is throttled/asynchronous),
> or the tag age/enabled flag is wrong — see Troubleshooting.

## Gate 5 — Purview DLM retention policy (if staged)

| Check | Method | Pass |
|-------|--------|------|
| Policy distributed successfully | `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" \| fl DistributionStatus,Enabled` | Healthy/`Success`, `Enabled = True` |
| Action is Keep only in pilot | `Get-RetentionComplianceRule -Policy "DLM-Exchange-Keep" \| fl RetentionComplianceAction` | `Keep` (no delete in pilot) |
| Scope is pilot-only | `Get-RetentionCompliancePolicy "DLM-Exchange-Keep" \| fl ExchangeLocation` | Pilot mailboxes only |

## Gate 6 — No unintended deletion / hold conflict

| Check | Method | Pass |
|-------|--------|------|
| No delete action active in pilot | Review all MRM tags in `RP-Corp-Archive` and the DLM rule | No `DeleteAndAllowRecovery` / `Delete` / `KeepAndDelete` enabled |
| Legal holds respected | Confirm with legal that any holds are in place and unaffected | Holds intact; archiving does not bypass hold |

**Fail action for any gate:** stop expansion, record the failing gate, apply the matching
Troubleshooting fix, re-run the gate, and only proceed when green.

---

## Evidence to capture

- Discovery output (baseline) and validation output (post-change) from the scripts.
- `Get-Mailbox`/`Get-MailboxStatistics` before/after for a sample of pilot users (archive growth,
  primary reduction).
- The MRM tag/policy definitions and the DLM policy distribution status.
- The adoption/tiering report from `Export-ArchiveReport.ps1`.
- Records/compliance/legal sign-off reference for the retention timeline (R5).

Store the evidence with the change record so the archiving strategy is **defensible** on audit.


---


# Troubleshooting

Common failure signatures when standing up the archiving strategy, and how to resolve them. All
diagnostic cmdlets below are **read-only**.

---

## Archive mailbox will not enable

**Signature:** `Enable-Mailbox -Archive` errors, or `ArchiveStatus` stays `None`.

- **Licensing.** Archiving requires **Exchange Online Plan 2** (E3/E5) or **Plan 1 + Exchange Online
  Archiving add-on** — *verify your licensing/tenant*. Confirm the user's assigned plan in the admin
  center, then retry. (R1)
- **Role.** You need Recipient Management (mail-recipient) rights. Check
  `Get-ManagementRoleAssignment -RoleAssignee <you>`. (R2)
- **Replication lag.** After enabling, `ArchiveStatus` and `ArchiveGuid` can take time to populate.
  Re-check `Get-Mailbox <user> | fl ArchiveStatus,ArchiveGuid` after a short wait.

## Auto-expanding archive can't be turned off

**Signature:** you enabled `-AutoExpandingArchive` and now need to reverse it.

- **It is not reversible.** Auto-expanding archive **cannot be disabled** once enabled, per Microsoft.
  This is why the Implementation Guide enables it per-mailbox in pilot and only org-wide at expansion
  with explicit approval. There is no fix — plan around it.

## Items are not moving to the archive

**Signature:** archive is enabled and the policy is assigned, but `Get-MailboxStatistics -Archive`
shows `ItemCount = 0` or no growth.

- **The Managed Folder Assistant hasn't run.** MFA is asynchronous and throttled. Force it on a pilot
  mailbox: `Start-ManagedFolderAssistant -Identity <user>`, then re-check after it completes.
- **Tag age not reached.** `MoveToArchive` only moves items **older than** `AgeLimitForRetention`. If
  the mailbox has no content older than the threshold, nothing moves — that is correct. Verify with a
  user who has aged mail, or temporarily test with a smaller age on a **test** mailbox.
- **Tag disabled or wrong action.** Confirm
  `Get-RetentionPolicyTag <tag> | fl RetentionAction,RetentionEnabled` shows `MoveToArchive` and
  `True`.
- **Tag not linked / policy not assigned.** Confirm `Get-RetentionPolicy <policy>` lists the tag and
  `Get-Mailbox <user> | fl RetentionPolicy` shows the policy.
- **Item on hold.** Litigation/In-Place hold or Purview retention can keep an item in place; this is
  expected and takes precedence over the archive move.

## Retention policy assigned but behaviour unchanged

**Signature:** `Set-Mailbox -RetentionPolicy` succeeded but nothing happens.

- Retention-policy changes only take effect on the **next MFA cycle**. Trigger MFA and wait.
- Confirm the assignment actually stuck: `Get-Mailbox <user> | fl RetentionPolicy`.

## Purview DLM retention policy stuck or not applying

**Signature:** `Get-RetentionCompliancePolicy | fl DistributionStatus` shows a pending/error state.

- **Distribution takes time.** New DLM policies can take time to reach all locations; recheck later.
- **Connect the right session.** DLM cmdlets require **Security & Compliance PowerShell**
  (`Connect-IPPSSession`), *not* the Exchange Online session.
- **Scope/location.** Confirm `ExchangeLocation` includes the intended (pilot) mailboxes and nothing
  unintended.
- **Never add a delete action to "fix" it.** Keep the action `Keep` until records/legal signs off
  (R5). If a delete action appears in pilot, it was misconfigured — remove it.

## `Get-RetentionCompliancePolicy` / DLM cmdlets not found

**Signature:** command not recognized.

- You are in the wrong session. Run `Connect-IPPSSession` (Security & Compliance PowerShell). Use
  `Get-ArchiveScopeHealth.ps1` to confirm both sessions are connected.

## Pilot group resolves to zero mailboxes

**Signature:** scripts report `0 mailbox member(s)`.

- Confirm the group name/identity and that its members are **mailboxes** (not contacts or nested
  groups the cmdlet doesn't expand). Check `Get-DistributionGroupMember -Identity <group>`.

## Script made no change

**Signature:** `Set-ArchiveStrategy.ps1` printed a plan but changed nothing.

- **Working as designed.** The script is `-WhatIf` by default. Re-run with **`-Commit`** to apply,
  after reviewing the preview.

---

If a **Testing & Validation** gate keeps failing after these steps, stop the expansion, capture the
discovery/validation output, and review against the Implementation Guide's pass/fail gate for that
step before proceeding. Remember the reversibility limits — never enable a delete action as a
"cleanup" during troubleshooting.


---


# Best Practices

Practices that keep the archiving strategy healthy, cost-effective, and defensible over time. They
extend the category Global Requirements and the pilot-first delivery model.

## Strategy and scope

- **Tier by access frequency, not by guesswork.** Base the move-to-archive age on real telemetry
  (mailbox growth, how far back users actually search) from the Discovery report, not a round number.
- **Separate "move" from "delete" completely.** Archiving (move-to-archive) reduces primary-store
  cost and is low-risk; **disposition (delete) is a records/legal decision** and irreversible. Ship
  archiving first; only add deletion once records/compliance has approved a schedule (R5).
- **Right-size auto-expanding archive.** Enable auto-expanding archive **only** for users whose
  archive will exceed the base quota — it is **irreversible** and adds background processing. Prefer
  per-mailbox enablement over the org-wide switch during rollout.

## Change discipline

- **Always pilot on test mailboxes first.** Never make a production user the first ring. Archiving
  moves data and is hard to reverse; a bad age threshold on production is expensive to unwind.
- **Gate every write behind `-Commit`.** Run every script in `-WhatIf` first, read the plan, then
  commit. Keep the default read-only.
- **One change per ring, validated before the next.** Enable archives, assign the policy, run MFA,
  validate — then widen scope. Do not stack changes across rings.
- **Document the rollback before you change anything.** For each step know the reverse action and its
  limits (disconnected archives are kept 30 days; auto-expanding cannot be disabled; already-moved
  items do not come back).

## Operations and monitoring

- **Understand the Managed Folder Assistant cadence.** MFA is asynchronous and throttled; archiving
  is not instant. Use `Start-ManagedFolderAssistant` to force a pilot mailbox, but expect the
  org-wide work cycle to process at its own pace.
- **Report on adoption and reduction, not just configuration.** Track archive item growth and
  primary-store reduction over time (`Export-ArchiveReport.ps1`) — that is the value evidence and the
  early-warning signal if MFA stalls.
- **Watch for hold interactions.** Litigation hold, In-Place Hold, and Purview retention can keep
  content beyond the archive move; that is correct behavior. Never disable a hold to make archiving
  "look cleaner."
- **Re-baseline periodically.** Re-run Discovery quarterly; mailbox growth and usage patterns drift,
  and the age threshold may need tuning.

## Governance and defensibility

- **Keep records/compliance/legal in the loop.** The retention timeline and any disposition are their
  determinations; capture named sign-off and store it with the change evidence.
- **Least privilege, no standing Global Admin.** Use Recipient Management / Retention Management
  scoped roles; reserve Global Administrator for the specific org-wide actions that require it.
- **No secrets in automation.** The scripts use interactive modern-auth (`Connect-ExchangeOnline` /
  `Connect-IPPSSession` / `Connect-MgGraph`) — never embed credentials, tokens, or app secrets.
- **Treat plan/portal detail as verify-first.** Archiving entitlements, auto-expanding archive, and
  **Microsoft 365 Archive** tiering are licensing-/billing-gated and evolving — confirm availability
  and paths against current Microsoft documentation for your tenant before relying on them.
- **Retain the evidence trail.** Baseline + post-change statistics, policy definitions, MFA/validation
  output, and sign-off together make the archiving strategy auditable and defensible.


---


# Deliverables Summary

Everything included in this solution and how the pieces fit together.

## Documentation

| Deliverable | Purpose |
|-------------|---------|
| **Solution Overview** | What the archiving strategy delivers, how mailbox archive / retention / tiering work in Purview and Exchange Online, and the Assess → Design → Configure → Pilot → Validate → Expand model. |
| **Requirements Guide** | Solution-specific prerequisites (archiving licensing, least-privilege roles, MRM/MFA toolchain, in-scope mailboxes and tiering intent, records/legal sign-off, pilot scope) referencing the category Global Requirements. |
| **Implementation Guide** | Exact ordered steps to enable archive mailboxes, create the `MTA-2yr` move-to-archive tag and `RP-Corp-Archive` policy, assign to the pilot, run the Managed Folder Assistant, optionally stage the `DLM-Exchange-Keep` retention policy, validate, and expand — each step with pass/fail gates and rollback. |
| **Testing & Validation** | Six pass/fail gates proving the archiving strategy took effect, with the evidence to capture. |
| **Troubleshooting** | Common failure signatures (archive not provisioning, items not moving, MFA lag, policy not distributing) and resolutions. |
| **Best Practices** | Keeping the strategy healthy, cost-effective, and defensible; move-vs-delete separation; change discipline. |
| **Executive Summary** | One-page business framing for decision-makers. |

## PowerShell scripts (5)

All scripts use interactive modern-auth (`Connect-ExchangeOnline` / `Connect-IPPSSession` /
`Connect-MgGraph`), contain **no credentials or secrets**, and are **read-only or `-WhatIf` by
default** — writes require an explicit `-Commit` switch.

| Script | Role | Default safety |
|--------|------|----------------|
| `Get-ArchiveScopeHealth.ps1` | Scope/health helper — connectivity, module, role and pilot-group preflight | Read-only |
| `Invoke-ArchiveDiscovery.ps1` | Discovery — archive status, mailbox sizes, MRM tags/policies, DLM retention policies, org auto-expanding setting | Read-only |
| `Set-ArchiveStrategy.ps1` | Configuration/Remediation — enable archives, create/assign MRM tag & policy, run MFA | `-WhatIf` unless `-Commit` |
| `Test-ArchiveStrategy.ps1` | Validation — runs the pass/fail gates and reports PASS/FAIL | Read-only |
| `Export-ArchiveReport.ps1` | Reporting — adoption, archive growth, and primary-store reduction to CSV/HTML | Read-only |

## How to use them together

1. `Get-ArchiveScopeHealth.ps1` — confirm you can proceed (licensing, roles, modules, pilot group).
2. `Invoke-ArchiveDiscovery.ps1` — capture the **baseline**.
3. `Set-ArchiveStrategy.ps1 -WhatIf` → review → `-Commit` — configure the **pilot** scope.
4. `Test-ArchiveStrategy.ps1` — confirm the pilot passes every gate.
5. `Export-ArchiveReport.ps1` — evidence of adoption and reduction; repeat per expansion ring.

## Boundaries

- The **retention timeline and any disposition (delete)** are **records / compliance / legal
  determinations** — deferred to those functions; this solution provides the technical method and
  evidence only.
- Purview/Exchange **licensing, auto-expanding archive, and Microsoft 365 Archive tiering** are
  plan-/billing-gated and evolving — **verify your licensing/tenant**.
- Automation is **PowerShell** (Exchange Online + Security & Compliance PowerShell / Graph); no
  hardcoded credentials.
