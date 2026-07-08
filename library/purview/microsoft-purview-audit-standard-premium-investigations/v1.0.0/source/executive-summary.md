# Executive Summary — Microsoft Purview Audit (Standard & Premium)

## The problem
Every investigation — a compromised mailbox, a departing employee suspected of taking data, a
questionable admin action — begins with the same question: *what does the audit trail show?* Too often
the answer arrives too late: unified audit logging was never confirmed on, the high-value events an
investigation needs were never captured, retention was too short, or nobody had a repeatable way to
search. **Audit is not retroactive** — if it wasn't configured before the incident, the evidence
simply isn't there.

## The solution
A complete, self-guided implementation of **Microsoft Purview Audit**. It confirms and enables
**unified audit logging**, establishes what **Audit Premium** (E5 / add-on) provides — the high-value
events that matter most, above all `MailItemsAccessed` (which messages an attacker actually read),
plus longer retention — configures **audit log retention policies**, builds tested **investigation
runbooks** for the common incident questions, and wires **SIEM export** via the Office 365 Management
Activity API. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you commit) do the
assessment, configuration, searching, readiness reporting, and export.

## What you get
- **Standard vs Premium, made concrete** — what each retains, which events each unlocks, and which of your users need Premium for forensic-grade auditing.
- **The foundation confirmed** — unified audit logging on, mailbox auditing on, no hidden audit-bypass suppressing a user's events.
- **Deliberate retention** — priority-ranked policies keeping privileged actions and mailbox high-value events for the duration your compliance and legal functions require.
- **Investigation runbooks** — the exact operations and record types for mailbox compromise, data exfiltration, and privilege escalation, with a paged search tool that never silently truncates results.
- **Continuous export** — audit streamed to your SIEM for real-time detection and durable retention.
- **Proven readiness** — a scorecard that confirms you can answer the questions an incident will ask, before it asks them.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot → Validate →
Expand** — enabling, retaining, and exporting **pilot-first** on a limited scope before any tenant-wide
change, with pass/fail gates and documented rollback at every step.

## Boundaries
Microsoft Purview Audit is **licensing-/plan-dependent** (Premium features require E5 or the E5
Compliance / Audit add-on, assigned per user) and the portal and search tooling are **actively
evolving** — capabilities and paths are cited or flagged **"verify your licensing/tenant,"** never
assumed. **Retention-schedule adequacy, legal-hold obligations, and regulatory determinations are
deferred to your compliance, records, privacy, and legal functions** — the solution provides the
technical method and the evidence, not the determination.

## The bottom line
An audit trail ready **before** you need it — unified logging on, high-value events captured and
retained, investigation runbooks in hand — so an incident finds **answers, not gaps**.
