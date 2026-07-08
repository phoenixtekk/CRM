# 1. Solution Overview — Disposition Review Program (Microsoft Purview)

## What this solution is
At the end of a retention period, content in Microsoft 365 is either **deleted automatically** or **held
for a human to review first**. Automatic deletion is efficient but blind: nothing confirms the content is
truly out of obligation, nothing records *why* it was disposed, and there is no proof for an auditor or
regulator that the deletion was deliberate and authorised. **Disposition review** is the control that
turns "delete on expiry" into a governed, evidenced decision — one or more named reviewers examine each
expiring item and approve permanent deletion, extend retention, or relabel it, and Microsoft Purview keeps
a **proof of disposal** for what was disposed, by whom, and when.

This solution is a repeatable, pilot-first method to stand up a **multi-stage disposition review program
in Microsoft Purview**: retention labels configured with **single- and multi-stage** disposition review,
named **reviewer stages** with strict role separation, the **Disposition Management** permission wired so
reviewers can act, a working evidence/proof trail, and a validated **defensible disposal** outcome —
piloted on a bounded scope and proven against explicit pass/fail gates before it governs real content.

## Scope: the review workflow, not the retention schedule
This product is deliberately **narrow**. It implements the **disposition-review layer** — the reviewer
stages, the permission model, the evidence, and the defensible-disposal proof — on top of retention labels.
It does **not** re-author the organisation's broader retention/records program:

- **The retention schedule is an input, not built here.** *Which* content is retained, for *how long*,
  and *whether* a category ends in review or automatic disposal are determined by the organisation's
  **records-management, compliance, privacy, and legal** functions and are typically implemented by the
  **org-wide Data Lifecycle & Records Management product**. This solution takes those labels/categories as
  given and adds (or verifies) the **disposition-review** behaviour on them.
- **The disposition decision itself is deferred.** This solution delivers the *method* by which a reviewer
  approves, extends, or relabels — and the evidence of that action — but **whether** a specific item should
  be deleted, kept, or held is the reviewer's (records/legal) determination, never a technical default and
  never made by a script.
- **Legal holds / eDiscovery preservation** override disposition and belong to legal/eDiscovery — content
  under hold is not disposed; this solution respects that boundary and does not manage holds.

Where retention-label, policy, event-based-retention, records-declaration, or file-plan mechanics are
needed, this solution **references** the org-wide Data Lifecycle & Records Management product rather than
re-documenting them.

## Why this matters
- **Blind auto-deletion is a defensibility gap.** If content is deleted the instant its label expires,
  there is no record of a decision — only a gap where evidence should be. Disposition review inserts a
  documented, accountable checkpoint before irreversible deletion.
- **Multi-stage review encodes real accountability.** Many organisations require more than one sign-off
  before high-value content is destroyed — e.g. a records manager, then compliance, then legal. Microsoft
  Purview supports **multiple review stages** on a label so each stage approves in sequence and disposal
  happens only after the **final** stage approves. *(Multi-stage disposition review is plan-dependent and
  the stage model evolves — verify availability and the exact configuration in your tenant.)*
- **Evidence is the product.** When an item is disposed after review, Microsoft Purview retains a
  **disposition record** (proof of disposal) and writes **audit events** — the artefact a regulator or
  auditor asks for. A review program that produces no evidence is not defensible; this solution treats the
  proof trail as a first-class deliverable.
- **Role separation protects the process.** Reviewers must hold the **Disposition Management** permission
  to see and act on the queue — and *only* that, so the person disposing content is not the same person who
  set the schedule. Getting this wrong either blocks reviewers (they cannot see the queue) or over-grants.
- **Doing it pilot-first avoids the high-impact failure mode.** A mis-scoped or mis-configured disposition
  label can route the wrong content to review — or worse, let content auto-delete when a review was
  required. Everything is proven on a **bounded pilot scope** with short-duration disposable test content
  before it governs production.

## How disposition review works in Microsoft Purview
1. **Disposition review is a property of a retention label.** A label whose retention action is
   **retain-then-delete** (`KeepAndDelete`) can have **disposition review enabled** instead of automatic
   deletion. At the end of the retention period the item is **not** deleted — it enters the **Disposition**
   queue for review. Labels are created/edited in Microsoft Purview → **Records management → File plan /
   Labels** (path evolves — verify in your tenant).
2. **Single-stage review** names one set of reviewers (`-ReviewerEmail`) — one approval disposes the item.
3. **Multi-stage review** defines an **ordered list of stages**, each with its own reviewers (via
   `-MultiStageReviewProperty`). Stage 1 approves → the item advances to Stage 2 → … → the **final** stage
   approves → the item is disposed. Any stage can instead **extend** retention or **relabel** the item,
   which stops disposal. *(Verify the multi-stage parameter shape and stage limit in your tenant — this
   capability is newer and its configuration has changed across releases.)*
4. **Reviewers act in the portal.** Named reviewers work the queue in Microsoft Purview → **Records
   management → Disposition**, where each can **permanently delete**, **extend the retention period**, or
   **apply a different retention label**. They must be in the **Disposition Management** role group to see
   the queue; they see only the labels for which they are a reviewer.
