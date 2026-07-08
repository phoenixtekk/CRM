# 1. Solution Overview — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

## What this solution is
Every tenant accumulates **ROT** — data that is **Redundant, Obsolete, or Trivial**: the mailbox of an
employee who left three years ago, a SharePoint site nobody has opened since a finished project, a decade of
duplicate drafts and "final_v7" attachments, a Teams team for an event that already happened. Left alone, ROT
and **inactive/legacy data** quietly inflate **storage cost**, enlarge the **attack surface and data-breach
blast radius**, and complicate **eDiscovery and audits** — every stale file is one more thing an attacker can
exfiltrate and one more thing counsel has to search. **Microsoft Purview Data Lifecycle Management (DLM)** and
**Records Management** are the native way to fix this: **retention labels** and **retention/deletion policies**
that keep what must be kept and **defensibly delete** what may go, across **Exchange, SharePoint, OneDrive,
Teams, and Microsoft 365 Groups** — driven by **static or adaptive scopes**, with **disposition review** and a
full **audit trail** for anything sensitive.

This is the **inactive & legacy data cleanup and storage-optimization solution**: a repeatable, evidence-driven
way to **identify** ROT and stale/legacy data (inactive mailboxes, dormant sites, unused OneDrives, orphaned
Teams/Groups, existing retention posture and holds), **design** the retention/deletion controls that clean it
up, and **execute** the cleanup **defensibly** — using only the **Microsoft Purview portal**, **Security &
Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online PowerShell**, and **Microsoft Graph** (usage
reports). Its defining discipline is that **deletion is high-impact and irreversible, so nothing is auto-deleted
and everything is proven safe first** — auto-apply label policies run in **simulation**, deletion policies are
piloted on a **limited scope**, scripts run **read-only or `-WhatIf`**, and **every existing hold is checked and
respected** before a single item is removed.

> **Scope boundary — retention-schedule and legal determinations are deferred.** This solution delivers the
> **technical method and the evidence** for identifying and cleaning up ROT/inactive/legacy data. *How long*
> each data class must be kept, *which* records are subject to a legal or regulatory retention obligation,
> *what* is under **legal hold**, and *whether* a given deletion is defensible are **records-management,
> compliance, privacy, and legal determinations** — deferred to those functions. The solution finds the
> candidates, configures the control, proves nothing held would be deleted, and produces the disposition
> evidence; it does **not** decide the retention schedule or authorize the deletion.

## Why this matters
- **Deletion is irreversible and high-impact.** A retention policy set to "delete after N days" over the wrong
  scope can purge live business content permanently. This is the opposite of DLP (which blocks) — a cleanup
  mistake destroys data. That is why every control here is **piloted on a limited scope, run in `-WhatIf`, and
  hold-checked** before enforcement, and why **nothing is ever auto-deleted** by these tools.
- **Holds must win, and you must prove it.** Content under a **litigation hold**, an **eDiscovery case hold**,
  or a retain-action retention policy is **protected from deletion** by Purview's retention principles — a
  delete policy will *not* purge held items. But "the platform should protect it" is not evidence; this solution
  **enumerates the holds and validates** that no in-scope item under hold would be removed **before** you enforce.
- **ROT is invisible until you measure it.** Inactive mailboxes, dormant sites, and unused OneDrives don't
  announce themselves. Storage and activity **reporting** (mailbox/site last-activity, storage consumed,
  inactive-mailbox inventory) is what turns "we probably have a lot of junk" into a named, sized candidate list
  the records function can act on.
- **Retention keeps what deletion would otherwise remove.** The same lifecycle engine that deletes ROT also
  **retains** what must be kept — the two are one system governed by the **principles of retention** (retention
  wins over deletion; the longest retention wins; explicit beats implicit; a hold blocks purge). Designing
  cleanup without understanding retention precedence is how you either delete too much or delete nothing.
- **Adaptive scopes keep cleanup targeted as the estate changes.** A static list of stale sites is stale the
  day after you write it. **Adaptive scopes** (query-based membership over user/site/group attributes) let a
  policy automatically target, say, sites with no recent activity or mailboxes of departed users — without
  hand-maintaining membership.

## How it works
1. **Discovery / storage reporting** identifies *what* is stale and *how big* it is: existing **retention
   policies, retention labels, and label policies**; **holds** in force (litigation, eDiscovery case, retention);
   **inactive mailboxes** (`Get-Mailbox -InactiveMailboxOnly`); and mailbox/site/OneDrive **last-activity and
   storage** signals (Exchange mailbox statistics and **Microsoft Graph usage reports**). This is the ROT
   candidate inventory.
2. **Retention labels** define *what happens to a class of content* — **retain**, **retain then delete**, or
   **delete-only** — and can require **disposition review** (a human approval step) before permanent deletion.
   Labels are the precise, item-level instrument (they can carry **records** declaration where the records
   function requires immutability).
3. **Retention (and deletion) policies** apply a retain/delete action **in bulk** across a **location** (Exchange
   mailboxes, SharePoint sites, OneDrive accounts, Teams chats/channels, M365 Groups) using a **static scope**
   (named locations) or an **adaptive scope** (attribute query).
4. **Auto-apply label policies** stamp a retention label onto content that matches a condition (sensitive info
   type, keyword/query, or trainable classifier) — and **support a simulation mode** so you can see *what would
   be labeled* before anything is applied.
