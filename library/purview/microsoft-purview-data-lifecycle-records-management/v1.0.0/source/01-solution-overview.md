# 1. Solution Overview — Microsoft Purview Data Lifecycle & Records Management

## What this solution is
Across Microsoft 365 — Exchange mailboxes, SharePoint sites, OneDrive accounts, and Teams chats and
channels — the organization accumulates content it is obligated to **retain** for a defined period and
then **dispose** of on schedule. When neither is enforced, that content becomes liability:
over-retained data inflates eDiscovery and breach exposure, under-retained data breaks a regulatory or
legal obligation, and content that is never reviewed for disposal accumulates forever. This solution is
a repeatable, pilot-first method to implement **data lifecycle and records management org-wide in
Microsoft Purview**: retention **policies** and retention **labels** across Exchange/SharePoint/
OneDrive/Teams, **records management** (records declaration, the file plan, regulatory records, and
event-based retention), **disposition review**, and **defensible disposal** — all mapped to the
organization's retention schedule — so data is kept and disposed on policy across the whole tenant.

It is deliberately **org-wide (tenant scope)**. Microsoft Purview treats data lifecycle management
(retention policies and labels) and records management (records + file plan + disposition) as
tenant-level solutions that apply across all four workloads at once. This product implements that
org-wide layer. The **SharePoint-scoped records/retention product** covers SharePoint-specific
mechanics — default library labels, in-place records inside document libraries, PnP-driven
site/library application, adaptive site scopes — in depth; where this solution needs SPO detail it
**references** that product rather than duplicating it.

## Retention policies vs retention labels — the core distinction
The single most important design decision in Microsoft Purview data lifecycle management is **policy
vs label**, and this solution treats it as first-class:

- A **retention policy** applies a single retention **outcome** (retain, delete, or retain-then-delete
  for one duration) to **whole locations** — all Exchange mailboxes, all SharePoint sites, all OneDrive
  accounts, all Microsoft 365 Groups, Teams chats/channels — **without touching individual items**.
  There is no user action, nothing is visible on the item, and it is the tenant-wide **safety net**:
  "everything in SharePoint is kept for at least N years." One policy can span multiple workloads.
- A **retention label** is applied to **individual items or documents** (a message, a file, a library's
  default) and can carry richer behavior a policy cannot: **records declaration** (mark as record /
  regulatory record), **event-based retention** (start the clock on an event, not a date),
  **disposition review**, and **file-plan descriptors**. Labels are published for users to apply,
  auto-applied by condition, or set as a library/folder default.

Policies are the broad floor; labels are the precise, records-grade instrument. The reference design
uses **both**: tenant-wide retention policies as the baseline, and retention labels for the categories
that require records, events, or a reviewed disposition. *(Retention precedence resolves conflicts when
both touch the same item — see "Retention precedence" below.)*

## What this solution is NOT (the deferred boundary)
- **The retention schedule itself is not authored here.** *Which* content is a record, *how long* each
  category is retained, the retention **trigger/event**, and the **disposition authority** are
  determined by the organization's **records-management, compliance, privacy, and legal** functions.
  This solution takes that schedule as input and implements it faithfully across M365; it does not
  invent retention periods, record status, or legal determinations.
- **Legal holds and eDiscovery determinations** (what to preserve for a matter, when a hold attaches or
  releases) belong to legal/eDiscovery, not to this lifecycle/records configuration.
- **Sensitivity (information-protection) labels, DLP, and the broader Purview data-governance program**
  are referenced and aligned to, not rebuilt here.
- **SharePoint-specific records mechanics** are the province of the SharePoint records/retention
  product — referenced, not re-documented.

## Why this matters
- Retention that lives only in a policy binder is not enforced. A retention **policy** or **label** in
  Microsoft Purview is enforcement the platform executes across Exchange, SharePoint, OneDrive, and
  Teams — consistently, on a timer, without relying on users.
- A **record** (or regulatory record) label locks content against premature edit or deletion — the
  defensibility a regulator or auditor expects — and the **file plan** makes the whole records inventory
  reportable (retention authority, category, department, citation).
- **Event-based retention** solves the hard cases the calendar cannot: keep an employee record for *N
  years after termination*, a contract for *N years after expiry*, a product record for *N years after
  end-of-life* — the clock starts on the **event**, triggered when it happens.
