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
