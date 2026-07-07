# 1. Solution Overview — Microsoft 365 Purview eDiscovery Administration

## What Microsoft Purview eDiscovery is
Microsoft Purview eDiscovery is Microsoft 365's built-in capability for **finding, preserving,
reviewing, and exporting** content in response to legal, regulatory, and internal-investigation
requests. It reaches across the workloads where enterprise content lives — **Exchange Online**
mailboxes, **SharePoint Online** and **OneDrive for Business** sites, and **Microsoft Teams** chats,
channel messages, and files (Teams messages are stored in the participants' mailboxes; Teams files
live in SharePoint/OneDrive). It exists in tiers of increasing capability:

1. **Content Search** — an ad-hoc search-and-export tool. You define a keyword/condition query,
   pick locations, estimate the hits, preview, and export. No case container, no custodian tracking,
   no analytics. Good for quick, one-off collection; **not** a defensible matter workflow on its own.
2. **eDiscovery (Standard)** — adds a **case** container that groups searches and, critically, adds
   **holds** (a case hold preserves in-place content so it cannot be permanently deleted while the
   matter is open). Standard is Content Search + cases + holds + export.
3. **eDiscovery (Premium)** — adds a defensible end-to-end workflow: **custodians** (people/data
   sources formally associated with the matter, each with a custodian hold and communications),
   **review sets** (collected content copied into a static, reviewable set), **analytics** (near-
   duplicate detection, email threading, themes) and **de-duplication**, tagging/redaction, and
   structured **export** with a load file. Premium is the tier legal teams rely on for large,
   defensible matters.

> **This solution is scoped to the eDiscovery *workflow* — search, hold, review, export.** It is
> deliberately **distinct** from the other Purview capabilities: **DLP** (data loss prevention),
> **sensitivity labels** (classification/encryption), and **retention/records** (keep-and-delete
> schedules). Those protect and govern data proactively; eDiscovery *finds and produces* it
> reactively for a matter. A separate Purview solution covers DLP/labels/retention.

## How it works (the eDiscovery model)
1. **A request arrives** (litigation, regulator, HR/investigation). Legal defines the scope —
   custodians, date range, subject matter, keywords. **The legal/records function owns the
   determination of what is in scope and what must be held**; you provide the technical method and
   the evidence that it was done correctly and completely.
2. **You design the query** — keywords and conditions expressed as **KQL** (Keyword Query Language)
   plus condition filters (date range, sender/recipient, file type, sensitive-info type). A tightly
   scoped query is defensible; an over-broad one is expensive and noisy.
3. **You create a case** and run **Content Searches** inside it against the chosen locations,
   review the **statistics** (item count, size, locations with hits), and refine the query until the
   scope is right.
4. **You place holds** — a case hold (Standard) or custodian hold (Premium) preserves the in-scope
   content so routine deletion or retention expiry cannot destroy it while the matter is open.
5. **(Premium) You collect into a review set**, run **analytics** (email threading, near-duplicate
   and de-duplication, themes) to cut review volume, tag/redact, and then **export** the reviewed
   content with a load file for outside counsel or the requesting authority.
6. **Every action is auditable** — case activity, search runs, hold changes, and exports are logged
   in the Purview audit log, which is the evidence that the collection was complete and defensible.

## The reference design
- **One case per matter**, named `eDiscovery Case – <Matter> – <Stage>` (e.g.
  `eDiscovery Case – Matter-A – Pilot`). All searches, holds, custodians, review sets, and exports
  for that matter live inside it and reuse the matter name.
- **Named, versioned searches** — `Content Search – <Matter>-<Purpose> – <Stage>`
  (e.g. `Content Search – Matter-A-Keywords – Pilot`). You iterate the query; the name stays stable.
- **Holds named to the matter** — `Hold Policy – <Matter> – <Stage>` and
  `Hold Rule – <Matter> – <Stage>`; custodians named `Custodian – <upn> – <Matter>`.
- **Review set and export named to the matter** — `Review Set – <Matter> – <Stage>` and
  `Export – <Matter> – <Stage>`.
- **Least-privilege roles** — operators are members of the **eDiscovery Manager** role group (they
  see only their own cases); a small number of **eDiscovery Administrator** members can see all
  cases and manage holds. Global Administrator is *not* used to run matters.
- **Compliance boundaries (optional)** — where the organization must restrict which custodians a
  given eDiscovery team can search (for example, by region or business unit), a **compliance
  security filter** scopes searches. The *policy* of who may search whom is a legal/HR decision.

## Benefits
- **Defensible and repeatable** — a case, a named search, a hold, an audit trail: the same
  documented pattern every matter, so collection is complete and provable rather than ad-hoc.
- **Complete across M365** — one workflow reaches Exchange, SharePoint, OneDrive, and Teams,
  including Teams messages that many ad-hoc tools miss.
- **Less review, lower cost** — Premium analytics (threading, near-dup, de-dup) cut the volume that
  reaches expensive human/outside-counsel review.
- **Least-privilege and scoped** — role groups and optional compliance boundaries mean eDiscovery
  power is granted narrowly, not via Global Admin.

## Limitations (be honest with buyers)
- **Tier gating.** Content Search and eDiscovery (Standard) are broadly available; **custodians,
  review sets, analytics/de-duplication, and structured export are eDiscovery (Premium)** and
  require the higher licensing (Microsoft 365 E5 / E5 eDiscovery and Audit add-on). The Requirements
  Guide names the licensing — **verify in your tenant**.
- **The eDiscovery experience was modernized.** Microsoft unified the classic *Standard* and
  *Premium* experiences into a **new eDiscovery** UI in the Purview portal (`purview.microsoft.com`);
  menu paths and some feature names differ from older screenshots. Where a path is version-dependent
  this guide flags **"verify in your tenant."**
- **Legal determinations are not ours to make.** What is in scope, who is a custodian, what must be
  held, and what is produced are **legal/records decisions** — this solution supplies the technical
  method and evidence, never the determination.
- **Holds and preservation have edge cases.** A hold preserves content but does not stop a user from
  editing/deleting their working copy (the preserved copy is retained in the recoverable/preservation
  location). Very large collections, unindexed/partially-indexed items, and encrypted content need
  explicit handling — covered in Troubleshooting.
- **Government clouds differ.** GCC High / DoD use different portal hosts (for example
  `*.office365.us`) and some features lag Commercial — **verify in your tenant**.

## The standard deployment model
> **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
> gates and a documented rollback. For eDiscovery this reads: **assess licensing/roles/in-scope
> workloads → design the case, query, and hold naming → configure roles and (optionally) compliance
> boundaries → run a *pilot matter* end-to-end (case → search → hold → review → export) → validate
> the gates (search scoped, hold effective, export complete and defensible) → expand the pattern to
> live matters.** Placing a broad hold or exporting is **high-impact** and is always piloted on a
> narrow, non-sensitive test matter first, with the case-hold rollback documented before you begin.