- **Disposition review** turns "delete on expiry" into a governed, evidenced decision: a named reviewer
  approves disposal (or extends/relabels), and Microsoft Purview keeps proof of what was disposed, by
  whom, and when.
- Doing this **pilot-first**, with policies staged and labels published to a bounded scope before
  tenant-wide enforcement, avoids the high-impact failure mode of an org-wide retention or records
  misconfiguration that locks or deletes content wrongly.

## How it works (org-wide)
1. **Retention labels** are created in Microsoft Purview → **Records management → File plan** (or **Data
   lifecycle management → Labels**). A label carries a **retention action** (retain / delete /
   retain-then-delete), a **duration**, a **retention trigger** (item created, last modified, labeled,
   or an **event**), and optionally a **records** setting (mark as record, or regulatory record),
   **file-plan descriptors**, and a **disposition review** with named reviewers.
2. **Retention policies** are created in **Data lifecycle management → Policies**. Each policy applies a
   retention outcome to selected **locations** — Exchange, SharePoint, OneDrive, Microsoft 365 Groups,
   Teams channel messages, Teams chats — as the tenant-wide safety net, with no per-item action.
3. **Label policies** publish labels (users apply them) or **auto-apply** them by condition (keyword,
   sensitive-info type, or trainable classifier) across the same locations.
4. **Records declaration** happens when a **record** or **regulatory-record** label is applied: the item
   becomes an in-place record — it stays where it is but is locked against edit/delete/move per its
   version and rules, with an auditable declare/undeclare trail. Regulatory records are one-way and
   cannot be unlocked or shortened.
5. **The file plan** organizes the label inventory with descriptors — **retention authority**,
   **category / sub-category**, **department**, **citation**, **reference ID** — so the records program
   is reportable and defensible, and labels can be imported/exported in bulk.
6. **Event-based retention** uses **event types**: a label's clock is set to start on an event (e.g.
   `Employee termination`, `Contract expiration`); when the event occurs, a **retention event** is
   raised (with the asset ID / keyword that matches the affected content) and the retention period
   begins for all matching items.
7. **Disposition review** runs at the end of the retention period for any label configured with
   reviewers: the item enters the **Disposition** queue in Microsoft Purview, a reviewer approves
   permanent deletion, extends retention, relabels, or applies a different label — and the decision is
   evidenced.
8. **Defensible disposition** is the outcome: content is disposed only after its schedule expires and
   (where required) a review is approved, and Microsoft Purview retains a **disposition record** as
   proof.
9. The whole configuration is delivered through the house model — **Assess → Design → Configure → Pilot
   → Validate → Expand** — so the schedule is proven on a bounded pilot scope before it is enforced
   tenant-wide.

## The reference design
- **Inputs (from records/legal):** the retention schedule — categories, retention periods, triggers
  (date vs event), record vs non-record vs regulatory, disposition authority (auto vs review, and who
  reviews), and the applicable regulatory citations.
- **Policies (the floor):** one or more tenant-wide **retention policies** per workload (or a single
  multi-workload policy) as the baseline safety net — e.g. `Retention Policy – Tenant-Baseline –
  Pilot`, staged with locations selected and left **disabled** until validated.
- **Labels (records-grade):** one retention/record label per schedule category, named consistently and
  imported with **file-plan descriptors** so the file plan is reportable — plain retention, **record**,
  or **regulatory record** as records/legal designate.
- **Application:** **published** label policies where users apply labels; **auto-apply** policies for
  categories detectable by condition; default library labels for SharePoint (deferred to the SPO
  records product for that mechanic).
- **Events:** **event types** for the event-based categories (termination, expiry, end-of-life) with a
  defined trigger source and the operational process to raise the event.
- **Disposition:** single- or multi-stage disposition review with named reviewer groups for the
  categories that require a human approval before disposal.
- **Scopes:** **static** scopes for the pilot; **adaptive** (query-driven) scopes as an option for
  expansion so a policy tracks locations automatically. *Adaptive scopes and several records features
  are plan-dependent — verify your licensing in your tenant.*

## Retention precedence (design with it, validate it)
When multiple retention outcomes touch the same item, Microsoft's **principle of retention** decides
the result, in order: **(1) Retention wins over deletion** — if anything says retain, the item is kept;
**(2) the longest retention period wins**; **(3) explicit (label) wins over implicit (policy)**; **(4)
the shortest deletion period wins**. Design labels and policies with this in mind, and **validate the
effective outcome** on pilot content — never assume the result of overlapping policies and labels.

