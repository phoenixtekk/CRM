# Best Practices — Exchange Lifecycle Policies in Microsoft Purview

Field-proven recommendations for running Exchange retention + cleanup safely. They reinforce the
model: **Assess → Design → Configure → Pilot → Validate → Expand**, with records/legal owning the
schedule.

## Treat delete as one-way — pilot and retain-first
- Retention **delete has no simulation mode and is largely irreversible** past the recovery window.
  Deploy **keep-only first** on the pilot, validate the "keep" behavior, and add the delete action only
  after the gate passes. This is the single most important habit in this solution.
- Never point a keep-**then**-delete rule at all mailboxes on day one. Widen scope in **rings**.

## Keep the schedule with records, not in the tool
- The retain period, disposition, and legal holds are **records/legal determinations**. Store the
  approved schedule in your records system and map policy names to it; the Purview policy is the
  *implementation*, not the *decision*. Re-confirm the schedule at each expansion.

## Name and document precedence deliberately
- Use consistent, self-describing names (`DLCEXO-Retention-Exchange-*`, `DLCEXO-Tag-*`,
  `DLCEXO-MRM-Cleanup-*`) so anyone reading the tenant can see scope and intent.
- Understand **principles of retention**: **retain wins over delete**, **longest retention wins**,
  **explicit wins over default**. When Purview retention and MRM both apply, expect Purview's
  preservation to win over an MRM delete — design so this is intentional, not a surprise.

## Prefer adaptive scopes for dynamic populations (where licensed)
- A **static** group scope targets *current* members and does not auto-re-scope as membership changes.
  For "all mailboxes in Legal" or "all leavers," an **adaptive scope** (E5) keeps membership current
  automatically. Confirm licensing before relying on it.

## Use the archive tier to shrink mailboxes without losing content
- **MoveToArchive** DPTs plus the **online / auto-expanding archive** keep primary mailboxes lean while
  content stays searchable and within retention. Enable the archive **before** assigning MoveToArchive
  tags, or the tag has nowhere to move mail to.

## Respect the Managed Folder Assistant cadence
- MRM is **best-effort, ~daily**, not instant. Don't judge cleanup on a stopwatch; trigger
  `Start-ManagedFolderAssistant` on pilot mailboxes for testing, but expect production to converge over
  a work cycle.

## Reconcile with holds every time
- A litigation/eDiscovery hold **overrides** delete (correctly). Always run discovery first so you know
  which mailboxes are held; never assume "cleanup removed it" for held content, and treat any held-mail
  deletion as a legal incident.

## Preservation Lock is a separate, deliberate decision
- Lock **only** when regulation requires immutability and records has approved it — a locked policy
  **cannot be shortened, disabled, or deleted by anyone**, including a Global Admin. Default to
  **unlocked**.

## Automate read-only, gate the writes
- Run `DLCEXO-Discovery.ps1` / `DLCEXO-Report.ps1` / `DLCEXO-Test-Readiness.ps1` on a schedule for
  ongoing assurance (coverage, drift, out-of-scope mailboxes). Keep all write operations behind
  `-WhatIf` → `-Commit` and change control. **No credentials in scripts** — use interactive modern-auth
  or a managed identity.

## Keep evidence
- Export policy names, scope, durations, and coverage at each phase. "Retention is configured and
  validated" is only defensible if you can **show** the scope, the schedule it implements, and the
  pass/fail gates — that evidence is the deliverable records and auditors actually want.
