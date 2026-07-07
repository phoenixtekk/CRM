# 8. Deliverables Summary — BitTitan MigrationWiz: M365 → Google Migration Execution

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The MigrationWiz execution model — projects, endpoints, agents, pre-stage/delta passes, coexistence — where it fits vs native tools, and the deployment model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (MigrationWiz account + licensing, source app registration, target delegation, endpoint/project design, pre-stage/throttle plan, pilot + cutover runbook) |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline, endpoint/project design, prove endpoints, pre-stage/delta + throttling plan, pilot wave, per-user validation, DNS/MX cutover, expand by wave, decommission coexistence |
| 5. Testing Guide | Per-wave validation gates (endpoints, mappings, pre-stage, per-user mail/docs/chat, coexistence, throttling, delta idempotency, cutover) with pass/fail criteria |
| 6. Troubleshooting Guide | Field failure modes and resolutions (auth errors, throttling, cutover overrun, duplication, missing items, mapping, DMA, coexistence) |
| 7. Best Practices | Prove endpoints first, pre-stage heavy/delta light, throttle deliberately, validate per user, stay inside the vendor boundary |

## Named artifacts
| Artifact | Name |
|---|---|
| Source/target scope & readiness baseline | `BTW Discovery – Source & Target – Baseline` |
| M365 source endpoint | `BTW Endpoint – M365 Source – Prod` |
| Google Workspace target endpoint | `BTW Endpoint – Google Target – Prod` |
| Mailbox migration project | `BTW Project – Mailbox – Prod` |
| Document migration project | `BTW Project – Documents – Prod` |
| Teams-to-Chat migration project | `BTW Project – Teams to Chat – Prod` |
| Line-item / user-mapping file | `BTW Mapping – User Pairs – Per Project` |
| Pilot wave | `BTW Wave – Pilot – Wave 0` |
| Per-wave production wave | `BTW Wave – <Segment> – Per Wave` |
| Pre-stage pass | `BTW Pass – Pre-Stage – Per Wave` |
| Delta / cutover pass | `BTW Pass – Delta Cutover – Per Wave` |
| Throttling profile | `BTW Throttle – Project Concurrency – Per Wave` |
| Per-user validation record | `BTW Validation – Mail/Docs/Chat – Per User` |
| DNS/MX cutover runbook | `BTW Cutover – DNS/MX – Per Wave` |

## Python tools
| Script | What it does |
|---|---|
| `btw-readiness-assessment.py` | Read-only baseline of both sides — the M365 source over Microsoft Graph (users, mailboxes, OneDrive/SharePoint, Teams) and the Google target over the Admin SDK (users, licensing, service-account delegation presence) — reporting scope and blocking readiness gaps. No writes; no MigrationWiz API |
| `btw-project-mapping-builder.py` | Builds and validates the source→target **line-item CSV that MigrationWiz consumes** for each project (mailbox / documents / teamschat), checking resolvable source, provisioned+licensed target, and no duplicates/blanks. Writes only the CSV you name |
| `btw-wave-planner.py` | Splits the user list into balanced waves (small pilot first) and emits, per wave, the **pre-stage/delta pass schedule and throttling guidance** with advisory duration estimates. Dry-run/stdlib only; no credentials |
| `btw-postmigration-validation.py` | Per-user, read-only **post-migration validation** — confirms each target account exists/active and shows mail (Gmail), documents (Drive), and (manual) chat present within an item-count tolerance; emits the `BTW Validation – Mail/Docs/Chat – Per User` report. Read-only scopes |
| `btw-config-helper.py` | Endpoint-config + throttling-health helper: `--check-delegation` confirms the target service account's domain-wide delegation resolves the required scopes (and best-effort source app-registration reachability); `--check-throttle` samples the target API for throttling/backoff to tune the concurrency profile. Read-only |

> All five tools are **safe by default** — read-only or planning/dry-run — take **no hardcoded
> credentials** (OAuth / service account / ADC), commit **no keys**, and call **no private BitTitan
> API**. They drive the migration only via the **CSV line-item and validation artifacts** MigrationWiz
> documents as consuming/producing.

## The execution playbook (outline)
A single reusable runbook the migration runs from, assembled from the artifacts above:

1. **Baseline** — `BTW Discovery – Source & Target – Baseline`: source scope, target readiness, and
   delegation gaps.
2. **Endpoint design** — `BTW Endpoint – M365 Source – Prod` + `BTW Endpoint – Google Target – Prod`:
   identities and scopes, proven on one test line item.
3. **Project design** — `BTW Project – Mailbox/Documents/Teams to Chat – Prod`: data types, mappings,
   and the explicit DMA decision.
4. **Pass plan** — `BTW Pass – Pre-Stage / Delta Cutover – Per Wave` + `BTW Throttle – Project
   Concurrency – Per Wave`: pre-stage heavy, delta light, throttled within provider limits.
5. **Pilot wave** — `BTW Wave – Pilot – Wave 0`: shared mailbox, SharePoint site, and Team included.
6. **DNS/MX cutover runbook** — `BTW Cutover – DNS/MX – Per Wave`: readiness → pre-stage → coexistence
   routing → delta cutover → validate → DNS/MX cutover → rollback.
7. **Per-user validation** — `BTW Validation – Mail/Docs/Chat – Per User`: mail **and** documents
   **and** chat confirmed per user.
8. **Expand & decommission** — expand wave by wave behind the go/no-go gate, then retire coexistence
   routing once the estate is fully on Gmail.

## What the buyer receives
- This implementation guide and all supporting docs as a Word document and PDF.
- All five Python tools in a single ZIP.
- A repeatable, wave-based MigrationWiz execution following the model: **Assess → Design → Configure →
  Pilot → Validate → Expand.**

## Outcome
Every in-scope user moved from M365 to Google Workspace on MigrationWiz — mail, documents, and chat
**validated per user**, the DNS/MX cutover **governed and reversible**, throttling controlled, and the
whole migration **proven on a pilot wave** before any production wave — so migrations run predictably
at enterprise scale, with the tool's console internals and licensing correctly deferred to BitTitan.
