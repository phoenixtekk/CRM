# Executive Summary — Exchange Lifecycle Policies in Microsoft Purview

Mailboxes grow without limit unless something governs the lifecycle of the mail inside them. Left
unaddressed, that is two liabilities at once: a **compliance gap** — you cannot demonstrate that mail
is kept as long as your schedule requires, and only that long — and a **data-risk exposure** — years of
old messages, emptied Deleted Items, and junk accumulating in every mailbox as discoverable, breachable
content. This solution closes both by delivering **Exchange-focused lifecycle policies** in **Microsoft
Purview**, end to end.

It gives a competent M365/compliance administrator a repeatable way to stand up **two complementary
engines**: **Purview Data Lifecycle Management retention** (the compliance-grade "keep, then defensibly
delete" control that overrides user deletion for the required period) and **Exchange messaging records
management** (the housekeeping engine that ages out Deleted Items and Junk and tiers old mail to the
archive) — configured to your schedule, scoped to a pilot ring, validated with explicit pass/fail
gates, and only then expanded.

This is a complete, deploy-it-carefully package, written for the administrator implementing Exchange
retention and cleanup for the first time.

## What you get
- A plain-language Solution Overview of the two engines, how they interact (principles of retention/
  precedence), and why retention **delete is high-impact and has no simulation mode**.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — licensing, the two
  PowerShell connections, the records schedule, legal holds, cleanup/archive design, and the pilot ring.
- An Implementation Guide of precise, ordered steps that configures both engines **scoped to a pilot**,
  supports a **retain-first** deployment, names every policy/tag/scope, and includes rollback.
- Five PowerShell scripts: a lifecycle discovery inventory, a scope-manifest helper, a configuration
  helper (`-WhatIf`/retain-first by default), a coverage/health report, and a PASS/GAP readiness gate —
  read-only or `-WhatIf` by default, no credentials in code.
- Testing and Troubleshooting guides, including a **blast-radius** check that proves nothing outside
  scope is touched.

## What this delivers
Mail retained for exactly as long as the schedule requires and no longer; Deleted Items and Junk aged
out on a set cadence; old mail moved to the archive to keep primary mailboxes lean; and every
destructive behavior proven on a bounded pilot before it reaches production mailboxes.

## The deployment model
Assess → Design → Configure → Pilot (limited scope / retain-first) → Validate → Expand (enforce).

## Scope boundary
This solution provides the **technical method and evidence**. The **retention schedule** (how long mail
is kept, when it may be deleted), any **legal hold**, and the decision to apply an irreversible
**Preservation Lock** are **records, privacy, and legal determinations** deferred to those functions —
not technical defaults and not the administrator's call (see `global-requirements-purview.md` §5).
Because retention delete is largely irreversible and has no simulation mode, the pilot ring is the
safety mechanism.

## Outcome
Exchange mail governed on policy in Microsoft Purview — kept, cleaned, and tiered exactly as the
schedule directs, piloted and validated before enforcement — so the capability is in place, defensible,
and evidenced.
