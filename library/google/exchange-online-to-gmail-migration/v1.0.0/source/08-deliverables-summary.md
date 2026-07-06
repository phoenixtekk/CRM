# 8. Deliverables Summary — Exchange Online → Gmail Migration (Mail, Calendar, Contacts)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Exchange-to-Gmail migration model — data types, tooling patterns, coexistence/mail routing, DNS/MX cutover — and the deployment model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline, tooling & coexistence design, pilot batch, per-user validation, DNS/MX cutover, expand by wave |
| 5. Testing Guide | Per-batch validation gates (mail/calendar/contacts, coexistence, cutover) with pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Cutover and coexistence without losing data |

## Named artifacts
| Artifact | Name |
|---|---|
| Source mailbox/estate baseline | `GWGMAIL Discovery - Source Mailboxes - Baseline` |
| Tooling & data-types design | `GWGMAIL Design - Tooling & Data Types - Mail` |
| Coexistence / mail-routing design | `GWGMAIL Coexistence - Mail Routing - Transition` |
| Pilot migration batch | `GWGMAIL Pilot - Mail Batch - Wave 0` |
| Per-wave target group | `GWGMAIL Wave - Target Group - Per Wave` |
| Per-user validation record | `GWGMAIL Validation - Mail/Cal/Contacts - Per User` |
| DNS/MX cutover runbook | `GWGMAIL Cutover - DNS/MX - Per Wave` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWGMAIL-Discovery.ps1` | Baselines the Exchange Online / M365 source estate for mail migration: user/mailbox counts, licensed users, shared mailboxes, resource/room mailboxes, and groups (Microsoft Graph, read-only) |
| `GWGMAIL-Validation.ps1` | Per-user migration validation — confirms a batch's users resolve, are licensed, the target is provisioned, and mail/calendar/contacts and coexistence signals are asserted (read-only) |
| `GWGMAIL-Report.ps1` | Renders migration coverage and exceptions: users migrated vs total and per-user mail/calendar/contacts coverage (Microsoft Graph, read-only) |
| `GWGMAIL-Remediation.ps1` | Safe remediation of migration data gaps in a batch members list (duplicates, blanks, unresolved UPNs, failed-item re-queue list); runs with `-WhatIf` by default |
| `GWGMAIL-Set-ScopeTargeting.ps1` | Builds a wave's target group in Microsoft Entra from a members CSV; runs with `-WhatIf` by default |

## The mail-migration playbook (outline)
A single reusable playbook the migration runs from, assembled from the artifacts above:

1. **Source baseline** — `GWGMAIL Discovery - Source Mailboxes - Baseline`: mailbox/user counts,
   data volumes, shared/resource mailboxes, contact counts, and mail-touching integrations.
2. **Tooling & data-types design** — `GWGMAIL Design - Tooling & Data Types - Mail`: the tool/pattern
   (data migration service / GWMME / third-party), data types and order, mappings, and the delta plan.
3. **Coexistence design** — `GWGMAIL Coexistence - Mail Routing - Transition`: split/dual delivery,
   calendar interop, lowered MX TTL, and the intended decommission point.
4. **Pilot batch** — `GWGMAIL Pilot - Mail Batch - Wave 0`: core IT + early adopters, a shared mailbox
   and a resource calendar included.
5. **DNS/MX cutover runbook** — `GWGMAIL Cutover - DNS/MX - Per Wave`: readiness → migrate
   mail/cal/contacts → coexistence routing → validate → DNS/MX cutover → rollback.
6. **Per-user validation** — `GWGMAIL Validation - Mail/Cal/Contacts - Per User`: mail **and**
   calendar **and** contacts confirmed per user.
7. **Expansion & decommission** — expand wave by wave with the go/no-go gate, then retire coexistence
   routing once the estate is fully on Gmail.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable mail migration following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
Every in-scope mailbox on Gmail with **calendars and contacts intact** — coexistence managed during
the transition, the DNS/MX cutover governed and reversible, and the whole migration proven on a pilot
batch before any production wave — so nothing is lost and users land smoothly.
