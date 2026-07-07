# Troubleshooting

Common failure modes of the messaging support operating model and how to resolve them. This is a
diagnostic playbook for the *practice* (SLAs, escalation, quality) and for the included tooling — not a
mail-flow diagnostic guide (that lives in the per-category KB articles).

## Operating-model symptoms

### Symptom: SLAs are missed even though the team is busy

- **Likely cause A — priority not driven by blast radius.** Single-user issues are being worked at the
  same urgency as domain-wide ones. **Resolve:** enforce `Priority Matrix – Messaging – Design`; P1/P2
  are defined by how much mail is affected, and they get worked first.
- **Likely cause B — incidents not all logged.** First-contact fixes go unlogged, so the metric is
  computed on a partial, skewed set. **Resolve:** the Incident Lifecycle requires logging *every*
  contact; audit with Testing T4.
- **Likely cause C — wrong SLA timers in the ITSM tool.** **Resolve:** confirm the priority-to-SLA
  mapping in `Ticket Taxonomy – Messaging – Configure` matches the agreed targets (R6).

### Symptom: tickets bounce between tiers ("hot potato")

- **Likely cause — escalation on frustration, not criteria.** **Resolve:** re-train to
  `Escalation Matrix – Messaging – Design`; escalation requires a *defined condition* (a
  connector/policy/hybrid change, multi-mailbox/domain/org impact, transport-side trace failure, or the
  L2 time-box). Sample with Testing T3; coach the misses.
- **Secondary cause — no diagnostic bundle.** The receiving tier restarts triage and pushes back.
  **Resolve:** make the bundle (message trace, timestamps, message IDs, recipients, `Get-` output)
  mandatory on escalation; the KB template enforces it.

### Symptom: the same mail incident keeps recurring

- **Likely cause — no problem management.** Incidents are closed individually; the underlying cause is
  never fixed. **Resolve:** run `Find-RecurringMessagingIncidents.ps1` each period, open a **Problem
  record** for the top candidate, drive root-cause, and publish a **Known-Error + workaround** so L2 can
  mitigate while the permanent fix is under change control. Verify with Testing T6.

### Symptom: low CSAT / high reopen rate

- **Likely cause A — "resolved" without confirmation.** Tickets closed before the user's issue actually
  cleared. **Resolve:** require confirmation on close for the priorities where SLA demands it; run a
  **reopen review** and feed reasons into the KB.
- **Likely cause B — stale KB.** Analysts follow old portal paths / retired cmdlet guidance and apply
  wrong fixes. **Resolve:** enforce owner + next-review date per article (Testing T9); refresh
  mail-surface steps against current Microsoft docs and your tenant/version.

### Symptom: the team can't tell "is it us or Microsoft?" quickly

- **Likely cause — service-availability step skipped.** The team dives into local diagnosis while an
  active Microsoft incident exists (or chases Microsoft while the fault is local). **Resolve:** enforce
  the `On-Call Runbook – Messaging – Design` first step — check **Service Health** (portal +
  `Get-ServiceHealthTriage.ps1`) *before* local diagnosis, and annotate the ticket with the MS incident
  ID when one matches. Drill it (Testing T5).

### Symptom: new analysts ramp slowly / quality varies by person

- **Likely cause — no structured onboarding/coaching.** **Resolve:** run the shadow →
  reverse-shadow → solo-with-review path in `Coaching Onboarding – Messaging – Configure`, including
  running the five scripts as part of ramp; coach from real tickets and reopens.

## Tooling / script symptoms

### `Get-ServiceHealthTriage.ps1` returns "Not connected to Microsoft Graph"

- Run `Connect-MgGraph -Scopes "ServiceHealth.Read.All"` first (**Government:** add `-Environment USGov`
  or `-Environment USGovDoD`). Confirm with `-CheckScope`. The scope requires **admin consent** — if
  consent is refused, an administrator must grant it (Requirement R3).

### `Get-ServiceHealthTriage.ps1` shows no issues during a real outage

- Not all local problems are Microsoft-side. A **green** Service Health means treat it as a **local**
  issue and proceed with local diagnosis — that is the expected, correct behavior, not a script fault.
- Also check the **Message center** advisories (`-IncludeAdvisories`) for change-driven issues that may
  not appear as a service incident.

### `Test-MailboxMailFlowHealth.ps1` errors on a valid mailbox

- Confirm `Connect-ExchangeOnline` succeeded and the **account has permission** to read that mailbox
  (tier least-privilege — Requirement R2). A `Get-Mailbox not found` on a real mailbox is almost always
  a permission or wrong-tenant/cloud issue.
- Message trace only covers **recent** history; for older mail use `Start-HistoricalSearch` (noted in the
  script output).

### `Get-MessagingSlaMetricsReport.ps1` numbers look wrong or blank

- Almost always a **column-mapping** issue. The script warns when an expected column is missing — map
  your ITSM export's real column names via `-ColumnMap` (e.g. `@{ Priority='urgency'; SlaMet='sla_flag' }`).
- CSAT must be numeric to average; non-numeric CSAT cells are ignored by design. Boolean-ish flags
  (SLA-met, FCR, reopened) are matched against the `-*TrueValues` sets — adjust them to your tool's
  values (`met`/`yes`/`true`/`1`).

### `Find-RecurringMessagingIncidents.ps1` finds nothing

- Lower `-Threshold` (default 3) to surface smaller clusters, and confirm the **Subject/Category**
  columns are mapped for your export. If subjects are highly templated with IDs, the normalizer already
  strips numbers/emails/GUIDs — verify it's clustering on the right field.

### `New-MessagingRunbookConfig.ps1` — did it change my tenant?

- No. It writes **only** to the local `-OutputPath` and makes **no** Microsoft 365 connection. Use
  `-WhatIf` to preview. Import/copy the generated `taxonomy.json`, `kb-skeleton\*.md`, and `runbooks.md`
  into your ITSM/KB tools yourself.

## Government cloud reminder

If any script or step fails on an endpoint, confirm you are targeting the **right cloud**: Government
tenants use `admin.microsoft.us` / `admin.exchange.microsoft.us`, Graph `graph.microsoft.us`
(`Connect-MgGraph -Environment USGov`/`USGovDoD`), and EXO via the correct
`-ExchangeEnvironmentName`. Commercial URLs will not resolve for a Government tenant. **Verify the
correct endpoints for your tenant.**
