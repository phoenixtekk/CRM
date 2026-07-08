# 8. Deliverables Summary — Financial / FINRA Communications Compliance (Microsoft Purview)

## What this solution delivers
A complete, repeatable way to stand up a **FINRA/SEC-aligned communications-supervision program** in
Microsoft Purview Communication Compliance — organized around three pillars: **lexicons** (regulated-
conduct detection), **review** (a designated-principal, risk-based-sample supervisory workflow), and
**evidence** (immutable communications retention and examiner-ready reporting) — configured, piloted in
**simulation/test**, validated with pass/fail gates, and expanded under change control.

## Documents
| # | Document | What it covers |
|---|---|---|
| 1 | **Solution Overview** | What the program is, the three pillars, how it works, scope/boundaries, and how it differs from general Communication Compliance |
| 2 | **Requirements Guide** | Solution-specific prerequisites (entitlement, designated principals + separation, supervised population, firm lexicons + WSPs, channels/connectors, retention + immutability decision, privacy, change control) — on top of the six category requirements |
| 3 | **Implementation Guide** | Ordered steps: guardrails first, design from WSPs/lexicons, build in simulation, validate detection + review, configure immutable evidence retention, tune, expand — each artifact named, with pass/fail gates + rollback |
| 5 | **Testing & Validation Guide** | 13 safe/read-only or pilot-contained tests across role separation, privacy, scope, lexicons, review workflow, and evidence; pilot exit criteria |
| 6 | **Troubleshooting Guide** | Common issues by symptom — entitlement/classifier availability, separation, scope, detection, review workflow, connectors, and retention/immutability |
| 7 | **Best Practices** | Program design, role separation/privacy, lexicon tuning, review workflow, evidence/recordkeeping, change control, operations |
| — | **Executive Summary** | One-page business framing for decision-makers |

## PowerShell tools (5)
All are **read-only or `-WhatIf` by default**; writes are gated behind `-Commit`, and the irreversible
retention **Preservation Lock** requires an additional explicit switch. **No credentials in code** —
they use interactive modern-auth `Connect-IPPSSession` / `Connect-MgGraph`. Cmdlet and classifier
availability is **plan-dependent — verify in your tenant.**

| Script | Purpose | Default mode |
|---|---|---|
| `CCFIN-Discovery.ps1` | Readiness + role-separation snapshot + existing policies/retention/privacy signals (`FINRA Supervision Roles – Evidence`) | Read-only |
| `CCFIN-Configuration.ps1` | Create/update the supervisory-review policy + rule in **simulation** (lexicons/classifiers/scope/reviewers/sampling); optional evidence-retention config | `-WhatIf` (needs `-Commit`; lock needs an extra switch) |
| `CCFIN-Validation.ps1` | Pass/fail checks: separation, policy scope/composition, reviewers, retention/immutability presence | Read-only |
| `CCFIN-Report.ps1` | Supervision-activity rollup + policy/role/retention inventory (`FINRA Supervision Rollup – Evidence`) | Read-only |
| `CCFIN-EvidenceCheck.ps1` | Scope + evidence health helper: supervised/excluded scope and immutable-retention (17a-4) coverage | Read-only |

## Named artifacts created/used
`FINRA Supervised – Pilot`, `FINRA Excluded – Privacy`, `FINRA Principals – Pilot`,
`FINRA Lexicon – Conduct`, `FINRA Supervision – Pilot – Simulation`, `FINRA Conduct Rule – Pilot`,
`FINRA Comms Records – 17a-4`, `FINRA Supervision Roles – Evidence`, `FINRA Supervision Rollup – Evidence`.

## Definition of done
- Role separation, privacy, and the approved supervised scope are configured and demonstrable.
- The supervisory-review policy runs in **simulation**, surfaces true positives, and suppresses noise
  across all in-scope channels.
- Designated principals can review end-to-end; escalation and Viewer-no-content work; the reviewer trail
  is defensible.
- Immutable communications retention is in effect for the Compliance/Records-approved period where
  required; reporting is examiner-ready.
- All 13 tests pass; expansion proceeds in rings under change control.

## Explicitly deferred (not in this solution)
The **regulatory determination** (which rules apply, whether a communication violates them), the
**retention schedule and immutability decision**, and any **supervisory or disciplinary action** are
owned by the firm's **designated supervisory principals, Compliance, Records, and Legal**. Trade/order
surveillance and third-party archiving products are separate disciplines. This solution delivers the
**technical supervision-and-evidence mechanism**, configured, piloted, and validated.
