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
