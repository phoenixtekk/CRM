# 1. Solution Overview — Regulatory & Immutable Records + File Plan (Microsoft Purview)

## What this solution is
Some content an organization holds is not merely *retained* — it must be made **immutable**: locked
against edit, deletion, and early disposal for its full obligation, and **mapped** to the authority
that requires it. This solution is a repeatable, pilot-first method to deliver exactly that layer in
**Microsoft Purview Records Management**: **record labels** that lock content in place (immutable
records), **regulatory-record labels** for the one-way, cannot-be-shortened cases regulators demand,
and a **mapped file plan** — every record label tagged with its **retention authority, category,
department, citation, and reference ID** so the records inventory is reportable and defensible. It is
configured, **piloted on a bounded scope**, validated against explicit pass/fail gates, and made
operable — so the immutability capability is in place and defensible, not just described in a binder.

The scope is deliberately **the locking + mapping layer**, not the whole retention program. Microsoft
Purview separates *data lifecycle management* (retention policies and labels as the tenant-wide floor)
from *records management* (records declaration, regulatory records, the file plan, disposition). This
product implements the **records-immutability and file-plan** portion in depth. Where tenant-wide
retention policies, event-based retention as a program, or a full disposition-review operation are
needed, the broader **data lifecycle & records management** product covers them — this solution
**references** that layer rather than rebuilding it, and keeps label names consistent with it.

## The core distinction — retention vs a record vs a regulatory record
The single most important design decision here is *how strong* the lock must be, and this solution
treats it as first-class:

- A **retention label** keeps (and/or deletes) an item for a duration, but the item stays **editable**
  until disposal. It is retention, not immutability.
- A **record label** (`-IsRecordLabel $true`) **declares the item a record**: it becomes an in-place
  record — it stays where it lives but is **locked against edit, deletion, and move** per its version
  and rules, with an auditable declare/undeclare trail. A records manager can **un-declare** a
  non-regulatory record (evidenced) if the schedule allows.
- A **regulatory-record label** (`-Regulatory $true`) is the strongest lock: it is **one-way**. Once
  applied it **cannot be removed, changed, un-declared, or shortened** — not by an admin, not by a
  records manager. Use it **only** where records/legal explicitly require an irreversible lock.

Immutability is a spectrum from "retained but editable" to "locked but reversible" to "locked forever."
This solution configures the **record** and **regulatory-record** rungs and maps them to the file plan;
which rung each category needs is a **records/legal determination** it takes as input.

## The mapped file plan
A locked record is only defensible if you can say **why** it is locked and **under what authority**.
The **file plan** in Microsoft Purview attaches descriptors to each retention/record label:

- **Retention authority** — the schedule or mandate that requires the record (e.g. a records schedule).
- **Category / sub-category** — the records taxonomy the item belongs to.
- **Department** — the owning business function.
- **Citation** — the specific regulatory/legal reference (with an optional URL).
- **Reference ID** — the stable identifier the records program uses.

With these populated, the file plan is a reportable inventory: every immutable record maps to an
authority and a citation, labels can be **exported/imported in bulk**, and an auditor's "show me your
records inventory and what requires each" is a report, not a fire drill.

## What this solution is NOT (the deferred boundary)
- **The records determination is not made here.** *Which* content is a record, *which* rung it needs
  (record vs regulatory record), *how long* it is locked, the **retention authority/citation**, and the
  **disposition authority** are determined by the organization's **records-management, compliance,
  privacy, and legal** functions. This solution **implements** those determinations faithfully; it does
  not author retention periods, decide record status, or make regulatory-applicability calls.
- **Tenant-wide retention policies, event-based-retention programs, and full disposition-review
  operations** belong to the broader **data lifecycle & records management** product — referenced and
  aligned to, not rebuilt here.
- **Legal holds and eDiscovery determinations** (what to preserve for a matter) belong to legal/
  eDiscovery, not to this records configuration.
- **Sensitivity (information-protection) labels and DLP** are the province of the broader Purview
  program — aligned to, not re-implemented.
- **SharePoint library-level records mechanics** (default library labels, in-place records inside
  libraries, PnP-driven application) are the SharePoint records/retention product's province —
  referenced, with label names kept consistent.

## Why this matters
- **A retention schedule that isn't enforced is not a control.** A **record** label in Microsoft
  Purview is enforcement the platform executes — the item is genuinely locked against edit and early
  deletion, consistently, without relying on users to behave.
- **Immutability is the defensibility a regulator expects.** For records under a mandate, "we intended
  to keep it" is not enough; a **regulatory-record** label is an irreversible lock the platform can
  attest to.
- **A mapped file plan turns records into evidence.** Authority, category, department, citation, and
  reference ID make the whole records inventory reportable and traceable to the mandate that requires
  it — the difference between "we have records somewhere" and "here is our records inventory and what
  each is locked under."
- **Doing this pilot-first avoids the expensive failure mode.** A wrong record declaration locks live
  content owners out; a mistaken **regulatory** label is **irreversible**. Proving the design on a
  bounded pilot with disposable test items — before any production content is touched — is the whole
  point.

## How it works
1. **File-plan descriptors** are created first in Microsoft Purview → **Records management → File plan**
   (or via `New-FilePlanProperty*` in Security & Compliance PowerShell): the **authority**, **category /
   sub-category**, **citation**, **department**, and **reference ID** values the labels will carry.
