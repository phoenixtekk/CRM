# 1. Solution Overview — Microsoft Purview Audit (Standard & Premium): Unified Audit Log & Investigations

## What this solution is
When something goes wrong — a compromised mailbox, a departing employee suspected of taking data, an
over-privileged admin action — the first question is always *"what does the audit trail show?"* Too
many organizations discover the answer too late: unified audit logging was never confirmed on, the
high-value events an investigation needs were never captured, retention was too short, or nobody had a
repeatable way to search. This solution implements **Microsoft Purview Audit** end to end: confirm and
enable **unified audit logging**, understand and (where licensed) enable **Audit Premium** for
high-value events and longer retention, configure **audit log retention policies**, build repeatable
**search and investigation runbooks**, wire **SIEM/export** via the Office 365 Management Activity API,
and validate that you can actually answer the questions an incident will ask — *before* it asks them.
It uses only the **Microsoft Purview portal**, **Exchange Online / Security & Compliance PowerShell**,
and **Microsoft Graph** — no third-party tooling.

## Why this matters
- Audit is the evidence layer for every investigation. If it wasn't configured before the incident, the data simply isn't there — audit is not retroactive.
- **Audit Standard** now retains most records for 180 days; **Audit Premium** extends default retention to one year (up to ten years with the add-on) and unlocks **high-value events** — most importantly `MailItemsAccessed`, which tells you *whether and which* messages an attacker actually read after compromising a mailbox. Without it, mailbox-compromise scope is guesswork.
- The controls are **licensing-dependent and evolving**. Audit Premium features require Microsoft 365 E5 or the E5 Compliance / Audit add-on, and Microsoft is transitioning search tooling (portal, `Search-UnifiedAuditLog`, and the newer Graph Audit Log Query API). Getting this right means confirming what your tenant actually has, not assuming.
- Auditing is only useful if someone can query it under pressure. A tested **investigation runbook** — the exact operations and record types for mailbox compromise, data exfiltration, and privilege escalation — turns a panic into a procedure.

## How it works
1. **Confirm the foundation.** Unified audit logging is on by default for newer tenants, but it can be disabled and it varies — the solution verifies `UnifiedAuditLogIngestionEnabled` and org-level mailbox auditing, and enables them if off.
2. **Establish the licensing reality.** Which workloads and users have **Audit Premium** (E5 / Audit add-on) is read from Graph, because `MailItemsAccessed` and long-term retention only apply where the license is assigned.
3. **Configure retention deliberately.** Beyond the default retention, **audit log retention policies** (priority-ranked, per record type / operation / user) keep the events that matter — privileged actions, mailbox high-value events, sign-ins — for the duration your compliance and legal functions require.
4. **Build investigation runbooks.** For the common incident questions, the solution names the exact **operations** and **record types** to search (e.g. `MailItemsAccessed`, `New-InboxRule`, `FileDownloaded`, `Add member to role`, `Consent to application`) and delivers a paged search tool so results aren't silently truncated.
5. **Wire export to a SIEM.** For continuous monitoring and retention beyond the audit store, audit data is streamed via the **Office 365 Management Activity API** (or a native connector such as Microsoft Sentinel) — the solution manages the content subscriptions.
6. **Validate readiness.** A readiness report scores the tenant against concrete gates — logging on, Premium where expected, high-value events present in recent data, retention policies covering the key record types, export active — so "investigation-ready" is proven, not assumed.

## The audit stack this solution configures
- **Unified audit log** — the single searchable log of user and admin activity across Exchange, SharePoint, OneDrive, Teams, Entra ID, and more.
- **Audit (Standard)** — included with most subscriptions; ~180-day retention, core operations.
- **Audit (Premium)** — E5 / add-on; **high-value events** (`MailItemsAccessed`, `Send`, `SearchQueryInitiatedExchange`/`SharePoint`), **one-year default retention** (up to **ten years** with the add-on), **custom retention policies**, and **higher bandwidth** to the Management Activity API.
- **Audit log retention policies** — priority-ranked rules that set how long specific record types / operations / users are kept.
- **Search & investigation** — the Purview **Audit** portal search, `Search-UnifiedAuditLog` (Exchange Online PowerShell), and the newer **Audit Log Query Graph API**.
- **Export** — Office 365 **Management Activity API** content subscriptions (and native SIEM connectors).

## What you can control
- Whether unified audit logging and org mailbox auditing are enabled (and confirming they stay on).
- Which record types / operations / users get **extended retention**, and for how long (within your licensing).
- The **investigation runbooks** — which operations map to which incident questions.
- The **export target** and which content types stream to your SIEM.
- The **pilot scope** (a small investigator group / limited record set) validated before any tenant-wide retention or export change.

## Limitations (be honest with buyers)
- **Audit is not retroactive.** Enabling logging or Premium today does not create history for yesterday — value accrues from the enablement date forward. This is the single most important reason to configure it *before* an incident.
- **Premium features are license-gated per user.** `MailItemsAccessed` and long-term retention only apply to mailboxes/users with the E5 / Audit add-on assigned; unlicensed users won't have high-value events. **Verify your licensing/tenant.**
- **Retention-policy durations and the ten-year tier depend on licensing.** The ten-year retention add-on is a separate license; accepted `RetentionDuration` values should be **verified in your tenant**.
- **Search tooling is transitioning.** `Search-UnifiedAuditLog` has result and throttling limits (page with `ReturnLargeSet`; keep windows short) and Microsoft has signalled a move toward the **Audit Log Query Graph API** — confirm the current, supported method for your tenant before standardizing automation on one path.
- **Retention schedules and legal-hold determinations are not ours to make.** How long audit evidence must be kept, and any legal-hold obligations, are **deferred to your compliance, records, privacy, and legal functions** — this solution provides the technical method and evidence, not the determination.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Mailbox high-value retention policy | `Audit Retention – Mailbox High-Value – Premium` |
| Privileged-action retention policy | `Audit Retention – Privileged Actions – LongTerm` |
| Sign-in / auth retention policy | `Audit Retention – Sign-in Events – Standard+` |
| Mailbox-compromise investigation runbook | `Investigation – Mailbox Compromise – Runbook` |
| Data-exfiltration investigation runbook | `Investigation – Data Exfiltration – Runbook` |
| Privilege-escalation investigation runbook | `Investigation – Privilege Escalation – Runbook` |
| Management API content subscription | `Audit Export – Management Activity API – SIEM` |
| Readiness scorecard export | `Audit Readiness – Tenant – Report` |
| Pilot validation scope | `Audit Pilot – Investigators – Stage1` |

## The standard deployment model
> Assess what auditing/licensing you actually have → design the retention and investigation coverage →
> configure logging, retention policies, and export → **pilot** on a limited scope in read/report mode
> first → validate you can answer the incident questions → expand to full retention and continuous
> export. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