5. **Piloting** proves the control on a **limited scope** first — a handful of pilot sites/mailboxes, auto-apply
   in **simulation**, deletion actions previewed with the delivered `-WhatIf` tooling — with a **hold-safety
   check** that no in-scope item is under hold.
6. **Disposition review** routes items reaching end-of-life to **reviewers** who approve, extend, or relabel —
   producing the **disposition evidence** (who approved deleting what, and when) that makes cleanup defensible.
7. **Reporting** produces the **storage-savings / candidate-ROT / disposition** report for the records and
   storage owners to review and sign off.

## The in-scope workloads (and what cleanup means for each)
- **Exchange Online mailboxes:** stale user and shared mailboxes; **inactive mailboxes** (retained after the
  user was deleted); oversized archives. Retention/delete policies and labels apply here.
- **SharePoint Online sites:** dormant sites (no content change / no views for a long period), orphaned
  project/team sites, oversized document libraries.
- **OneDrive for Business:** unused OneDrives (often belonging to departed users), duplicate/obsolete personal
  files.
- **Microsoft Teams (chats & channel messages) and Microsoft 365 Groups:** finished-project teams, expired
  event teams, and the group-connected SharePoint/mailbox behind them.
- **Data estate / storage reporting:** the cross-workload storage and activity picture that sizes the ROT and
  measures savings. *Deeper data-estate scanning (e.g. Data Map / non-M365 sources) is licensing-dependent —
  verify your tenant.*

## The identify→clean-up-defensibly journey (the core discipline)
> **Report** stale/inactive/legacy data and existing retention + holds → **design** the labels/policies and the
> scope (static or adaptive) with the records function → **configure** labels and policies, auto-apply in
> **SIMULATION** → **validate** that scope is correct and **no held item would be deleted** → **pilot** on a
> **limited scope** with **`-WhatIf`** deletion previews and **disposition review** → **expand** to the intended
> scope under change control → **operate** (recurring reporting, disposition review, adaptive-scope refresh).

## What you can control
- Which **retention labels** exist and their action — **retain**, **retain-then-delete**, or **delete-only** —
  and whether a label requires **disposition review** before deletion. *(Retention periods and which content
  they apply to are records determinations.)*
- Which **retention/deletion policies** cover which **locations**, and whether membership is a **static scope**
  or an **adaptive scope** query.
- Which content is **auto-labeled**, and whether the auto-apply policy runs in **simulation** or is turned on.
- The **pilot scope** (limited sites/mailboxes) enforced first and the dwell/observation time before expansion.
- Who sits on the **disposition review board** and what the review workflow is.

## Limitations (be honest with buyers)
- **Deletion is destructive.** Once a retention/delete action permanently removes content past its retention,
  it is gone. This solution's discipline (limited-scope pilot, `-WhatIf`, hold checks, disposition review) exists
  because the failure mode is data loss, not a help-desk ticket.
- **Feature availability is licensing-/plan-dependent.** Basic retention policies and labels are broadly
  available; **auto-apply based on classifiers/query, adaptive scopes, records management, and disposition
  review** typically require **Microsoft 365 E5** or the **E5 Compliance** add-on (some capabilities are in
  **preview**). Availability and portal paths **evolve** — this solution flags "verify your licensing/tenant"
  rather than asserting a feature is present.
- **Retention actions have latency.** Applying labels, timer-driven deletion, and disposition processing are
  **not instant** — policies can take time to reach all locations and the deletion timer runs on Microsoft's
  cadence. "Nothing happened yet" is usually latency, not failure.
- **The retention schedule and the deletion authorization are not ours to set.** *How long* to keep each class,
  *what* is under legal hold, and *whether* a deletion is defensible are **records/compliance/legal**
  determinations. This solution provides the method and the evidence; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `DLC – <Purpose> – <Scope/Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Retention label — retain then delete | `DLC – Retain-Delete – GeneralContent` |
| Retention label — delete-only (stale cleanup) | `DLC – Delete-Stale – LegacyContent` |
| Retention label — mandatory disposition review before delete | `DLC – Disposition Review – LegacyRecords` |
| Label publishing policy (pilot ring) | `DLC – Publish Cleanup Labels – Pilot` |
| Auto-apply retention-label policy (simulation) | `DLC – Auto-Apply Cleanup – Simulation` |
| Retention/deletion policy — pilot scope | `DLC – Delete Inactive Content – Pilot` |
| Adaptive scope — stale SharePoint sites | `DLC – Stale Sites – Adaptive Scope` |
| Adaptive scope — inactive mailboxes / departed users | `DLC – Inactive Mailboxes – Adaptive Scope` |
| Pilot scope (limited sites/users) | `DLC Cleanup Pilot – Stage1` |
| Disposition review board | `DLC Disposition Review – Board` |

## The standard deployment model
> **Assess** current storage/ROT posture, existing retention, and holds → **Design** labels, policies, and
> scope (static/adaptive) with the records function → **Configure** labels and policies, auto-apply **in
> simulation** → **Pilot** on a **limited scope** with **`-WhatIf`** deletion previews and disposition review →
> **Validate** against pass/fail gates (correct scope, **no held item deletable**, savings measured, disposition
> evidence produced) → **Expand** to the intended scope and ongoing operations. Every high-impact change is
> piloted first, hold-checked, and reversible up to the point of permanent deletion — with a documented rollback.
