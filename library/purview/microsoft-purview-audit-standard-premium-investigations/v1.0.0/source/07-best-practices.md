# 7. Best Practices — Investigation-Ready Auditing with Microsoft Purview

Operating principles for keeping Purview Audit trustworthy and investigations fast. Grounded in
Microsoft's public guidance and the **Assess → Design → Configure → Pilot → Validate → Expand** model.

## Configure it before you need it
- **Audit is not retroactive** — the single most important rule. Enable unified audit logging, mailbox auditing, and Audit Premium (where licensed) **now**, so history exists when an incident asks for it. Every deferred day is permanently missing evidence.
- Treat "is auditing on?" as a **standing monitored control**, not a one-time check. Ingestion can be turned off and licenses can lapse; the scheduled `PURVAUDIT-Discovery.ps1`/`PURVAUDIT-Report.ps1` chain catches drift.

## Understand — and license for — the events you'll actually need
- The events that make or break an investigation (`MailItemsAccessed`, `Send`, `SearchQueryInitiated*`) are **Premium** and **per-user licensed**. Decide *which* users must have forensic-grade auditing (executives, admins, finance, high-risk roles) and ensure they carry the license.
- Don't assume every user has high-value events. An unlicensed user showing no `MailItemsAccessed` is a **licensing fact, not an all-clear** — say so in the investigation write-up.

## Retention: deliberate, priority-ranked, and governed
- Set **audit log retention policies** by record-type class rather than relying on the default. Keep privileged actions and mailbox high-value events the longest; keep noisy, low-value operations shorter.
- Priorities are **unique and lower-first** — plan the numbering (e.g. 100/200/300) so a specific policy wins over a broad one predictably.
- **Retention duration and legal-hold are compliance/records/legal determinations.** Configure to their schedule; don't invent one. Verify the ten-year tier is licensed before promising it.

## Watch the gotchas that make audit "find nothing"
- **Mailbox audit bypass** silently suppresses a user's mailbox events — audit any bypass associations and remove unintended ones.
- **Ingestion latency** means recent activity may not appear immediately — allow time before concluding an event is absent.
- **Search truncation** — `Search-UnifiedAuditLog` caps results; always page (`ReturnLargeSet`) and keep windows short so you never silently miss records. The provided search tool does this.
- **Time zones / UTC** — audit timestamps are UTC; normalize when correlating with other logs.

## Standardize investigations as runbooks
- Encode the common incident questions once (mailbox compromise, data exfiltration, privilege escalation) with the exact operations and record types. Under pressure, investigators run a procedure, not a memory test.
- **Corroborate across sources** — audit for user/admin actions, **Entra sign-in logs** for authentication detail, message trace for mail flow. No single log tells the whole story.
- Keep runbooks current as Microsoft renames/adds operations and shifts search tooling (portal, `Search-UnifiedAuditLog`, the Graph **Audit Log Query API**) — verify against current docs periodically.

## Export for durability and monitoring — but keep identities clean
- Stream to a **SIEM** for real-time detection and retention beyond the audit store. Prefer a **native connector** (e.g. Microsoft Sentinel) where available; use the **Management Activity API** app when you need the raw feed.
- The export app authenticates with a **certificate, never a client secret in code**. Grant least-privilege (`ActivityFeed.Read`, add `ActivityFeed.ReadDlp` only if you need DLP events), and rotate the certificate.

## Least-privilege roles and separation
- Give investigators **Audit Reader**; give the configuring admin **Audit Manager**. Reserve Global Administrator for one-time enablement.
- Access to the audit log is itself sensitive (it reveals who did what) — review Audit role membership periodically and log configuration changes.

## Pilot every change, keep a rollback
- Enable, retain, and export **pilot-first** on a limited scope in `-WhatIf`/read mode; validate with the readiness report before tenant-wide expansion.
- Retention-policy and export changes are reversible (`-Remove`, `StopSubscription`) — record the exact rollback with every change so a questioned change can be backed out cleanly.
