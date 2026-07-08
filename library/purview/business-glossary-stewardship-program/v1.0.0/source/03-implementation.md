# 3. Implementation Guide — Business Glossary & Stewardship Program (Microsoft Purview)

Follow these steps in order. This guide stands up a **governance domain** and its **roles**, defines
the **stewardship workflow**, seeds the **business glossary** with a small agreed term set **in Draft**,
validates the cycle on a pilot, and only then **Publishes** and **expands** to further domains.
Artifact names are fixed — create them with the exact names shown and reuse them everywhere. **Every
new term starts in Draft; nothing is Published until the owner approves it against the pilot gate.**

> Model: build the domain and roles, prove the propose → review → approve → publish → report cycle on
> a bounded term set, then expand. The repeatable way:
> **Assess → Design → Configure → Pilot (Draft) → Validate → Expand (Publish).** Verify current portal
> paths, capability availability, and data-plane API versions for your tenant as you go — the Purview
> Data Governance experience is evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGGLOSS-Discovery.ps1` to capture readiness signals: the Purview account data-plane endpoint
   is reachable, which **governance domains** exist, how many **glossary terms** are already present
   and their status mix, and whether governance roles (domain owner / steward) are assigned. No
   changes are made.
2. Record gaps against the Requirements checklist. Do **not** proceed past a missing Unified Catalog
   experience, missing least-privilege governance roles, or a missing pilot domain — remediate first.

## Step 2 — Design the domain, role, and workflow model
1. Decide the **pilot governance domain** named `DGGLOSS-Domain-Pilot` (for example, Finance). Plan
   the broader domain map (by business unit) on paper for the expansion phase.
2. Decide the **stewardship RACI** for the pilot: the **data owner** (accountable for term meaning),
   the **data steward** (day-to-day curator), and the **approver** for publishing. Record it.
3. Design the **term workflow**: `Draft` (proposed) → `Review` (steward + owner review) → `Approved`
   → `Published` (business-visible) → `Expired` (retired/superseded), with a **re-certification
   interval** (for example, re-certify Published terms every quarter).

## Step 3 — Assign least-privilege governance roles
1. In the Unified Catalog, on `DGGLOSS-Domain-Pilot`, assign: **governance domain owner** to a small
   named group, **data owner** to the accountable business owner, **data steward** to the curator(s),
   and **data reader** to browsers. Reserve any account/tenant admin for a minimal named group.
2. Where the glossary will link to scanned assets, confirm the relevant **Data Map** roles
   (collection admin / data curator) exist; if not linking assets in the pilot, skip.
3. Pass/fail: each named person can perform only their intended action in the portal (a steward can
   edit a Draft term; a reader cannot). Re-run `DGGLOSS-Discovery.ps1` and confirm role coverage.

## Step 4 — Record the pilot scope (read-only)
1. Run `DGGLOSS-Set-Scope.ps1` to record the pilot **domain**, the 5–10 candidate **terms / critical
   data elements**, the **owner/steward** mapping, and the **re-certification interval**. This is
   read-only and produces the scope manifest you configure against.
2. Confirm with the pilot domain's **data owner** that the candidate term list and draft definitions
   are the right starting set. *The authoritative meaning of each term is the owner's to set.*

## Step 5 — Configure the stewardship workflow
1. In the Unified Catalog, configure (or confirm) the **term-approval workflow** for
   `DGGLOSS-Domain-Pilot` so that creating/updating a term routes to the named **approver** before it
   can be **Published**. Where a built-in approval workflow is available in your tenant, use it; where
   it is not, record the manual approval step in the RACI. **Verify workflow availability for your
   tenant** — this feature is evolving.
2. Set the **status model** convention (Draft/Review/Approved/Published/Expired) that the team will
   use consistently.
3. Pass/fail: a test Draft term cannot reach **Published** without passing the approver. Rollback:
   there is nothing to undo — a Draft term is not business-visible.

## Step 6 — Seed the glossary in Draft (pilot, simulate-first)
1. Create `DGGLOSS-Domain-Pilot` if it does not exist and seed the agreed terms **in Draft** using
   `DGGLOSS-Configure-Glossary.ps1`, which **defaults to `-WhatIf`** and prints exactly the domain and
   each term it *would* create, changing nothing. Review that plan.
2. Re-run with `-Commit` to create the domain and the terms **in `Draft` status**, each carrying its
   proposed **definition**, an **owner**, and a **steward**. No term is Published in this step.
3. Pass/fail: `DGGLOSS-Discovery.ps1` / the portal show the pilot domain with the seeded terms present
   in **Draft**, each with a definition and an owner. Rollback: delete or leave Draft terms — they are
   not business-visible; re-run after correcting definitions.

## Step 7 — Review, approve, and publish (owner-gated)
1. The **data steward** reviews each Draft term with the **data owner**; the owner sets the
   **authoritative definition** and approves. Move approved terms to **Published** through the
   workflow (portal or `DGGLOSS-Configure-Glossary.ps1 -SetStatus Published -Commit`, owner-approved).
2. Link terms to their **critical data elements / assets** where useful so the meaning is anchored to
   real data.
3. Pass/fail: each Published term has an approved definition, a named owner and steward, and (where
   applicable) linked assets. Only owner-approved terms are Published.

## Step 8 — Validate against the pilot gate
1. Run `DGGLOSS-Validate.ps1` and complete the Testing Guide. The pilot passes only when: the pilot
   domain exists with least-privilege roles assigned; every seeded term has a **definition**, a named
   **owner**, and a **steward**; the **workflow** blocks unapproved publishing; and the agreed pilot
   terms are **Published** (the rest legitimately still Draft/Review).
2. Remediate any gap and re-run the relevant validation before widening scope. Do **not** expand to
   further domains until the gate passes.

## Step 9 — Establish the upkeep cadence
1. Run `DGGLOSS-Report.ps1` to produce the stewardship report: terms by **status**, **unowned** terms,
   **stale** Published terms past the re-certification interval, and coverage per domain.
2. Schedule the steward's recurring cadence (for example monthly): re-certify Published terms, retire
   superseded terms to **Expired**, and fill unowned/undefined gaps. The report is the evidence the
   program is being maintained.

## Step 10 — Expand across domains (enforce)
1. After the pilot passes, add governance domains one at a time (`DGGLOSS-Domain-<name>`), re-running
   `DGGLOSS-Set-Scope.ps1`, `DGGLOSS-Configure-Glossary.ps1` (Draft-first, `-WhatIf` then `-Commit`),
   `DGGLOSS-Validate.ps1`, and `DGGLOSS-Report.ps1` for each new domain.
2. Keep the discipline: new terms start **Draft**, owner-approved before **Published**, every term
   owned and stewarded, and the upkeep cadence enforced with `DGGLOSS-Report.ps1` per domain.
3. Retire and re-certify on the agreed interval so the glossary stays trustworthy as the business
   evolves.

---
### Order of operations
`Assess -> Design (domain/roles/workflow) -> Assign roles -> Record scope -> Configure workflow -> Seed glossary (Draft, -WhatIf then -Commit) -> Review/approve/Publish (owner-gated) -> Validate gate -> Upkeep cadence -> Expand (further domains)`
