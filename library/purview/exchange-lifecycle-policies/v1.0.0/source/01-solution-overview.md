# Solution Overview — Exchange Lifecycle Policies in Microsoft Purview

## What this solution delivers

Mailboxes grow forever unless something tells mail when to **stay** and when to **go**. Left alone,
that is two problems at once: a **compliance gap** (you cannot show that mail is kept for as long as
the schedule requires — and only as long) and a **data-risk exposure** (years of old messages,
deleted items, and junk sitting in every mailbox as discoverable, breachable content). This solution
closes both by delivering **Exchange-focused lifecycle policies** in **Microsoft Purview**: a
**retention** side that keeps mail for the required period, and a **cleanup** side that removes or
archives mail once it is past its useful life — configured to your schedule, piloted on a bounded
scope, validated with pass/fail gates, and operable.

This solution walks a competent-but-novice administrator through a **complete, repeatable Exchange
lifecycle deployment** built from **two complementary engines**:

1. **Purview Data Lifecycle Management retention (the "keep" and "keep-then-delete" engine).** A
   **retention policy** scoped to **Exchange mailboxes** (and, where in scope, Exchange **public
   folders**) with a **retention rule** that says *retain for N, then delete* — or *retain only*, or
   *delete only* — applied per the schedule your records function sets. This is the compliance-grade
   control: retention overrides user deletion (content is preserved in the Recoverable Items folder
   even if the user empties it) for the duration of the retain period.
2. **Exchange (MRM) messaging records management (the "housekeeping / cleanup" engine).** A **retention
   policy** made of **retention tags** that quietly age mail out of noisy folders — permanently delete
   **Deleted Items** and **Junk Email** after a set age, and (optionally) **move older mail to the
   archive mailbox** with a default policy tag — run by the **Managed Folder Assistant**. This is the
   hygiene control that keeps primary mailboxes lean.

The two are designed to work **together**: Purview retention guarantees the floor (mail is kept long
enough and is defensibly removed at end-of-life), while MRM handles day-to-day cleanup and archive
tiering. This solution configures both, names every policy/tag/scope, pilots on a limited ring
**before** any destructive action reaches production mailboxes, validates, and only then expands.

## Read this first — retention deletion is high-impact and there is no "simulation" toggle

Unlike DLP or auto-labeling, **Purview retention policies do not have a simulation/test mode**. When a
retention rule includes a **delete** action, mail **past the retention age is permanently removed** —
this is real, and for most tenants **irreversible** once the Recoverable Items window passes. Two
principles therefore run through every step:

- **Pilot by SCOPE, not by simulation.** The safe pilot here is a **small, named pilot ring** (a
  handful of mailboxes / a pilot group) and, where you want extra safety, starting the retention rule
  as **retain-only** (no delete) or with a deliberately long test window, **validating**, and adding
  the delete action only after the gate passes. Never point a keep-**then**-delete rule at the whole
  tenant on day one.
- **The schedule is a records/legal determination, not a technical default.** *How long* mail must be
  kept, *when* it may be deleted, and *which* mail is subject to legal hold are decided by your
  **records-management, compliance, privacy, and legal** functions — not by this solution and not by
  the administrator. This solution provides the **technical method and the evidence**; the retention
  schedule and any hold come from the owners who set them (see `global-requirements-purview.md` §5).

> **Preservation Lock is irreversible.** If your regulatory obligations require an immutable,
> can-never-be-shortened retention policy, Purview offers **Preservation Lock** — but once locked, the
> policy **cannot be disabled, deleted, or made less restrictive by anyone, including a Global
> Administrator**. Treat locking as a separate, records-approved decision; this solution keeps policies
> **unlocked** unless your records function explicitly directs otherwise.

## How the pieces fit

- **Retention policy (Purview) → retention rule.** The **policy** defines *where* it applies
  (Exchange mailboxes, public folders) and *to whom* (all mailboxes, a static list, or an **adaptive
  scope**). The **rule** defines *the behavior*: `Retain` (keep), `Delete` (remove), or `KeepAndDelete`
  (retain N, then delete), with the duration measured from when content was created or last modified.
  Retention **wins over user deletion** while the retain period runs.
- **MRM retention policy → retention tags.** An MRM **policy** is a bundle of **tags**: a **Default
  Policy Tag (DPT)** applies to all untagged items (e.g. *move to archive after 2 years*), **Retention
  Policy Tags (RPTs)** apply to specific default folders (e.g. *Deleted Items → permanently delete
  after 30 days*), and optional **Personal Tags** users can apply themselves. Assigned to a mailbox
  and run by the **Managed Folder Assistant**, this is the cleanup/archive engine.
- **The archive mailbox (optional tier).** Enabling the **online archive** (and **auto-expanding
  archive** where licensed) gives MoveToArchive tags somewhere to move old mail to — shrinking the
  primary mailbox while keeping the content searchable and within retention.
- **Precedence, understood.** When multiple retention settings apply, Purview follows a defined
  **principles of retention** order (retain wins over delete; longest retention wins; explicit wins
  over default). This solution names each object so precedence is deliberate, not accidental.

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (limited scope / retain-first) → Validate → Expand (enforce).**

- **Assess** — confirm licensing (retention is available on **Exchange Online Plan 2 / M365 E3+**;
  adaptive scopes and auto-expanding archive have their own plan gates — **verify your licensing/
  tenant**), roles, the in-scope mailboxes, the **records schedule**, and legal-hold status.
- **Design** — with records/legal, decide the **retention schedule** (retain N, then delete? retain
  only?), the **cleanup** tags (Deleted Items / Junk age-out, archive DPT), the **pilot ring**, and
  **name every object**.
- **Configure** — create the Purview retention policy + rule scoped to the **pilot**, and the MRM
  policy + tags; assign the MRM policy to pilot mailboxes.
- **Pilot** — run on the pilot ring only; where extra safety is wanted, retain-only first. Confirm
  mail is being kept/moved/cleaned as intended and **nothing outside scope is touched**.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — widen the Purview policy scope (to all mailboxes / an adaptive scope) and add/enable the
  delete action **only** after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Exchange Online PowerShell / Graph): a
  lifecycle **discovery** inventory, a **scope** manifest helper, a **configuration** helper
  (`-WhatIf`/retain-first by default, applies only with `-Commit`), a coverage/health **report**, and a
  PASS/GAP **readiness** gate — read-only or `-WhatIf` by default; **no credentials in code**.

> **Sources:** Microsoft Learn — *Learn about retention policies & retention labels*, *Create and
> configure retention policies*, *Principles of retention*, *Preservation Lock*, *Adaptive scopes*
> (Purview Data Lifecycle Management); *Retention tags and retention policies (MRM)*, *Set up an
> archive and retention policy*, *Enable auto-expanding archiving*, and *Managed Folder Assistant*
> (Exchange Online). Retention/lifecycle capability is **licensing-dependent** and the Purview portal
> is **evolving** — **verify capability availability and portal paths against your licensing/tenant**
> rather than assuming.