2. **Record labels** are created (`New-ComplianceTag -IsRecordLabel $true`) with a retention action and
   duration and the **file-plan descriptors attached** — these lock content in place when applied.
3. **Regulatory-record labels** (`New-ComplianceTag -Regulatory $true`) are created **only** for the
   categories records/legal designate as one-way, gated behind an explicit sign-off — an irreversible
   lock.
4. **Labels are applied** by publishing them (users apply the record label to declare a record),
   auto-applying by condition, or setting a library default (SharePoint mechanic deferred). Applying a
   record label **declares the record** and locks the item.
5. **The file plan** is now a reportable inventory: each label maps to authority/category/department/
   citation/reference ID, and labels can be exported/imported in bulk.
6. **Disposition at end of life** (for records that end in a reviewed disposal) routes to the Purview
   **Disposition** queue where a named reviewer acts — this solution wires the reviewer role and
   reporting and defers the disposition *operation* to the broader records product.
7. The whole configuration runs through the house model — **Assess → Design → Configure → Pilot →
   Validate → Expand** — so immutability is proven on a bounded scope before any production record is
   declared.

## The reference design
- **Inputs (from records/legal):** for each in-scope category — record status (record vs **regulatory
  record**), lock duration and trigger, retention **authority**, **citation**, **department**,
  **reference ID**, and whether disposal is automatic or reviewed.
- **File plan (built first):** the descriptor set — `Authority – Records-Schedule-2026`, categories,
  citations, departments, reference IDs — so every label is mapped from creation.
- **Record labels (immutable, reversible):** one record label per schedule category that needs an
  in-place lock, named consistently, with file-plan descriptors attached — e.g. `Record Label –
  Contracts-7yr – Pilot`.
- **Regulatory-record labels (one-way):** only where records/legal require an irreversible lock —
  e.g. `Regulatory Record Label – Financial-7yr – Pilot` — gated behind explicit sign-off.
- **Application:** **published** label policies where users declare records manually; **auto-apply**
  policies for categories detectable by condition; SharePoint default-library labels deferred to the
  SharePoint records product.
- **Scope:** a **static** pilot scope for validation; expansion to production (adaptive scopes optional)
  only after the gates pass. *Records management, the file plan, regulatory records, and auto-apply are
  plan-dependent — verify your licensing in your tenant.*

## Naming convention (used in every doc and script)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the docs, scripts,
and Purview admin surfaces:

| Artifact | Name |
|---|---|
| Record label (immutable, reversible) | `Record Label – Contracts-7yr – Pilot` |
| Regulatory-record label (one-way) | `Regulatory Record Label – Financial-7yr – Pilot` |
| Published label policy (manual declare) | `Label Policy – Records-Publish – Pilot` |
| Auto-apply label policy | `Label Policy – Records-AutoApply – Pilot` |
| File-plan retention authority | `Authority – Records-Schedule-2026` |
| File-plan category | `Category – Contracts` |
| File-plan citation | `Citation – SOX` |
| File-plan department | `Department – Finance` |
| File-plan reference ID | `ReferenceId – REC-CON-001` |
| Pilot scope (static) | `Scope – Records-Pilot – Static` |
| Disposition reviewer group | `Disposition Reviewers – Records – Stage1` |
| Assessment export | `Records Posture – Tenant – Discovery` |
| Compliance report | `Records & File Plan – Tenant – Report` |

When the pilot passes and you expand, mint the production equivalents by swapping the `– Pilot` stage
for `– Prod` (e.g. `Record Label – Contracts-7yr – Prod`) — never edit a validated pilot artifact in
place, and never re-declare a regulatory record.

## Limitations (be honest with buyers)
- **Records management and the file plan are plan-dependent.** Record/regulatory-record labels, the
  file plan, auto-apply, and adaptive scopes generally require an **E5 / E5 Compliance-class** plan or
  add-on — **verify what your tenant is licensed for.**
- **Regulatory records are one-way and irreversible.** A regulatory-record label cannot be removed,
  changed, un-declared, or shortened. Use it only where records/legal explicitly require it, and never
  apply it to content you are not prepared to keep for its full period.
- **A record label locks content by design.** Owners/users lose edit/delete on declared items;
  communicate this before applying record labels to live content.
- **Declaration and propagation are eventually consistent, not instant.** Label publish/auto-apply and
  declaration run on service timers (hours to several days; auto-apply of existing content can take 7+
  days) — do not judge a pilot on the first minutes.
- **Disposition is a portal workflow.** Reviewers act in the Purview **Records management → Disposition**
  area; this solution wires the role and reports coverage, and points reviewers to the queue rather than
  approving disposals from a script.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC / GCC High / DoD (e.g. `*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify the
  portal path and feature in your cloud.**

## The standard deployment model
> **Assess** current records/file-plan posture and ingest the records determination → **Design** the
> record/regulatory-label + file-plan map → **Configure** file-plan descriptors, record labels, and
> (where required) regulatory labels, staged safe → **Pilot** on `Scope – Records-Pilot – Static`
> (publish/auto-apply to the pilot, declare disposable test items) → **Validate** against explicit
> pass/fail gates → **Expand** to production (adaptive scopes optional) under change control.

Records declaration — and especially **regulatory** declaration — is high-impact and partly
**irreversible**. Every production change goes through change control with a documented rollback that
explicitly flags the no-rollback parts, and nothing expands past the pilot until the Section 5 gates
pass.
