# 8. Deliverables Summary — Vendor Technical Governance & Anti-Lock-In Playbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The operating model between the enterprise architect and partners, where architectural authority sits, and the artifacts the method names and reuses |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | The vendor-design review method, the Anti-Lock-In Criteria checklist, the Governance RACI, and the escalation path — in ordered steps |
| 5. Testing Guide | Governance and conformance gates with pass/fail thresholds |
| 6. Troubleshooting Guide | Handling non-conformant designs and field issues |
| 7. Best Practices | Field-proven recommendations for durable partner governance |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWVEND-Discovery.ps1` | Inventories the vendor design register and cross-checks it against vendor-created objects readable in the source Microsoft 365 / Entra environment (read-only) |
| `GWVEND-Validation.ps1` | Scores each design against the four anti-lock-in criteria, confirms every entry is dispositioned, and flags un-approved objects and past-due exceptions (read-only) |
| `GWVEND-Report.ps1` | Review/finding report — per design: criteria results, disposition, open conditions, exceptions (read-only) |
| `GWVEND-Remediation.ps1` | Records remediation actions for non-conformant designs (disposition/condition updates); `-WhatIf` by default |
| `GWVEND-Set-ScopeTargeting.ps1` | Builds and previews the design-authority reviewer and pilot-scope groups |

## The Vendor-Governance Runbook (outline)
A one-page repeatable procedure the enterprise runs for every incoming vendor design, so the method
is executed the same way regardless of partner or architect:

1. **Intake** — log the design in the register (`GWVEND-Discovery.ps1`); assign `DesignId`, owner,
   type, status = proposed.
2. **Assumptions** — extract dependencies into the Vendor Assumption Log; mark each
   validated / unvalidated / rejected.
3. **Baseline review** — compare the design to the Target Architecture Baseline (identity,
   integration, data ownership, standards).
4. **Anti-lock-in scoring** — score all four criteria (`GWVEND-Validation.ps1`): portability, data
   ownership, standards conformance, exit criteria.
5. **Challenge** — require the sanctioned/standard pattern or a documented, accepted reason for any
   proprietary shortcut; require every assumption validated.
6. **Disposition** — record Approved / Approved-with-conditions / Rejected in the Design Review
   Record, with conditions; only Approved (or conditions-met) proceeds to build.
7. **Escalate if blocked** — run the escalation ladder (§6); grant and track a time-boxed exception
   only with owner accountability.
8. **Report & close** — `GWVEND-Report.ps1`; track conditions and exceptions to closure; re-run
   discovery on cadence.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Vendor execution that aligns to the target architecture — assumptions validated, every design
reviewed against a fixed anti-lock-in bar and dispositioned by the enterprise, non-conformant
designs escalated rather than waved through — with architectural authority firmly held by the
enterprise and no long-term lock-in accumulating unseen.
