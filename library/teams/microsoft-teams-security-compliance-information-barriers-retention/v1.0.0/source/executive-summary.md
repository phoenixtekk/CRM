# Executive Summary

**Outcome.** Microsoft Teams is brought under the compliance controls that are specific to it —
**information barriers** enforced between groups that must stay separated, **retention** applied to
Teams chat and channel messages, and **Data Loss Prevention** effective in Teams conversations. These
are the Teams-specific controls most Purview rollouts leave open (email and files are covered; Teams
chat often is not). The result closes that gap and aligns Teams to the organization's existing Purview
program rather than duplicating it.

**Approach.** The solution provides the technical method — exact Security & Compliance PowerShell and
Purview-portal steps, five safe-by-default PowerShell tools, and named, reusable artifacts — for three
controls: information-barrier **segments and policies**, Teams **chat/channel retention**, and Teams
**DLP**. The determinations that drive them (who must not communicate, how long to retain, what to
block) remain with the organization's **compliance, records, and legal** functions; the solution
implements those decisions, it does not make them.

**Why it is low-risk.** Every control follows a pilot-first model — **Assess → Design → Configure →
Pilot → Validate → Expand** — with explicit pass/fail gates and a documented rollback per control.
Information barriers are validated on a limited pilot population before the attribute is expanded; DLP
runs through an **audit gate** in test mode before it ever blocks a message; retention is validated on
a small scope before broad deletion. Automation is read-only or `-WhatIf` by default, requires an
explicit `-Commit` to change anything, and carries no credentials in code. Plan-, version-, and
cloud-dependent specifics (E5/E5-Compliance entitlements, channel-type coverage, Government-cloud
endpoints) are flagged to verify in-tenant rather than assumed.

**Bottom line.** Teams brought under compliance — barriers enforced, chat/channel retention applied,
Teams DLP effective — the Teams-specific controls closed and aligned to Purview, delivered as a
self-guided, tested runbook at a fraction of consulting cost.
