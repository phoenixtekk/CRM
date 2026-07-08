# 8. Deliverables Summary — Legal-Hold & Custodian Management Program (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The legal-hold + custodian program model — the hold-type distinction (case hold vs custodian-based hold vs Litigation Hold vs retention), how cases/holds/custodians/notices/tracking fit together, the deferred legal boundary and the MSEDISC (readiness) boundary, and the naming convention for every case/hold/custodian/notice object. |
| **Requirements Guide** | Solution-specific prerequisites — eDiscovery **Standard vs Premium** licensing, eDiscovery **Manager/Administrator** role groups, in-scope custodians/data-sources/non-custodial locations, the preservation scope + notice content from legal, a named **release authority** + change control, and audit logging + a pilot matter — each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design the case + scope → configure the **case hold** (preview → commit) → add custodians + issue the notice (Premium) → validate distribution/coverage/acknowledgment → track and expand to real matters; each phase named, gated, with a rollback — and **no automated release**. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — the hold **preserves** (A), custodians/notices are **covered and tracked** (B, Premium), and the program is **operable and defensible** (C) — plus overlapping-hold safety, pilot isolation, and no-auto-release checks, all on a pilot matter with **fabricated** custodians. |
| **Troubleshooting Guide** | The common failure modes (hold not distributing, custodian data source not mapping, notice not acknowledged, Premium features missing, tracking report empty) and how to resolve them. |
| **Best Practices** | Pilot-first discipline, preserve-first scoping, distribution validation, the notice/acknowledgment evidence trail, the release-is-irreversible rule, the legal-vs-technical boundary, and licensing/portal reality. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. **No tool releases
a hold** — release is a deliberate portal + sign-off action (Req 2.5). No credentials are stored in code. They
connect via `Connect-IPPSSession` and/or `Connect-MgGraph` (eDiscovery, some endpoints **beta** — verify).

| # | Script | Role | Default / run-mode |
|---|---|---|---|
| 1 | **EDHOLD-Discovery.ps1** | eDiscovery posture assessment: existing cases, case hold policies and their **distribution status**, custodian/communications signal (Graph, where licensed), a **Premium-licensing** signal, and eDiscovery role-group membership. | **Read-only** |
| 2 | **EDHOLD-Config.ps1** | Hold/custodian config helper: creates/updates an eDiscovery **case hold policy + rule**, adds a **custodian** (Graph, where licensed), or enables Litigation Hold — **`-WhatIf` by default**; writes need `-Commit`. **Never releases a hold.** | `-WhatIf` (writes need `-Commit`) |
| 3 | **EDHOLD-Validate.ps1** | Validation checker: confirms hold **distribution = Success** across locations, expected custodians/locations in scope, Litigation Hold state, and (Graph, where exposed) notice/acknowledgment signal — per-gate pass/fail. | **Read-only** |
| 4 | **EDHOLD-Report.ps1** | Tracking report: exports the **hold/custodian register** — custodians, data sources, hold/distribution status, and notice/acknowledgment status/dates where exposed. | **Read-only** |
| 5 | **EDHOLD-Set-Scope.ps1** | Scope/health helper: reports a hold's locations/custodians and (with `-Commit`) **adds/adjusts** hold locations / custodian data sources. **Never releases a hold.** | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- eDiscovery licensing tier confirmed (Standard = case holds; Premium = custodians + communications) and
  eDiscovery role-group ownership assigned (Administrator + per-matter Managers).
- A **pilot matter** case with a **case hold policy + rule** built (preview → commit), scoped to **fabricated
  test** locations, at the preservation scope legal chose (everything vs a validated query).
- **Custodians** (Premium) added with mapped data sources, **non-custodial** locations held, and the
  **hold notice** issued with acknowledgment tracked and reminder/escalation configured.
- Hold **distribution = Success** validated across all pilot locations, deleted held content proven
  recoverable, and every intended custodian/location confirmed in scope (Gate A/B).
- The **hold register** exported and current; the evidence/audit trail present; role separation and a named
  **release authority** in place (Gate C).
- Pilot isolation, safe teardown, and **no-auto-release** verified (S1–S4); the program minted to production
  naming for real matters under change control.

> **Boundary:** the solution delivers the technical program and the evidence. **Whether a duty has attached,
> who is a custodian, the preservation scope, a notice's legal sufficiency, and when a hold may be released**
> are legal / eDiscovery-counsel determinations, captured alongside the evidence — and **no delivered tool
> releases a hold**.
