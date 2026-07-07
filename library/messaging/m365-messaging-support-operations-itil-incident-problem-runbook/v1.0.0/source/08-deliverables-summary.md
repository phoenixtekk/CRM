# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** | The messaging support operating model: L2–L4 responsibilities + escalation, ITIL incident/problem management for mail, on-call & service-availability handling, SLA/FCR/CSAT, KB/coaching — and the scope boundary vs desktop support and security IR. |
| **Requirements Guide** | Solution-specific prerequisites (ITSM tool + CSV export, tiered least-privilege admin access, Service Health read scope, on-call rota, KB platform, SLA targets/baseline, analyst workstation), each with how to verify/implement — on top of the shared messaging requirements. |
| **Implementation Guide** | Ordered rollout on the Assess→Design→Configure→Pilot→Validate→Expand model: define L2–L4 responsibilities and escalation, stand up incident + problem management for messaging, wire on-call + service-availability handling, set FCR/CSAT/reopen practices, operate KB + coaching. Every runbook named; pass/fail gates and a process rollback included. |
| **Testing & Validation** | T1–T10 procedures with pass/fail signals, mapped to the validation gates. |
| **Troubleshooting** | Common operating-model failure modes (missed SLAs, escalation bouncing, repeat incidents, low CSAT/high reopen, "is it us or Microsoft?" confusion, script/permission issues) and their resolutions. |
| **Best Practices** | Durable practices for a high-CSAT messaging support practice. |
| **Executive Summary** | The outcome, approach, and why the rollout is low-risk — for sponsors. |

## PowerShell tools (5) — read-only or `-WhatIf` by default, no credentials in code

| # | Script | What it does | Safe default |
|---|--------|--------------|--------------|
| 1 | **Get-ServiceHealthTriage.ps1** | **Service Health / message-trace triage helper (also the scope/health pre-flight).** Reads the Microsoft Graph **Service Communications API** (`Get-MgServiceAnnouncementIssue` / message-center advisories) to list active **Exchange Online** service issues and advisories, so on-call can quickly answer "is it us or Microsoft?". `-CheckScope` reports the connected operator's effective role posture and required module versions (the pre-flight in Testing T1). Optional single-user message-trace summary via EXO. | Read-only |
| 2 | **New-MessagingRunbookConfig.ps1** | **KB / runbook config helper.** Generates a starter **ticket taxonomy** (categories, P1–P4 priorities), a **KB skeleton** (one stub per category, with owner/next-review placeholders), and the named runbook list as JSON/Markdown to import or copy into your ITSM/KB tools. | Writes only to a local `-OutputPath` (no tenant change); `-WhatIf` supported |
| 3 | **Test-MailboxMailFlowHealth.ps1** | **Mailbox / mail-flow health-check for common tickets.** For a given mailbox, returns the key facts L2 needs in one place: mailbox type & primary SMTP, forwarding, hold/retention state, quota, and a recent **message-trace** summary for that user. | Read-only |
| 4 | **Get-MessagingSlaMetricsReport.ps1** | **SLA / ticket-metric rollup report.** From an exported ticket **CSV**, computes **SLA attainment** (per priority), **First-Call-Resolution**, **CSAT**, and **reopen rate**, with a configurable column map for any ITSM tool. | Read-only (reads a CSV) |
| 5 | **Find-RecurringMessagingIncidents.ps1** | **Recurring-incident / problem-candidate analyzer.** From an exported ticket **CSV**, clusters incidents by category/subject to surface the **repeat offenders** that should become **Problem records** for root-cause. | Read-only (reads a CSV) |

The **scope/health helper** capability (pre-flight: confirm the operator's effective least-privilege
posture per tier and required module versions) is provided by **`Get-ServiceHealthTriage.ps1
-CheckScope`** — see Testing T1. This solution ships **exactly the five scripts above**.
