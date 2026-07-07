# 1. Solution Overview — SharePoint Online Records, Retention & Information Governance

## What this solution is
SharePoint Online holds a growing mass of content — contracts, financial records, policies, project
files, HR documents — that the organization is obligated to **retain** for a defined period and then
**dispose** of on schedule. When neither happens, the content becomes liability: over-retained data
inflates eDiscovery and breach exposure, under-retained data breaks a regulatory or legal obligation,
and content that is never reviewed for disposal accumulates indefinitely. This solution is a
repeatable, pilot-first method to apply **records and retention governance to SharePoint content**:
create retention labels and policies, apply them to sites and libraries, declare records (in-place),
run the disposition-review workflow, and dispose defensibly — so SharePoint content is retained,
declared, and disposed on schedule.

It is **scoped to SharePoint Online content** and **aligned to the broader Microsoft Purview
program**, not a replacement for it. Data Loss Prevention, sensitivity (information-protection)
labels, Exchange/Teams retention, insider-risk, and the tenant-wide Purview data-governance strategy
are the province of the organization's overall Purview product/program; this solution reuses that
program's foundations and focuses the records/retention mechanics on SharePoint sites and libraries.

## What this solution is NOT (the deferred boundary)
- **The records schedule itself is not authored here.** *Which* content is a record, *how long* each
  category is retained, the retention **trigger**, and the disposition **authority** are determined by
  the organization's **records-management, compliance, and legal** functions. This solution takes that
  schedule as input and implements it faithfully in SharePoint; it does not invent retention periods
  or legal determinations.
- **Legal holds and eDiscovery determinations** (what to preserve for a matter, when a hold attaches
  or releases) belong to legal/eDiscovery, not to this records/retention configuration.
- **DLP, sensitivity labels, and the broader Purview program** are referenced, not re-built here.

## Why this matters
- Retention that lives only in a policy binder is not enforced. A retention **label** and **policy**
  in Microsoft Purview, applied to SharePoint content, is enforcement the platform executes.
- A **record label** locks content in place (in-place records) so it cannot be edited or deleted
  before its schedule allows — the defensibility a regulator or auditor expects.
- **Disposition review** turns "delete on expiry" into a governed, evidenced decision: a named
  reviewer approves disposal (or extends/relabels), and Microsoft Purview keeps proof of what was
  disposed, by whom, and when.
- Doing this **pilot-first**, on a bounded site set with explicit gates and a rollback, avoids the
  high-impact failure mode of a tenant-wide retention or records misconfiguration that locks or
  deletes content wrongly.

## How it works
1. **Retention labels** are created in Microsoft Purview (Records management → File plan). A label
   carries a **retention action** (retain, delete, or retain-then-delete), a **duration**, a
   **retention trigger** (when the clock starts: item created, last modified, labeled, or an event),
   and optionally a **records** setting (mark as record or regulatory record) and a **disposition
   review** with named reviewers.
2. **Retention policies** apply a retention **outcome** to whole SharePoint locations (all sites, or
   specific sites) without a per-item label — the tenant-wide safety net. **Label policies** publish
   labels so users/owners can apply them, or **auto-apply policies** apply a label automatically to
   content that matches a condition (keyword, sensitive-info type, or trainable classifier).
3. **Application to SharePoint** happens three ways: a **default library label** (every item in a
   document library inherits the label), a **published label** applied by content owners, or an
   **auto-apply** policy. A default label is the workhorse for library-scoped records.
4. **Records declaration** happens when a **record** (or regulatory record) label is applied:
   SharePoint declares the item an **in-place record** — it stays in its library but is locked against
   edit/delete/move per the record's version and rules, with an auditable declare/undeclare trail.
5. **Disposition review** runs at the end of the retention period for any label configured with
   reviewers: the item enters the **Disposition** queue in Microsoft Purview, a reviewer approves
   permanent deletion, extends retention, applies a different label, or relabels — and the decision is
   evidenced.
6. **Defensible disposition** is the outcome: content is disposed only after its schedule expires and
   (where required) a review is approved, and Microsoft Purview retains a **disposition record** as
   proof.
7. The whole configuration is delivered through the house model — **Assess → Design → Configure →
   Pilot → Validate → Expand** — so the retention/records schedule is proven on a pilot site set
   before it is expanded tenant-wide.

## The reference design
- **Inputs (from records/legal):** the records/retention schedule — categories, retention periods,
  triggers, record vs non-record, disposition authority.