5. **Notifications drive the queue.** Reviewers receive email when items await them and periodic reminders;
   disposition settings control reminders and (where available) what happens to overdue stages. *(Confirm
   the notification/overdue behaviour in your tenant — settings evolve.)*
6. **Defensible disposal is the outcome.** Content is deleted **only after the final review stage
   approves**, and Microsoft Purview retains a **disposition record** as proof of disposal plus **audit**
   events — the evidence trail this program exists to produce.

## The reference design
- **Inputs (from records/legal):** which retention labels/categories require review, how many **stages**,
  who reviews at each stage, and the disposition authority. (This solution implements the design; it does
  not decide the stages or the reviewers.)
- **Disposition labels:** retain-then-delete retention labels with review enabled — single-stage where one
  sign-off suffices, multi-stage where accountability requires sequential approvals — named per the
  convention below. Where these labels already exist (from the org-wide records product), this solution
  **verifies and, where needed, adds** the review configuration rather than re-minting them.
- **Reviewer stages:** each stage's reviewers are a **mail-enabled security group** (so membership is
  managed once), and every member is placed in the **Disposition Management** role group. Typical stages:
  `Records → Compliance → Legal`.
- **Application:** disposition labels are **published** to (or **auto-applied** within) the **pilot scope**
  only, via a pilot-scoped label policy — never tenant-wide until validated.
- **Evidence:** the proof-of-disposal / disposition-record trail plus audit events, surfaced by the
  reporting script and the portal Disposition export.
- **Scope:** a **static pilot scope** to prove on, with short-duration disposable test labels so a full
  review cycle can be exercised without waiting years.

## Naming convention (used in every doc and script)
Every artefact this solution creates or verifies is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and the Purview admin surfaces:

| Artefact | Name |
|---|---|
| Retain-then-delete label, single-stage review | `Disposition Label – Records-7yr – Pilot` |
| Retain-then-delete label, multi-stage review | `Disposition Label – Contracts-7yr-MS – Pilot` |
| Stage 1 reviewer group (records) | `Disposition Reviewers – Records – Stage1` |
| Stage 2 reviewer group (compliance) | `Disposition Reviewers – Compliance – Stage2` |
| Stage 3 reviewer group (legal) | `Disposition Reviewers – Legal – Stage3` |
| Built-in permission for reviewers | `Disposition Management` (built-in role group) |
| Label policy publishing disposition labels | `Label Policy – Disposition-Publish – Pilot` |
| Auto-apply label policy (by condition) | `Label Policy – Disposition-AutoApply – Pilot` |
| Pilot scope (static) | `Scope – Disposition-Pilot – Static` |
| Assessment export | `Disposition Posture – Tenant – Discovery` |
| Evidence / compliance report | `Disposition Evidence – Tenant – Report` |

When the pilot passes and you expand, mint the production equivalents by swapping the `– Pilot` stage for
`– Prod` — never edit a validated pilot artefact in place.

## Limitations (be honest with buyers)
- **Disposition review — especially multi-stage — is plan-dependent.** It generally requires an **E5 / E5
  Compliance-class** plan or the equivalent Microsoft Purview add-on, and the **multi-stage** model is
  newer than single-stage. **Verify what your tenant is licensed for and the exact configuration shape.**
- **Reviewers act in the portal; scripts do not approve dispositions.** The provided tooling **configures,
  validates, and reports on** the review program and points reviewers to the portal Disposition queue —
  it never approves, extends, or deletes on a reviewer's behalf. The determination is human (records/legal).
- **Disposed items are not enumerable via a supported cmdlet.** The actual per-item disposition proof is
  exported from the portal **Disposition** area (and corroborated by the audit log); the reporting script
  surfaces label/stage/reviewer *configuration* and points to that export rather than inventing an item list.
- **Everything is eventually consistent.** Label application, expiry, entry into the queue, notifications,
  and disposal run on service timers (hours to days). Use short-duration test labels in pilot; never judge
  a cycle in the first minutes.
- **Permanent deletion is irreversible.** An approved final-stage disposition permanently deletes content.
  In pilot, exercise the full cycle only on **disposable test content** you are prepared to lose.
- **Legal hold overrides disposition.** Content on legal hold / eDiscovery hold is not disposed even after
  review approval; hold management is out of scope and owned by legal/eDiscovery.
- **Commercial vs Government cloud paths differ.** Portal URLs and some feature availability differ in
  GCC / GCC High / DoD (`*.office365.us`, `Connect-IPPSSession -ConnectionUri`) — **verify in your cloud.**

## The standard deployment model
> **Assess** the current disposition posture (which labels review vs auto-delete, existing reviewers and
> permissions) → **Design** the stage/reviewer map from the records/legal requirement → **Configure**
> disposition-review labels, reviewer stages, and the Disposition Management permission → **Pilot** on
> `Scope – Disposition-Pilot – Static` with short-duration disposable test content → **Validate** against
> explicit pass/fail gates (including a full review cycle and its evidence) → **Expand** to production
> labels/scope under change control.

Permanent disposal is **irreversible** and role separation is a compliance control — so nothing governs
production content until the pilot cycle, including its proof of disposal, has passed the gates in
Section 5, and every production change goes through change control with a documented rollback.