## What you can control
- Which workloads and locations are in scope (Exchange / SharePoint / OneDrive / Groups / Teams), and
  whether coverage is by tenant-wide policy, published/auto-applied label, or both.
- Which schedule categories become labels, and whether each is a plain retention label, a **record**, or
  a **regulatory record** (regulatory records cannot be unlocked — use only where records/legal require).
- How labels are applied (published, auto-applied, or default) and whether retention is **date-based** or
  **event-based**.
- Whether a category ends in automatic disposal or **disposition review**, and who the reviewers are.
- The pilot scope, the pass/fail gates, and the rollback — before any tenant-wide expansion.

## Limitations (be honest with buyers)
- **Advanced lifecycle/records features are plan-dependent.** Auto-apply policies, adaptive scopes,
  records management (record/regulatory-record labels, the file plan), event-based retention, and
  multi-stage disposition review generally require the appropriate compliance licensing (commonly an
  **E5 / E5 Compliance-class** plan or add-on) — **verify what your tenant is licensed for.**
- **Retention and deletion are eventually consistent, not instant.** Policy application, label
  propagation, event processing, and disposition run on service timers; expect propagation delays (often
  hours to a few days, and up to 7 days for some policy application) — do not judge a pilot on the first
  minutes.
- **Regulatory records are one-way.** A regulatory-record label cannot be removed or changed and its
  retention cannot be shortened. Use it only where records/legal explicitly require it.
- **A record label locks content.** Owners/users lose edit/delete on declared items by design;
  communicate this before applying record labels to live content.
- **Retention precedence governs overlaps.** Multiple policies/labels on the same content resolve by the
  principle above — validate the effective outcome, don't assume it.
- **Disposition review is a portal workflow.** Reviewers act in the Purview **Disposition** area; the
  provided reporting surfaces label/policy coverage and configuration, and points reviewers to the
  portal queue rather than approving disposals from a script.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC / GCC High / DoD (e.g. `*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify the
  portal path and feature in your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and the Purview admin surfaces. The standard set:

| Artifact | Name |
|---|---|
| Tenant-wide baseline retention policy | `Retention Policy – Tenant-Baseline – Pilot` |
| Workload retention policy (e.g. Exchange) | `Retention Policy – Exchange-3yr – Pilot` |
| Retention label (general category) | `Retention Label – General-3yr – Pilot` |
| Record label (record category) | `Record Label – Contracts-7yr – Pilot` |
| Regulatory record label (where required) | `Regulatory Record Label – Financial-7yr – Pilot` |
| Auto-apply label policy | `Label Policy – Contracts-AutoApply – Pilot` |
| Published label policy (manual apply) | `Label Policy – User-Publish – Pilot` |
| Event type (event-based retention) | `Event Type – Employee-Termination` |
| File-plan retention authority | `Authority – Records-Schedule-2026` |
| Pilot scope (static) | `Scope – Lifecycle-Pilot – Static` |
| Adaptive scope (expansion) | `Scope – Lifecycle-Prod – Adaptive` |
| Disposition reviewer group (stage 1) | `Disposition Reviewers – Records – Stage1` |
| Assessment export | `Retention Posture – Tenant – Discovery` |
| Compliance report | `Lifecycle Compliance – Tenant – Report` |

When the pilot passes and you expand to production, mint the production equivalents by swapping the
`– Pilot` stage for `– Prod` (e.g. `Record Label – Contracts-7yr – Prod`) — never edit a validated
pilot artifact in place.

## The standard deployment model
> **Assess** current tenant retention/records posture and ingest the retention schedule → **Design** the
> policy/label/scope/event map → **Configure** policies, labels, records, the file plan, events, and
> disposition → **Pilot** on `Scope – Lifecycle-Pilot – Static` (policies disabled / labels published to
> the pilot) → **Validate** against explicit pass/fail gates → **Expand** tenant-wide with adaptive
> scopes and enabled policies.

Tenant-wide retention, records declaration, and disposition are **high-impact** — a wrong retention
period, an over-broad auto-apply, or a mistaken regulatory-record label is expensive or irreversible.
Every production change goes through change control with a documented rollback, and nothing expands past
the pilot until the gates in Section 5 pass.