- **Labels:** one retention/record label per schedule category, named consistently, imported with
  **file-plan descriptors** (retention authority, category, sub-category) so the file plan is
  reportable.
- **Policies:** a tenant-wide **retention policy** as the baseline safety net for all SharePoint
  sites; **auto-apply** or **default-library-label** application for the record categories; a
  **published label policy** where owners apply labels manually.
- **Scopes:** **static** scopes (named sites) for the pilot; **adaptive** scopes (query-driven) as an
  option for expansion so the policy tracks sites automatically. *Adaptive scopes and some records
  features are plan-dependent — verify your licensing in your tenant.*
- **Records:** record or regulatory-record labels for the categories records/legal designate;
  in-place records so content is governed without moving it to a separate records center.
- **Disposition:** single- or multi-stage disposition review with named reviewer groups for the
  categories that require a human approval before disposal.

## What you can control
- Which SharePoint sites and libraries are in scope (start with the pilot site set).
- Which schedule categories become labels, and whether each is a plain retention label, a **record**,
  or a **regulatory record** (regulatory records cannot be unlocked — use only where records/legal
  require it).
- How labels are applied: default library label, published for manual apply, or auto-apply by
  condition.
- Whether a category ends in automatic disposal or **disposition review**, and who the reviewers are.
- The pilot scope, the pass/fail gates, and the rollback — before any tenant-wide expansion.

## Limitations (be honest with buyers)
- **Advanced records/retention features are plan-dependent.** Auto-apply policies, adaptive scopes,
  regulatory records, event-based retention, multi-stage disposition review, and the records-
  management file plan generally require the appropriate compliance licensing (commonly an E5/E5
  Compliance-class plan or add-on) — **verify what your tenant is licensed for in your tenant.**
- **Retention and deletion are eventually consistent, not instant.** Labels, policy application, and
  disposition run on service timers; expect propagation delays (often hours to a few days) — do not
  judge a pilot on the first minutes.
- **Regulatory records are one-way.** A regulatory-record label cannot be removed or changed and its
  retention cannot be shortened. Use it only where records/legal explicitly require it.
- **A record label locks content.** Owners lose edit/delete on declared items by design; communicate
  this before applying record labels to a live library.
- **Principle of retention precedence still applies.** When multiple retention outcomes touch the same
  content, Microsoft's retention-conflict rules (retention wins over deletion; longest wins; explicit
  over policy; shortest deletion wins) decide the result — design labels/policies with this in mind
  and validate the effective outcome, don't assume.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC/GCC High/DoD (e.g. `*.office365.us`) — **verify the portal path and feature in your cloud.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and the Purview/SharePoint admin surfaces. The standard set:

| Artifact | Name |
|---|---|
| Retention label (general category) | `Retention Label – General-3yr – Pilot` |
| Record label (record category) | `Record Label – Contracts – Pilot` |
| Regulatory record label (where required) | `Regulatory Record Label – Financial-7yr – Pilot` |
| Tenant-wide baseline retention policy | `Retention Policy – SPO-Baseline – Pilot` |
| Auto-apply label policy | `Label Policy – Contracts-AutoApply – Pilot` |
| Published label policy (manual apply) | `Label Policy – Owner-Publish – Pilot` |
| Pilot site scope (static) | `Scope – Records-Pilot – Static` |
| Adaptive scope (expansion) | `Scope – Records-Prod – Adaptive` |
| Disposition reviewer group (stage 1) | `Disposition Reviewers – Records – Stage1` |
| Assessment export | `Retention Posture – SPO – Discovery` |
| Compliance report | `Records Compliance – SPO – Report` |

When the pilot passes and you expand to production, mint the production equivalents by swapping the
`– Pilot` stage for `– Prod` (e.g. `Record Label – Contracts – Prod`) — never edit a validated pilot
artifact in place.

## The standard deployment model
> **Assess** current SharePoint retention/records posture and ingest the records schedule → **Design**
> the label/policy/scope map → **Configure** labels, policies, records, and disposition → **Pilot** on
> `Scope – Records-Pilot – Static` → **Validate** against explicit pass/fail gates → **Expand**
> tenant-wide with adaptive scopes.

Tenant-wide retention, records declaration, and disposition are **high-impact** — a wrong retention
period, an over-broad auto-apply, or a mistaken regulatory-record label is expensive or irreversible.
Every production change goes through change control with a documented rollback, and nothing expands
past the pilot until the gates in Section 5 pass.
