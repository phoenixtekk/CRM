# 8. Deliverables Summary — Microsoft Purview Audit (Standard & Premium)

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What Purview Audit is, Standard vs Premium, the audit stack, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Audit-specific prerequisites (licensing tier, Audit roles, Exchange Online + S&C PowerShell + Graph toolchain, logging/mailbox-audit state, export identity, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design, enable logging, configure retention policies, validate high-value events, build investigation runbooks, wire export, validate readiness, expand — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Nine gates from "logging on" to "readiness scorecard green," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes that make audit "find nothing" — bypass, latency, truncation, licensing, endpoint confusion, export auth — and their fixes. |
| **7. Best Practices** | Investigation-ready operating principles: configure before you need it, license the right users, deliberate retention, runbooks, clean export identities, least-privilege roles. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Retention-policy cmdlets use **Security & Compliance PowerShell** (`Connect-IPPSSession`);
search/config use **Exchange Online PowerShell** (`Connect-ExchangeOnline`); licensing/query use
**Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `PURVAUDIT-Discovery.ps1` | Assess: unified-audit state, org mailbox auditing + bypass, Audit Premium licensing, existing retention policies. | Read-only |
| `PURVAUDIT-Set-RetentionPolicy.ps1` | Configure/Remediate: enable unified audit; create/update/remove audit log retention policies. | `-WhatIf` (writes on `-Commit`) |
| `PURVAUDIT-Search.ps1` | Investigate: paged `Search-UnifiedAuditLog` by operation / record type / user / window (no silent truncation). | Read-only |
| `PURVAUDIT-Report.ps1` | Validate: investigation-readiness scorecard across logging, licensing, high-value events, retention, export. | Read-only |
| `PURVAUDIT-Export.ps1` | Configure: list/start/stop Office 365 Management Activity API content subscriptions (certificate app-only auth). | Read-only (writes on `-Commit`) |

## Named artifacts created
- Retention policies: `Audit Retention – Mailbox High-Value – Premium`, `Audit Retention – Privileged Actions – LongTerm`, `Audit Retention – Sign-in Events – Standard+`.
- Investigation runbooks: `Investigation – Mailbox Compromise – Runbook`, `Investigation – Data Exfiltration – Runbook`, `Investigation – Privilege Escalation – Runbook`.
- Export subscription effort: `Audit Export – Management Activity API – SIEM`.
- Readiness export: `Audit Readiness – Tenant – Report`. Pilot scope: `Audit Pilot – Investigators – Stage1`.

## Definition of done
- Unified audit logging **on**; mailbox auditing on with no unintended bypass.
- Audit Premium **licensed** for the users who need high-value events, and `MailItemsAccessed`/`Send` **confirmed present** for a licensed pilot user.
- The three **retention policies** in place with agreed durations/priorities.
- The three **investigation runbooks** proven to answer their questions.
- Export flowing to the SIEM (if in scope), and the **readiness scorecard green** for the pilot — then expanded tenant-wide with a monitoring cadence scheduled.

> **Boundary:** this solution delivers the technical configuration and evidence. **Retention-schedule
> adequacy, legal-hold obligations, and any regulatory determination are deferred to your compliance,
> records, privacy, and legal functions.** Feature availability is **licensing-/tenant-dependent and
> evolving — verify against your entitlements and current Microsoft documentation.**
